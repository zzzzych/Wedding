//
//  RsvpController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent
import Vapor
import Foundation  // CharacterSet 사용을 위해 추가

/// 참석 응답 관련 API를 처리하는 컨트롤러 (새 버전)
struct RsvpController: RouteCollection {
    
    /// 라우트 등록 함수 - 이 컨트롤러가 처리할 API 경로들을 정의합니다
    /// - Parameter routes: 라우트 빌더 객체
    func boot(routes: any RoutesBuilder) throws {
        // === 하객용 API (인증 불필요) ===
        // POST /api/invitation/:uniqueCode/rsvp - 참석 여부 응답 제출
        routes.post("invitation", ":uniqueCode", "rsvp", use: submitRsvp)
        
        // === 관리자용 API ===
        let admin = routes.grouped("admin")
        
        // 응답 조회 API들
        admin.get("rsvps", use: getAllRsvps)                      // 전체 응답 통계 조회
        admin.get("rsvps", "list", use: getAllRsvpsList)          // 개별 응답 목록 조회
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
    /// - Parameter req: HTTP 요청 객체
    /// - Returns: 제출된 응답 데이터
    func submitRsvp(req: Request) async throws -> SimpleRsvpResponse {
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
        
        // 4. 요청 데이터 파싱 및 유효성 검사
        let rsvpRequest = try req.content.decode(RsvpRequest.self)
        try rsvpRequest.validate()
        
       // 5. 대표 응답자 이름 추출 (개선됨 - 불참자 이름 처리)
        let responderName: String
        if let reqResponderName = rsvpRequest.responderName, !reqResponderName.isEmpty {
            // 요청에 응답자 이름이 명시적으로 포함된 경우 사용
            responderName = reqResponderName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else if rsvpRequest.isAttending && !rsvpRequest.attendeeNames.isEmpty {
            // 참석인 경우 첫 번째 참석자 이름 사용
            responderName = rsvpRequest.attendeeNames[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            // 모든 경우에 해당하지 않으면 "미응답자"
            responderName = "미응답자"
        }
        
        // 6. 이미 같은 이름으로 응답했는지 확인 (중복 응답 방지)
        // 해당 그룹의 모든 응답을 가져와서 첫 번째 이름으로 중복 체크
        let allGroupResponses = try await RsvpResponse.query(on: req.db)
            .filter(\.$group.$id == invitationGroup.id!)
            .all()

        let existingResponse = allGroupResponses.first { response in
            !response.attendeeNames.isEmpty && response.attendeeNames[0] == responderName
        }
        
        if let existing = existingResponse {
            // 기존 응답 업데이트
            existing.isAttending = rsvpRequest.isAttending
            existing.totalCount = rsvpRequest.totalCount
            existing.attendeeNames = rsvpRequest.attendeeNames.map { 
                $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) 
            }
            existing.phoneNumber = rsvpRequest.phoneNumber?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            existing.message = rsvpRequest.message?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            try await existing.save(on: req.db)
            return SimpleRsvpResponse.from(existing)
        } else {
            // 새 응답 생성
            let newRsvp = RsvpResponse(
                isAttending: rsvpRequest.isAttending,
                totalCount: rsvpRequest.totalCount,
                attendeeNames: rsvpRequest.attendeeNames.map { 
                    $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) 
                },
                responderName: responderName, // 새로 추가된 매개변수
                phoneNumber: rsvpRequest.phoneNumber?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                message: rsvpRequest.message?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                groupID: invitationGroup.id!
            )
            
            try await newRsvp.save(on: req.db)
            return SimpleRsvpResponse.from(newRsvp)
        }
    }
    
    // MARK: - 관리자용 조회 API 기능들
    
    /// 모든 참석 응답 현황 조회 (관리자용)
    func getAllRsvps(req: Request) async throws -> RsvpSummary {
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)
            .sort(\.$createdAt, .descending)
            .all()
        
        let totalResponses = allRsvps.count
        let attendingResponses = allRsvps.filter { $0.isAttending }
        let attendingCount = attendingResponses.count
        let totalAttendingCount = attendingResponses.reduce(0) { $0 + $1.totalCount }
        
        return RsvpSummary(
            totalResponses: totalResponses,
            attendingResponses: attendingCount,
            notAttendingResponses: totalResponses - attendingCount,
            totalAttendingCount: totalAttendingCount,
            totalAdultCount: 0,  // 새 버전에서는 성인/자녀 구분 없음
            totalChildrenCount: 0
        )
    }
    
    /// 모든 응답 목록 조회 (관리자용)
    func getAllRsvpsList(req: Request) async throws -> RsvpListResponse {
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)
            .sort(\.$createdAt, .descending)
            .all()
        
        let responses = allRsvps.map { SimpleRsvpWithGroupInfo.from($0) }
        let summary = try await getAllRsvps(req: req)
        
        return RsvpListResponse(responses: responses, summary: summary)
    }
    
    /// 특정 응답 조회 (관리자용)
    func getRsvp(req: Request) async throws -> SimpleRsvpWithGroupInfo {
        guard let rsvpId = req.parameters.get("rsvpId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "잘못된 응답 ID입니다.")
        }
        
        guard let rsvp = try await RsvpResponse.query(on: req.db)
            .filter(\.$id == rsvpId)
            .with(\.$group)
            .first() else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        return SimpleRsvpWithGroupInfo.from(rsvp)
    }
    
    /// 응답 수정 (관리자용)
    func updateRsvp(req: Request) async throws -> SimpleRsvpResponse {
        guard let rsvpId = req.parameters.get("rsvpId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "잘못된 응답 ID입니다.")
        }
        
        guard let rsvp = try await RsvpResponse.find(rsvpId, on: req.db) else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        let updateRequest = try req.content.decode(RsvpRequest.self)
        try updateRequest.validate()
        
        rsvp.isAttending = updateRequest.isAttending
        rsvp.totalCount = updateRequest.totalCount
        rsvp.attendeeNames = updateRequest.attendeeNames
        rsvp.phoneNumber = updateRequest.phoneNumber
        rsvp.message = updateRequest.message
        
        try await rsvp.save(on: req.db)
        return SimpleRsvpResponse.from(rsvp)
    }
    
    /// 응답 삭제 (관리자용)
    func deleteRsvp(req: Request) async throws -> HTTPStatus {
        guard let rsvpId = req.parameters.get("rsvpId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "잘못된 응답 ID입니다.")
        }
        
        guard let rsvp = try await RsvpResponse.find(rsvpId, on: req.db) else {
            throw Abort(.notFound, reason: "응답을 찾을 수 없습니다.")
        }
        
        try await rsvp.delete(on: req.db)
        return .noContent
    }
    
    /// 여러 응답 일괄 삭제 (관리자용)
    func bulkDeleteRsvps(req: Request) async throws -> HTTPStatus {
        struct BulkDeleteRequest: Content {
            let rsvpIds: [UUID]
        }
        
        let deleteRequest = try req.content.decode(BulkDeleteRequest.self)
        
        try await RsvpResponse.query(on: req.db)
            .filter(\.$id ~~ deleteRequest.rsvpIds)
            .delete()
        
        return .noContent
    }
    
    /// 응답 데이터 CSV 내보내기 (관리자용)
    func exportRsvps(req: Request) async throws -> Response {
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)
            .sort(\.$createdAt, .descending)
            .all()
        
        var csvContent = "응답자,참석여부,총인원,참석자명단,전화번호,메시지,그룹명,응답시간\n"
        
        for rsvp in allRsvps {
            let attendeeList = rsvp.attendeeNames.joined(separator: ";")
            let line = "\(rsvp.responderName),\(rsvp.isAttending ? "참석" : "불참"),\(rsvp.totalCount),\(attendeeList),\(rsvp.phoneNumber ?? ""),\(rsvp.message ?? ""),\(rsvp.group.groupName),\(rsvp.createdAt?.description ?? "")\n"
            csvContent += line
        }
        
        let response = Response(status: .ok, body: .init(string: csvContent))
        response.headers.contentType = .init(type: "text", subType: "csv")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=rsvp_responses.csv")
        
        return response
    }
}