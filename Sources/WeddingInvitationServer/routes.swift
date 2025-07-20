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

    // --- [추가된 부분] ---
    // 우리가 만든 WeddingController를 앱에 등록합니다.
    // 이제 앱은 WeddingController 안에 어떤 기능들이 있는지 알게 됩니다.
    try app.register(collection: WeddingController())
}
