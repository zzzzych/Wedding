//
//  UpdateRsvpSchemaV3.swift  // ✅ 파일명 변경
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/10/25.
//

import Fluent
import Vapor
import Foundation

/// RsvpResponse 테이블을 새로운 스키마로 업데이트하는 마이그레이션 V3 (강제 타입 변경)
struct UpdateRsvpSchemaV3: Migration {  // ✅ 구조체명 변경
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // 1. 기존 rsvp_responses 테이블 완전 삭제 (데이터 포함)
        return database.schema(RsvpResponse.schema)
            .delete()
            .flatMap { _ in
                // 2. 새로운 스키마로 테이블 재생성
                return database.schema(RsvpResponse.schema)
                    .id()
                    .field("is_attending", .bool, .required)
                    .field("total_count", .int, .required, .custom("DEFAULT 0"))
                    .field("attendee_names", .array(of: .string), .required, .custom("DEFAULT '{}'"))
                    .field("phone_number", .string)
                    .field("message", .string)
                    .field("created_at", .datetime)
                    .field("updated_at", .datetime)
                    .field("group_id", .uuid, .required, .references("invitation_groups", "id"))
                    .create()
            }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        return database.schema(RsvpResponse.schema).delete()
    }
}