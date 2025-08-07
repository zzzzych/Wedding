//
//  RemoveVenuePhoneFromWeddingInfo.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/8/25.
//

import Fluent
import PostgresKit

/// WeddingInfo 테이블에서 venue_phone 컬럼을 삭제하는 마이그레이션
struct RemoveVenuePhoneFromWeddingInfo: Migration {
    
    /// 마이그레이션 실행 - venue_phone 컬럼 삭제
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // PostgreSQL에서 컬럼 존재 여부 확인
        guard let postgres = database as? PostgresDatabase else {
            // PostgreSQL이 아닌 경우 일반적인 방법 사용
            return database.schema("wedding_infos")
                .deleteField("venue_phone")
                .update()
                .flatMapError { error in
                    let errorDescription = String(describing: error)
                    if errorDescription.contains("does not exist") || 
                       errorDescription.contains("42703") {
                        print("✅ venue_phone 컬럼이 이미 존재하지 않습니다. 스킵합니다.")
                        return database.eventLoop.makeSucceededVoidFuture()
                    }
                    return database.eventLoop.makeFailedFuture(error)
                }
        }
        
        // PostgreSQL에서 컬럼 존재 여부 확인
        let checkQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'wedding_infos' 
            AND column_name = 'venue_phone'
        """
        
        return postgres.query(checkQuery)
            .flatMap { rows in
                // venue_phone 컬럼이 존재하지 않는 경우
                if rows.isEmpty {
                    print("✅ venue_phone 컬럼이 존재하지 않습니다. 스킵합니다.")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                
                // venue_phone 컬럼이 존재하는 경우에만 삭제
                print("📝 venue_phone 컬럼을 삭제합니다.")
                return database.schema("wedding_infos")
                    .deleteField("venue_phone")
                    .update()
                    .map {
                        print("✅ venue_phone 컬럼 삭제 완료")
                    }
            }
            .flatMapError { error in
                // 쿼리 실행 중 오류가 발생한 경우에도 안전하게 처리
                let errorDescription = String(describing: error)
                if errorDescription.contains("does not exist") || 
                   errorDescription.contains("42703") {
                    print("✅ venue_phone 컬럼이 존재하지 않습니다. (에러 캐치)")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                print("❌ 마이그레이션 오류: \(error)")
                return database.eventLoop.makeFailedFuture(error)
            }
    }

    /// 마이그레이션 롤백 - venue_phone 컬럼 다시 추가 (필요시)
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("wedding_infos")
            .field("venue_phone", .string)
            .update()
    }
}