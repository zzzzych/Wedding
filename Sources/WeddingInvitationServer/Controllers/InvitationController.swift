//
//  InvitationController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//


import Fluent
import Vapor

/// 청첩장 관련 API를 처리하는 컨트롤러 (수정/삭제 기능 추가)
struct InvitationController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // === 하객용 API (인증 불필요) ===
        // GET /api/invitation/:uniqueCode - 고유 코드로 청첩장 정보 조회
        api.get("invitation", ":uniqueCode", use: getInvitation)
        
        // === 관리자용 API ===
        let admin = api.grouped("admin")
        
        // 그룹 관리 API들
        admin.post("groups", use: createGroup)                    // 그룹 생성
        admin.get("groups", use: getAllGroups)                    // 전체 그룹 목록 조회 ✨ 새로 추가
        admin.get("groups", ":groupId", use: getGroup)            // 특정 그룹 조회 ✨ 새로 추가
        admin.put("groups", ":groupId", use: updateGroup)         // 그룹 수정 ✨ 새로 추가
        admin.delete("groups", ":groupId", use: deleteGroup)      // 그룹 삭제 ✨ 새로 추가
    }
    
    // MARK: - 기존 기능들
    
    /// 고유 코드로 청첩장 정보 조회 (하객용)
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
        
        // 3. 결혼식 정보 조회
        guard let weddingInfo = try await WeddingInfo.query(on: req.db)
            .first() else {
            throw Abort(.notFound, reason: "결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 4. 그룹별로 필터링된 응답 생성
        let response = InvitationResponse.create(from: weddingInfo, and: invitationGroup)
        return response
    }
    
    /// 새로운 초대 그룹 생성 (관리자용)
    func createGroup(req: Request) async throws -> InvitationGroup {
        // 1. 요청 데이터 파싱
        let createRequest = try req.content.decode(CreateGroupRequest.self)
        
        // 2. 그룹 타입 유효성 검사
        guard GroupType(rawValue: createRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }
        
        // 3. 그룹 이름 중복 검사
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$groupName == createRequest.groupName)
            .first()
        
        if existingGroup != nil {
            throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
        }
        
        // 4. 새 초대 그룹 생성 (uniqueCode는 자동 생성됨)
        let newGroup = InvitationGroup(
            groupName: createRequest.groupName,
            groupType: createRequest.groupType
        )
        
        // 5. 데이터베이스에 저장
        try await newGroup.save(on: req.db)
        return newGroup
    }
    
    // MARK: - ✨ 새로 추가된 관리자 기능들
    
    /// 전체 그룹 목록 조회 (관리자용)
    func getAllGroups(req: Request) async throws -> GroupsListResponse {
        // 1. 모든 그룹 조회
        let allGroups = try await InvitationGroup.query(on: req.db)
            .sort(\.$groupName) // 그룹 이름순으로 정렬
            .all()
        
        // 2. 각 그룹별 응답 수 조회
        var groupsWithStats: [GroupWithStats] = []
        
        for group in allGroups {
            // 해당 그룹의 응답 수 계산
            let responseCount = try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == group.id!)
                .count()
            
            // 참석 예정 응답 수 계산
            let attendingCount = try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == group.id!)
                .filter(\.$isAttending == true)
                .count()
            
            let groupWithStats = GroupWithStats(
                id: group.id!,
                groupName: group.groupName,
                groupType: group.groupType,
                uniqueCode: group.uniqueCode,
                totalResponses: responseCount,
                attendingResponses: attendingCount
            )
            
            groupsWithStats.append(groupWithStats)
        }
        
        return GroupsListResponse(
            totalGroups: allGroups.count,
            groups: groupsWithStats
        )
    }
    
    /// 특정 그룹 상세 조회 (관리자용)
    func getGroup(req: Request) async throws -> GroupDetailResponse {
        // 1. URL에서 groupId 파라미터 추출
        guard let groupIdString = req.parameters.get("groupId"),
              let groupId = UUID(uuidString: groupIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID입니다.")
        }
        
        // 2. 그룹 정보 조회
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 3. 해당 그룹의 모든 응답 조회
        let responses = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .sort(\.$createdAt) // 응답 시간순으로 정렬
            .all()
        
        // 4. 응답 데이터 변환
        let responseData = responses.map { response in
            RsvpResponseData(
                id: response.id,
                responderName: response.responderName,
                isAttending: response.isAttending,
                adultCount: response.adultCount,
                childrenCount: response.childrenCount,
                submittedAt: response.createdAt
            )
        }
        
        return GroupDetailResponse(
            group: group,
            responses: responseData,
            statistics: GroupStatistics(
                totalResponses: responses.count,
                attendingCount: responses.filter { $0.isAttending }.count,
                totalAdults: responses.filter { $0.isAttending }.reduce(0) { $0 + $1.adultCount },
                totalChildren: responses.filter { $0.isAttending }.reduce(0) { $0 + $1.childrenCount }
            )
        )
    }
    
    /// 그룹 정보 수정 (관리자용)
    func updateGroup(req: Request) async throws -> InvitationGroup {
        // 1. URL에서 groupId 파라미터 추출
        guard let groupIdString = req.parameters.get("groupId"),
              let groupId = UUID(uuidString: groupIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID입니다.")
        }
        
        // 2. 그룹 조회
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 3. 요청 데이터 파싱
        let updateRequest = try req.content.decode(UpdateGroupRequest.self)
        
        // 4. 그룹 타입 유효성 검사
        guard GroupType(rawValue: updateRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }
        
        // 5. 그룹 이름 중복 검사 (자신 제외)
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$groupName == updateRequest.groupName)
            .filter(\.$id != groupId)
            .first()
        
        if existingGroup != nil {
            throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
        }
        
        // 6. 그룹 정보 업데이트
        group.groupName = updateRequest.groupName
        group.groupType = updateRequest.groupType
        
        // 7. 데이터베이스에 저장
        try await group.save(on: req.db)
        
        return group
    }
    
    /// 그룹 삭제 (관리자용)
    func deleteGroup(req: Request) async throws -> HTTPStatus {
        // 1. URL에서 groupId 파라미터 추출
        guard let groupIdString = req.parameters.get("groupId"),
              let groupId = UUID(uuidString: groupIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID입니다.")
        }
        
        // 2. 그룹 조회
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 3. 해당 그룹의 응답 수 확인
        let responseCount = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .count()
        
        // 4. 응답이 있는 경우 확인 요청
        if responseCount > 0 {
            // 강제 삭제 플래그 확인
            let forceDelete = req.query[Bool.self, at: "force"] ?? false
            
            if !forceDelete {
                throw Abort(.conflict, reason: "이 그룹에는 \(responseCount)개의 응답이 있습니다. 강제 삭제하려면 ?force=true를 추가하세요.")
            }
            
            // 5. 관련 응답들 먼저 삭제 (외래키 제약조건 때문)
            try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == groupId)
                .delete()
        }
        
        // 6. 그룹 삭제
        try await group.delete(on: req.db)
        
        return .noContent // 204 No Content
    }
}

// MARK: - Request/Response Models

/// 그룹 생성 요청 데이터
struct CreateGroupRequest: Content {
    let groupName: String    // 그룹 이름 (예: "신랑 대학 동기")
    let groupType: String    // 그룹 타입 (예: "WEDDING_GUEST")
}

/// 그룹 수정 요청 데이터
struct UpdateGroupRequest: Content {
    let groupName: String    // 새로운 그룹 이름
    let groupType: String    // 새로운 그룹 타입
}

/// 통계 정보가 포함된 그룹 데이터
struct GroupWithStats: Content {
    let id: UUID
    let groupName: String
    let groupType: String
    let uniqueCode: String
    let totalResponses: Int      // 총 응답 수
    let attendingResponses: Int  // 참석 응답 수
}

/// 전체 그룹 목록 응답
struct GroupsListResponse: Content {
    let totalGroups: Int
    let groups: [GroupWithStats]
}

/// 그룹 통계 정보
struct GroupStatistics: Content {
    let totalResponses: Int    // 총 응답 수
    let attendingCount: Int    // 참석 응답 수
    let totalAdults: Int       // 총 성인 인원
    let totalChildren: Int     // 총 자녀 인원
}

/// 그룹 상세 정보 응답
struct GroupDetailResponse: Content {
    let group: InvitationGroup
    let responses: [RsvpResponseData]
    let statistics: GroupStatistics
}
