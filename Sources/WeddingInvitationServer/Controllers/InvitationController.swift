//
//  InvitationController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent
import Vapor

/// 청첩장 관련 API를 처리하는 컨트롤러
struct InvitationController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // GET /api/invitation/:uniqueCode - 고유 코드로 청첩장 정보 조회 (인증 불필요)
        api.get("invitation", ":uniqueCode", use: getInvitation)
        
        // 관리자 전용 라우트 (임시로 인증 미들웨어 제거)
        let admin = api.grouped("admin")
        admin.post("groups", use: createGroup)
    }
    
    // MARK: - GET /api/invitation/:uniqueCode
    /// 고유 코드로 청첩장 정보 조회
    func getInvitation(req: Request) async throws -> InvitationResponse {
        // 1. URL에서 uniqueCode 파라미터 추출
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "고유 코드가 필요합니다.")
        }
        
        // 2. uniqueCode로 초대 그룹 찾기
        guard let invitationGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == uniqueCode)
            .first() else {
            throw Abort(.notFound, reason: "유효하지 않은 초대 코드입니다.")
        }
        
        // 3. 결혼식 정보 조회 (현재는 첫 번째 정보 사용, 나중에 관계 설정 가능)
        guard let weddingInfo = try await WeddingInfo.query(on: req.db)
            .first() else {
            throw Abort(.notFound, reason: "결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 4. 그룹별로 필터링된 응답 생성
        let response = InvitationResponse.create(from: weddingInfo, and: invitationGroup)
        
        return response
    }
    
    // MARK: - POST /api/admin/groups
    /// 새로운 초대 그룹 생성 (관리자용)
    func createGroup(req: Request) async throws -> InvitationGroup {
        // 1. 요청 데이터 파싱
        let createRequest = try req.content.decode(CreateGroupRequest.self)
        
        // 2. 그룹 타입 유효성 검사
        guard GroupType(rawValue: createRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }
        
        // 3. 새 초대 그룹 생성 (uniqueCode는 자동 생성됨)
        let newGroup = InvitationGroup(
            groupName: createRequest.groupName,
            groupType: createRequest.groupType
        )
        
        // 4. 데이터베이스에 저장
        try await newGroup.save(on: req.db)
        
        return newGroup
    }
}

// MARK: - Request/Response Models

/// 새 그룹 생성 요청 데이터
struct CreateGroupRequest: Content {
    let groupName: String    // 그룹 이름 (예: "신랑 대학 동기")
    let groupType: String    // 그룹 타입 (예: "WEDDING_GUEST")
}
