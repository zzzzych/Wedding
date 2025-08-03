//
//  AdminJWTAuthenticator.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 8/4/25.
//


import Fluent
import Vapor
import JWT

/// JWT 토큰을 검증하여 관리자 인증을 처리하는 미들웨어
struct AdminJWTAuthenticator: JWTAuthenticator {
    typealias Payload = AdminJWTPayload
    
    func authenticate(jwt: AdminJWTPayload, for request: Request) -> EventLoopFuture<Void> {
        // JWT 페이로드를 request.auth에 저장하여 나중에 사용할 수 있게 함
        request.auth.login(jwt)
        return request.eventLoop.makeSucceededFuture(())
    }
}
