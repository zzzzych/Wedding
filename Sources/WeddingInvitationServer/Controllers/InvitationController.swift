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
        // ✅ let api = routes.grouped("api") 줄 삭제
        
        // === 하객용 API (인증 불필요) ===
        // GET /api/invitation/:uniqueCode - 고유 코드로 청첩장 정보 조회
        routes.get("invitation", ":uniqueCode", use: getInvitation)
        
        // === 관리자용 API (JWT 인증 필요) ===
        // 여기서는 토큰 인증 미들웨어를 추가해야 하지만, 우선 기능 구현에 집중합니다.
        let admin = routes.grouped("admin")
        
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

        // 3. 기본 결혼식 정보 하드코딩 (데이터베이스 의존성 제거)
        // 3. 기본 결혼식 정보 하드코딩 (데이터베이스 의존성 제거)
        let defaultWeddingInfo = WeddingInfo()
        defaultWeddingInfo.groomName = "이지환"
        defaultWeddingInfo.brideName = "이윤진"
        defaultWeddingInfo.weddingDate = Date()
        defaultWeddingInfo.venueName = "포포인츠 바이 쉐라톤 조선 서울역"
        defaultWeddingInfo.venueAddress = "서울특별시 용산구 한강대로 366"
        defaultWeddingInfo.venueDetail = "19층"
        defaultWeddingInfo.kakaoMapUrl = "https://place.map.kakao.com/1821839394"
        defaultWeddingInfo.naverMapUrl = "https://naver.me/FG7xPnTx"
        defaultWeddingInfo.parkingInfo = "포포인츠 바이 쉐라톤 조선 서울역 주차장 지하 2-4층"
        defaultWeddingInfo.transportInfo = "서울역 10번 출구쪽 지하 연결 통로 이용 도보 4분, 서울역 12번 출구 도보 2분"
        defaultWeddingInfo.greetingMessage = "두 손 잡고 걷다보니 즐거움만 가득, 더 큰 즐거움의 시작에 함께 해주세요."
        defaultWeddingInfo.ceremonyProgram = "오후 6시 예식"
        defaultWeddingInfo.accountInfo = ["농협 121065-56-105215 (고인옥 / 신랑母)"]
        // 4. 로깅 추가
        req.logger.info("청첩장 정보 조회: 그룹 '\(group.groupName)' (코드: \(uniqueCode))")
        
        // 5. 응답 생성
        return InvitationResponse.create(from: defaultWeddingInfo, and: group)
    }

    // MARK: - 관리자용 그룹 관리 API 기능
    
    /// 새로운 초대 그룹 생성 (관리자용)
    /// - Method: `POST`
    /// - Path: `/api/admin/groups`
    func createGroup(req: Request) async throws -> InvitationGroup {
        let createRequest = try req.content.decode(CreateGroupRequest.self)

        // 1. 입력 데이터 유효성 검사
        let trimmedGroupName = createRequest.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGroupName.isEmpty else {
            throw Abort(.badRequest, reason: "그룹 이름은 필수입니다.")
        }
        
        let trimmedGreetingMessage = createRequest.greetingMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGreetingMessage.isEmpty else {
            throw Abort(.badRequest, reason: "인사말은 필수입니다.")
        }

        // 2. 그룹 타입 유효성 검사
        guard GroupType(rawValue: createRequest.groupType) != nil else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 타입입니다.")
        }

        // 3. 중복 그룹명 검사
        let existingGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$groupName == trimmedGroupName)
            .first()

        if existingGroup != nil {
            throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
        }

        // 4. 고유 코드 중복 검사 (사용자 정의 코드가 있는 경우)
        if let customCode = createRequest.uniqueCode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !customCode.isEmpty {
            let existingCodeGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$uniqueCode == customCode)
                .first()
            
            if existingCodeGroup != nil {
                throw Abort(.conflict, reason: "이미 사용 중인 고유 코드입니다.")
            }
        }

        // 5. 새 그룹 생성
        let finalUniqueCode = createRequest.uniqueCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        let newGroup = InvitationGroup(
            groupName: trimmedGroupName,
            groupType: createRequest.groupType,
            greetingMessage: trimmedGreetingMessage,
            uniqueCode: (finalUniqueCode?.isEmpty == false) ? finalUniqueCode! : InvitationGroup.generateSecureCode()
        )

        // 6. 데이터베이스에 저장
        try await newGroup.save(on: req.db)
        
        // 7. 로깅 추가
        req.logger.info("새 그룹 생성: '\(newGroup.groupName)' (코드: \(newGroup.uniqueCode))")
        
        return newGroup
    }

    /// 그룹 삭제 (관리자용)
    /// - Method: `DELETE`
    /// - Path: `/api/admin/groups/:groupId`
    func deleteGroup(req: Request) async throws -> HTTPStatus {
        // 1. 그룹 ID 파라미터 추출 및 검증
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }
        
        // 2. 그룹 존재 여부 확인
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 3. 관련 RSVP 응답 수 확인 (로깅용)
        let responseCount = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .count()
        
        req.logger.info("그룹 삭제 시작: '\(group.groupName)' (관련 응답 \(responseCount)개)")
        
        // 4. 해당 그룹의 모든 RSVP 응답도 함께 삭제
        try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .delete()
        
        // 5. 그룹 삭제
        try await group.delete(on: req.db)
        
        req.logger.info("그룹 삭제 완료: '\(group.groupName)'")
        
        return .noContent
    }
    
    /// 전체 그룹 목록 조회 (관리자용)
    /// - Method: `GET`
    /// - Path: `/api/admin/groups`
    func getAllGroups(req: Request) async throws -> [InvitationGroup] {
        // 모든 그룹을 이름순으로 정렬하여 반환
        let allGroups = try await InvitationGroup.query(on: req.db)
            .sort(\.$groupName)
            .all()
        
        req.logger.info("전체 그룹 목록 조회: \(allGroups.count)개 그룹")
        
        return allGroups
    }
    
    /// 특정 그룹 상세 조회 (관리자용)
    /// - Method: `GET`
    /// - Path: `/api/admin/groups/:groupId`
    func getGroup(req: Request) async throws -> GroupDetailResponse {
        // 1. 그룹 ID 파라미터 추출 및 검증
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }

        // 2. 그룹 존재 여부 확인
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }

        // 3. 해당 그룹의 모든 응답 조회
        let responses = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .sort(\.$createdAt)
            .all()

        // 4. 응답 데이터 변환
        let responseData = responses.map { SimpleRsvpResponse.from($0) }
        
        // 5. 통계 계산
        let attendingResponses = responses.filter { $0.isAttending }
        let statistics = GroupStatistics(
            totalResponses: responses.count,
            attendingCount: attendingResponses.count,
            totalAdults: attendingResponses.reduce(0) { $0 + $1.adultCount },
            totalChildren: attendingResponses.reduce(0) { $0 + $1.childrenCount }
        )

        req.logger.info("그룹 상세 조회: '\(group.groupName)' (응답 \(responses.count)개)")

        return GroupDetailResponse(group: group, responses: responseData, statistics: statistics)
    }

    /// 그룹 정보 수정 (관리자용)
    /// - Method: `PUT`
    /// - Path: `/api/admin/groups/:groupId`
    func updateGroup(req: Request) async throws -> InvitationGroup {
        // 1. 그룹 ID 파라미터 추출 및 검증
        guard let groupId = req.parameters.get("groupId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "유효하지 않은 그룹 ID 형식입니다.")
        }
        
        // 2. 그룹 존재 여부 확인
        guard let group = try await InvitationGroup.find(groupId, on: req.db) else {
            throw Abort(.notFound, reason: "그룹을 찾을 수 없습니다.")
        }
        
        // 3. 요청 데이터 파싱
        let updateRequest = try req.content.decode(UpdateGroupRequest.self)

        // 4. 수정된 필드들을 추적하기 위한 배열
        var updatedFields: [String] = []

        // 5. 기본 필드 업데이트 (nil이 아닌 값만)
        if let groupName = updateRequest.groupName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !groupName.isEmpty {
            // 중복 그룹명 검사 (자기 자신 제외)
            let existingGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$groupName == groupName)
                .filter(\.$id != groupId)
                .first()
            
            if existingGroup != nil {
                throw Abort(.conflict, reason: "이미 존재하는 그룹 이름입니다.")
            }
            
            group.groupName = groupName
            updatedFields.append("그룹명")
        }
        
        if let greetingMessage = updateRequest.greetingMessage {
            group.greetingMessage = greetingMessage
            updatedFields.append("인사말")
        }
        
        if let uniqueCode = updateRequest.uniqueCode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !uniqueCode.isEmpty {
            // 중복 고유 코드 검사 (자기 자신 제외)
            let existingCodeGroup = try await InvitationGroup.query(on: req.db)
                .filter(\.$uniqueCode == uniqueCode)
                .filter(\.$id != groupId)
                .first()
            
            if existingCodeGroup != nil {
                throw Abort(.conflict, reason: "이미 사용 중인 고유 코드입니다.")
            }
            
            group.uniqueCode = uniqueCode
            updatedFields.append("고유코드")
        }
        
        // 6. 기능 설정 필드 업데이트
        if let showVenueInfo = updateRequest.showVenueInfo {
            group.showVenueInfo = showVenueInfo
            updatedFields.append("오시는길표시")
        }
        if let showShareButton = updateRequest.showShareButton {
            group.showShareButton = showShareButton
            updatedFields.append("공유버튼표시")
        }
        if let showCeremonyProgram = updateRequest.showCeremonyProgram {
            group.showCeremonyProgram = showCeremonyProgram
            updatedFields.append("예식순서표시")
        }
        if let showRsvpForm = updateRequest.showRsvpForm {
            group.showRsvpForm = showRsvpForm
            updatedFields.append("참석응답표시")
        }
        if let showAccountInfo = updateRequest.showAccountInfo {
            group.showAccountInfo = showAccountInfo
            updatedFields.append("계좌정보표시")
        }
        if let showPhotoGallery = updateRequest.showPhotoGallery {
            group.showPhotoGallery = showPhotoGallery
            updatedFields.append("포토갤러리표시")
        }

        // 7. 변경사항이 있는 경우에만 저장
        if !updatedFields.isEmpty {
            try await group.save(on: req.db)
            req.logger.info("그룹 정보 업데이트: '\(group.groupName)' (ID: \(groupId)) - 수정된 필드: \(updatedFields.joined(separator: ", "))")
        } else {
            req.logger.info("그룹 정보 업데이트: '\(group.groupName)' - 변경사항 없음")
        }

        return group
    }
}
