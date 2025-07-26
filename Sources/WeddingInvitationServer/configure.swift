import Fluent
import FluentSQLiteDriver
import Vapor
import JWTKit

public func configure(_ app: Application) async throws {
    // --- [JWT 설정 - 임시 주석 처리] ---
    // let jwtSecret = Environment.get("JWT_SECRET") ?? "your-256-bit-secret-key-here-change-in-production"
    // app.jwt.signers.use(.hs256(key: Data(jwtSecret.utf8)))
    
    // --- [새로 추가: CORS 설정] ---
    // 프론트엔드와의 연동을 위한 CORS 설정
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,  // 개발용 - 운영시에는 특정 도메인으로 제한
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    // --- [기존 코드] ---
    // 정적 파일 서빙 (Public 폴더)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // 데이터베이스 설정
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // 마이그레이션 등록
    app.migrations.add(CreateWeddingSchema())
    
    // --- [새로 추가: 초기 관리자 계정 생성을 위한 마이그레이션] ---
    app.migrations.add(CreateInitialAdminUser())

    // 라우트 등록
    try routes(app)
}
