//
//  AdminUser.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/20/25.
//

import Fluent
import Vapor

// Sendable 관련 에러 방지를 위해 클래스 선언부에 `, @unchecked Sendable` 추가
final class AdminUser: Model, Content, @unchecked Sendable {
    
    // 1. 테이블 이름 정의
    static let schema = "admin_users"
    
    // 2. 고유 ID 필드 정의
    @ID(key: .id)
    var id: UUID?
    
    // 3. 데이터 필드 정의
    // 관리자 로그인 아이디
    @Field(key: "username")
    var username: String
    
    // 암호화 된 비밀번호
    // 보안을 위해 실제 비밀번호가 아닌, 해싱된 결과 값 저장
    @Field(key: "password_hash")
    var passwordHash: String
    
    // 4. 기본 생성자
    init() {}
    
    // 5. 사용자 정의 생성자
    init(id: UUID? = nil, username: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
    }
}
