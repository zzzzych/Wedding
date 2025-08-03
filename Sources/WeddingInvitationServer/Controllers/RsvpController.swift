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
    
    /// 라우트 등록 함수 - 이 컨트롤러가 처리할 API 경로들을 정의합니다
    /// - Parameter routes: 라우트 빌더 객체
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // === 하객용 API (인증 불필요) ===
        // POST /api/invitation/:uniqueCode/rsvp - 참석 여부 응답 제출
        api.post("invitation", ":uniqueCode", "rsvp", use: submitRsvp)
        
        // === 관리자용 API ===
        let admin = api.grouped("admin")
        
        // 응답 조회 API들
        admin.get("rsvps", use: getAllRsvps)                      // 전체 응답 현황 조회
        admin.get("rsvps", ":rsvpId", use: getRsvp)               // 특정 응답 조회
        
        // 응답 관리 API들
        admin.put("rsvps", ":rsvpId", use: updateRsvp)            // 응답 수정
        admin.delete("rsvps", ":rsvpId", use: deleteRsvp)         // 응답 삭제
        
        // 대량 작업 API들
        admin.delete("rsvps", "bulk", use: bulkDeleteRsvps)       // 여러 응답 일괄 삭제
        admin.get("rsvps", "export", use: exportRsvps)            // 응답 데이터 CSV 내보내기
    }
    
    // MARK: - 하객용 API 기능들
    
    /// 참석 여부 응답 제출 (하객용)
    /// 하객이 청첩장 링크를 통해 참석 여부를 제출하는 기능입니다
    /// - Parameter req: HTTP 요청 객체 (uniqueCode 파라미터와 응답 데이터 포함)
    /// - Returns: 제출된 응답 데이터
    func submitRsvp(req: Request) async throws -> SimpleRsvpResponse {
        // 1. URL에서 uniqueCode 파라미터 추출
        // 예: /api/invitation/ABC123DEF/rsvp 에서 ABC123DEF 부분
        guard let uniqueCode = req.parameters.get("uniqueCode") else {
            throw Abort(.badRequest, reason: "고유 코드가 필요합니다.")
        }
        
        // 2. uniqueCode로 초대 그룹 찾기
        // 데이터베이스에서 해당 고유 코드를 가진 그룹을 검색합니다
        guard let invitationGroup = try await InvitationGroup.query(on: req.db)
            .filter(\.$uniqueCode == uniqueCode)
            .first() else {
            throw Abort(.notFound, reason: "유효하지 않은 초대 코드입니다.")
        }
        
        // 3. 그룹 타입이 WEDDING_GUEST인지 확인 (참석 응답이 가능한 그룹만)
        // 부모님 그룹이나 회사 그룹은 참석 응답을 받지 않습니다
        guard invitationGroup.groupType == GroupType.weddingGuest.rawValue else {
            throw Abort(.forbidden, reason: "이 그룹은 참석 여부를 응답할 수 없습니다.")
        }
        
        // 4. 요청 데이터 파싱 및 유효성 검사
        // JSON으로 전송된 응답 데이터를 RsvpRequest 구조체로 변환합니다
        let rsvpRequest = try req.content.decode(RsvpRequest.self)
        try rsvpRequest.validate() // 입력 데이터의 유효성을 검증합니다
        
        // 5. 이미 같은 이름으로 응답했는지 확인 (중복 응답 방지)
        // 이름의 앞뒤 공백을 제거하고 정리합니다
        let trimmedName = rsvpRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingResponse = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == invitationGroup.id!)
            .filter(\.$responderName == trimmedName)
            .first()
        
        if let existing = existingResponse {
            // 기존 응답이 있으면 업데이트 (같은 이름으로 다시 응답한 경우)
            existing.isAttending = rsvpRequest.isAttending
            existing.adultCount = rsvpRequest.adultCount
            existing.childrenCount = rsvpRequest.childrenCount
            try await existing.save(on: req.db)
            
            return SimpleRsvpResponse.from(existing)
        } else {
            // 새 응답 생성 (처음 응답하는 경우)
            let newRsvp = RsvpResponse(
                responderName: trimmedName,
                isAttending: rsvpRequest.isAttending,
                adultCount: rsvpRequest.adultCount,
                childrenCount: rsvpRequest.childrenCount,
                groupID: invitationGroup.id!
            )
            
            try await newRsvp.save(on: req.db)
            return SimpleRsvpResponse.from(newRsvp)
        }
    }
    
    // MARK: - 관리자용 조회 API 기능들
    
    /// 모든 참석 응답 현황 조회 (관리자용)
    /// 관리자가 전체 응답 현황을 한눈에 볼 수 있는 요약 정보를 제공합니다
    /// - Parameter req: HTTP 요청 객체
    /// - Returns: 전체 응답 요약 정보 (통계 + 개별 응답 목록)
    func getAllRsvps(req: Request) async throws -> RsvpSummary {
        // 1. 모든 참석 응답 조회 (그룹 정보 포함)
        // .with(\.$group)를 사용해 연관된 그룹 정보도 함께 로드합니다
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)  // 관련된 그룹 정보도 함께 로드
            .sort(\.$createdAt, .descending) // 최신 응답순으로 정렬
            .all()
        
        // 2. 통계 계산
        let totalResponses = allRsvps.count
        let attendingResponses = allRsvps.filter { $0.isAttending } // 참석 응답만 필터링
        let attendingCount = attendingResponses.count
        // 참석하는 사람들의 성인 인원 수 합계
        let totalAdults = attendingResponses.reduce(0) { $0 + $1.adultCount }
        // 참석하는 사람들의 자녀 인원 수 합계
        let totalChildren = attendingResponses.reduce(0) { $0 + $1.childrenCount }
        
        // 3. 응답 데이터 변환
        // RsvpResponse 모델을 API 응답용 구조체로 변환합니다
        let responseData = allRsvps.map { SimpleRsvpWithGroupInfo.from($0) }
        
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
    
    /// 특정 응답 상세 조회 (관리자용)
    /// 관리자가 특정 응답의 상세 정보를 확인할 때 사용합니다
    /// - Parameter req: HTTP 요청 객체 (rsvpId 파라미터 포함)
    /// - Returns: 그룹 정보가 포함된 응답 데이터
    func getRsvp(req: Request) async throws -> SimpleRsvpWithGroupInfo {
        // 1. URL에서 rsvpId 파라미터 추출 및 UUID 변환
        // 예: /api/admin/rsvps/550e8400-e29b-41d4-a716-446655440000
        guard let rsvpIdString = req.parameters.get("rsvpId"),
              let rsvpId = UUID(uuidString: rsvpIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 응답 ID입니다.")
        }
        
        // 2. 응답 조회 (그룹 정보 포함)
        guard let rsvp = try await RsvpResponse.query(on: req.db)
            .filter(\.$id == rsvpId)
            .with(\.$group) // 연관된 그룹 정보도 함께 로드
            .first() else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        return SimpleRsvpWithGroupInfo.from(rsvp)
    }
    
    // MARK: - 관리자용 수정/삭제 API 기능들
    /// 응답 수정 (관리자용)
    func updateRsvp(req: Request) async throws -> SimpleRsvpResponse {
        // 1. URL에서 rsvpId 파라미터 추출
        guard let rsvpIdString = req.parameters.get("rsvpId"),
              let rsvpId = UUID(uuidString: rsvpIdString) else {
            throw Abort(.badRequest, reason: "유효하지 않은 응답 ID입니다.")
        }
        
        // 2. 응답 조회
        guard let rsvp = try await RsvpResponse.find(rsvpId, on: req.db) else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        // 3. 요청 데이터 파싱 및 유효성 검사
        let updateRequest = try req.content.decode(UpdateRsvpRequest.self)
        try updateRequest.validate()
        
        // 4. 응답 데이터 업데이트
        rsvp.responderName = updateRequest.responderName.trimmingCharacters(in: .whitespacesAndNewlines)
        rsvp.isAttending = updateRequest.isAttending
        rsvp.adultCount = updateRequest.adultCount
        rsvp.childrenCount = updateRequest.childrenCount
        
        // 5. 데이터베이스에 저장
        try await rsvp.save(on: req.db)
        
        return SimpleRsvpResponse.from(rsvp)
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
        
        // 3. 데이터베이스에서 삭제
        try await rsvp.delete(on: req.db)
        
        return .noContent
    }

    /// 여러 응답 일괄 삭제 (관리자용)
    func bulkDeleteRsvps(req: Request) async throws -> HTTPStatus {
        // 1. 요청 데이터 파싱
        let deleteRequest = try req.content.decode(BulkDeleteRequest.self)
        
        // 2. UUID 배열 검증
        let rsvpIds = try deleteRequest.ids.map { idString in
            guard let uuid = UUID(uuidString: idString) else {
                throw Abort(.badRequest, reason: "유효하지 않은 ID 형식입니다: \(idString)")
            }
            return uuid
        }
        
        // 3. 해당 응답들을 모두 삭제
        try await RsvpResponse.query(on: req.db)
            .filter(\.$id ~~ rsvpIds)
            .delete()
        
        return .noContent
    }

    /// 응답 데이터 CSV 내보내기 (관리자용)
    func exportRsvps(req: Request) async throws -> Response {
        // 1. 모든 응답 조회 (그룹 정보 포함)
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)
            .sort(\.$createdAt, .ascending)
            .all()
        
        // 2. CSV 헤더 생성
        var csvContent = "응답자 이름,참석 여부,성인 인원,자녀 인원,총 인원,그룹명,그룹 타입,응답 시간\n"
        
        // 3. 각 응답을 CSV 행으로 변환
        for rsvp in allRsvps {
            let attendingText = rsvp.isAttending ? "참석" : "불참"
            let totalCount = rsvp.adultCount + rsvp.childrenCount
            let groupName = rsvp.group.groupName
            let groupType = rsvp.group.groupType
            
            // 날짜 포맷팅
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let createdAtString = formatter.string(from: rsvp.createdAt ?? Date())
            
            csvContent += "\(rsvp.responderName),\(attendingText),\(rsvp.adultCount),\(rsvp.childrenCount),\(totalCount),\(groupName),\(groupType),\(createdAtString)\n"
        }
        
        // 4. CSV 응답 생성
        let response = Response()
        response.headers.contentType = .init(type: "text", subType: "csv")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"rsvp_responses.csv\"")
        response.body = .init(string: csvContent)
        
        return response
    }
}
