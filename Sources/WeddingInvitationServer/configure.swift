import Fluent
import FluentSQLiteDriver
import Vapor

// configure(_:) 함수는 Vapor 애플리케이션이 시작되기 전에 호출되어
// 필요한 모든 서비스와 설정을 등록하는 역할을 합니다.
// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // 1. 데이터베이스 설정
    // 우리 앱의 데이터베이스로 SQLite를 사용하겠다고 등록합니다.
    // .sqlite(.file("db.sqlite")): 데이터는 프로젝트 폴더에 생성될 "db.sqlite"라는 파일에 저장됩니다.
    // as: .sqlite: 이 데이터베이스를 앞으로 ".sqlite"라는 ID로 부르겠다고 별명을 지어줍니다.
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // 2. 마이그레이션 등록
    // 우리가 Migrations 폴더에 만들었던 CreateWeddingSchema를
    // 앱이 실행해야 할 마이그레이션 목록에 추가합니다.
    app.migrations.add(CreateWeddingSchema())

    // 3. 라우트 등록
    // routes.swift 파일에 정의된 API 경로들을 앱에 등록합니다.
    try routes(app)
}
