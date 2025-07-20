//
//  RsvpResponse.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/17/25.
//

import Fluent
import Vapor

// Sendable 관련 에러 방지를 위해 클래스 선언부에 `, @unchecked Sendable` 추가
final class RsvpResponse: Model, Content, @unchecked Sendable {
    
    // 1. 테이블 이름 정의
    static let schema = "rsvp_responses"
    
    // 2. 고유 ID 필드 정의
    @ID(key: .id)
    var id: UUID?
    
    // 3. 데이터 필드 정의
    // 응답자 이름
    @Field(key: "responder_name")
    var responderName: String
    
    // 참석 여부
    // Bool은 참(true) 또는 거짓(false) 값만 저장하는 타입
    @Field(key: "is_attending")
    var isAttending: Bool
    
    // 참석 인원 - 성인
    // Int는 정수(Integer) 값만 저장하는 타입
    @Field(key: "adult_count")
    var adultCount: Int
    
    // 참석 인원 - 자녀
    @Field(key: "children_count")
    var childrenCount: Int
    
    // 4. 관계 필드 정의
    // @Parent: 이 필드가 부모 모델과의 관계를 나타냄을 의미합니다.
    // (key: "group_id"): 데이터베이스에 'group_id'라는 이름으로 부모의 ID를 저장할 칸을 만듭니다.
    // var group: InvitationGroup: 이 응답(자식)이 속한 부모가 'InvitationGroup' 타입임을 선언합니다.
    @Parent(key: "group_id")
    var group: InvitationGroup
    
    // 5. 기본 생성자
    init() {}
    
    // 6. 사용자 정의 생성자
    init(id: UUID? = nil, responderName: String, isAttending: Bool, adultCount: Int, childrenCount: Int, groupID: UUID) {
        self.id = id
        self.responderName = responderName
        self.isAttending = isAttending
        self.adultCount = adultCount
        self.childrenCount = childrenCount
        // 관계를 설정할 때는 '$' 기호를 붙여 ID를 직접 할당해줍니다.
        // "이 응답의 부모 ID는, 전달받은 groupID 값이야" 라는 뜻입니다.
        self.$group.id = groupID
    }
}
