@preconcurrency import Fluent
@preconcurrency import FluentPostgresDriver
@preconcurrency import Vapor
@preconcurrency import JWT

// 애플리케이션의 서비스와 설정을 구성하는 함수
public func configure(_ app: Application) async throws {
    // 🗃️ PostgreSQL 데이터베이스 설정
    // ✅ PostgreSQL 데이터베이스 설정 (SSL 비활성화)
    guard let databaseURL = Environment.get("DATABASE_URL") else {
        fatalError("DATABASE_URL 환경변수가 설정되지 않았습니다.")
    }

    // PostgreSQL URL을 파싱해서 SSL을 비활성화하고 연결
    try app.databases.use(.postgres(url: databaseURL + "?sslmode=disable"), as: .psql)
    
    // 🔐 JWT 설정 추가
    let jwtSecret = Environment.get("JWT_SECRET") ?? "your-256-bit-secret-key-here-make-it-very-long-and-secure"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    
    // 🌐 CORS 설정 - React 앱에서 API 호출 허용
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .custom("https://leelee.kr"),  // ✅ 구체적인 도메인 지정
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .HEAD, .PATCH],
        allowedHeaders: [
            .accept,
            .authorization,
            .contentType,
            .origin,
            .xRequestedWith,
            .userAgent,
            .accessControlAllowOrigin,
            .accessControlAllowHeaders,
            .accessControlAllowMethods,
            .cacheControl,
            .ifModifiedSince
        ],
        allowCredentials: true  // ✅ 인증 정보 허용 추가
    )
    
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    
    // CORS 미들웨어를 앱에 추가
    app.middleware.use(corsMiddleware, at: .beginning)
    
    // 🔄 마이그레이션 등록 - 순서대로 실행됩니다
    app.migrations.add(CreateWeddingSchema())                    // 1. 메인 테이블들 생성
    app.migrations.add(CreateInitialAdminUser())                 // 2. 관리자 계정 생성  
    app.migrations.add(AddRoleToAdminUser())                     // 3. role 컬럼 추가
    app.migrations.add(AddTimestampsToAdminUser())               // 4. AdminUser 타임스탬프 컬럼 추가
    app.migrations.add(UpdateExistingAdminRole())                // 5. 기존 관리자에 role 설정
    app.migrations.add(RemoveVenuePhoneFromWeddingInfo())        // 🆕 6. venue_phone 컬럼 삭제
    app.migrations.add(ForceRemoveVenueColumns())                // 🔥 7. 강제 컬럼 삭제
    // 다음 라인들을 삭제해주세요:
    // app.migrations.add(AddFeatureSettingsToInvitationGroup()) // ❌ 삭제 - CreateWeddingSchema에 이미 포함됨
    
    // 🚀 서버 시작 시 자동으로 마이그레이션 실행
    try await app.autoMigrate()
    
    // 🌐 라우트 등록
    try routes(app)
}