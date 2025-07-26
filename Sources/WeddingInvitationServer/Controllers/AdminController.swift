//
//  AdminController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Fluent
import Vapor
import JWTKit

/// 관리자 인증 관련 API를 처리하는 컨트롤러
struct AdminController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("api", "admin")
        
        // POST /api/admin/login - 관리자 로그인
        admin.post("login", use: login)
    }
    
    // MARK: - POST /api/admin/login
    /// 관리자 로그인 및 JWT 토큰 발급
    func login(req: Request) async throws -> LoginResponse {
        // 1. 요청 데이터 파싱
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // 2. 사용자명으로 관리자 계정 찾기
        guard let adminUser = try await AdminUser.query(on: req.db)
            .filter(\.$username == loginRequest.username)
            .first() else {
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        // 3. 비밀번호 검증
        guard try adminUser.verify(password: loginRequest.password) else {
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        // 4. JWT 토큰 생성
        let payload = AdminJWTPayload(
            sub: SubjectClaim(value: adminUser.id!.uuidString),
            exp: ExpirationClaim(value: Date().addingTimeInterval(60 * 60 * 24)), // 24시간 후 만료
            iat: IssuedAtClaim(value: Date()),
            username: adminUser.username
        )
        
        let token = try req.jwt.sign(payload)
        
        // 5. 응답 반환
        return LoginResponse(
            token: token,
            expiresAt: payload.exp.value,
            username: adminUser.username
        )
    }
}

// MARK: - JWT 미들웨어
/// JWT 토큰을 검증하는 미들웨어
struct AdminAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // 1. Authorization 헤더에서 Bearer 토큰 추출
        guard let bearerAuthorization = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "인증 토큰이 필요합니다.")
        }
        
        // 2. JWT 토큰 검증
        let payload = try request.jwt.verify(bearerAuthorization.token, as: AdminJWTPayload.self)
        
        // 3. 토큰이 유효하면 사용자 정보를 request에 저장
        request.auth.login(AuthenticatedAdmin(
            id: UUID(uuidString: payload.sub.value)!,
            username: payload.username
        ))
        
        // 4. 다음 미들웨어로 요청 전달
        return try await next.respond(to: request)
    }
}

// MARK: - 인증된 관리자 정보
/// 인증된 관리자 정보를 담는 구조체
struct AuthenticatedAdmin: Authenticatable {
    let id: UUID
    let username: String
}
