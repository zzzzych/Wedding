// Sources/WeddingInvitationServer/routes.swift
@preconcurrency import Fluent
@preconcurrency import Vapor

// 🏗️ API 응답을 위한 구조체들 (이름 변경)
struct InvitationAPIResponse: Content {
    let groupName: String
    let groupType: String
    let groomName: String
    let brideName: String
    let weddingDate: String
    let weddingLocation: String
    let greetingMessage: String
    let ceremonyProgram: String
    let accountInfo: [String]
    let features: InvitationFeatures
}

struct InvitationFeatures: Content {
    let showRsvpForm: Bool
    let showAccountInfo: Bool
    let showShareButton: Bool
    let showVenueInfo: Bool
    let showPhotoGallery: Bool
    let showCeremonyProgram: Bool
}

// 라우트 설정 함수
func routes(_ app: Application) throws {
    
    // ✅ 추가: 서버 시작 시 테스트 데이터 자동 생성
    app.get("setup-test-data") { req async throws -> String in
        // wedding123 그룹이 이미 존재하는지 확인
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == "wedding123")
            .first()
        
        if existingGroup == nil {
            // 없으면 새로 생성
            let testGroup = InvitationGroup()
            testGroup.groupName = "결혼식 초대 그룹"
            testGroup.groupType = GroupType.weddingGuest.rawValue
            testGroup.uniqueCode = "wedding123"
            
            try await testGroup.save(on: req.db)
            return "✅ wedding123 그룹이 데이터베이스에 생성되었습니다!"
        } else {
            return "✅ wedding123 그룹이 이미 존재합니다!"
        }
    }
    
    // 기존 코드들...
    
    // 기본 루트 - 서버 상태 확인용
    app.get { req async in
        return "Wedding Invitation Server is running! 💍"
    }
    
    // ✅ RsvpController 등록 아래에 추가
    try app.register(collection: RsvpController())
    // AdminController 등록
    try app.register(collection: AdminController())
    // InvitationController 등록 - 누락된 부분 추가
    try app.register(collection: InvitationController())
    
    // API 그룹 생성 (/api/...)
    let api = app.grouped("api")
    
    // 4. 모든 그룹 조회 API (관리자용)
    // GET /api/groups
    api.get("groups") { req async throws -> Response in
        let jsonString = """
        [
            {
                "id": "1",
                "groupName": "결혼식 초대 그룹",
                "groupType": "WEDDING_GUEST",
                "uniqueCode": "wedding123",
                "createdAt": "2025-01-01T00:00:00Z"
            },
            {
                "id": "2",
                "groupName": "부모님 그룹",
                "groupType": "PARENTS_GUEST",
                "uniqueCode": "parent456",
                "createdAt": "2025-01-01T00:00:00Z"
            },
            {
                "id": "3",
                "groupName": "회사 그룹",
                "groupType": "COMPANY_GUEST",
                "uniqueCode": "company789",
                "createdAt": "2025-01-01T00:00:00Z"
            }
        ]
        """
        
        let response = Response(
            status: .ok,
            headers: HTTPHeaders([("Content-Type", "application/json")]),
            body: .init(string: jsonString)
        )
        return response
    }
}
