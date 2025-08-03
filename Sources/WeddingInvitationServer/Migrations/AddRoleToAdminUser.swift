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
        return database.schema("admin_users")
            .field("role", .string, .required, .custom("DEFAULT 'admin'"))
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            .deleteField("role")
            .update()
    }
}
