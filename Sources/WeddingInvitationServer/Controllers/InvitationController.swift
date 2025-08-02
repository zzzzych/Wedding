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
    // 기존 getInvitation 함수를 찾아서 다음 코드로 교체하세요
    func getInvitation(_ req: Request) throws -> EventLoopFuture<InvitationResponse> {
        // URL에서 고유 코드 추출
        guard let uniqueCode = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "초대 코드가 필요합니다.")
        }
        
        // 먼저 해당 그룹이 존재하는지 확인
        return InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == uniqueCode)
            .first()
            .unwrap(or: Abort(.notFound, reason: "존재하지 않는 초대 코드입니다."))
            .flatMap { group in
                // wedding_infos 테이블에서 데이터 조회, 없으면 기본 데이터 생성
                return WeddingInfo.query(on: req.db)
                    .first()
                    .flatMap { weddingInfo in
                        if let existingInfo = weddingInfo {
                            // 기존 데이터가 있으면 그대로 사용
                            return self.createInvitationResponse(for: group, with: existingInfo, on: req)
                        } else {
                            // 기본 데이터가 없으면 새로 생성
                            return self.createDefaultWeddingInfo(on: req.db)
                                .flatMap { newWeddingInfo in
                                    return self.createInvitationResponse(for: group, with: newWeddingInfo, on: req)
                                }
                        }
                    }
            }
    }

    // 기본 웨딩 정보 생성 함수 (새로 추가)
    private func createDefaultWeddingInfo(on database: Database) -> EventLoopFuture<WeddingInfo> {
        let defaultWeddingInfo = WeddingInfo(
            groomName: "이지환",
            brideName: "이윤진",
            weddingDate: try! Date("2025-10-25T18:00:00Z", strategy: .iso8601),
            venueName: "포포인츠 바이셰라톤 조선 서울역점 19층",
            venueAddress: "서울특별시 용산구 한강대로 366",
            venueDetail: "두 손 잡고 걸더니 즐거웠던 가을,\n더 큰 즐거움의 시간에 함께 해주세요.\n지환, 윤진 결혼합니다.",
            venuePhone: "02-6030-8000",
            kakaoMapUrl: nil,
            naverMapUrl: nil,
            googleMapUrl: nil,
            parkingInfo: nil,
            transportInfo: nil,
            greetingMessage: "두 손 잡고 걸더니 즐거웠던 가을,\n더 큰 즐거움의 시간에 함께 해주세요.\n지환, 윤진 결혼합니다.",
            ceremonyProgram: "17:30 - 18:00 웨딩 세레모니\n18:00 - 19:30 피로연",
            accountInfo: ["신한은행 110-xxx-xxxxxx (신랑)", "카카오뱅크 3333-xx-xxxxxxx (신부)"]
        )
        
        return defaultWeddingInfo.save(on: database).map { defaultWeddingInfo }
    }

    // 응답 생성 헬퍼 함수 (새로 추가)
    private func createInvitationResponse(for group: InvitationGroup, with weddingInfo: WeddingInfo, on req: Request) -> EventLoopFuture<InvitationResponse> {
        // 그룹별 기능 설정 가져오기
        let features = InvitationFeatures(
            showVenueInfo: group.showVenueInfo ?? true,
            showShareButton: group.showShareButton ?? true,
            showCeremonyProgram: group.showCeremonyProgram ?? true,
            showRsvpForm: group.showRsvpForm ?? true,
            showAccountInfo: group.showAccountInfo ?? false,
            showPhotoGallery: group.showPhotoGallery ?? true
        )
        
        let response = InvitationResponse(
            id: weddingInfo.id!,
            groomName: weddingInfo.groomName,
            brideName: weddingInfo.brideName,
            weddingDate: weddingInfo.weddingDate,
            venueName: weddingInfo.venueName,
            venueAddress: weddingInfo.venueAddress,
            venueDetail: weddingInfo.venueDetail,
            venuePhone: weddingInfo.venuePhone,
            kakaoMapUrl: weddingInfo.kakaoMapUrl,
            naverMapUrl: weddingInfo.naverMapUrl,
            googleMapUrl: weddingInfo.googleMapUrl,
            parkingInfo: weddingInfo.parkingInfo,
            transportInfo: weddingInfo.transportInfo,
            greetingMessage: group.greetingMessage, // 그룹별 인사말 사용
            ceremonyProgram: weddingInfo.ceremonyProgram,
            accountInfo: weddingInfo.accountInfo,
            features: features,
            groupName: group.groupName
        )
        
        return req.eventLoop.makeSucceededFuture(response)
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
            let groupWithStats = GroupWithStats(
                id: group.id!,
                groupName: group.groupName,
                groupType: group.groupType,
                uniqueCode: group.uniqueCode,
                greetingMessage: group.greetingMessage,
                totalResponses: responseCount,
                attendingResponses: attendingCount,
                showVenueInfo: group.showVenueInfo,
                showShareButton: group.showShareButton,
                showCeremonyProgram: group.showCeremonyProgram,
                showRsvpForm: group.showRsvpForm,
                showAccountInfo: group.showAccountInfo,
                showPhotoGallery: group.showPhotoGallery
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
        
        // 🆕 기능 설정 업데이트 로직 추가
        if let showVenueInfo = updateRequest.showVenueInfo {
            group.showVenueInfo = showVenueInfo
        }

        if let showShareButton = updateRequest.showShareButton {
            group.showShareButton = showShareButton
        }

        if let showCeremonyProgram = updateRequest.showCeremonyProgram {
            group.showCeremonyProgram = showCeremonyProgram
        }

        if let showRsvpForm = updateRequest.showRsvpForm {
            group.showRsvpForm = showRsvpForm
        }

        if let showAccountInfo = updateRequest.showAccountInfo {
            group.showAccountInfo = showAccountInfo
        }

        if let showPhotoGallery = updateRequest.showPhotoGallery {
            group.showPhotoGallery = showPhotoGallery
        }

        // 5. 데이터베이스에 저장
        try await group.save(on: req.db)

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
