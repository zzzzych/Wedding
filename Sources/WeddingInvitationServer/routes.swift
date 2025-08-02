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
    try app.register(collection: InvitationController())
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
    
    // ✅ 데이터베이스 완전 초기화 + 기본 데이터 자동 생성 API
    app.get("reset-database") { req async throws -> String in
        do {
            // 1. 모든 테이블 데이터 삭제
            try await InvitationGroup.query(on: req.db).delete()
            try await RsvpResponse.query(on: req.db).delete()
            try await AdminUser.query(on: req.db).delete()
            try await WeddingInfo.query(on: req.db).delete()
            
            // 2. 마이그레이션 재실행
            try await req.application.autoMigrate()
            
            // 3. ✅ 기본 결혼식 정보 자동 생성
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
            
            // 4. ✅ 관리자 계정 자동 생성 (환경변수 기반)
            if let adminUsername = Environment.get("ADMIN_USERNAME"),
               let adminPassword = Environment.get("ADMIN_PASSWORD") {
                let hashedPassword = try Bcrypt.hash(adminPassword)
                let adminUser = AdminUser()
                adminUser.username = adminUsername
                adminUser.passwordHash = hashedPassword
                try await adminUser.save(on: req.db)
            }
            
            // 5. ✅ 테스트 그룹 자동 생성
            let testGroup = InvitationGroup(
                groupName: "결혼식 초대 그룹",
                groupType: GroupType.weddingGuest.rawValue,
                greetingMessage: "저희의 소중한 날에 함께해주셔서 감사합니다."
            )
            testGroup.uniqueCode = "wedding123"
            try await testGroup.save(on: req.db)
            
            return "✅ 데이터베이스 초기화 완료!\n✅ 기본 결혼식 정보 생성\n✅ 관리자 계정 생성\n✅ 테스트 그룹(wedding123) 생성"
            
        } catch {
            return "❌ 초기화 실패: \(error)"
        }
    }
    
    // ✅ 환경변수 필수인 관리자 계정 업데이트 API
    app.get("update-admin-from-env") { req async throws -> String in
        guard let newUsername = Environment.get("ADMIN_USERNAME"),
              let newPassword = Environment.get("ADMIN_PASSWORD") else {
            throw Abort(.badRequest, reason: "환경변수 ADMIN_USERNAME 또는 ADMIN_PASSWORD가 설정되지 않았습니다.")
        }
        
        do {
            let hashedPassword = try Bcrypt.hash(newPassword)
            
            if let existingAdmin = try await AdminUser.query(on: req.db).first() {
                existingAdmin.username = newUsername
                existingAdmin.passwordHash = hashedPassword
                try await existingAdmin.save(on: req.db)
                return "✅ 관리자 계정이 업데이트되었습니다!"
            } else {
                let adminUser = AdminUser()
                adminUser.username = newUsername
                adminUser.passwordHash = hashedPassword
                try await adminUser.save(on: req.db)
                return "✅ 새 관리자 계정이 생성되었습니다!"
            }
        } catch {
            throw Abort(.internalServerError, reason: "계정 업데이트 실패: \(error)")
        }
    }
    
    // ✅ 기본 데이터 확인 및 생성 API
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
}
