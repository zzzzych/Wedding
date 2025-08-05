//
//  AddRoleToAdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/3/25.
//

import Fluent
import PostgresKit

/// AdminUser 테이블에 role 컬럼을 추가하는 마이그레이션
struct AddRoleToAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // ⭐ PostgreSQL 전용 방법으로 컬럼 존재 여부 확인
        guard let postgres = database as? PostgresDatabase else {
            // PostgreSQL이 아닌 경우 기존 방식 사용
            return database.schema("admin_users")
                .field("role", .string, .required, .custom("DEFAULT 'admin'"))
                .update()
                .flatMapError { error in
                    let errorDescription = String(describing: error)
                    if errorDescription.contains("already exists") || 
                       errorDescription.contains("42701") {
                        print("✅ role 컬럼이 이미 존재합니다. 스킵합니다.")
                        return database.eventLoop.makeSucceededVoidFuture()
                    }
                    return database.eventLoop.makeFailedFuture(error)
                }
        }
        
        // PostgreSQL에서 컬럼 존재 여부 확인
        let checkQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'admin_users' 
            AND column_name = 'role'
        """
        
        return postgres.query(checkQuery)
            .flatMap { rows in
                // role 컬럼이 이미 존재하는 경우
                if !rows.isEmpty {
                    print("✅ role 컬럼이 이미 존재합니다. 스킵합니다.")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                
                // role 컬럼이 존재하지 않는 경우에만 추가
                return database.schema("admin_users")
                    .field("role", .string, .required, .custom("DEFAULT 'admin'"))
                    .update()
                    .map {
                        print("✅ role 컬럼 추가 완료")
                    }
            }
            .flatMapError { error in
                // 쿼리 실행 중 오류가 발생한 경우에도 안전하게 처리
                let errorDescription = String(describing: error)
                if errorDescription.contains("already exists") || 
                   errorDescription.contains("42701") {
                    print("✅ role 컬럼이 이미 존재합니다. (에러 캐치)")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                print("❌ 마이그레이션 오류: \(error)")
                return database.eventLoop.makeFailedFuture(error)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            .deleteField("role")
            .update()
    }
}