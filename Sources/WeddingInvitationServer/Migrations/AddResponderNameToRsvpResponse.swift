//
//  AddResponderNameToRsvpResponse.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/10/25.
//

import Fluent

/// RSVP 응답 테이블에 응답자 이름 필드를 추가하는 마이그레이션
struct AddResponderNameToRsvpResponse: AsyncMigration {
    
    /// 마이그레이션 실행 (필드 추가)
    func prepare(on database: Database) async throws {
        try await database.schema("rsvp_responses")
            .field("responder_name", .string) // 선택적 필드로 추가 (required 제거)
            .update()
    }
    
    /// 마이그레이션 롤백 (필드 삭제)
    func revert(on database: Database) async throws {
        try await database.schema("rsvp_responses")
            .deleteField("responder_name")
            .update()
    }
}