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
}
