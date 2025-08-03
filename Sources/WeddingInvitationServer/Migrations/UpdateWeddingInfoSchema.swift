//
//  UpdateWeddingInfoSchema.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Fluent

/// WeddingInfo 테이블에 지도 및 상세 주소 필드를 추가하는 마이그레이션
struct UpdateWeddingInfoSchema: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(WeddingInfo.schema)
            // 기존 wedding_location 필드 삭제
            .deleteField("wedding_location")
            
            // 새로운 웨딩홀 정보 필드들 추가
            .field("venue_name", .string, .required)           // 웨딩홀 이름
            .field("venue_address", .string, .required)        // 기본 주소
            .field("venue_detail", .string, .required)         // 상세 위치
            
            // 지도 링크 필드들 추가
            .field("kakao_map_url", .string)                   // 카카오맵 링크
            .field("naver_map_url", .string)                   // 네이버지도 링크
            
            // 교통/주차 정보 필드들 추가
            .field("parking_info", .string)                    // 주차 안내
            .field("transport_info", .string)                  // 대중교통 안내
            
            .update()
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(WeddingInfo.schema)
            // 추가된 필드들 삭제
            .deleteField("venue_name")
            .deleteField("venue_address")
            .deleteField("venue_detail")
            .deleteField("kakao_map_url")
            .deleteField("naver_map_url")
            .deleteField("parking_info")
            .deleteField("transport_info")
            
            // 기존 필드 복원
            .field("wedding_location", .string, .required)
            
            .update()
    }
}
