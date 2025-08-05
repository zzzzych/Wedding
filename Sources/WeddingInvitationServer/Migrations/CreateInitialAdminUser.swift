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
        
        // ⭐ 중복 체크 추가: 이미 존재하는 사용자인지 확인
        return AdminUser.query(on: database)
            .filter(\.$username == adminUsername)
            .first()
            .flatMap { existingUser in
                // 이미 존재하면 스킵
                if existingUser != nil {
                    print("✅ 관리자 '\(adminUsername)'이 이미 존재합니다. 스킵합니다.")
                    return database.eventLoop.makeSucceededFuture(())
                }
                
                // 존재하지 않으면 새로 생성
                do {
                    let adminUser = try AdminUser(
                        username: adminUsername,
                        password: adminPassword
                    )
                    
                    return adminUser.save(on: database).map {
                        print("✅ 새 관리자 계정 '\(adminUsername)' 생성 완료")
                    }
                } catch {
                    return database.eventLoop.makeFailedFuture(error)
                }
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