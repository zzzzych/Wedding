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
    var totalCount: Int {
        return adultCount + childrenCount
    }
    
    /// 응답 제출 시간
    let submittedAt: Date?
    
    /// 응답 수정 시간
    let updatedAt: Date?
    
    /// RsvpResponse 모델에서 RsvpResponseData 생성
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
struct RsvpWithGroupInfo: Content {
    /// 응답 정보
    let response: RsvpResponseData
    
    /// 속한 그룹 정보
    let groupInfo: GroupInfo
    
    /// RsvpResponse와 연관된 그룹에서 생성
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

/// 참석 응답 전체 요약 정보
struct RsvpSummary: Content {
    /// 총 응답 수
    let totalResponses: Int
    
    /// 참석 응답 수
    let attendingCount: Int
    
    /// 불참 응답 수
    let notAttendingCount: Int
    
    /// 총 성인 참석 인원
    let totalAdults: Int
    
    /// 총 자녀 참석 인원
    let totalChildren: Int
    
    /// 총 참석 인원 (성인 + 자녀)
    let totalPeople: Int
    
    /// 개별 응답 목록
    let responses: [RsvpWithGroupInfo]
    
    /// 참석률 (백분율)
    var attendanceRate: Double {
        guard totalResponses > 0 else { return 0.0 }
        return Double(attendingCount) / Double(totalResponses) * 100.0
    }
}
