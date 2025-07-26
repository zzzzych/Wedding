// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WeddingInvitationServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        
        // 🗄️ An ORM for Swift and Vapor. (데이터베이스 작업을 위한 Fluent)
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        
        // SQLite3 driver for Fluent. (개발용 데이터베이스 드라이버)
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        
        // 보안 라이브러리
        // 🔐 JWT tokens in Swift
            .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        
        // 🔒 Bcrypt hashing for Vapor
        // Note: Bcrypt는 Vapor 4에 내장되어 있어 별도 패키지 불필요
        
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "WeddingInvitationServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                
                // --- [JWT 의존성 추가] ---
                .product(name: "JWTKit", package: "jwt-kit"),
                
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WeddingInvitationServerTests",
            dependencies: [
                .target(name: "WeddingInvitationServer"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
