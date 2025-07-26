//
//  RsvpResponseData.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Fluent
import Vapor
import Foundation

/// 참석 응답 데이터 (API 응답용)
/// 이 구조체는 데이터베이스의 RsvpResponse를 API 응답용으로 변환할 때 사용됩니다
struct RsvpResponseData: Content {
    /// 응답 고유 ID
    let id: UUID?
    
    /// 응답자 이름
    let responderName: String
    
    /// 참석 여부 (true: 참석, false: 불참)
    let isAttending: Bool
    
    /// 성인 참석 인원 수
    let adultCount: Int
    
    /// 자녀 참석 인원 수
    let childrenCount: Int
    
    /// 총 참석 인원 수 (성인 + 자녀)
    /// 계산된 프로퍼티로 성인과 자녀 인원의 합계를 자동으로 반환합니다
    var totalCount: Int {
        return adultCount + childrenCount
    }
    
    /// 응답 제출 시간
    let submittedAt: Date?
    
    /// 응답 수정 시간
    let updatedAt: Date?
    
    /// RsvpResponse 모델에서 RsvpResponseData 생성
    /// 데이터베이스 모델을 API 응답용 구조체로 변환하는 팩토리 메서드입니다
    /// - Parameter rsvp: 데이터베이스의 RsvpResponse 객체
    /// - Returns: API 응답용 RsvpResponseData 객체
    static func from(_ rsvp: RsvpResponse) -> RsvpResponseData {
        return RsvpResponseData(
            id: rsvp.id,
            responderName: rsvp.responderName,
            isAttending: rsvp.isAttending,
            adultCount: rsvp.adultCount,
            childrenCount: rsvp.childrenCount,
            submittedAt: rsvp.createdAt,
            updatedAt: rsvp.updatedAt
        )
    }
}

/// 그룹 정보가 포함된 참석 응답 데이터
/// 관리자가 응답을 조회할 때 어떤 그룹의 응답인지 알 수 있도록 그룹 정보를 포함합니다
struct RsvpWithGroupInfo: Content {
    /// 응답 정보
    let response: RsvpResponseData
    
    /// 속한 그룹 정보
    let groupInfo: GroupInfo
    
    /// RsvpResponse와 연관된 그룹에서 생성
    /// 그룹 정보가 로드된 RsvpResponse 객체에서 응답 데이터를 생성합니다
    /// - Parameter rsvp: 그룹 정보가 로드된 RsvpResponse 객체
    /// - Returns: 그룹 정보가 포함된 응답 데이터
    static func from(_ rsvp: RsvpResponse) -> RsvpWithGroupInfo {
        return RsvpWithGroupInfo(
            response: RsvpResponseData.from(rsvp),
            groupInfo: GroupInfo(
                id: rsvp.group.id!,
                groupName: rsvp.group.groupName,
                groupType: rsvp.group.groupType,
                uniqueCode: rsvp.group.uniqueCode
            )
        )
    }
}

/// 그룹 기본 정보
/// 응답과 함께 표시할 그룹의 기본 정보를 담는 구조체입니다
struct GroupInfo: Content {
    /// 그룹 고유 ID
    let id: UUID
    
    /// 그룹 이름 (예: "신랑 대학 동기")
    let groupName: String
    
    /// 그룹 타입 (예: "WEDDING_GUEST")
    let groupType: String
    
    /// 고유 접근 코드
    let uniqueCode: String
}

// 주의: RsvpSummary는 SharedResponseModels.swift에서 정의되어 있으므로
// 여기서는 제거합니다. 중복 선언을 방지하기 위함입니다.
