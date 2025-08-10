//
//  SharedResponseModels.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Fluent
import Vapor
import Foundation

// MARK: - 커스텀 에러 타입

/// 유효성 검증 실패 시 발생하는 에러
struct ValidationError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

// MARK: - 공통 응답 데이터 모델들

/// 간단한 응답 데이터 구조체 (API 응답용)
/// 여러 컨트롤러에서 공통으로 사용하는 응답 데이터 구조체입니다
struct SimpleRsvpResponse: Content {
    /// 응답 고유 ID
    let id: UUID?
    /// 대표 응답자 이름 (첫 번째 참석자 이름)
    let responderName: String
    /// 참석 여부 (true: 참석, false: 불참)
    let isAttending: Bool
    /// 총 참석 인원 수
    let totalCount: Int
    /// 참석자 이름 목록
    let attendeeNames: [String]
    /// 전화번호 (선택사항)
    let phoneNumber: String?
    /// 추가 메시지 (선택사항)
    let message: String?
    /// 응답 제출 시간
    let submittedAt: Date?
    /// 응답 수정 시간 (옵셔널)
    let updatedAt: Date?
    
    /// RsvpResponse 모델에서 SimpleRsvpResponse 생성
    /// 데이터베이스의 RsvpResponse 객체를 API 응답용 구조체로 변환합니다
    /// - Parameter rsvp: 데이터베이스의 RsvpResponse 객체
    /// - Returns: API 응답용 SimpleRsvpResponse 객체
    static func from(_ rsvp: RsvpResponse) -> SimpleRsvpResponse {
        return SimpleRsvpResponse(
            id: rsvp.id,
            responderName: rsvp.responderName,
            isAttending: rsvp.isAttending,
            totalCount: rsvp.totalCount,
            attendeeNames: rsvp.attendeeNames,
            phoneNumber: rsvp.phoneNumber,
            message: rsvp.message,
            submittedAt: rsvp.createdAt,
            updatedAt: rsvp.updatedAt
        )
    }
}

/// 그룹 기본 정보 구조체
/// 응답과 함께 표시할 그룹의 기본 정보를 담는 구조체입니다
struct SimpleGroupInfo: Content {
    /// 그룹 고유 ID
    let id: UUID
    /// 그룹 이름 (예: "신랑 대학 동기")
    let groupName: String
    /// 그룹 타입 (예: "WEDDING_GUEST")
    let groupType: String
    /// 고유 접근 코드 (초대장 링크에 사용)
    let uniqueCode: String
}

/// 그룹 정보가 포함된 응답 데이터
/// 관리자가 응답을 조회할 때 어떤 그룹의 응답인지 알 수 있도록 그룹 정보를 포함합니다
struct SimpleRsvpWithGroupInfo: Content {
    /// 응답 정보
    let response: SimpleRsvpResponse
    /// 속한 그룹의 기본 정보
    let groupInfo: SimpleGroupInfo
    
    /// RsvpResponse와 연관된 그룹에서 생성
    /// 그룹 정보가 로드된 RsvpResponse 객체에서 응답 데이터를 생성합니다
    /// - Parameter rsvp: 그룹 정보가 로드된 RsvpResponse 객체 (.with(\.$group)로 로드된 상태)
    /// - Returns: 그룹 정보가 포함된 응답 데이터
    static func from(_ rsvp: RsvpResponse) -> SimpleRsvpWithGroupInfo {
        return SimpleRsvpWithGroupInfo(
            response: SimpleRsvpResponse.from(rsvp),
            groupInfo: SimpleGroupInfo(
                id: rsvp.group.id!,
                groupName: rsvp.group.groupName,
                groupType: rsvp.group.groupType,
                uniqueCode: rsvp.group.uniqueCode
            )
        )
    }
}

/// 참석 여부 응답 제출 요청 데이터 (새 버전)
struct RsvpRequest: Content {
    /// 참석 여부 (필수)
    /// - true: 참석, false: 불참
    let isAttending: Bool
    
    /// 응답자 이름 (필수) - 불참인 경우에도 응답한 사람의 이름
    let responderName: String?
    
    /// 총 참석 인원 수 (참석인 경우에만 사용)
    /// 불참인 경우 0으로 설정
    let totalCount: Int
    
    /// 참석자 이름 목록 (참석인 경우에만 사용)
    /// 첫 번째 이름이 대표 응답자가 됨
    let attendeeNames: [String]
    
    /// 전화번호 (선택사항)
    let phoneNumber: String?
    
    /// 추가 메시지 (선택사항)
    let message: String?
    
    /// 요청 데이터 유효성 검증
    /// - Throws: 유효하지 않은 데이터가 있을 때 ValidationError
    func validate() throws {
        // 응답자 이름 검증 (참석/불참 관계없이 필수)
        if let name = responderName {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ValidationError("응답자 이름은 필수입니다.")
            }
            guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
                throw ValidationError("응답자 이름은 2글자 이상이어야 합니다.")
            }
        }
        
        // 참석하는 경우 검증
        if isAttending {
            // 총 인원수 검증
            guard totalCount > 0 else {
                throw ValidationError("참석하는 경우 최소 1명 이상의 인원을 입력해야 합니다.")
            }
            
            guard totalCount <= 10 else {
                throw ValidationError("참석 인원은 최대 10명까지 가능합니다.")
            }
            
            // 참석자 이름 목록 검증
            guard attendeeNames.count == totalCount else {
                throw ValidationError("참석 인원 수와 이름 개수가 일치하지 않습니다.")
            }
            
            // 각 이름의 유효성 검증
            for (index, name) in attendeeNames.enumerated() {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    throw ValidationError("\(index + 1)번째 참석자 이름을 입력해주세요.")
                }
                
                guard trimmedName.count <= 50 else {
                    throw ValidationError("\(index + 1)번째 참석자 이름은 50자 이내여야 합니다.")
                }
            }
        } else {
            // 불참하는 경우 검증
            guard totalCount == 0 else {
                throw ValidationError("불참하는 경우 인원수는 0이어야 합니다.")
            }
            
            guard attendeeNames.isEmpty else {
                throw ValidationError("불참하는 경우 참석자 이름을 입력할 수 없습니다.")
            }
        }
        
        // 전화번호 검증 (선택사항)
        if let phone = phoneNumber, !phone.isEmpty {
            let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedPhone.count <= 20 else {
                throw ValidationError("전화번호는 20자 이내여야 합니다.")
            }
        }
        
        // 메시지 길이 검증 (선택사항)
        if let message = message, message.count > 200 {
            throw ValidationError("메시지는 200자 이내여야 합니다.")
        }
    }
}

/// 참석 응답 전체 요약 정보
/// 관리자 대시보드에서 사용할 전체 응답 현황 요약 데이터입니다
struct RsvpSummary: Content {
    /// 총 응답 수 (참석 + 불참)
    let totalResponses: Int
    /// 참석 응답 수
    let attendingResponses: Int
    /// 불참 응답 수
    let notAttendingResponses: Int
    /// 총 참석 예정 인원 (성인 + 자녀)
    let totalAttendingCount: Int
    /// 참석 예정 성인 인원
    let totalAdultCount: Int
    /// 참석 예정 자녀 인원
    let totalChildrenCount: Int
}

/// 개별 응답 목록과 통계가 포함된 전체 응답 데이터
/// 관리자가 개별 응답자 정보와 통계를 함께 확인할 때 사용하는 구조체입니다
struct RsvpListResponse: Content {
    /// 개별 응답 목록 (그룹 정보 포함)
    let responses: [SimpleRsvpWithGroupInfo]
    /// 전체 응답 통계 정보
    let summary: RsvpSummary
}

// MARK: - 그룹 관련 공통 모델들

/// 통계 정보가 포함된 그룹 데이터
struct GroupWithStats: Content {
    /// 그룹 고유 ID
    let id: UUID
    /// 그룹 이름
    let groupName: String
    /// 그룹 타입
    let groupType: String
    /// 고유 접근 코드
    let uniqueCode: String
    /// 그룹별 인사말
    let greetingMessage: String
    /// 총 응답 수 (해당 그룹에서 응답한 사람 수)
    let totalResponses: Int
    /// 참석 응답 수 (해당 그룹에서 참석한다고 응답한 사람 수)
    let attendingResponses: Int
    
    // 기능 설정 필드들
    /// 오시는 길 정보 표시 여부
    let showVenueInfo: Bool?
    /// 공유 버튼 표시 여부
    let showShareButton: Bool?
    /// 본식 순서 표시 여부
    let showCeremonyProgram: Bool?
    /// 참석 응답 폼 표시 여부
    let showRsvpForm: Bool?
    /// 계좌 정보 표시 여부
    let showAccountInfo: Bool?
    /// 포토 갤러리 표시 여부
    let showPhotoGallery: Bool?
}

/// 전체 그룹 목록 응답
/// 관리자가 모든 그룹의 목록과 통계를 한눈에 볼 수 있는 응답 구조체입니다
struct GroupsListResponse: Content {
    /// 총 그룹 수
    let totalGroups: Int
    /// 그룹 목록 (통계 포함)
    let groups: [GroupWithStats]
}

/// 그룹 통계 정보
/// 특정 그룹의 상세한 응답 통계를 제공하는 구조체입니다
struct GroupStatistics: Content {
    /// 총 응답 수
    let totalResponses: Int
    /// 참석 응답 수
    let attendingCount: Int
    /// 총 성인 인원 (참석자만)
    let totalAdults: Int
    /// 총 자녀 인원 (참석자만)
    let totalChildren: Int
}

/// 그룹 상세 정보 응답
/// 관리자가 특정 그룹의 상세 정보와 모든 응답을 확인할 때 사용하는 구조체입니다
struct GroupDetailResponse: Content {
    /// 그룹 기본 정보
    let group: InvitationGroup
    /// 해당 그룹의 모든 응답 목록
    let responses: [SimpleRsvpResponse]
    /// 그룹의 통계 정보
    let statistics: GroupStatistics
}

// MARK: - 요청 데이터 모델들 (통합 정리)

/// 그룹 생성 요청 데이터
/// 관리자가 새로운 초대 그룹을 만들 때 사용하는 요청 구조체입니다
struct CreateGroupRequest: Content {
    /// 그룹 이름 (예: "신랑 대학 동기")
    let groupName: String
    /// 그룹 타입 (예: "WEDDING_GUEST")
    let groupType: String
    /// 그룹별 인사말
    let greetingMessage: String
    /// 사용자 정의 고유 코드 (선택사항)
    let uniqueCode: String?
}

/// 그룹 수정 요청 데이터 (부분 업데이트용)
struct UpdateGroupRequest: Content {
    /// 새로운 그룹 이름 (옵셔널)
    let groupName: String?
    /// 그룹별 인사말 (옵셔널)
    let greetingMessage: String?
    /// 고유 URL 코드 (옵셔널)
    let uniqueCode: String?
    
    // 기능 설정 필드들
    /// 오시는 길 정보 표시 여부 (옵셔널)
    let showVenueInfo: Bool?
    /// 공유 버튼 표시 여부 (옵셔널)
    let showShareButton: Bool?
    /// 본식 순서 표시 여부 (옵셔널)
    let showCeremonyProgram: Bool?
    /// 참석 응답 폼 표시 여부 (옵셔널)
    let showRsvpForm: Bool?
    /// 계좌 정보 표시 여부 (옵셔널)
    let showAccountInfo: Bool?
    /// 포토 갤러리 표시 여부 (옵셔널)
    let showPhotoGallery: Bool?
}