@preconcurrency import Fluent
@preconcurrency import FluentSQLiteDriver
@preconcurrency import Vapor
@preconcurrency import JWT

// 애플리케이션의 서비스와 설정을 구성하는 함수
public func configure(_ app: Application) async throws {
    // 🗃️ SQLite 데이터베이스 설정
    // 데이터베이스 파일을 프로젝트 루트의 db.sqlite에 저장
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
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
    app.migrations.add(CreateWeddingSchema())        // 1번: 모든 테이블 생성
    app.migrations.add(CreateInitialAdminUser())     // 2번: 초기 데이터 삽입

    
    // 🚀 서버 시작 시 자동으로 마이그레이션 실행
    try await app.autoMigrate()
    
    // 🌐 라우트 등록
    try routes(app)
}
