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
        // 환경변수에서 관리자 정보 읽기 (기본값 제공)
        let adminUsername = Environment.get("ADMIN_USERNAME") ?? "admin"
        let adminPassword = Environment.get("ADMIN_PASSWORD") ?? "wedding2025!"
        
        do {
            // 관리자 계정 생성
            let adminUser = try AdminUser(
                username: adminUsername,
                password: adminPassword
            )
            
            // 데이터베이스에 저장
            return adminUser.save(on: database)
        } catch {
            // 에러 발생시 실패한 future 반환
            return database.eventLoop.makeFailedFuture(error)
        }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // 롤백시 생성된 관리자 계정 삭제
        let adminUsername = Environment.get("ADMIN_USERNAME") ?? "admin"
        
        return AdminUser.query(on: database)
            .filter(\.$username == adminUsername)
            .delete()
    }
}
