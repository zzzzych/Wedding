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
        
        // POST /api/admin/create-admin - 새 관리자 생성
        // JWT 보호된 라우트 그룹 생성
        let protected = admin.grouped(AdminJWTAuthenticator())
        protected.post("create-admin", use: createAdmin)
        
        protected.get("list", use: getAdminList)
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
    
    // Sources/WeddingInvitationServer/Controllers/AdminController.swift 파일에 추가할 코드

    // MARK: - POST /api/admin/create-admin
    /// 새 관리자 계정 생성 (기존 관리자만 가능)
    func createAdmin(req: Request) async throws -> AdminCreateResponse {
        // 🔐 JWT 토큰 검증 (기존 관리자만 새 관리자 생성 가능)
        let payload = try req.auth.require(AdminJWTPayload.self)
        print("🔐 관리자 생성 요청 - 인증된 사용자: \(payload.username)")
        
        // 1. 요청 데이터 파싱
        let createRequest = try req.content.decode(CreateAdminRequest.self)
        print("📥 생성할 관리자 정보: 사용자명='\(createRequest.username)', 역할='\(createRequest.role)'")
        
        // 2. 유효성 검사 실행
        do {
            try createRequest.validate()
            print("✅ 유효성 검사 통과")
        } catch let error as AbortError {
            print("❌ 유효성 검사 실패: \(error.reason)")
            throw error
        }
        
        // 3. 중복 사용자명 확인
        let existingUser = try await AdminUser.query(on: req.db)
            .filter(\.$username == createRequest.username.trimmingCharacters(in: .whitespacesAndNewlines))
            .first()
        
        if existingUser != nil {
            print("❌ 중복된 사용자명: '\(createRequest.username)'")
            throw Abort(.conflict, reason: "이미 존재하는 사용자명입니다.")
        }
        
        // 4. 새 관리자 계정 생성
        do {
            let newAdmin = try AdminUser(
                username: createRequest.username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: createRequest.password,
                role: createRequest.role
            )
            
            // 5. 데이터베이스에 저장
            try await newAdmin.save(on: req.db)
            print("✅ 새 관리자 계정 생성 완료: '\(newAdmin.username)', ID: \(newAdmin.id?.uuidString ?? "N/A")")
            
            // 6. 응답 반환 (비밀번호는 제외)
            return AdminCreateResponse(
                id: newAdmin.id?.uuidString ?? "",
                username: newAdmin.username,
                role: newAdmin.role,
                createdAt: newAdmin.createdAt ?? Date(),
                message: "관리자 계정이 성공적으로 생성되었습니다."
            )
            
        } catch let error as AbortError {
            // AbortError는 그대로 전달
            throw error
        } catch {
            // 기타 에러 처리
            print("❌ 관리자 생성 중 오류 발생: \(error)")
            throw Abort(.internalServerError, reason: "관리자 계정 생성 중 오류가 발생했습니다.")
        }
    }
    
    // AdminController.swift에 추가할 메서드

    // MARK: - GET /api/admin/list
    /// 관리자 목록 조회 (기존 관리자만 가능)
    func getAdminList(req: Request) async throws -> AdminListResponse {
        // 🔐 JWT 토큰 검증
        let payload = try req.auth.require(AdminJWTPayload.self)
        print("🔍 관리자 목록 조회 요청 - 인증된 사용자: \(payload.username)")
        
        // 모든 관리자 조회 (비밀번호 제외)
        let adminUsers = try await AdminUser.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()
        
        // AdminInfo 모델로 변환
        let adminInfos = adminUsers.map { admin in
            AdminInfo(
                id: admin.id?.uuidString ?? "",
                username: admin.username,
                role: admin.role,
                createdAt: admin.createdAt ?? Date(),
                lastLoginAt: nil // 추후 구현 시 업데이트
            )
        }
        
        print("✅ 관리자 목록 조회 완료: 총 \(adminInfos.count)명")
        
        return AdminListResponse(
            admins: adminInfos,
            totalCount: adminInfos.count
        )
    }
}
