@preconcurrency import Fluent
@preconcurrency import FluentPostgresDriver
@preconcurrency import Vapor
@preconcurrency import JWT

// 애플리케이션의 서비스와 설정을 구성하는 함수
public func configure(_ app: Application) async throws {
    // 🗃️ PostgreSQL 데이터베이스 설정
    try app.databases.use(.postgres(url: Environment.get("DATABASE_URL")!), as: .psql)

    
    // 🔐 JWT 설정 추가
    let jwtSecret = Environment.get("JWT_SECRET") ?? "your-256-bit-secret-key-here-make-it-very-long-and-secure"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    
    // 🌐 CORS 설정 - React 앱에서 API 호출 허용
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .originBased,          // Origin 기반 허용
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS], // 허용할 HTTP 메서드
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith] // 허용할 헤더
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning) // CORS 미들웨어를 가장 먼저 적용
    
    // 🔄 마이그레이션 등록 - 새로 생성한 마이그레이션 추가
    // 마이그레이션 추가 - 순서가 중요합니다!
    // configure.swift 파일에서 마이그레이션 부분
    app.migrations.add(CreateWeddingSchema())        // ✅ 메인 테이블들
    app.migrations.add(CreateInitialAdminUser())     // ✅ 관리자 계정 생성
//    app.migrations.add(AddFeatureSettingsToInvitationGroup())

    
    // 🚀 서버 시작 시 자동으로 마이그레이션 실행
    try await app.autoMigrate()
    
    // 🌐 라우트 등록
    try routes(app)
}
