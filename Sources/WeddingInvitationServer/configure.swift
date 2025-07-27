// Sources/WeddingInvitationServer/configure.swift
@preconcurrency import Fluent
@preconcurrency import FluentSQLiteDriver
@preconcurrency import Vapor

// configure 함수 - 애플리케이션 설정
public func configure(_ app: Application) throws {
    // 데이터베이스 설정
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // CORS 설정 추가 - React 앱에서 API 호출 허용
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .originBased,          // Origin 기반 허용
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS], // 허용할 HTTP 메서드
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith] // 허용할 헤더
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning) // CORS 미들웨어를 가장 먼저 적용
    
    // 마이그레이션 설정 (기존에 있다면 그대로 유지)
    // app.migrations.add(CreateWeddingInfo())
    // app.migrations.add(CreateInvitationGroup())
    // app.migrations.add(CreateRsvpResponse())
    // app.migrations.add(CreateAdminUser())
    
    // 라우터 등록
    try routes(app)
}
