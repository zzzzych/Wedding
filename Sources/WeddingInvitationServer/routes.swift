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
    
    // ✅ 수정된 setup-test-data 라우트
    app.get("setup-test-data") { req async throws -> String in
        // wedding123 그룹이 이미 존재하는지 확인
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == "wedding123")
            .first()
        
        if existingGroup == nil {
            // 없으면 새로 생성 (greetingMessage 추가)
            let testGroup = InvitationGroup()
            testGroup.groupName = "결혼식 초대 그룹"
            testGroup.groupType = GroupType.weddingGuest.rawValue
            testGroup.uniqueCode = "wedding123"
            testGroup.greetingMessage = "저희의 소중한 날에 함께해주셔서 감사합니다."  // ✅ 추가
            
            try await testGroup.save(on: req.db)
            return "✅ wedding123 그룹이 데이터베이스에 생성되었습니다!"
        } else {
            return "✅ wedding123 그룹이 이미 존재합니다!"
        }
    }
    
    app.get("run-migrations") { req async throws -> String in
        try await app.autoMigrate()
        return "✅ PostgreSQL 마이그레이션이 성공적으로 완료되었습니다!"
    }
    
    // 기본 루트 - 서버 상태 확인용
    app.get { req async in
        return "Wedding Invitation Server is running! 💍"
    }
        
    // Hello 테스트 경로
    app.get("hello") { req async in
        return "Hello, world!"
    }
    // ✅ RsvpController 등록 아래에 추가
    try app.register(collection: RsvpController())
    // AdminController 등록
    try app.register(collection: AdminController())
    // InvitationController 등록 - 누락된 부분 추가
//    try app.register(collection: InvitationController())
    // routes.swift 파일의 맨 아래에 다음 줄을 추가하세요
    try app.register(collection: WeddingController())
    
    
    // API 그룹 생성 (/api/...)
    let api = app.grouped("api")
    
    // WeddingInfo 기본 데이터 생성 라우트 추가
    app.get("create-wedding-data") { req async throws -> String in
        // 기존 결혼식 정보가 있는지 확인
        let existingWedding = try await WeddingInfo.query(on: req.db).first()
        
        if existingWedding == nil {
            // 기본 결혼식 정보 생성
            let weddingInfo = WeddingInfo()
            weddingInfo.groomName = "이지환"
            weddingInfo.brideName = "이윤진"
            weddingInfo.weddingDate = Date()
            weddingInfo.venueName = "포포인츠 바이 쉐라톤 조선 서울역"
            weddingInfo.venueAddress = "서울 용산구 한강대로 366 포포인츠바이쉐라톤조선 서울역"
            weddingInfo.venueDetail = "포포인츠 바이 쉐라톤 조선 서울역 19층"
            weddingInfo.greetingMessage = "저희 두 사람의 새로운 시작을 축복해주세요."
            weddingInfo.ceremonyProgram = "오후 6시 예식"
            weddingInfo.accountInfo = ["농협 121065-56- 105215 (고인옥 / 신랑母)"]
            
            try await weddingInfo.save(on: req.db)
            return "✅ 기본 결혼식 정보가 생성되었습니다!"
        } else {
            return "✅ 결혼식 정보가 이미 존재합니다!"
        }
    }
    
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
    
    // ✅ 임시 단순 그룹 조회 API 추가
    app.get("api", "admin", "groups") { req async throws -> Response in
        do {
            let groups = try await InvitationGroup.query(on: req.db).all()
            
            // 단순 JSON 응답 생성
            let simpleGroups = groups.map { group in
                return [
                    "id": group.id?.uuidString ?? "",
                    "groupName": group.groupName,
                    "groupType": group.groupType,
                    "uniqueCode": group.uniqueCode,
                    "greetingMessage": group.greetingMessage,
                    "totalResponses": 0,
                    "attendingResponses": 0
                ]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: simpleGroups)
            let response = Response(status: .ok, body: .init(data: jsonData))
            response.headers.contentType = .json
            return response
            
        } catch {
            print("❌ 그룹 조회 에러:", error)
            let errorResponse = ["error": true, "message": "그룹 조회 실패: \(error)"]
            let jsonData = try JSONSerialization.data(withJSONObject: errorResponse)
            let response = Response(status: .internalServerError, body: .init(data: jsonData))
            response.headers.contentType = .json
            return response
        }
    }
}
