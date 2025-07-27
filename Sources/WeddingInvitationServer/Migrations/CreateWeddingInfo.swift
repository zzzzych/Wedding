//
//  CreateWeddingInfo.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/27/25.
//

@preconcurrency import Fluent

// 🏗️ WeddingInfo 테이블 생성을 위한 마이그레이션
struct CreateWeddingInfo: AsyncMigration {
    // ⬆️ 마이그레이션 실행 (테이블 생성)
    func prepare(on database: Database) async throws {
        try await database.schema("wedding_info")
            // 🆔 기본 키 (UUID)
            .id()
            // 👰 신랑 이름
            .field("groom_name", .string, .required)
            // 👰 신부 이름
            .field("bride_name", .string, .required)
            // 📅 결혼식 날짜
            .field("wedding_date", .datetime, .required)
            // 🏛️ 예식장 이름
            .field("venue_name", .string, .required)
            // 📍 예식장 주소
            .field("venue_address", .string, .required)
            // 📝 예식장 상세 정보
            .field("venue_detail", .string)
            // 📞 예식장 전화번호
            .field("venue_phone", .string)
            // 🗺️ 카카오맵 URL
            .field("kakao_map_url", .string)
            // 🗺️ 네이버맵 URL
            .field("naver_map_url", .string)
            // 🗺️ 구글맵 URL
            .field("google_map_url", .string)
            // 🚗 주차 안내
            .field("parking_info", .string)
            // 🚌 교통 안내
            .field("transport_info", .string)
            // 💌 인사말
            .field("greeting_message", .string, .required)
            // 📋 본식 순서
            .field("ceremony_program", .string, .required)
            // 💳 계좌 정보 (JSON 배열)
            .field("account_info", .json, .required)
            // ⏰ 생성 일시
            .field("created_at", .datetime)
            // ⏰ 수정 일시
            .field("updated_at", .datetime)
            .create()
    }
    
    // ⬇️ 마이그레이션 되돌리기 (테이블 삭제)
    func revert(on database: Database) async throws {
        try await database.schema("wedding_info").delete()
    }
}
