//
//  RsvpResponse.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/17/25.
//

import Fluent
import Vapor

final class RsvpResponse: Model, Content, @unchecked Sendable {
    
    static let schema = "rsvp_responses"
    
    @ID(key: .id)
    var id: UUID?
    
    // 응답자 이름
    @Field(key: "responder_name")
    var responderName: String
    
    // 참석 여부
    @Field(key: "is_attending")
    var isAttending: Bool
    
    // 참석 인원 - 성인
    @Field(key: "adult_count")
    var adultCount: Int
    
    // 참석 인원 - 자녀
    @Field(key: "children_count")
    var childrenCount: Int
    
    // --- [새로 추가된 부분] ← 여기가 추가됨
    // 응답 생성 시간
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    // 응답 수정 시간
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // 관계 필드 정의
    @Parent(key: "group_id")
    var group: InvitationGroup
    
    init() {}
    
    init(id: UUID? = nil, responderName: String, isAttending: Bool, adultCount: Int, childrenCount: Int, groupID: UUID) {
        self.id = id
        self.responderName = responderName
        self.isAttending = isAttending
        self.adultCount = adultCount
        self.childrenCount = childrenCount
        self.$group.id = groupID
    }
}
