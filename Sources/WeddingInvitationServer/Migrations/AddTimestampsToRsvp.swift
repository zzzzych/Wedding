//
//  AddTimestampsToRsvp.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent

/// RsvpResponse 테이블에 타임스탬프 필드 추가하는 마이그레이션
struct AddTimestampsToRsvp: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(RsvpResponse.schema)
            .field("created_at", .datetime)    // 생성 시간
            .field("updated_at", .datetime)    // 수정 시간
            .update()
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(RsvpResponse.schema)
            .deleteField("created_at")
            .deleteField("updated_at")
            .update()
    }
}
