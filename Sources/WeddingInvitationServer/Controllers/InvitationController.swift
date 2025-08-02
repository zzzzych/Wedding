//
//  InvitationController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent
import Vapor
import Foundation

/// 청첩장 관련 API를 처리하는 컨트롤러 (수정/삭제 기능 추가)
struct InvitationController: RouteCollection {
    
    /// 라우트 등록 함수 - 이 컨트롤러가 처리할 API 경로들을 정의합니다
    /// - Parameter routes: 라우트 빌더 객체
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // === 하객용 API (인증 불필요) ===
        // GET /api/invitation/:uniqueCode - 고유 코드로 청첩장 정보 조회
        api.get("invitation", ":uniqueCode", use: getInvitation)
        
        // === 관리자용 API ===
        let admin = api.grouped("admin")
        
        // 그룹 관리 API들
        admin.post("groups", use: createGroup)                    // 그룹 생성
        admin.get("groups", use: getAllGroups)                    // 전체 그룹 목록 조회
        admin.get("groups", ":groupId", use: getGroup)            // 특정 그룹 조회
        admin.put("groups", ":groupId", use: updateGroup)         // 그룹 수정
        admin.delete("groups", ":groupId", use: deleteGroup)      // 그룹 삭제
    }
    
    // MARK: - 하객용 API 기능들
    
    /// 고유 코드로 청첩장 정보 조회 (하객용)
    /// 하객이 고유 링크를 통해 접속했을 때 그룹에 맞는 청첩장 정보를 제공합니다
    /// - Parameter req: HTTP 요청 객체 (uniqueCode 파라미터 포함)
    /// - Returns: 그룹별로 필터링된 청첩장 응답 데이터
    // ✅ 수정된 코드
    func getInvitation(req: Request) async throws -> InvitationAPIResponse {
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
        
        // 3. 결혼식 기본 정보 조회
        guard let weddingInfo = try await WeddingInfo.query(on: req.db)
            .first() else {
            throw Abort(.notFound, reason: "결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 4. 그룹 타입별 기능 설정
        // ✅ 수정 후: 데이터베이스에서 실제 설정 값 사용
        // ✅ 매개변수 순서를 구조체 정의에 맞춰 수정
        let features = InvitationFeatures(
            showRsvpForm: invitationGroup.showRsvpForm ?? false,        // 1번째
            showAccountInfo: invitationGroup.showAccountInfo ?? false,  // 2번째
            showShareButton: invitationGroup.showShareButton ?? false,  // 3번째
            showVenueInfo: invitationGroup.showVenueInfo ?? false,      // 4번째
            showPhotoGallery: invitationGroup.showPhotoGallery ?? true, // 5번째
            showCeremonyProgram: invitationGroup.showCeremonyProgram ?? false // 6번째
        )
        
        // 5. 통합된 장소 정보 생성
        let weddingLocation = "\(weddingInfo.venueName) \(weddingInfo.venueAddress)"
        
        // 6. 단순한 응답 형식으로 반환
        return InvitationAPIResponse(
            groupName: invitationGroup.groupName,
            groupType: invitationGroup.groupType,
            groomName: weddingInfo.groomName,
            brideName: weddingInfo.brideName,
            weddingDate: ISO8601DateFormatter().string(from: weddingInfo.weddingDate),
            weddingLocation: weddingLocation,
            greetingMessage: invitationGroup.greetingMessage,
            ceremonyProgram: weddingInfo.ceremonyProgram,
            accountInfo: weddingInfo.accountInfo,
            features: features
        )
    }
    
    
    // MARK: - 관리자용 그룹 관리 API 기능들
    
    /// 새로운 초대 그룹 생성 (관리자용)
    /// 관리자가 새로운 초대 그룹을 만들고 고유 링크를 생성합니다
    /// - Parameter req: HTTP 요청 객체 (그룹 생성 데이터 포함)
    /// - Returns: 생성된 초대 그룹 정보 (고유 코드 포함)
    func createGroup(req: Request) async throws -> InvitationGroup {
        // 1. 요청 데이터 파싱
        let createRequest = try req.content.decode(CreateGroupRequest.self)
        
        // 2. 그룹 타입 유효성 검사
        // 정의된 그룹 타입(WEDDING_GUEST, PARENTS_GUEST, COMPANY_GUEST) 중 하나인지 확인
        guard GroupType(rawValue: createRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }
        
        // 3. 그룹 이름 중복 검사
        // 같은 이름의 그룹이 이미 있는지 확인합니다
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$groupName == createRequest.groupName)
            .first()
        
        if existingGroup != nil {
            throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
        }
        
        // 4. 새 초대 그룹 생성
        // uniqueCode는 InvitationGroup의 생성자에서 자동으로 생성됩니다
        // ✅ 수정된 코드 (greetingMessage 추가)
        let newGroup = InvitationGroup(
            groupName: createRequest.groupName,
            groupType: createRequest.groupType,
            greetingMessage: createRequest.greetingMessage
        )
        
        // 5. 데이터베이스에 저장
        try await newGroup.save(on: req.db)
        return newGroup
    }
    
    /// 전체 그룹 목록 조회 (관리자용)
    /// 관리자가 모든 그룹의 목록과 각 그룹별 응답 통계를 확인할 수 있습니다
    /// - Parameter req: HTTP 요청 객체
    /// - Returns: 통계 정보가 포함된 그룹 목록
    func getAllGroups(req: Request) async throws -> GroupsListResponse {
        // 1. 모든 그룹 조회
        let allGroups = try await InvitationGroup.query(on: req.db)
            .sort(\.$groupName) // 그룹 이름순으로 정렬
            .all()
        
        // 2. 각 그룹별 응답 수 조회
        var groupsWithStats: [GroupWithStats] = []
        
        for group in allGroups {
            // 해당 그룹의 총 응답 수 계산
            let responseCount = try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == group.id!)
                .count()
            
            // 참석 예정 응답 수 계산
            let attendingCount = try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == group.id!)
                .filter(\.$isAttending == true)
                .count()
            
            // 통계 정보가 포함된 그룹 데이터 생성
            // ✅ 수정된 코드 (greetingMessage 추가)
            let groupWithStats = GroupWithStats(
                id: group.id!,
                groupName: group.groupName,
                groupType: group.groupType,
                uniqueCode: group.uniqueCode,
                greetingMessage: group.greetingMessage,
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
    /// 관리자가 특정 그룹의 상세 정보와 모든 응답을 확인할 수 있습니다
    /// - Parameter req: HTTP 요청 객체 (groupId 파라미터 포함)
    /// - Returns: 그룹 상세 정보와 응답 목록
    func getGroup(req: Request) async throws -> GroupDetailResponse {
        // 1. URL에서 groupId 파라미터 추출
        // 예: /api/admin/groups/550e8400-e29b-41d4-a716-446655440000
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
        
        // 4. 응답 데이터 변환 (SimpleRsvpResponse 타입으로)
        let responseData = responses.map { response in
            SimpleRsvpResponse.from(response)
        }
        
        // 5. 통계 정보 계산
        let attendingResponses = responses.filter { $0.isAttending }
        let statistics = GroupStatistics(
            totalResponses: responses.count,
            attendingCount: attendingResponses.count,
            totalAdults: attendingResponses.reduce(0) { $0 + $1.adultCount },
            totalChildren: attendingResponses.reduce(0) { $0 + $1.childrenCount }
        )
        
        return GroupDetailResponse(
            group: group,
            responses: responseData,
            statistics: statistics
        )
    }
    
    /// 그룹 정보 수정 (관리자용) - 부분 업데이트 지원
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
        
        // 3. 요청 데이터 파싱 (부분 업데이트용)
        let updateRequest = try req.content.decode(UpdateGroupRequest.self)
        
        // 4. 필드별 업데이트 (nil이 아닌 필드만)
        if let groupName = updateRequest.groupName, !groupName.isEmpty {
            // 그룹 이름 중복 검사 (자신 제외)
            let existingGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$groupName == groupName)
                .filter(\.$id != groupId) // 자신은 제외
                .first()
            
            if existingGroup != nil {
                throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
            }
            
            group.groupName = groupName
        }
        
        if let greetingMessage = updateRequest.greetingMessage {
            group.greetingMessage = greetingMessage
        }

        // 🆕 uniqueCode 업데이트 로직 추가
        if let uniqueCode = updateRequest.uniqueCode, !uniqueCode.isEmpty {
            // uniqueCode 중복 검사 (자신 제외)
            let existingGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$uniqueCode == uniqueCode)
                .filter(\.$id != groupId) // 자신은 제외
                .first()
            
            if existingGroup != nil {
                throw Abort(.conflict, reason: "이미 존재하는 URL 코드입니다.")
            }
            
            group.uniqueCode = uniqueCode
        }

        // 5. 데이터베이스에 저장
        try await group.save(on: req.db)
        
        return group
    }
    
    /// 그룹 삭제 (관리자용)
    /// 관리자가 그룹을 삭제할 수 있습니다. 응답이 있는 그룹은 강제 삭제 옵션이 필요합니다
    /// - Parameter req: HTTP 요청 객체 (groupId 파라미터, 선택적으로 force 쿼리 파라미터)
    /// - Returns: HTTP 상태 코드 (204 No Content)
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
            // 강제 삭제 플래그 확인 (?force=true 쿼리 파라미터)
            let forceDelete = req.query[Bool.self, at: "force"] ?? false
            
            if !forceDelete {
                throw Abort(.conflict, reason: "이 그룹에는 \(responseCount)개의 응답이 있습니다. 강제 삭제하려면 ?force=true를 추가하세요.")
            }
            
            // 5. 관련 응답들 먼저 삭제 (외래키 제약조건 때문)
            // 자식 테이블(응답)을 먼저 삭제해야 부모 테이블(그룹)을 삭제할 수 있습니다
            try await RsvpResponse.query(on: req.db)
                .filter(\.$group.$id == groupId)
                .delete()
        }
        
        // 6. 그룹 삭제
        try await group.delete(on: req.db)
        
        return .noContent // 204 No Content - 성공적으로 삭제되었음을 나타냄
    }
}
