// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WeddingInvitationServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 Vapor 프레임워크
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        // 🔍 Fluent ORM - 데이터베이스 연결을 위해 추가
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // 🗃️ SQLite 드라이버 - SQLite 데이터베이스 사용을 위해 추가
        // .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        // PostgreSQL
        .product(name: "FluentPostgreSQLDriver", package: "fluent-postgresql-driver"),
        // 🔐 JWT 라이브러리 - 인증 토큰 생성/검증을 위해 추가
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "WeddingInvitationServer",
            dependencies: [
                // Vapor 프레임워크 의존성
                .product(name: "Vapor", package: "vapor"),
                // Fluent ORM 의존성 - 데이터베이스 모델링
                .product(name: "Fluent", package: "fluent"),
                // SQLite 드라이버 의존성 - SQLite 연결
                // .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                // PostgreSQL
                .package(url: "https://github.com/vapor/fluent-postgresql-driver.git", from: "4.0.0"),
                // JWT 의존성 - 토큰 인증
                .product(name: "JWT", package: "jwt")
            ]
        ),
        .testTarget(
            name: "WeddingInvitationServerTests",
            dependencies: ["WeddingInvitationServer"]
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
