//
//  CreateWeddingSchema.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/20/25.
//

import Fluent
// 'CreateWeddingSchema' 라는 이름의 마이그레이션(데이터베이스 테이블 생성 작업)을 정의합니다.
struct CreateWeddingSchema: Migration {
    
    // 이 함수는 마이그레이션을 실행할 때(테이블을 생성할 때) 호출됩니다.
    // func prepare: '준비하다'라는 의미의 함수(func)입니다. 마이그레이션을 실행하면 이 함수 안의 코드가 동작합니다.
    // (on database: Database): 이 함수가 작업을 수행하기 위해 'database'라는 이름의 'Database' 타입 도구를 전달받는다는 의미입니다.
    // -> EventLoopFuture<Void>: 이 함수의 작업이 비동기(시간이 걸리는 작업)로 처리되며,
    //                          작업이 모두 끝나면 특별한 값 없이(Void) 완료된다는 것을 의미합니다.
    // database: 데이터베이스에 접근할 수 있게 해주는 도구입니다.
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // 데이터베이스 작업을 순서대로 실행하기 위한 준비입니다.
        // 먼저 WeddingInfo 테이블을 만듭니다.
        database.schema(WeddingInfo.schema)
            .id() // 고유 ID 필드를 만듭니다. (Primary Key)
            .field( "groom_name", .string, .required) // 신랑 이름, "groom_name"이라는 이름의 문자열(String) 필드를 만들고, 이 값은 필수(required)임을 명시
            .field( "bride_name", .string, .required) // 신부 이름
            .field( "wedding_date", .datetime, .required) // 날짜와 시간을 저장하는 필드
            .field( "wedding_location", .string, .required) // 식장 위치
            .field( "greeting_message", .string, .required) // 초대 인삿말
            .field( "ceremony_program", .string, .required) // 결혼식 식순
            .field( "account_info", .array(of: .string), .required) // 계좌 정보, 배열로 저장
            .create() //위에서 정의한 내용으로 실제 테이블 생성
            .flatMap { //작업 이어서 하기
                // InvitationGroup 테이블 만들기
                database.schema(InvitationGroup.schema)
                    .id()
                    .field( "group_name", .string, .required)
                    .field( "group_type", .string, .required)
                    .field( "unique_code", .string, .required)
                    .unique(on: "unique_code") // unique_code 값은 절대 중복될 수 없도록 설정합니다.
                    .create()
            }.flatMap {
                // 그 다음, AdminUser 테이블을 만듭니다.
                database.schema(AdminUser.schema)
                    .id()
                    .field( "username", .string, .required)
                    .unique(on: "username")
                    .field( "password_hash", .string, .required)
                    .create()
            }.flatMap {
                // 마지막으로 RsvpResponse 테이블을 만듭니다.
                database.schema(RsvpResponse.schema)
                    .id()
                    .field( "responder_name", .string, .required)
                    .field( "is_attending", .bool, .required)
                    .field( "adult_count", .int, .required)
                    .field( "children_count", .int, .required)
                // "group_id" 필드를 만들고, 이 필드가 invitation_groups 테이블의 id를 참조함을 명시합니다. (Foreign Key)
                    .field("group_id", .uuid, .required, .references(InvitationGroup.schema, "id"))
                    .create()
            }
    }
    
    // 이 함수는 마이그레이션을 되돌릴 때(만들었던 테이블을 삭제할 때) 호출됩니다.
    // func revert: '되돌리다'라는 의미의 함수입니다. 마이그레이션을 취소하면 이 함수 안의 코드가 동작합니다.
    //             prepare 함수와 마찬가지로 비동기로 처리되며, 작업이 끝나면 완료 신호를 보냅니다.
   func revert(on database: any Database) -> EventLoopFuture<Void> {
       // 테이블 생성의 역순으로 삭제해야 안전합니다.
       // 자식 테이블(RsvpResponse)이 부모 테이블(InvitationGroup)을 참조하고 있기 때문에,
       // 자식 테이블을 먼저 삭제해야 부모 테이블을 안전하게 삭제할 수 있습니다.
       database.schema(RsvpResponse.schema).delete()
           .flatMap { database.schema(AdminUser.schema).delete() }
           .flatMap { database.schema(InvitationGroup.schema).delete() }
           .flatMap { database.schema(WeddingInfo.schema).delete() }
   }
}
