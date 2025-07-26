import Fluent
import FluentSQLiteDriver
import Vapor
import JWTKit

public func configure(_ app: Application) async throws {
    // CORS 설정
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    // 정적 파일 서빙
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // 데이터베이스 설정
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // === 마이그레이션 등록 (순서 중요!) ===
    // 1. 기본 스키마 생성 또는 업데이트된 스키마 생성
    app.migrations.add(CreateWeddingSchema())
    
    // 2. 초기 관리자 계정 생성
    app.migrations.add(CreateInitialAdminUser())
    
    // 3. 스키마 업데이트 (이미 CreateWeddingSchema에 포함되어 있으므로 제거)
    // app.migrations.add(UpdateWeddingInfoSchema())  // <- 이 줄 주석 처리 또는 삭제

    // 라우트 등록
    try routes(app)
}
