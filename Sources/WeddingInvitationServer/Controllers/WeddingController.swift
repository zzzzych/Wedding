//
//  WeddingController.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/20/25.
//
import Fluent
import Vapor

// WeddingInfo 데이터와 관련된 API 요청들을 처리할 컨트롤러를 정의합니다.
struct WeddingController: RouteCollection {
    // RouteCollection 규칙을 따르기 위해 꼭 필요한 함수입니다.
    // 이 컨트롤러가 어떤 API 경로들을 처리할지 등록하는 역할을 합니다.
    func boot(routes: any RoutesBuilder) throws {
        // "/wedding-info" 라는 경로로 들어오는 요청들을 처리할 그룹을 만듭니다.
        let weddingRoutes = routes.grouped("wedding-info")
        // POST 요청이 들어왔을 때 create 함수를 실행하도록 등록합니다.
        weddingRoutes.post(use: create)
        
        // --- [새로 추가: 관리자 전용 라우트] ---
        // ✅ let api = routes.grouped("api") 줄 삭제
        let admin = routes.grouped("admin")
        
        // GET /api/admin/wedding-info - 결혼식 정보 조회 (관리자용)
        admin.get("wedding-info", use: getWeddingInfo)
        
        // PUT /api/admin/wedding-info - 결혼식 정보 전체 수정 (관리자용)
        admin.put("wedding-info", use: updateWeddingInfo)
        
        // PATCH /api/admin/wedding-info - 결혼식 정보 부분 수정 (관리자용)
        admin.patch("wedding-info", use: patchWeddingInfo)
    }

    // POST /wedding-info 요청을 처리할 함수입니다.
    // 'async'는 이 함수가 비동기(시간이 걸리는 작업)로 동작함을 의미합니다.
    // 'throws'는 함수 실행 중 에러가 발생할 수 있음을 의미합니다.
    func create(req: Request) async throws -> WeddingInfo {
        // 1. 요청(req)에 담겨온 JSON 데이터를 WeddingInfo 모델(설계도)에 맞게 디코딩(해석)합니다.
        let weddingInfo = try req.content.decode(WeddingInfo.self)
        
        // 2. 해석된 weddingInfo 데이터를 데이터베이스에 저장합니다.
        // 'req.db'는 데이터베이스에 접근할 수 있게 해주는 도구입니다.
        try await weddingInfo.save(on: req.db)
        
        // 3. 저장이 성공적으로 끝나면, 방금 저장된 weddingInfo 데이터를 다시 반환합니다.
        return weddingInfo
    }
    
    // MARK: - GET /api/admin/wedding-info
    /// 결혼식 정보 조회 (관리자용)
    func getWeddingInfo(req: Request) async throws -> WeddingInfo {
        // 1. 데이터베이스에서 첫 번째 결혼식 정보 조회
        // (현재는 하나의 결혼식만 지원하므로 첫 번째 정보 반환)
        guard let weddingInfo = try await WeddingInfo.query(on: req.db).first() else {
            throw Abort(.notFound, reason: "결혼식 정보를 찾을 수 없습니다.")
        }
        
        return weddingInfo
    }
    
    // MARK: - PUT /api/admin/wedding-info
    /// 결혼식 정보 전체 수정 (관리자용)
    func updateWeddingInfo(req: Request) async throws -> WeddingInfo {
        // 1. 기존 결혼식 정보 조회
        guard let existingWeddingInfo = try await WeddingInfo.query(on: req.db).first() else {
            throw Abort(.notFound, reason: "수정할 결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 2. 요청 데이터 파싱
        let updateData = try req.content.decode(WeddingInfoUpdateRequest.self)
        
        // 3. 모든 필드 업데이트
        existingWeddingInfo.groomName = updateData.groomName
        existingWeddingInfo.brideName = updateData.brideName
        existingWeddingInfo.weddingDate = updateData.weddingDate
        existingWeddingInfo.venueName = updateData.venueName
        existingWeddingInfo.venueAddress = updateData.venueAddress
        existingWeddingInfo.venueDetail = updateData.venueDetail
        existingWeddingInfo.kakaoMapUrl = updateData.kakaoMapUrl
        existingWeddingInfo.naverMapUrl = updateData.naverMapUrl
        existingWeddingInfo.parkingInfo = updateData.parkingInfo
        existingWeddingInfo.transportInfo = updateData.transportInfo
        existingWeddingInfo.greetingMessage = updateData.greetingMessage
        existingWeddingInfo.ceremonyProgram = updateData.ceremonyProgram
        existingWeddingInfo.accountInfo = updateData.accountInfo
        
        // 4. 데이터베이스에 저장
        try await existingWeddingInfo.save(on: req.db)
        
        return existingWeddingInfo
    }

    // MARK: - PATCH /api/admin/wedding-info
    /// 결혼식 정보 부분 수정 (관리자용)
    func patchWeddingInfo(req: Request) async throws -> WeddingInfo {
        // 1. 기존 결혼식 정보 조회
        guard let existingWeddingInfo = try await WeddingInfo.query(on: req.db).first() else {
            throw Abort(.notFound, reason: "수정할 결혼식 정보를 찾을 수 없습니다.")
        }
        
        // 2. 요청 데이터 파싱 (부분 업데이트용)
        let patchData = try req.content.decode(WeddingInfoPatchRequest.self)
        
        // 3. 전달된 필드만 선택적으로 업데이트
        if let groomName = patchData.groomName {
            existingWeddingInfo.groomName = groomName
        }
        if let brideName = patchData.brideName {
            existingWeddingInfo.brideName = brideName
        }
        if let weddingDate = patchData.weddingDate {
            existingWeddingInfo.weddingDate = weddingDate
        }
        if let venueName = patchData.venueName {
            existingWeddingInfo.venueName = venueName
        }
        if let venueAddress = patchData.venueAddress {
            existingWeddingInfo.venueAddress = venueAddress
        }
        if let venueDetail = patchData.venueDetail {
            existingWeddingInfo.venueDetail = venueDetail
        }
        if let kakaoMapUrl = patchData.kakaoMapUrl {
            existingWeddingInfo.kakaoMapUrl = kakaoMapUrl
        }
        if let naverMapUrl = patchData.naverMapUrl {
            existingWeddingInfo.naverMapUrl = naverMapUrl
        }
        if let parkingInfo = patchData.parkingInfo {
            existingWeddingInfo.parkingInfo = parkingInfo
        }
        if let transportInfo = patchData.transportInfo {
            existingWeddingInfo.transportInfo = transportInfo
        }
        if let greetingMessage = patchData.greetingMessage {
            existingWeddingInfo.greetingMessage = greetingMessage
        }
        if let ceremonyProgram = patchData.ceremonyProgram {
            existingWeddingInfo.ceremonyProgram = ceremonyProgram
        }
        if let accountInfo = patchData.accountInfo {
            existingWeddingInfo.accountInfo = accountInfo
        }
        
        // 4. 데이터베이스에 저장
        try await existingWeddingInfo.save(on: req.db)
        
        return existingWeddingInfo
    }
}

// MARK: - Request Models

/// 결혼식 정보 전체 수정 요청 데이터
struct WeddingInfoUpdateRequest: Content {
    let groomName: String
    let brideName: String
    let weddingDate: Date
    let venueName: String
    let venueAddress: String
    let venueDetail: String
    let kakaoMapUrl: String?
    let naverMapUrl: String?
    let parkingInfo: String?
    let transportInfo: String?
    let greetingMessage: String
    let ceremonyProgram: String
    let accountInfo: [String]
}

/// 결혼식 정보 부분 수정 요청 데이터 (모든 필드 선택사항)
struct WeddingInfoPatchRequest: Content {
    let groomName: String?
    let brideName: String?
    let weddingDate: Date?
    let venueName: String?
    let venueAddress: String?
    let venueDetail: String?
    let kakaoMapUrl: String?
    let naverMapUrl: String?
    let parkingInfo: String?
    let transportInfo: String?
    let greetingMessage: String?
    let ceremonyProgram: String?
    let accountInfo: [String]?
}
