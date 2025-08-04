//
//  AddTimestampsToAdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/4/25.
//

import Fluent

/// AdminUser 테이블에 타임스탬프 필드를 추가하는 마이그레이션
struct AddTimestampsToAdminUser: Migration {
    
    /// 마이그레이션 실행 - created_at, updated_at 컬럼 추가
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            // 생성 시간 컬럼 추가
            .field("created_at", .datetime)
            // 수정 시간 컬럼 추가
            .field("updated_at", .datetime)
            .update() // 기존 테이블 업데이트
    }
    
    /// 마이그레이션 롤백 - 추가했던 컬럼들 삭제
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            .deleteField("created_at")
            .deleteField("updated_at")
            .update()
    }
}
