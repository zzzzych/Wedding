//
//  RemoveVenuePhoneFromWeddingInfo.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/8/25.
//

import Fluent
import PostgresKit

/// WeddingInfo 테이블에서 불필요한 컬럼들을 삭제하는 마이그레이션
struct RemoveVenuePhoneFromWeddingInfo: Migration {
    
    /// 마이그레이션 실행 - venue_phone, venue_detail, google_map_url 컬럼 삭제
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // PostgreSQL에서 컬럼 존재 여부 확인
        guard let postgres = database as? PostgresDatabase else {
            // PostgreSQL이 아닌 경우 일반적인 방법 사용
            return database.schema("wedding_infos")
                .deleteField("venue_phone")
                .deleteField("venue_detail")
                .deleteField("google_map_url")  // 🆕 추가
                .update()
                .flatMapError { error in
                    let errorDescription = String(describing: error)
                    if errorDescription.contains("does not exist") || 
                       errorDescription.contains("42703") {
                        print("✅ 불필요한 컬럼들이 이미 존재하지 않습니다. 스킵합니다.")
                        return database.eventLoop.makeSucceededVoidFuture()
                    }
                    return database.eventLoop.makeFailedFuture(error)
                }
        }
        
        // 컬럼들 존재 여부 개별 확인
        let checkVenuePhoneQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'wedding_infos' 
            AND column_name = 'venue_phone'
        """
        
        let checkVenueDetailQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'wedding_infos' 
            AND column_name = 'venue_detail'
        """
        
        let checkGoogleMapUrlQuery = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'wedding_infos' 
            AND column_name = 'google_map_url'
        """
        
        return postgres.query(checkVenuePhoneQuery)
            .flatMap { venuePhoneRows in
                return postgres.query(checkVenueDetailQuery)
                    .flatMap { venueDetailRows in
                        return postgres.query(checkGoogleMapUrlQuery)
                            .flatMap { googleMapUrlRows in
                                let venuePhoneExists = !venuePhoneRows.isEmpty
                                let venueDetailExists = !venueDetailRows.isEmpty
                                let googleMapUrlExists = !googleMapUrlRows.isEmpty
                                
                                // 모든 컬럼이 존재하지 않는 경우
                                if !venuePhoneExists && !venueDetailExists && !googleMapUrlExists {
                                    print("✅ venue_phone, venue_detail, google_map_url 컬럼이 존재하지 않습니다. 스킵합니다.")
                                    return database.eventLoop.makeSucceededVoidFuture()
                                }
                                
                                // 존재하는 컬럼만 삭제
                                var schema = database.schema("wedding_infos")
                                var hasColumnsToDelete = false
                                
                                if venuePhoneExists {
                                    schema = schema.deleteField("venue_phone")
                                    print("📝 venue_phone 컬럼을 삭제합니다.")
                                    hasColumnsToDelete = true
                                }
                                
                                if venueDetailExists {
                                    schema = schema.deleteField("venue_detail")
                                    print("📝 venue_detail 컬럼을 삭제합니다.")
                                    hasColumnsToDelete = true
                                }
                                
                                if googleMapUrlExists {
                                    schema = schema.deleteField("google_map_url")
                                    print("📝 google_map_url 컬럼을 삭제합니다.")
                                    hasColumnsToDelete = true
                                }
                                
                                // 삭제할 컬럼이 있는 경우에만 실행
                                if hasColumnsToDelete {
                                    return schema.update()
                                        .map {
                                            print("✅ 불필요한 컬럼들 삭제 완료")
                                        }
                                } else {
                                    return database.eventLoop.makeSucceededVoidFuture()
                                }
                            }
                    }
            }
            .flatMapError { error in
                let errorDescription = String(describing: error)
                if errorDescription.contains("does not exist") || 
                   errorDescription.contains("42703") {
                    print("✅ 불필요한 컬럼들이 존재하지 않습니다. (에러 캐치)")
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                print("❌ 마이그레이션 오류: \(error)")
                return database.eventLoop.makeFailedFuture(error)
            }
    }

    /// 마이그레이션 롤백 - 컬럼들 다시 추가 (필요시)
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("wedding_infos")
            .field("venue_phone", .string)
            .field("venue_detail", .string)
            .field("google_map_url", .string)  // 🆕 추가
            .update()
    }
}