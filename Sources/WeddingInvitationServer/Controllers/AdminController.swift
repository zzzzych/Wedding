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
        // ✅ 수정 전: let admin = routes.grouped("api", "admin")
        // ✅ 수정 후: routes는 이미 /api 그룹이므로 "admin"만 추가
        let admin = routes.grouped("admin")
        
        // POST /api/admin/login - 관리자 로그인
        admin.post("login", use: login)
    }
    
    // MARK: - POST /api/admin/login
    /// 관리자 로그인 - 실제 JWT 토큰 생성
    func login(req: Request) async throws -> LoginResponse {
        // 🔍 디버깅: 요청 시작 로그
        print("🔐 === 관리자 로그인 요청 시작 ===")
        
        // 1. 요청 데이터 파싱
        let loginRequest = try req.content.decode(LoginRequest.self)
        print("📥 입력된 사용자명: '\(loginRequest.username)'")
        print("📥 입력된 비밀번호: '\(loginRequest.password)'")
        
        // 2. 사용자명으로 관리자 계정 찾기
        guard let adminUser = try await AdminUser.query(on: req.db)
            .filter(\.$username == loginRequest.username)
            .first() else {
            print("❌ 사용자를 찾을 수 없음: '\(loginRequest.username)'")
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        print("✅ 사용자 찾음: '\(adminUser.username)'")
        print("🔒 저장된 해시: '\(adminUser.passwordHash)'")
        print("📏 해시 길이: \(adminUser.passwordHash.count)")
        
        // 3. 비밀번호 검증
        let isPasswordValid = try adminUser.verify(password: loginRequest.password)
        print("🔑 비밀번호 검증 결과: \(isPasswordValid)")
        
        guard isPasswordValid else {
            print("❌ 비밀번호 불일치!")
            throw Abort(.unauthorized, reason: "아이디 또는 비밀번호가 올바르지 않습니다.")
        }
        
        print("✅ 로그인 성공! JWT 토큰 생성 중...")
        
        // 4. JWT 토큰 생성 (기존 코드 그대로)
        let expirationTime = Date().addingTimeInterval(60 * 60 * 24)
        
        let payload = AdminJWTPayload(
            sub: .init(value: adminUser.id?.uuidString ?? UUID().uuidString),
            exp: .init(value: expirationTime),
            iat: .init(value: Date()),
            username: adminUser.username
        )
        
        let token = try req.jwt.sign(payload)
        
        print("🎫 JWT 토큰 생성 완료")
        print("=== 로그인 처리 완료 ===")
        
        // 5. 응답 반환
        return LoginResponse(
            token: token,
            expiresAt: expirationTime,
            username: adminUser.username
        )
    }
}
