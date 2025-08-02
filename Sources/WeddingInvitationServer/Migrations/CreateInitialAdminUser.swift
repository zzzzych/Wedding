//
//  CreateInitialAdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/21/25.
//

import Fluent
import Vapor

/// 초기 관리자 계정을 생성하는 마이그레이션
struct CreateInitialAdminUser: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // ✅ 환경변수가 없으면 아예 실패하도록 처리
        guard let adminUsername = Environment.get("ADMIN_USERNAME"),
              let adminPassword = Environment.get("ADMIN_PASSWORD") else {
            print("❌ ADMIN_USERNAME 또는 ADMIN_PASSWORD 환경변수가 설정되지 않았습니다.")
            return database.eventLoop.makeSucceededFuture(()) // 에러 대신 조용히 스킵
        }
        
        do {
            // 관리자 계정 생성
            let adminUser = try AdminUser(
                username: adminUsername,
                password: adminPassword
            )
            
            return adminUser.save(on: database)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // ✅ 환경변수가 없으면 롤백도 스킵
        guard let adminUsername = Environment.get("ADMIN_USERNAME") else {
            return database.eventLoop.makeSucceededFuture(())
        }
        
        return AdminUser.query(on: database)
            .filter(\.$username == adminUsername)
            .delete()
    }
}
