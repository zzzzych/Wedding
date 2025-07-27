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
    
    // 기본 루트 - 서버 상태 확인용
    app.get { req async in
        return "Wedding Invitation Server is running! 💍"
    }
    
    // API 그룹 생성 (/api/...)
    let api = app.grouped("api")
    
    // 1. 초대장 정보 조회 API (실제 DB 쿼리로 변경)
    // GET /api/invitation/:uniqueCode
    api.get("invitation", ":uniqueCode") { req async throws -> InvitationAPIResponse in
        // 🔍 URL에서 고유 코드 추출
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "유효하지 않은 초대 코드입니다.")
        }
        
        // 📋 데이터베이스에서 결혼식 기본 정보 조회
        guard let weddingInfo = try await WeddingInfo.query(on: req.db).first() else {
            throw Abort(.notFound, reason: "결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 📦 API 응답 데이터 구성
        return InvitationAPIResponse(
            groupName: "결혼식 초대 그룹",
            groupType: "WEDDING_GUEST",
            groomName: weddingInfo.groomName,
            brideName: weddingInfo.brideName,
            weddingDate: ISO8601DateFormatter().string(from: weddingInfo.weddingDate),
            weddingLocation: weddingInfo.venueName + " " + weddingInfo.venueAddress,
            greetingMessage: weddingInfo.greetingMessage,
            ceremonyProgram: weddingInfo.ceremonyProgram,
            accountInfo: weddingInfo.accountInfo,
            features: InvitationFeatures(
                showRsvpForm: true,
                showAccountInfo: false,
                showShareButton: false,
                showVenueInfo: true,
                showPhotoGallery: true,
                showCeremonyProgram: true
            )
        )
    }
    
    // 2. 참석 응답 제출 API
    // POST /api/invitation/:uniqueCode/rsvp
    api.post("invitation", ":uniqueCode", "rsvp") { req async throws -> Response in
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "유효하지 않은 초대 코드입니다.")
        }
        
        let jsonString = """
        {
            "success": true,
            "message": "참석 응답이 성공적으로 등록되었습니다."
        }
        """
        
        let response = Response(
            status: .ok,
            headers: HTTPHeaders([("Content-Type", "application/json")]),
            body: .init(string: jsonString)
        )
        return response
    }
    
    // 3. 관리자 로그인 API
    // POST /api/admin/login
    api.post("admin", "login") { req async throws -> Response in
        // 요청 본문을 문자열로 읽어서 간단히 확인
        let bodyString = req.body.string ?? ""
        
        // 간단한 인증 확인 (username과 password 포함 여부)
        if bodyString.contains("admin") && bodyString.contains("test123") {
            let jsonString = """
            {
                "success": true,
                "token": "temporary-jwt-token",
                "message": "로그인에 성공했습니다."
            }
            """
            
            let response = Response(
                status: .ok,
                headers: HTTPHeaders([("Content-Type", "application/json")]),
                body: .init(string: jsonString)
            )
            return response
        } else {
            throw Abort(.unauthorized, reason: "잘못된 사용자명 또는 비밀번호입니다.")
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
    
    // 새 그룹 생성 (관리자용)
    app.post("api", "admin", "groups") { req -> String in
        // 요청 본문에서 그룹 데이터 파싱 (실제로는 JSON 파싱 필요)
        return """
        {
            "id": "new_group_\(Int.random(in: 1000...9999))",
            "groupName": "새로운 그룹",
            "groupType": "CUSTOM_GUEST",
            "uniqueCode": "custom\(Int.random(in: 100...999))",
            "createdAt": "\(Date().ISO8601Format())",
            "description": "관리자가 생성한 새 그룹"
        }
        """
    }

    // 모든 참석 응답 조회 (관리자용)
    app.get("api", "admin", "rsvps") { req -> String in
        return """
        [
            {
                "id": "rsvp001",
                "groupCode": "wedding123",
                "guestName": "김하객",
                "attendanceCount": 2,
                "message": "축하드립니다!",
                "contactInfo": "guest1@example.com",
                "submittedAt": "2025-01-15T10:30:00Z"
            },
            {
                "id": "rsvp002", 
                "groupCode": "parent456",
                "guestName": "박친척",
                "attendanceCount": 4,
                "message": "건강하게 잘 살아요",
                "contactInfo": "relative@example.com",
                "submittedAt": "2025-01-16T14:20:00Z"
            }
        ]
        """
    }
}
