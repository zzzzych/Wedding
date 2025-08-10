//
//  UpdateRsvpSchemaV2.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/10/25.
//

import Fluent
import Vapor
import Foundation

/// RsvpResponse 테이블을 새로운 스키마로 업데이트하는 마이그레이션 (간소화 버전)
/// 성인/자녀 구분을 제거하고 참석자 이름 배열 방식으로 변경
struct UpdateRsvpSchemaV2: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // 1. 새로운 컬럼들 추가
        return database.schema(RsvpResponse.schema)
            .field("total_count", .int, .required, .custom("DEFAULT 0"))           // 총 참석 인원
            .field("attendee_names", .json, .required, .custom("DEFAULT '[]'"))    // 참석자 이름 배열
            .field("phone_number", .string)                                        // 전화번호 (선택사항)
            .field("message", .string)                                             // 메시지 (선택사항)
            .update()
            .flatMap { _ in
                // 2. 기존 컬럼들 제거 (데이터 마이그레이션 없이 바로 제거)
                return database.schema(RsvpResponse.schema)
                    .deleteField("responder_name")      // 대표 응답자 이름 필드 제거
                    .deleteField("adult_count")         // 성인 인원 필드 제거
                    .deleteField("children_count")      // 자녀 인원 필드 제거
                    .update()
            }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // 롤백 시 기존 스키마로 복원
        return database.schema(RsvpResponse.schema)
            .field("responder_name", .string, .required)    // 대표 응답자 이름 복원
            .field("adult_count", .int, .required)          // 성인 인원 복원
            .field("children_count", .int, .required)       // 자녀 인원 복원
            .deleteField("total_count")                     // 새 필드들 제거
            .deleteField("attendee_names")
            .deleteField("phone_number")
            .deleteField("message")
            .update()
    }
}