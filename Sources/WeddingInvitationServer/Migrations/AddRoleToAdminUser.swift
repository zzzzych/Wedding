//
//  AddRoleToAdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/3/25.
//

import Fluent

/// AdminUser 테이블에 role 컬럼을 추가하는 마이그레이션
struct AddRoleToAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // ⭐ 에러를 캐치해서 컬럼이 이미 존재하면 무시
        return database.schema("admin_users")
            .field("role", .string, .required, .custom("DEFAULT 'admin'"))
            .update()
            .flatMapError { error in
                // 에러 메시지에 "already exists"가 포함되어 있으면 무시
                let errorDescription = String(describing: error)
                if errorDescription.contains("already exists") || 
                   errorDescription.contains("42701") {
                    print("✅ role 컬럼이 이미 존재합니다. 스킵합니다.")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                // 다른 에러는 그대로 전파
                return database.eventLoop.makeFailedFuture(error)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            .deleteField("role")
            .update()
    }
}