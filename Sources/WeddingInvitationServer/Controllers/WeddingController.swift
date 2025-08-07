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
    
    /// 결혼식 기본 정보 조회 (관리자용)
/// - Description: 관리자가 결혼식 기본 정보를 조회합니다. 데이터가 없으면 기본값을 반환합니다.
/// - Method: `GET`
/// - Path: `/api/admin/wedding-info`
func getWeddingInfo(req: Request) async throws -> WeddingInfo {
    // 1. JWT 토큰 검증 (실제 프로덕션에서는 미들웨어로 처리)
    // 현재는 구현 단순화를 위해 생략
    
    // 2. 데이터베이스에서 결혼식 정보 조회
    if let existingWeddingInfo = try await WeddingInfo.query(on: req.db).first() {
        // 기존 데이터가 있으면 반환
        req.logger.info("✅ 기존 결혼식 정보 조회 성공")
        return existingWeddingInfo
    } else {
        // 데이터가 없으면 빈 기본값으로 새 인스턴스 생성해서 반환
        req.logger.info("📝 결혼식 정보가 없어서 기본값 반환")
        
        let defaultWeddingInfo = WeddingInfo()
        // 필수 필드들을 빈 문자열로 초기화
        defaultWeddingInfo.groomName = ""
        defaultWeddingInfo.brideName = ""
        defaultWeddingInfo.weddingDate = Date() // 현재 날짜로 임시 설정
        defaultWeddingInfo.venueName = ""
        defaultWeddingInfo.venueAddress = ""
        defaultWeddingInfo.greetingMessage = ""
        defaultWeddingInfo.ceremonyProgram = ""
        defaultWeddingInfo.accountInfo = []
        
        // 선택사항 필드들
        defaultWeddingInfo.kakaoMapUrl = ""
        defaultWeddingInfo.naverMapUrl = ""
        defaultWeddingInfo.parkingInfo = ""
        defaultWeddingInfo.transportInfo = ""
        
        return defaultWeddingInfo
    }
}
    
    /// 결혼식 기본 정보 전체 수정 또는 생성 (관리자용)
/// - Description: 기존 데이터가 있으면 수정하고, 없으면 새로 생성합니다.
/// - Method: `PUT`
/// - Path: `/api/admin/wedding-info`
func updateWeddingInfo(req: Request) async throws -> WeddingInfo {
    // 1. JWT 토큰 검증 (실제 프로덕션에서는 미들웨어로 처리)
    // 현재는 구현 단순화를 위해 생략
    
    // 2. 요청 데이터 파싱
    let updateData = try req.content.decode(WeddingInfoUpdateRequest.self)
    
    // 3. 기존 결혼식 정보 조회
    let existingWeddingInfo = try await WeddingInfo.query(on: req.db).first()
    
    let weddingInfo: WeddingInfo
    
    if let existing = existingWeddingInfo {
        // 기존 데이터가 있으면 업데이트
        req.logger.info("🔄 기존 결혼식 정보 업데이트")
        weddingInfo = existing
    } else {
        // 기존 데이터가 없으면 새로 생성
        req.logger.info("🆕 새 결혼식 정보 생성")
        weddingInfo = WeddingInfo()
    }
    
    // 4. 모든 필드 업데이트
    weddingInfo.groomName = updateData.groomName
    weddingInfo.brideName = updateData.brideName
    weddingInfo.weddingDate = updateData.weddingDate
    weddingInfo.venueName = updateData.venueName
    weddingInfo.venueAddress = updateData.venueAddress
    weddingInfo.kakaoMapUrl = updateData.kakaoMapUrl
    weddingInfo.naverMapUrl = updateData.naverMapUrl
    weddingInfo.parkingInfo = updateData.parkingInfo
    weddingInfo.transportInfo = updateData.transportInfo
    weddingInfo.greetingMessage = updateData.greetingMessage
    weddingInfo.ceremonyProgram = updateData.ceremonyProgram
    weddingInfo.accountInfo = updateData.accountInfo
    
    // 5. 데이터베이스에 저장 (생성 또는 업데이트)
    try await weddingInfo.save(on: req.db)
    
    req.logger.info("✅ 결혼식 정보 저장 완료")
    return weddingInfo
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
    let kakaoMapUrl: String?
    let naverMapUrl: String?
    let parkingInfo: String?
    let transportInfo: String?
    let greetingMessage: String?
    let ceremonyProgram: String?
    let accountInfo: [String]?
}

// MARK: - Custom Date Decoding

extension WeddingInfoUpdateRequest {
    /// 커스텀 날짜 디코딩을 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case groomName, brideName, weddingDate, venueName, venueAddress
        case kakaoMapUrl, naverMapUrl, parkingInfo, transportInfo
        case greetingMessage, ceremonyProgram, accountInfo
    }
    
    /// 커스텀 디코딩 초기화
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 기본 문자열 필드들
        self.groomName = try container.decode(String.self, forKey: .groomName)
        self.brideName = try container.decode(String.self, forKey: .brideName)
        self.venueName = try container.decode(String.self, forKey: .venueName)
        self.venueAddress = try container.decode(String.self, forKey: .venueAddress)
        self.greetingMessage = try container.decode(String.self, forKey: .greetingMessage)
        self.ceremonyProgram = try container.decode(String.self, forKey: .ceremonyProgram)
        self.accountInfo = try container.decode([String].self, forKey: .accountInfo)
        
        // 선택적 문자열 필드들 (null 처리)
        self.kakaoMapUrl = try container.decodeIfPresent(String.self, forKey: .kakaoMapUrl)
        self.naverMapUrl = try container.decodeIfPresent(String.self, forKey: .naverMapUrl)
        self.parkingInfo = try container.decodeIfPresent(String.self, forKey: .parkingInfo)
        self.transportInfo = try container.decodeIfPresent(String.self, forKey: .transportInfo)
        
        // 📅 커스텀 날짜 디코딩 - ISO 8601 문자열을 Date로 변환
        let weddingDateString = try container.decode(String.self, forKey: .weddingDate)
        
        // ISO 8601 포맷터 생성
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 먼저 fractional seconds 포함 형태로 시도
        if let date = isoFormatter.date(from: weddingDateString) {
            self.weddingDate = date
        } else {
            // fractional seconds 없는 형태로 재시도
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: weddingDateString) {
                self.weddingDate = date
            } else {
                // 기본 DateFormatter로 최종 시도
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                fallbackFormatter.timeZone = TimeZone(abbreviation: "UTC")
                
                if let date = fallbackFormatter.date(from: weddingDateString) {
                    self.weddingDate = date
                } else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .weddingDate,
                        in: container,
                        debugDescription: "날짜 형식이 올바르지 않습니다: \(weddingDateString)"
                    )
                }
            }
        }
    }
}

extension WeddingInfoPatchRequest {
    /// 커스텀 날짜 디코딩을 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case groomName, brideName, weddingDate, venueName, venueAddress
        case kakaoMapUrl, naverMapUrl, parkingInfo, transportInfo
        case greetingMessage, ceremonyProgram, accountInfo
    }
    
    /// 커스텀 디코딩 초기화 (PATCH용 - 모든 필드 선택사항)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 모든 필드가 선택사항이므로 decodeIfPresent 사용
        self.groomName = try container.decodeIfPresent(String.self, forKey: .groomName)
        self.brideName = try container.decodeIfPresent(String.self, forKey: .brideName)
        self.venueName = try container.decodeIfPresent(String.self, forKey: .venueName)
        self.venueAddress = try container.decodeIfPresent(String.self, forKey: .venueAddress)
        self.greetingMessage = try container.decodeIfPresent(String.self, forKey: .greetingMessage)
        self.ceremonyProgram = try container.decodeIfPresent(String.self, forKey: .ceremonyProgram)
        self.accountInfo = try container.decodeIfPresent([String].self, forKey: .accountInfo)
        self.kakaoMapUrl = try container.decodeIfPresent(String.self, forKey: .kakaoMapUrl)
        self.naverMapUrl = try container.decodeIfPresent(String.self, forKey: .naverMapUrl)
        self.parkingInfo = try container.decodeIfPresent(String.self, forKey: .parkingInfo)
        self.transportInfo = try container.decodeIfPresent(String.self, forKey: .transportInfo)
        
        // 📅 선택적 날짜 디코딩
        if let weddingDateString = try container.decodeIfPresent(String.self, forKey: .weddingDate) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = isoFormatter.date(from: weddingDateString) {
                self.weddingDate = date
            } else {
                isoFormatter.formatOptions = [.withInternetDateTime]
                if let date = isoFormatter.date(from: weddingDateString) {
                    self.weddingDate = date
                } else {
                    let fallbackFormatter = DateFormatter()
                    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    fallbackFormatter.timeZone = TimeZone(abbreviation: "UTC")
                    
                    if let date = fallbackFormatter.date(from: weddingDateString) {
                        self.weddingDate = date
                    } else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .weddingDate,
                            in: container,
                            debugDescription: "날짜 형식이 올바르지 않습니다: \(weddingDateString)"
                        )
                    }
                }
            }
        } else {
            self.weddingDate = nil
        }
    }
}