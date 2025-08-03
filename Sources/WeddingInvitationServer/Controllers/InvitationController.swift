//
//  InvitationController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent
import Vapor
import Foundation

/// 청첩장 관련 API를 처리하는 컨트롤러
struct InvitationController: RouteCollection {
    
    /// 라우트 등록 함수 - 이 컨트롤러가 처리할 API 경로들을 정의합니다.
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // === 하객용 API (인증 불필요) ===
        // GET /api/invitation/:uniqueCode - 고유 코드로 청첩장 정보 조회
        api.get("invitation", ":uniqueCode", use: getInvitation)
        
        // === 관리자용 API (JWT 인증 필요) ===
        // 여기서는 토큰 인증 미들웨어를 추가해야 하지만, 우선 기능 구현에 집중합니다.
        let admin = api.grouped("admin")
        
        // 그룹 관리 API들
        admin.post("groups", use: createGroup)
        admin.get("groups", use: getAllGroups)
        admin.get("groups", ":groupId", use: getGroup)
        admin.put("groups", ":groupId", use: updateGroup)
        admin.delete("groups", ":groupId", use: deleteGroup)
    }
    
    // MARK: - 하객용 API 기능
    
    /// 고유 코드로 청첩장 정보 조회 (하객용)
    /// - Description: 하객이 고유 링크를 통해 접속했을 때 그룹에 맞는 청첩장 정보를 제공합니다.
    /// - Method: `GET`
    /// - Path: `/api/invitation/:uniqueCode`
    func getInvitation(req: Request) async throws -> InvitationResponse {
        // 1. URL에서 고유 코드 추출
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "초대 코드가 필요합니다.")
        }

        // 2. 고유 코드로 초대 그룹 찾기
        guard let group = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == uniqueCode)
            .first() else {
            throw Abort(.notFound, reason: "존재하지 않는 초대 코드입니다.")
        }

        // 3. ✅ 기본 결혼식 정보 하드코딩 (데이터베이스 의존성 제거)
        let defaultWeddingInfo = WeddingInfo()
        defaultWeddingInfo.groomName = "이지환"
        defaultWeddingInfo.brideName = "이윤진"
        defaultWeddingInfo.weddingDate = Date()
        defaultWeddingInfo.venueName = "포포인츠 바이 쉐라톤 조선 서울역"
        defaultWeddingInfo.venueAddress = "서울특별시 용산구 한강대로 366"
        defaultWeddingInfo.venueDetail = "19층"
        defaultWeddingInfo.greetingMessage = "두 손 잡고 걷다보니 즐거움만 가득, 더 큰 즐거움의 시작에 함께 해주세요."
        defaultWeddingInfo.ceremonyProgram = "오후 6시 예식"
        defaultWeddingInfo.accountInfo = ["농협 121065-56-105215 (고인옥 / 신랑母)"]
        
        // 4. 응답 생성
        return InvitationResponse.create(from: defaultWeddingInfo, and: group)
    }

    // MARK: - 관리자용 그룹 관리 API 기능
    /// 새로운 초대 그룹 생성 (관리자용)
    func createGroup(req: Request) async throws -> InvitationGroup {
        let createRequest = try req.content.decode(CreateGroupRequest.self)

        guard GroupType(rawValue: createRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }

        // 중복 그룹명 검사
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$groupName == createRequest.groupName)
            .first()

        if existingGroup != nil {
            throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
        }

        // 🔧 수정된 부분: InvitationGroup 생성자 호출 방식 수정
        let newGroup = InvitationGroup(
            groupName: createRequest.groupName,
            groupType: createRequest.groupType,
            greetingMessage: createRequest.greetingMessage,
            uniqueCode: createRequest.uniqueCode ?? InvitationGroup.generateSecureCode()
        )

        try await newGroup.save(on: req.db)
        return newGroup
    }

    /// 그룹 삭제 (관리자용)
    /// - Method: `DELETE`
    /// - Path: `/api/admin/groups/:groupId`
    func deleteGroup(req: Request) async throws -> HTTPStatus {
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }
        
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 해당 그룹의 모든 RSVP 응답도 함께 삭제
        try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .delete()
        
        // 그룹 삭제
        try await group.delete(on: req.db)
        
        return .noContent
    }
    
    
    /// 전체 그룹 목록 조회 (관리자용)
    /// - Method: `GET`
    /// - Path: `/api/admin/groups`
    func getAllGroups(req: Request) async throws -> [InvitationGroup] {
        // ✅ 단순하게 그룹 목록만 반환 (통계 제외)
        let allGroups = try await InvitationGroup.query(on: req.db)
            .sort(\.$groupName)
            .all()
        
        return allGroups
    }
    /// 특정 그룹 상세 조회 (관리자용)
    /// - Method: `GET`
    /// - Path: `/api/admin/groups/:groupId`
    func getGroup(req: Request) async throws -> GroupDetailResponse {
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }

        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }

        let responses = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .sort(\.$createdAt)
            .all()

        let responseData = responses.map { SimpleRsvpResponse.from($0) }
        
        let attendingResponses = responses.filter { $0.isAttending }
        let statistics = GroupStatistics(
            totalResponses: responses.count,
            attendingCount: attendingResponses.count,
            totalAdults: attendingResponses.reduce(0) { $0 + $1.adultCount },
            totalChildren: attendingResponses.reduce(0) { $0 + $1.childrenCount }
        )

        return GroupDetailResponse(group: group, responses: responseData, statistics: statistics)
    }

    /// 그룹 정보 수정 (관리자용)
    /// - Method: `PUT`
    /// - Path: `/api/admin/groups/:groupId`
    func updateGroup(req: Request) async throws -> InvitationGroup {
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }
        
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        let updateRequest = try req.content.decode(UpdateGroupRequest.self)

        // 이름, 인사말, 코드 등 필드 업데이트 (nil이 아닌 값만)
        if let groupName = updateRequest.groupName, !groupName.isEmpty {
            group.groupName = groupName
        }
        if let greetingMessage = updateRequest.greetingMessage {
            group.greetingMessage = greetingMessage
        }
        if let uniqueCode = updateRequest.uniqueCode, !uniqueCode.isEmpty {
            group.uniqueCode = uniqueCode
        }
        
        // 기능 플래그 업데이트
        if let showVenueInfo = updateRequest.showVenueInfo { group.showVenueInfo = showVenueInfo }
        if let showShareButton = updateRequest.showShareButton { group.showShareButton = showShareButton }
        if let showCeremonyProgram = updateRequest.showCeremonyProgram { group.showCeremonyProgram = showCeremonyProgram }
        if let showRsvpForm = updateRequest.showRsvpForm { group.showRsvpForm = showRsvpForm }
        if let showAccountInfo = updateRequest.showAccountInfo { group.showAccountInfo = showAccountInfo }
        if let showPhotoGallery = updateRequest.showPhotoGallery { group.showPhotoGallery = showPhotoGallery }

        try await group.save(on: req.db)
        return group
    }
}
