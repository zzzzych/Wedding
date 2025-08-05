//
//  AddTimestampsToAdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/4/25.
//

import Fluent
import PostgresKit

/// AdminUser 테이블에 타임스탬프 필드를 추가하는 마이그레이션
struct AddTimestampsToAdminUser: Migration {
    
    /// 마이그레이션 실행 - created_at, updated_at 컬럼 추가
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // ⭐ PostgreSQL에서 각 컬럼의 존재 여부를 개별적으로 확인
        guard let postgres = database as? PostgresDatabase else {
            // PostgreSQL이 아닌 경우 기존 방식 사용 (에러 처리 포함)
            return database.schema("admin_users")
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .update()
                .flatMapError { error in
                    let errorDescription = String(describing: error)
                    if errorDescription.contains("already exists") || 
                       errorDescription.contains("42701") {
                        print("✅ 타임스탬프 컬럼들이 이미 존재합니다. 스킵합니다.")
                        return database.eventLoop.makeSucceededVoidFuture()
                    }
                    return database.eventLoop.makeFailedFuture(error)
                }
        }
        
        // created_at 컬럼 존재 여부 확인
        let checkCreatedAtQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'admin_users' 
            AND column_name = 'created_at'
        """
        
        // updated_at 컬럼 존재 여부 확인
        let checkUpdatedAtQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'admin_users' 
            AND column_name = 'updated_at'
        """
        
        return postgres.query(checkCreatedAtQuery)
            .flatMap { createdAtRows in
                return postgres.query(checkUpdatedAtQuery)
                    .flatMap { updatedAtRows in
                        let createdAtExists = !createdAtRows.isEmpty
                        let updatedAtExists = !updatedAtRows.isEmpty
                        
                        // 둘 다 이미 존재하는 경우
                        if createdAtExists && updatedAtExists {
                            print("✅ created_at, updated_at 컬럼들이 이미 존재합니다. 스킵합니다.")
                            return database.eventLoop.makeSucceededVoidFuture()
                        }
                        
                        // 필요한 컬럼만 추가
                        var schema = database.schema("admin_users")
                        
                        if !createdAtExists {
                            schema = schema.field("created_at", .datetime)
                            print("📝 created_at 컬럼을 추가합니다.")
                        }
                        
                        if !updatedAtExists {
                            schema = schema.field("updated_at", .datetime)
                            print("📝 updated_at 컬럼을 추가합니다.")
                        }
                        
                        // 추가할 컬럼이 있는 경우에만 실행
                        if !createdAtExists || !updatedAtExists {
                            return schema.update().map {
                                print("✅ 타임스탬프 컬럼 추가 완료")
                            }
                        } else {
                            return database.eventLoop.makeSucceededVoidFuture()
                        }
                    }
            }
            .flatMapError { error in
                // 쿼리 실행 중 오류가 발생한 경우에도 안전하게 처리
                let errorDescription = String(describing: error)
                if errorDescription.contains("already exists") || 
                   errorDescription.contains("42701") {
                    print("✅ 타임스탬프 컬럼들이 이미 존재합니다. (에러 캐치)")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                print("❌ 타임스탬프 마이그레이션 오류: \(error)")
                return database.eventLoop.makeFailedFuture(error)
            }
    }
    
    /// 마이그레이션 롤백 - 추가했던 컬럼들 삭제
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("admin_users")
            .deleteField("created_at")
            .deleteField("updated_at")
            .update()
    }
}