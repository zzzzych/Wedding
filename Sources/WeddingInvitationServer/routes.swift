import Fluent
import Vapor

func routes(_ app: Application) throws {
    // 기본 경로 "/" 로 GET 요청이 오면 "It works!" 라는 문구를 보여줍니다. (기본 코드)
    app.get { req async in
        "It works!"
    }

    // "/hello" 경로로 GET 요청이 오면 "Hello, world!" 라는 문구를 보여줍니다. (기본 코드)
    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    // 컨트롤러 등록
    try app.register(collection: WeddingController())
    try app.register(collection: InvitationController())
    try app.register(collection: RsvpController())
    try app.register(collection: AdminController())  // ← 새로 추가
}
