//
//  FixAttendeeNamesColumnType.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/10/25.
//

import Fluent
import Vapor
import Foundation

/// attendee_names 컬럼의 타입을 jsonb에서 text[]로 수정하는 마이그레이션
/// 이는 Swift의 [String] 배열과 PostgreSQL의 호환성 문제를 해결합니다
struct FixAttendeeNamesColumnType: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // PostgreSQL에서 jsonb를 text[] 배열로 변경
        return database.schema(RsvpResponse.schema)
            .deleteField("attendee_names")  // 기존 jsonb 컬럼 삭제
            .update()
            .flatMap { _ in
                // text[] 타입으로 새로 생성
                return database.schema(RsvpResponse.schema)
                    .field("attendee_names", .array(of: .string), .required, .custom("DEFAULT '{}'"))
                    .update()
            }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // 롤백 시 다시 jsonb로 복원
        return database.schema(RsvpResponse.schema)
            .deleteField("attendee_names")
            .update()
            .flatMap { _ in
                return database.schema(RsvpResponse.schema)
                    .field("attendee_names", .json, .required, .custom("DEFAULT '[]'"))
                    .update()
            }
    }
}