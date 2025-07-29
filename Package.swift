// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WeddingInvitationServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 기존 dependencies...
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"), // ✅ 추가
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0")
    ],

    targets: [
        .executableTarget(
            name: "WeddingInvitationServer",
            dependencies: [
                        .product(name: "Fluent", package: "fluent"),
                        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"), // ✅ 추가
                        .product(name: "Vapor", package: "vapor"),
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
