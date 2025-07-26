//
//  RsvpController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/24/25.
//

import Fluent
import Vapor

/// 참석 응답 관련 API를 처리하는 컨트롤러
struct RsvpController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // POST /api/invitation/:uniqueCode/rsvp - 참석 여부 응답 제출 (인증 불필요)
        api.post("invitation", ":uniqueCode", "rsvp", use: submitRsvp)
        
        // 관리자 전용 라우트 (임시로 인증 미들웨어 제거)
        let admin = api.grouped("admin")
        admin.get("rsvps", use: getAllRsvps)
    }
    
    // MARK: - POST /api/invitation/:uniqueCode/rsvp
    /// 참석 여부 응답 제출
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
        
        // 3. 그룹 타입이 WEDDING_GUEST인지 확인 (참석 응답은 결혼식 초대 그룹만 가능)
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
    
    // MARK: - GET /api/admin/rsvps
    /// 모든 참석 응답 현황 조회 (관리자용)
    func getAllRsvps(req: Request) async throws -> RsvpSummary {
        // 1. 모든 참석 응답 조회 (그룹 정보 포함)
        let allRsvps = try await RsvpResponse.query(on: req.db)
            .with(\.$group)  // 관련된 그룹 정보도 함께 로드
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
}

// MARK: - Request/Response Models

/// 참석 여부 응답 요청 데이터
struct RsvpRequest: Content {
    let responderName: String    // 응답자 이름
    let isAttending: Bool        // 참석 여부
    let adultCount: Int          // 성인 인원수
    let childrenCount: Int       // 자녀 인원수
}

/// 참석 여부 응답 반환 데이터
struct RsvpResponseData: Content {
    let id: UUID?
    let responderName: String
    let isAttending: Bool
    let adultCount: Int
    let childrenCount: Int
    let submittedAt: Date?
    
    static func from(_ rsvp: RsvpResponse) -> RsvpResponseData {
        return RsvpResponseData(
            id: rsvp.id,
            responderName: rsvp.responderName,
            isAttending: rsvp.isAttending,
            adultCount: rsvp.adultCount,
            childrenCount: rsvp.childrenCount,
            submittedAt: rsvp.createdAt
        )
    }
}

/// 그룹 정보가 포함된 참석 응답 데이터
struct RsvpWithGroupInfo: Content {
    let id: UUID?
    let responderName: String
    let isAttending: Bool
    let adultCount: Int
    let childrenCount: Int
    let submittedAt: Date?
    let groupName: String
    let groupType: String
    
    static func from(_ rsvp: RsvpResponse) -> RsvpWithGroupInfo {
        return RsvpWithGroupInfo(
            id: rsvp.id,
            responderName: rsvp.responderName,
            isAttending: rsvp.isAttending,
            adultCount: rsvp.adultCount,
            childrenCount: rsvp.childrenCount,
            submittedAt: rsvp.createdAt,
            groupName: rsvp.group.groupName,
            groupType: rsvp.group.groupType
        )
    }
}

/// 참석 응답 요약 정보
struct RsvpSummary: Content {
    let totalResponses: Int      // 총 응답 수
    let attendingCount: Int      // 참석 응답 수
    let notAttendingCount: Int   // 불참 응답 수
    let totalAdults: Int         // 총 성인 인원
    let totalChildren: Int       // 총 자녀 인원
    let totalPeople: Int         // 총 인원수
    let responses: [RsvpWithGroupInfo]  // 개별 응답 목록
}
