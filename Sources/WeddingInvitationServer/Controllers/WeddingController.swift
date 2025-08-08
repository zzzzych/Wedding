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
    func boot(routes: RoutesBuilder) throws {
        // "/wedding-info" 라는 경로로 들어오는 요청들을 처리할 그룹을 만듭니다.
        let weddingRoutes = routes.grouped("wedding-info")
        // POST 요청이 들어왔을 때 create 함수를 실행하도록 등록합니다.
        weddingRoutes.post(use: create)
        
        // --- [새로 추가: 관리자 전용 라우트] ---
        let admin = routes.grouped("admin")
        
        // GET /api/admin/wedding-info - 결혼식 정보 조회 (관리자용)
        admin.get("wedding-info", use: getWeddingInfo)
        
        // PUT /api/admin/wedding-info - 결혼식 정보 전체 수정 (관리자용)
        admin.put("wedding-info", use: updateWeddingInfo)
        
        // PATCH /api/admin/wedding-info - 결혼식 정보 부분 수정 (관리자용)
        admin.patch("wedding-info", use: patchWeddingInfo)
        
        // 디버그용 임시 엔드포인트 추가
        admin.get("debug", "table-info", use: getTableInfo)
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
        
        do {
            // 2. 요청 데이터 파싱 - 더 자세한 로깅 추가
            req.logger.info("📥 결혼식 정보 수정 요청 시작")
            req.logger.info("📊 요청 본문 크기: \(req.body.data?.readableBytes ?? 0) bytes")
            
            let updateData: WeddingInfoUpdateRequest
            do {
                updateData = try req.content.decode(WeddingInfoUpdateRequest.self)
                req.logger.info("✅ 요청 데이터 디코딩 성공")
                req.logger.info("👰 신부: \(updateData.brideName), 🤵 신랑: \(updateData.groomName)")
                req.logger.info("📅 결혼식 날짜: \(updateData.weddingDate)")
                req.logger.info("🏛️ 웨딩홀: \(updateData.venueName)")
            } catch {
                req.logger.error("❌ 요청 데이터 디코딩 실패: \(error)")
                throw Abort(.badRequest, reason: "요청 데이터 형식이 올바르지 않습니다: \(error.localizedDescription)")
            }
            
            // 3. 기존 결혼식 정보 조회
            req.logger.info("🔍 기존 결혼식 정보 조회 중...")
            let existingWeddingInfo = try await WeddingInfo.query(on: req.db).first()
            
            let weddingInfo: WeddingInfo
            
            if let existing = existingWeddingInfo {
                // 기존 데이터 업데이트
                req.logger.info("🔄 기존 결혼식 정보 업데이트 (ID: \(existing.id?.uuidString ?? "unknown"))")
                weddingInfo = existing
                
                // 모든 필드 업데이트
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
            } else {
                // 새 데이터 생성
                req.logger.info("🆕 새로운 결혼식 정보 생성")
                weddingInfo = WeddingInfo(
                    groomName: updateData.groomName,
                    brideName: updateData.brideName,
                    weddingDate: updateData.weddingDate,
                    venueName: updateData.venueName,
                    venueAddress: updateData.venueAddress,
                    kakaoMapUrl: updateData.kakaoMapUrl,
                    naverMapUrl: updateData.naverMapUrl,
                    parkingInfo: updateData.parkingInfo,
                    transportInfo: updateData.transportInfo,
                    greetingMessage: updateData.greetingMessage,
                    ceremonyProgram: updateData.ceremonyProgram,
                    accountInfo: updateData.accountInfo
                )
            }
            
            // 4. 데이터베이스에 저장 (생성 또는 업데이트) - 상세 에러 처리
            req.logger.info("💾 데이터베이스 저장 시작...")
            do {
                try await weddingInfo.save(on: req.db)
                req.logger.info("✅ 결혼식 정보 저장 완료 (ID: \(weddingInfo.id?.uuidString ?? "unknown"))")
            } catch let saveError {
                req.logger.error("❌ 데이터베이스 저장 실패: \(saveError)")
                req.logger.error("❌ 저장 실패 상세: \(String(describing: saveError))")
                
                // 🆕 더 상세한 오류 정보 출력 (임시 디버깅용)
                req.logger.error("❌ 상세 오류 내용: \(String(reflecting: saveError))")
                
                // Fluent/PostgreSQL 특정 에러 분석
                if let fluentError = saveError as? FluentError {
                    req.logger.error("❌ Fluent 에러: \(fluentError)")
                }
                
                throw Abort(.internalServerError, reason: "데이터베이스 저장 중 오류가 발생했습니다: \(saveError.localizedDescription)")
            }
            
            req.logger.info("🎉 결혼식 정보 수정 프로세스 완료")
            return weddingInfo
            
        } catch let controllerError {
            // 최상위 에러 캐치 및 로깅
            req.logger.error("❌ updateWeddingInfo 함수 전체 에러: \(controllerError)")
            req.logger.error("❌ 에러 타입: \(type(of: controllerError))")
            req.logger.error("❌ 에러 상세: \(String(describing: controllerError))")
            
            // Abort 에러는 그대로 전달, 그 외는 일반적인 내부 서버 에러로 변환
            if let abort = controllerError as? Abort {
                throw abort
            } else {
                throw Abort(.internalServerError, reason: "결혼식 정보 처리 중 예상치 못한 오류가 발생했습니다: \(controllerError.localizedDescription)")
            }
        }
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
    
    /// 테이블 구조 확인용 임시 디버그 함수
    func getTableInfo(req: Request) async throws -> [String: Any] {
        // PostgreSQL 테이블 구조 조회 쿼리
        let query = """
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'wedding_infos' 
        ORDER BY ordinal_position;
        """
        
        do {
            // Raw SQL 쿼리 실행
            let rows = try await req.db.raw(query).all()
            
            // 결과를 배열로 변환
            var columns: [[String: Any]] = []
            for row in rows {
                var columnInfo: [String: Any] = [:]
                
                // 각 컬럼에서 값을 추출
                for (key, value) in row.schema {
                    switch key {
                    case "column_name", "data_type", "is_nullable":
                        columnInfo[key] = "\(value)"
                    default:
                        break
                    }
                }
                
                if !columnInfo.isEmpty {
                    columns.append(columnInfo)
                }
            }
            
            return [
                "table_name": "wedding_infos",
                "columns": columns,
                "total_columns": columns.count
            ]
        } catch {
            req.logger.error("테이블 정보 조회 실패: \(error)")
            throw Abort(.internalServerError, reason: "테이블 정보를 조회할 수 없습니다.")
        }
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