//
//  AdminController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//
import Fluent
import Vapor
// import JWTKit  // 임시 주석 처리

/// 관리자 인증 관련 API를 처리하는 컨트롤러
struct AdminController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("api", "admin")
        
        // POST /api/admin/login - 관리자 로그인
        admin.post("login", use: login)
    }
    
    // MARK: - POST /api/admin/login
    /// 관리자 로그인 (임시로 간단한 응답만 반환)
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
        
        // 4. 임시 토큰 반환 (실제 JWT는 나중에 구현)
        return LoginResponse(
            token: "temporary-token-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(60 * 60 * 24),
            username: adminUser.username
        )
    }
}

// MARK: - JWT 미들웨어
/// JWT 토큰을 검증하는 미들웨어
struct AdminAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
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
