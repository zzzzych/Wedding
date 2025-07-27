// Sources/WeddingInvitationServer/routes.swift
@preconcurrency import Fluent
@preconcurrency import Vapor

// 라우트 설정 함수
func routes(_ app: Application) throws {
    
    // 기본 루트 - 서버 상태 확인용
    app.get { req async in
        return "Wedding Invitation Server is running! 💍"
    }
    
    // API 그룹 생성 (/api/...)
    let api = app.grouped("api")
    
    // 1. 초대장 정보 조회 API
    // GET /api/invitation/:uniqueCode
    api.get("invitation", ":uniqueCode") { req async throws -> Response in
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "유효하지 않은 초대 코드입니다.")
        }
        
        // JSON 문자열로 직접 응답 생성
        let jsonString = """
        {
            "groupName": "결혼식 초대 그룹",
            "groupType": "WEDDING_GUEST",
            "groomName": "김신랑",
            "brideName": "이신부",
            "weddingDate": "2025-10-25T17:00:00Z",
            "weddingLocation": "서울 강남구 웨딩홀",
            "greetingMessage": "저희 두 사람, 새로운 시작을 함께 축복해주세요.",
            "ceremonyProgram": "1부: 예식, 2부: 피로연",
            "accountInfo": ["신한은행 110-xxx-xxxxxx (신랑)", "카카오뱅크 3333-xx-xxxxxxx (신부)"],
            "features": {
                "showRsvpForm": true,
                "showAccountInfo": false,
                "showShareButton": false,
                "showVenueInfo": true,
                "showPhotoGallery": true,
                "showCeremonyProgram": true
            }
        }
        """
        
        let response = Response(
            status: .ok,
            headers: HTTPHeaders([("Content-Type", "application/json")]),
            body: .init(string: jsonString)
        )
        return response
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
}
