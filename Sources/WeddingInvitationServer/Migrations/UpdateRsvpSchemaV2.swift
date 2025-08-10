//
//  UpdateRsvpSchemaV2.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/10/25.
//

import Fluent
import Vapor
import Foundation

/// RsvpResponse 테이블을 새로운 스키마로 업데이트하는 마이그레이션 (강제 타입 변경 버전)
/// 성인/자녀 구분을 제거하고 참석자 이름 배열 방식으로 변경
struct UpdateRsvpSchemaV2: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // 1. 기존 rsvp_responses 테이블 완전 삭제 (데이터 포함)
        return database.schema(RsvpResponse.schema)
            .delete()
            .flatMap { _ in
                // 2. 새로운 스키마로 테이블 재생성
                return database.schema(RsvpResponse.schema)
                    .id()
                    .field("is_attending", .bool, .required)                                        // 참석 여부
                    .field("total_count", .int, .required, .custom("DEFAULT 0"))                   // 총 참석 인원
                    .field("attendee_names", .array(of: .string), .required, .custom("DEFAULT '{}'"))  // 참석자 이름 배열 (text[])
                    .field("phone_number", .string)                                                // 전화번호 (선택사항)
                    .field("message", .string)                                                     // 메시지 (선택사항)
                    .field("created_at", .datetime)                                                // 생성 시간
                    .field("updated_at", .datetime)                                                // 수정 시간
                    .field("group_id", .uuid, .required, .references("invitation_groups", "id"))   // 그룹 참조
                    .create()
            }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // 롤백 시 기존 스키마로 복원
        return database.schema(RsvpResponse.schema)
            .delete()
            .flatMap { _ in
                return database.schema(RsvpResponse.schema)
                    .id()
                    .field("responder_name", .string, .required)    // 대표 응답자 이름
                    .field("is_attending", .bool, .required)        // 참석 여부
                    .field("adult_count", .int, .required)          // 성인 인원
                    .field("children_count", .int, .required)       // 자녀 인원
                    .field("created_at", .datetime)                 // 생성 시간
                    .field("updated_at", .datetime)                 // 수정 시간
                    .field("group_id", .uuid, .required, .references("invitation_groups", "id"))
                    .create()
            }
    }
}