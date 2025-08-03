//
//  AdminModels.swift
//  WeddingInvitationServer
//
//  Created by Admin on [현재날짜]
//

import Fluent
import Vapor

/// 새 관리자 생성 요청 모델
struct CreateAdminRequest: Content {
    /// 새 관리자의 사용자명
    let username: String
    
    /// 새 관리자의 비밀번호
    let password: String
    
    /// 새 관리자의 역할 (기본값: "admin")
    let role: String
    
    /// 유효성 검사
    func validate() throws {
        // 사용자명 검증
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "사용자명은 필수입니다.")
        }
        
        guard username.count >= 3 else {
            throw Abort(.badRequest, reason: "사용자명은 3글자 이상이어야 합니다.")
        }
        
        guard username.count <= 20 else {
            throw Abort(.badRequest, reason: "사용자명은 20글자 이하여야 합니다.")
        }
        
        // 비밀번호 검증
        guard !password.isEmpty else {
            throw Abort(.badRequest, reason: "비밀번호는 필수입니다.")
        }
        
        guard password.count >= 4 else {
            throw Abort(.badRequest, reason: "비밀번호는 4글자 이상이어야 합니다.")
        }
        
        // 역할 검증
        let validRoles = ["admin", "super_admin", "manager"]
        guard validRoles.contains(role) else {
            throw Abort(.badRequest, reason: "유효하지 않은 역할입니다. (admin, super_admin, manager 중 선택)")
        }
    }
}

/// 관리자 생성 응답 모델
struct AdminCreateResponse: Content {
    /// 생성된 관리자 ID
    let id: String
    
    /// 생성된 관리자 사용자명
    let username: String
    
    /// 생성된 관리자 역할
    let role: String
    
    /// 생성 일시
    let createdAt: Date
    
    /// 성공 메시지
    let message: String
}

/// 관리자 목록 조회 응답 모델
struct AdminListResponse: Content {
    /// 관리자 목록
    let admins: [AdminInfo]
    
    /// 전체 관리자 수
    let totalCount: Int
}

/// 관리자 정보 모델 (비밀번호 제외)
struct AdminInfo: Content {
    /// 관리자 ID
    let id: String
    
    /// 사용자명
    let username: String
    
    /// 역할
    let role: String
    
    /// 생성 일시
    let createdAt: Date
    
    /// 마지막 로그인 시간 (옵셔널)
    let lastLoginAt: Date?
}
