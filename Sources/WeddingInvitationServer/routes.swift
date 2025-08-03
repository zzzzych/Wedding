// Sources/WeddingInvitationServer/routes.swift
@preconcurrency import Fluent
@preconcurrency import Vapor

// 🏗️ API 응답을 위한 구조체들
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
    
    // 기본 루트 - 서버 상태 확인용
    app.get { req async in
        return "Wedding Invitation Server is running! 💍"
    }
        
    // Hello 테스트 경로
    app.get("hello") { req async in
        return "Hello, world!"
    }
    
    // 마이그레이션 실행 경로
    app.get("run-migrations") { req async throws -> String in
        try await app.autoMigrate()
        return "✅ PostgreSQL 마이그레이션이 성공적으로 완료되었습니다!"
    }
    
    // 테스트 데이터 생성 경로
    app.get("setup-test-data") { req async throws -> String in
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == "wedding123")
            .first()
        
        if existingGroup == nil {
            let testGroup = InvitationGroup()
            testGroup.groupName = "결혼식 초대 그룹"
            testGroup.groupType = GroupType.weddingGuest.rawValue
            testGroup.uniqueCode = "wedding123"
            testGroup.greetingMessage = "저희의 소중한 날에 함께해주셔서 감사합니다."
            
            try await testGroup.save(on: req.db)
            return "✅ wedding123 그룹이 데이터베이스에 생성되었습니다!"
        } else {
            return "✅ wedding123 그룹이 이미 존재합니다!"
        }
    }
    
    // 기본 데이터 생성 및 확인
    app.get("ensure-default-data") { req async throws -> String in
        var messages: [String] = []
        
        do {
            // 1. 결혼식 정보 확인 및 생성
            let existingWedding = try await WeddingInfo.query(on: req.db).first()
            if existingWedding == nil {
                let weddingInfo = WeddingInfo()
                weddingInfo.groomName = "이지환"
                weddingInfo.brideName = "이윤진"
                weddingInfo.weddingDate = Date()
                weddingInfo.venueName = "포포인츠 바이 쉐라톤 조선 서울역"
                weddingInfo.venueAddress = "서울특별시 용산구 한강대로 366"
                weddingInfo.venueDetail = "19층"
                weddingInfo.greetingMessage = "두 손 잡고 걷다보니 즐거움만 가득, 더 큰 즐거움의 시작에 함께 해주세요."
                weddingInfo.ceremonyProgram = "오후 6시 예식"
                weddingInfo.accountInfo = ["농협 121065-56-105215 (고인옥 / 신랑母)"]
                
                try await weddingInfo.save(on: req.db)
                messages.append("✅ 기본 결혼식 정보 생성")
            } else {
                messages.append("✅ 결혼식 정보 존재")
            }
            
            // 2. 테스트 그룹 확인 및 생성
            let existingGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$uniqueCode == "wedding123")
                .first()
            
            if existingGroup == nil {
                let testGroup = InvitationGroup(
                    groupName: "결혼식 초대 그룹",
                    groupType: GroupType.weddingGuest.rawValue,
                    greetingMessage: "저희의 소중한 날에 함께해주셔서 감사합니다."
                )
                testGroup.uniqueCode = "wedding123"
                try await testGroup.save(on: req.db)
                messages.append("✅ 테스트 그룹(wedding123) 생성")
            } else {
                messages.append("✅ 테스트 그룹 존재")
            }
            
            return messages.joined(separator: "\n")
            
        } catch {
            return "❌ 기본 데이터 확인 실패: \(error)"
        }
    }
    
    // ✅ 핵심 수정: API 그룹 생성 (/api/...)
    let api = app.grouped("api")
    
    // ✅ 모든 컨트롤러를 /api 그룹 하위에 등록
    try api.register(collection: InvitationController())
    try api.register(collection: AdminController())
    try api.register(collection: RsvpController())
    try api.register(collection: WeddingController())
}
