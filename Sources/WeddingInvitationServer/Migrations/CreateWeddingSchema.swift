//
//  CreateWeddingSchema.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/20/25.
//


import Fluent

struct CreateWeddingSchema: Migration {
    
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // 먼저 WeddingInfo 테이블을 새로운 구조로 만듭니다.
        database.schema(WeddingInfo.schema)
            .id()
            .field("groom_name", .string, .required)
            .field("bride_name", .string, .required)
            .field("wedding_date", .datetime, .required)
            
            // === 새로운 웨딩홀 정보 필드들 ===
            .field("venue_name", .string, .required)
            .field("venue_address", .string, .required)
            .field("venue_detail", .string, .required)
            .field("venue_phone", .string)
            
            // === 지도 링크 필드들 ===
            .field("kakao_map_url", .string)
            .field("naver_map_url", .string)
            .field("google_map_url", .string)
            
            // === 교통/주차 정보 ===
            .field("parking_info", .string)
            .field("transport_info", .string)
            
            // === 기존 필드들 ===
            .field("greeting_message", .string, .required)
            .field("ceremony_program", .string, .required)
            .field("account_info", .array(of: .string), .required)
            .create()
            .flatMap {
                // InvitationGroup 테이블 생성 부분을 찾아서
                database.schema(InvitationGroup.schema)
                    .id()
                    .field("group_name", .string, .required)
                    .field("group_type", .string, .required)
                    .field("unique_code", .string, .required)
                    // ✅ 누락된 필드 추가
                    .field("greeting_message", .string, .required)
                    // ✅ 기능 설정 필드들도 함께 추가
                    .field("show_venue_info", .bool)
                    .field("show_share_button", .bool)
                    .field("show_ceremony_program", .bool)
                    .field("show_rsvp_form", .bool)
                    .field("show_account_info", .bool)
                    .field("show_photo_gallery", .bool)
                    .unique(on: "unique_code")
                    .create()
            }.flatMap {
                // AdminUser 테이블 생성
                database.schema(AdminUser.schema)
                    .id()
                    .field("username", .string, .required)
                    .unique(on: "username")
                    .field("password_hash", .string, .required)
                    .create()
            }.flatMap {
                // RsvpResponse 테이블 생성
                database.schema(RsvpResponse.schema)
                    .id()
                    .field("responder_name", .string, .required)
                    .field("is_attending", .bool, .required)
                    .field("adult_count", .int, .required)
                    .field("children_count", .int, .required)
                    .field("created_at", .datetime)
                    .field("updated_at", .datetime)
                    .field("group_id", .uuid, .required, .references(InvitationGroup.schema, "id"))
                    .create()
            }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(RsvpResponse.schema).delete()
            .flatMap { database.schema(AdminUser.schema).delete() }
            .flatMap { database.schema(InvitationGroup.schema).delete() }
            .flatMap { database.schema(WeddingInfo.schema).delete() }
    }
}
