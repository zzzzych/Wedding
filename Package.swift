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
        // 🗃️ SQLite 드라이버 (로컬용)
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        // 🗃️ PostgreSQL 드라이버 (Railway용)
        .package(url: "https://github.com/vapor/fluent-postgresql-driver.git", from: "4.0.0"),
        // 🔐 JWT 라이브러리
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "WeddingInvitationServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "FluentPostgreSQLDriver", package: "fluent-postgresql-driver"),
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
