//
//  InvitationGroup.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/15/25.
//

// 필요한 도구 상자(Fluent, Vapor)를 가져옵니다.
import Fluent
import Vapor

// 'InvitationGroup'이라는 이름의 데이터 설계도를 만듭니다.
// WeddingInfo 모델과 마찬가지로, 데이터베이스에 저장(Model)하고 JSON으로 변환(Content)할 수 있습니다.
// : Model, Content, @unchecked Sendable: 이 클래스가 Model과 Content 규칙을 따르며,
// Sendable 규칙 검사는 개발자가 책임질 테니 생략해달라고(@unchecked) 컴파일러에게 알려줍니다.
// 이것이 Sendable 관련 에러의 가장 확실한 해결책이었습니다.
final class InvitationGroup: Model, Content, @unchecked Sendable {
    // 1. 테이블 이름 정의: 데이터베이스에 "invitation_groups" 라는 이름의 테이블을 만듭니다.
    static let schema = "invitation_groups"
    
    // 2. 고유 ID 필드 정의: 각 그룹 데이터를 구분하기 위한 고유 ID입니다.
    @ID(key: .id)
    var id: UUID?
    
    // 3. 데이터 필드 정의
        
    // 그룹 이름 (예: "신랑 대학 동기", "신부 회사 동료")
    @Field(key: "group_name")
    var groupName: String

    // 그룹 유형 (예: "WEDDING_GUEST", "PARENTS_GUEST", "COMPANY_GUEST")
    // 이 값을 보고 각 그룹에 어떤 기능을 보여줄지 결정하게 됩니다.
    @Field(key: "group_type")
    var groupType: String

    // 추측 불가능한 고유 URL 코드
    // 하객들은 이 코드가 포함된 링크를 통해 청첩장에 접속하게 됩니다.
    @Field(key: "unique_code")
    var uniqueCode: String

    // 4. 기본 생성자: Fluent가 데이터베이스에서 데이터를 읽어올 때 사용합니다.
    init() { }
    
    // 5. 사용자 정의 생성자: 우리가 코드로 새로운 그룹을 만들 때 사용합니다.
    // self: 클래스 설계도 안에서 '이 코드를 실행하고 있는 실제 객체 자신'을 가리키는 대명사입니다.
    //       붕어빵 틀(클래스)의 레시피에서 "나 자신의 몸통"이라고 말하는 것과 같습니다.
    init(id: UUID? = nil, groupName: String, groupType: String, uniqueCode: String) {
        // self.id는 '이 객체의 id 필드'를, 오른쪽의 id는 생성자를 통해 전달받은 '매개변수 id'를 의미합니다.
        // 즉, "이 객체의 id 필드에, 전달받은 id 값을 넣어줘" 라는 뜻입니다.
        self.id = id
        self.groupName = groupName
        self.groupType = groupType
        self.uniqueCode = uniqueCode
    }
}
