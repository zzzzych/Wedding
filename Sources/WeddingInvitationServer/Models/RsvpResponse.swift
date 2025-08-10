//
//  RsvpResponse.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/17/25.
//

import Fluent
import Vapor

/// 참석 응답 데이터베이스 모델 (새 버전)
final class RsvpResponse: Model, Content, @unchecked Sendable {
    
    static let schema = "rsvp_responses"
    
    @ID(key: .id)
    var id: UUID?
    
    /// 참석 여부 (true: 참석, false: 불참)
    @Field(key: "is_attending")
    var isAttending: Bool
    
    /// 총 참석 인원 수 (참석인 경우에만 의미있음)
    @Field(key: "total_count")
    var totalCount: Int
    
    /// 참석자 이름 목록 (JSON 배열로 저장)
    /// 첫 번째 이름이 대표 응답자가 됨
    @Field(key: "attendee_names")
    var attendeeNames: [String]
    
    /// 전화번호 (선택사항)
    @OptionalField(key: "phone_number")
    var phoneNumber: String?
    
    /// 추가 메시지 (선택사항)
    @OptionalField(key: "message")
    var message: String?
    
    /// 응답 생성 시간
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    /// 응답 수정 시간
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    /// 관계 필드 - 어떤 그룹의 응답인지
    @Parent(key: "group_id")
    var group: InvitationGroup
    
    /// 빈 초기화 함수 (Fluent 요구사항)
    init() {}
    
    /// 새 응답 생성 초기화 함수
    /// - Parameters:
    ///   - id: 응답 고유 ID (선택사항)
    ///   - isAttending: 참석 여부
    ///   - totalCount: 총 참석 인원
    ///   - attendeeNames: 참석자 이름 목록
    ///   - phoneNumber: 전화번호 (선택사항)
    ///   - message: 추가 메시지 (선택사항)
    ///   - groupID: 속한 그룹의 ID
    init(id: UUID? = nil, 
         isAttending: Bool, 
         totalCount: Int, 
         attendeeNames: [String], 
         phoneNumber: String? = nil, 
         message: String? = nil, 
         groupID: UUID) {
        self.id = id
        self.isAttending = isAttending
        self.totalCount = totalCount
        self.attendeeNames = attendeeNames
        self.phoneNumber = phoneNumber
        self.message = message
        self.$group.id = groupID
    }
    
    /// 대표 응답자 이름 (첫 번째 참석자 이름)
    /// 불참인 경우 "미응답자"를 반환
    var responderName: String {
        if isAttending && !attendeeNames.isEmpty {
            return attendeeNames[0]
        } else {
            return "미응답자"
        }
    }
}