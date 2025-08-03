//
//  UpdateExistingAdminRole.swift
//  WeddingInvitationServer
//
//  Created by Admin on [현재날짜]
//

import Fluent

/// 기존 관리자 계정들에 기본 role 값을 설정하는 마이그레이션
struct UpdateExistingAdminRole: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // ✅ 모든 기존 관리자를 조회해서 role이 없으면 'admin'으로 설정
        return AdminUser.query(on: database)
            .all()
            .flatMap { adminUsers in
                let updates = adminUsers.compactMap { user -> EventLoopFuture<Void>? in
                    // role이 비어있거나 설정되지 않은 경우에만 업데이트
                    if user.role.isEmpty {
                        user.role = "admin"
                        return user.save(on: database)
                    }
                    return nil
                }
                
                return EventLoopFuture<Void>.andAllSucceed(updates, on: database.eventLoop)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        // 롤백: admin role을 가진 사용자들의 role을 빈 문자열로 변경
        return AdminUser.query(on: database)
            .filter(\.$role == "admin")
            .all()
            .flatMap { adminUsers in
                let updates = adminUsers.map { user in
                    user.role = ""
                    return user.save(on: database)
                }
                
                return EventLoopFuture<Void>.andAllSucceed(updates, on: database.eventLoop)
            }
    }
}
