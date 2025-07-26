//
//  RsvpController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//


import Fluent
import Vapor

/// 참석 응답 관련 API를 처리하는 컨트롤러 (개별 관리 기능 추가)
struct RsvpController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // === 하객용 API (인증 불필요) ===
        // POST /api/invitation/:uniqueCode/rsvp - 참석 여부 응답 제출
        api.post("invitation", ":uniqueCode", "rsvp", use: submitRsvp)
        
        // === 관리자용 API ===
        let admin = api.grouped("admin")
        
        // 응답 조회 API들
        admin.get("rsvps", use: getAllRsvps)                      // 전체 응답 현황 조회
        admin.get("rsvps", ":rsvpId", use: getRsvp)               // 특정 응답 조회 ✨ 새로 추가
        
        // 응답 관리 API들
        admin.put("rsvps", ":rsvpId", use: updateRsvp)            // 응답 수정 ✨ 새로 추가
        admin.delete("rsvps", ":rsvpId", use: deleteRsvp)         // 응답 삭제 ✨ 새로 추가
        
        // 대량 작업 API들
        admin.delete("rsvps", "bulk", use: bulkDeleteRsvps)       // 여러 응답 일괄 삭제 ✨ 새로 추가
        admin.get("rsvps", "export", use: exportRsvps)            // 응답 데이터 CSV 내보내기 ✨ 새로 추가
    }
    
    // MARK: - 기존 기능들
    
    /// 참석 여부 응답 제출 (하객용)
    func submitRsvp(req: Request) async throws -> RsvpResponseData {
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
        
        // 3. 그룹 타입이 WEDDING_GUEST인지 확인
        guard invitationGroup.groupType == GroupType.weddingGuest.rawValue else {
            throw Abort(.forbidden, reason: "이 그룹은 참석 여부를 응답할 수 없습니다.")
        }
        
        // 4. 요청 데이터 파싱
        let rsvpRequest = try req.content.decode(RsvpRequest.self)
        
        // 5. 데이터 유효성 검사
        guard !rsvpRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "응답자 이름이 필요합니다.")
        }
        
        guard rsvpRequest.adultCount >= 0 && rsvpRequest.childrenCount >= 0 else {
            throw Abort(.badRequest, reason: "인원수는 0 이상이어야 합니다.")
        }
        
        // 6. 이미 같은 이름으로 응답했는지 확인
        let existingResponse = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == invitationGroup.id!)
            .filter(\.$responderName == rsvpRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines))
            .first()
        
        if let existing = existingResponse {
            // 기존 응답 업데이트
            existing.isAttending = rsvpRequest.isAttending
            existing.adultCount = rsvpRequest.adultCount
            existing.childrenCount = rsvpRequest.childrenCount
            try await existing.save(on: req.db)
            
            return RsvpResponseData.from(existing)
        } else {
            // 새 응답 생성
            let newRsvp = RsvpResponse(
                responderName: rsvpRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines),
                isAttending: rsvpRequest.isAttending,
                adultCount: rsvpRequest.adultCount,
                childrenCount: rsvpRequest.childrenCount,
                groupID: invitationGroup.id!
            )
            
            try await newRsvp.save(on: req.db)
            return RsvpResponseData.from(newRsvp)
        }
    }
    
    /// 모든 참석 응답 현황 조회 (관리자용)
    func getAllRsvps(req: Request) async throws -> RsvpSummary {
        // 1. 모든 참석 응답 조회 (그룹 정보 포함)
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)  // 관련된 그룹 정보도 함께 로드
            .sort(\.$createdAt, .descending) // 최신 응답순으로 정렬
            .all()
        
        // 2. 통계 계산
        let totalResponses = allRsvps.count
        let attendingResponses = allRsvps.filter { $0.isAttending }
        let attendingCount = attendingResponses.count
        let totalAdults = attendingResponses.reduce(0) { $0 + $1.adultCount }
        let totalChildren = attendingResponses.reduce(0) { $0 + $1.childrenCount }
        
        // 3. 응답 데이터 변환
        let responseData = allRsvps.map { RsvpWithGroupInfo.from($0) }
        
        return RsvpSummary(
            totalResponses: totalResponses,
            attendingCount: attendingCount,
            notAttendingCount: totalResponses - attendingCount,
            totalAdults: totalAdults,
            totalChildren: totalChildren,
            totalPeople: totalAdults + totalChildren,
            responses: responseData
        )
    }
    
    // MARK: - ✨ 새로 추가된 개별 응답 관리 기능들
    
    /// 특정 응답 상세 조회 (관리자용)
    func getRsvp(req: Request) async throws -> RsvpWithGroupInfo {
        // 1. URL에서 rsvpId 파라미터 추출
        guard let rsvpIdString = req.parameters.get("rsvpId"),
              let rsvpId = UUID(uuidString: rsvpIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 응답 ID입니다.")
        }
        
        // 2. 응답 조회 (그룹 정보 포함)
        guard let rsvp = try await RsvpResponse.query(on: req.db)
            .filter(\.$id == rsvpId)
            .with(\.$group)
            .first() else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        return RsvpWithGroupInfo.from(rsvp)
    }
    
    /// 응답 수정 (관리자용)
    func updateRsvp(req: Request) async throws -> RsvpResponseData {
        // 1. URL에서 rsvpId 파라미터 추출
        guard let rsvpIdString = req.parameters.get("rsvpId"),
              let rsvpId = UUID(uuidString: rsvpIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 응답 ID입니다.")
        }
        
        // 2. 응답 조회
        guard let rsvp = try await RsvpResponse.find(rsvpId, on: req.db) else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        // 3. 요청 데이터 파싱
        let updateRequest = try req.content.decode(UpdateRsvpRequest.self)
        
        // 4. 데이터 유효성 검사
        guard !updateRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "응답자 이름이 필요합니다.")
        }
        
        guard updateRequest.adultCount >= 0 && updateRequest.childrenCount >= 0 else {
            throw Abort(.badRequest, reason: "인원수는 0 이상이어야 합니다.")
        }
        
        // 5. 동일한 그룹 내에서 이름 중복 검사 (자신 제외)
        let existingResponse = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == rsvp.$group.id)
            .filter(\.$responderName == updateRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines))
            .filter(\.$id != rsvpId)
            .first()
        
        if existingResponse != nil {
            throw Abort(.conflict, reason: "같은 그룹에 이미 동일한 이름의 응답자가 있습니다.")
        }
        
        // 6. 응답 정보 업데이트
        rsvp.responderName = updateRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines)
        rsvp.isAttending = updateRequest.isAttending
        rsvp.adultCount = updateRequest.adultCount
        rsvp.childrenCount = updateRequest.childrenCount
        
        // 7. 데이터베이스에 저장
        try await rsvp.save(on: req.db)
        
        return RsvpResponseData.from(rsvp)
    }
    
    /// 응답 삭제 (관리자용)
    func deleteRsvp(req: Request) async throws -> HTTPStatus {
        // 1. URL에서 rsvpId 파라미터 추출
        guard let rsvpIdString = req.parameters.get("rsvpId"),
              let rsvpId = UUID(uuidString: rsvpIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 응답 ID입니다.")
        }
        
        // 2. 응답 조회
        guard let rsvp = try await RsvpResponse.find(rsvpId, on: req.db) else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        // 3. 응답 삭제
        try await rsvp.delete(on: req.db)
        
        return .noContent // 204 No Content
    }
    
    /// 여러 응답 일괄 삭제 (관리자용)
    func bulkDeleteRsvps(req: Request) async throws -> BulkDeleteResult {
        // 1. 요청 데이터 파싱
        let deleteRequest = try req.content.decode(BulkDeleteRequest.self)
        
        // 2. 유효한 UUID인지 검사
        let validIds = deleteRequest.rsvpIds.compactMap { UUID(uuidString: $0) }
        
        if validIds.isEmpty {
            throw Abort(.badRequest, reason: "유효한 응답 ID가 없습니다.")
        }
        
        // 3. 해당 ID들의 응답 조회
        let rsvpsToDelete = try await RsvpResponse.query(on: req.db)
            .filter(\.$id ~~ validIds) // IN 조건
            .all()
        
        let foundCount = rsvpsToDelete.count
        
        // 4. 일괄 삭제 실행
        try await RsvpResponse.query(on: req.db)
            .filter(\.$id ~~ validIds)
            .delete()
        
        return BulkDeleteResult(
            requestedCount: deleteRequest.rsvpIds.count,
            deletedCount: foundCount,
            notFoundCount: deleteRequest.rsvpIds.count - foundCount
        )
    }
    
    /// 응답 데이터 CSV 내보내기 (관리자용)
    func exportRsvps(req: Request) async throws -> Response {
        // 1. 모든 응답 조회 (그룹 정보 포함)
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)
            .sort(\.$createdAt)
            .all()
        
        // 2. CSV 헤더 생성
        var csvContent = "응답자명,참석여부,성인인원,자녀인원,총인원,그룹명,그
