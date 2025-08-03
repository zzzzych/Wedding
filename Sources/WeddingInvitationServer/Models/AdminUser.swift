//
//  AdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/20/25.
//

import Fluent
import Vapor
import JWTKit

// Sendable 관련 에러 방지를 위해 클래스 선언부에 `, @unchecked Sendable` 추가
final class AdminUser: Model, Content, @unchecked Sendable, Authenticatable {
    
    // 1. 테이블 이름 정의
    static let schema = "admin_users"
    
    // 2. 고유 ID 필드 정의
    @ID(key: .id)
    var id: UUID?
    
    // 3. 데이터 필드 정의
    // 관리자 로그인 아이디
    @Field(key: "username")
    var username: String
    
    // 암호화 된 비밀번호
    // 보안을 위해 실제 비밀번호가 아닌, 해싱된 결과 값 저장
    @Field(key: "password_hash")
    var passwordHash: String
    
    //사용자 생성
    @Field(key: "role")
    var role: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // 4. 기본 생성자
    init() {}
    
    // ✅ 평문 비밀번호를 받는 생성자 (role 매개변수 추가)
    init(id: UUID? = nil, username: String, password: String, role: String = "admin") throws {
        self.id = id
        self.username = username
        self.passwordHash = try Bcrypt.hash(password)
        self.role = role
    }

    // ✅ 해싱된 비밀번호용 생성자 (role 매개변수 추가)
    internal init(id: UUID? = nil, username: String, passwordHash: String, role: String = "admin") {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.role = role
    }
    
    /// 입력된 비밀번호가 저장된 해시와 일치하는지 검증
    /// - Parameter password: 검증할 평문 비밀번호
    /// - Returns: 비밀번호 일치 여부
    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }
    
    /// 비밀번호 변경
    /// - Parameter newPassword: 새로운 평문 비밀번호
    func updatePassword(_ newPassword: String) throws {
        self.passwordHash = try Bcrypt.hash(newPassword)
    }
}

// --- [새로 추가: 로그인 관련 DTO] ---
/// 로그인 요청 데이터
struct LoginRequest: Content {
    let username: String
    let password: String
}

/// 로그인 응답 데이터
struct LoginResponse: Content {
    let token: String
    let expiresAt: Date
    let username: String
}

// Sources/WeddingInvitationServer/Models/AdminUser.swift 파일에서 AdminJWTPayload 부분 수정

/// JWT 페이로드 - Authenticatable 프로토콜 추가
struct AdminJWTPayload: JWTPayload, Authenticatable {
    // JWT의 기본 클레임들
    var sub: SubjectClaim    // 사용자 ID
    var exp: ExpirationClaim // 만료 시간
    var iat: IssuedAtClaim   // 발급 시간
    
    // 커스텀 클레임
    var username: String
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
