//
//  AdminController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

@preconcurrency import Fluent
@preconcurrency import Vapor
@preconcurrency import JWT

/// 관리자 인증 관련 API를 처리하는 컨트롤러
struct AdminController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("api", "admin")
        
        // POST /api/admin/login - 관리자 로그인
        admin.post("login", use: login)
    }
    
    // MARK: - POST /api/admin/login
    /// 관리자 로그인 - 실제 JWT 토큰 생성
    func login(req: Request) async throws -> LoginResponse {
        // 1. 요청 데이터 파싱
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // 2. 사용자명으로 관리자 계정 찾기
        guard let adminUser = try await AdminUser.query(on: req.db)
            .filter(\.$username == loginRequest.username)
            .first() else {
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        // 3. 임시 비밀번호 검증 (테스트용)
        guard try adminUser.verify(password: loginRequest.password) else {
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        // 4. JWT 토큰 생성
        let expirationTime = Date().addingTimeInterval(60 * 60 * 24) // 24시간 후 만료
        
        let payload = AdminJWTPayload(
            sub: .init(value: adminUser.id?.uuidString ?? UUID().uuidString),
            exp: .init(value: expirationTime),
            iat: .init(value: Date()),
            username: adminUser.username
        )
        
        // JWT 토큰 서명
        let token = try req.jwt.sign(payload)
        
        // 5. 응답 반환
        return LoginResponse(
            token: token,
            expiresAt: expirationTime,
            username: adminUser.username
        )
    }
}
