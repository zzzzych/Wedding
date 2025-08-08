//
//  ForceRemoveVenueColumns.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/9/25.
//

import Fluent
import PostgresKit

/// venue_detail과 google_map_url 컬럼을 강제로 삭제하는 마이그레이션
struct ForceRemoveVenueColumns: Migration {
    
    /// 마이그레이션 실행 - venue_detail, google_map_url 컬럼 강제 삭제
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // 각 컬럼을 개별적으로 삭제 시도
        let deleteVenueDetail = database.schema("wedding_infos")
            .deleteField("venue_detail")
            .update()
            .flatMapError { error in
                // 컬럼이 존재하지 않는 경우 무시
                database.eventLoop.makeSucceededVoidFuture()
            }
        
        let deleteGoogleMapUrl = database.schema("wedding_infos")
            .deleteField("google_map_url") 
            .update()
            .flatMapError { error in
                // 컬럼이 존재하지 않는 경우 무시
                database.eventLoop.makeSucceededVoidFuture()
            }
        
        return deleteVenueDetail.flatMap { _ in
            return deleteGoogleMapUrl
        }
    }

    /// 마이그레이션 롤백 - 컬럼들 다시 추가 (필요시)
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("wedding_infos")
            .field("venue_detail", .string)
            .field("google_map_url", .string)
            .update()
    }
}