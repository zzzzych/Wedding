//
//  WeddingInfo.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/13/25.
//

//Fluent와 Vapor라는 도구 상자 가져오기
//Fluent는 데이터베이스, Vapor는 웹 서버

import Fluent
import Vapor

// MARK: - WeddingInfo (공통 정보)

// 'WeddingInfo'라는 이름의 데이터 설계도를 만듭니다.
// 이 한 줄의 구조는 'final class [설계도 이름]: [자격증1], [자격증2]' 형식입니다.
// 1. final class WeddingInfo: 'WeddingInfo'라는 이름의 최종본 설계도(클래스)를 만든다는 선언입니다.
//    - class: Swift에서 '설계도'를 만드는 핵심 키워드입니다.
//    - final: 이 설계도를 더 이상 고쳐서 다른 버전을 만들 수 없다는 뜻입니다.
// 2. : Model, Content: 콜론(:) 뒤에는 이 설계도가 따를 규칙(프로토콜)이나 물려받을 능력을 적습니다.
//    - Model: 데이터베이스에 저장될 수 있는 '모델' 자격증입니다.
//    - Content: 웹에서 쓰는 데이터 형식(JSON)으로 쉽게 변환될 수 있는 '콘텐츠' 자격증입니다.
//    - Vapor로 데이터베이스와 통신하는 서버를 만들 땐 이 두 자격증이 거의 필수 조합입니다.
final class WeddingInfo: Model, @unchecked Sendable, Content  {
    // 1. 테이블 이름 정의: 이 설계도로 만들 데이터베이스 테이블의 이름을 "wedding_infos"로 정합니다.
    // static: 이 정보가 WeddingInfo 라는 '설계도 자체'에 속한 공용 정보임을 뜻합니다. (객체마다 갖는 개별 정보가 아님)
    // let: 한번 정하면 절대 바꿀 수 없는 상수라는 뜻입니다. 테이블 이름이 바뀌면 안 되니까요.
    static let schema = "wedding_infos"
    
    
    // 2. 고유 ID 필드 정의: 각 데이터의 고유한 주민등록번호 같은 역할을 할 ID 필드입니다.
    // @ID(key: .id): 이 필드가 데이터베이스의 고유 식별자(Primary Key)임을 나타내는 특별한 딱지입니다.
    //      - @ID: "이 필드는 PK야!" 라고 선언하는 부분입니다.
    //      - (key: .id): "데이터베이스 테이블에 만들 컬럼(칸)의 이름은 'id'로 해줘" 라는 구체적인 지시입니다.
    //      이것은 Swift 기본 문법이 아니라, Vapor의 데이터베이스 도구인 Fluent가 제공하는 기능입니다.
    // var id: UUID?: 'id'라는 이름의 저장 공간. UUID는 절대 중복되지 않는 긴 랜덤 아이디를 의미합니다.
    // '?'(Optional)이 붙은 이유: 처음 데이터를 만들 땐 id가 없다가(nil), DB에 저장된 후에야 자동으로 id가 생기기 때문입니다.
    @ID(key: .id)
    var id: UUID?
    
    // 3. 데이터 필드 정의: 실제 데이터를 담을 공간들을 정의합니다.
    // @Field: 이 필드가 데이터베이스의 일반 데이터 칸(컬럼)임을 나타내는 Fluent의 기능입니다.
    //         (key: "groom_name")은 DB에 저장될 때의 컬럼 이름을 'groom_name'으로 지정하는 것입니다.
    // var groomName: String: Swift의 변수 선언 문법입니다.
    //      - 'var [변수명]: [데이터 타입]' 형식으로, 'groomName'이라는 이름의 변수를 만들고,
    //      - 이 변수에는 오직 글자(String)만 담을 수 있도록 타입을 지정합니다.
    
    // 신랑 이름
    @Field(key: "groom_name")
    var groomName: String

    // 신부 이름
    @Field(key: "bride_name")
    var brideName: String

    // 결혼식 날짜
    // Date는 특정 시점(날짜와 시간)을 저장하는 타입입니다.
    // 데이터베이스나 JSON에서는 보통 국제 표준 형식(ISO 8601)으로 표현됩니다.
    // 예시 (UTC): "2025-10-25T17:00:00Z"
    //   - 'Z'는 시간대가 UTC(협정 세계시, 세계 표준 시간)임을 의미합니다.
    // 예시 (KST): "2025-10-26T02:00:00+09:00"
    //   - '+09:00'은 시간대가 UTC보다 9시간 빠른 한국 표준시(KST)임을 의미합니다.
    @Field(key: "wedding_date")
    var weddingDate: Date

    // 결혼식 장소
    @Field(key: "wedding_location")
    var weddingLocation: String

    // 인사말
    @Field(key: "greeting_message")
    var greetingMessage: String

    // 본식 순서
    @Field(key: "ceremony_program")
    var ceremonyProgram: String

    // 마음 전할 곳 (계좌 정보)
    // [String]은 여러 개의 글자(String)를 순서대로 담을 수 있는 '배열(Array)' 또는 '목록' 타입입니다.
    // 신랑, 신부 측 계좌 정보를 모두 담기 위해 하나의 글자가 아닌 글자의 목록으로 선언합니다.
    @Field(key: "account_info")
    var accountInfo: [String]
    
    
    // 4. 기본 생성자 (Default Initializer)
    // init()은 '생성자'라고 부르며, 클래스라는 '설계도'를 가지고 실제 데이터 '객체'를 만드는 공장 같은 역할을 합니다.
    //   - 객체(Object)란? 클래스라는 '설계도'를 바탕으로 메모리에 실체화된 데이터 덩어리를 의미합니다.
    //     예를 들어, WeddingInfo라는 설계도로 '신랑 A와 신부 B의 결혼식 정보'라는 실제 데이터 객체를 만드는 것입니다.
    // 비유하자면, init()은 붕어빵 틀(class)에 반죽을 붓고 팥을 넣어 실제 붕어빵(객체)을 만드는 과정 그 자체입니다.
    // 여기서 매개변수가 없는 비어있는 생성자 'init() { }'는 Vapor(Fluent)가 데이터베이스에서 정보를 읽어올 때,
    // 먼저 텅 빈 WeddingInfo 객체를 만든 다음, 각 필드를 채워 넣기 위해 꼭 필요합니다.
    init() { }

    
    // 5. 사용자 정의 생성자 (Custom Initializer)
    // 우리가 직접 코드로 WeddingInfo 객체를 만들 때, 모든 정보를 한 번에 넣어주기 위한 '특별 주문' 생성자입니다.
    // 4번 기본 생성자가 텅 빈 객체를 만들고 하나씩 채워 넣는 방식이라면,
    // 이 생성자는 필요한 모든 재료를 받아서 완전한 객체를 즉시 만들어냅니다.
    //
    // 사용 예시:
    // let ourWedding = WeddingInfo(groomName: "김신랑", brideName: "이신부", weddingDate: Date(), ...)
    //
    // init(id: UUID? = nil, ...): 생성자에 전달될 매개변수 목록입니다.
    // self.groomName = groomName:
    //   - 왼쪽의 self.groomName은 이 클래스(설계도)의 'groomName' 필드를 의미합니다.
    //   - 오른쪽의 groomName은 생성자를 통해 전달받은 '매개변수 groomName'을 의미합니다.
    //   - 즉, "이 객체의 groomName 필드에, 전달받은 groomName 값을 넣어줘" 라는 뜻입니다.
    init(id: UUID? = nil, groomName: String, brideName: String, weddingDate: Date, weddingLocation: String, greetingMessage: String, ceremonyProgram: String, accountInfo: [String]) {
        self.id = id                      // 전달받은 id 값으로 이 객체의 id를 설정합니다.
        self.groomName = groomName        // 전달받은 groomName 값으로 이 객체의 groomName을 설정합니다.
        self.brideName = brideName        // 전달받은 brideName 값으로 이 객체의 brideName을 설정합니다.
        self.weddingDate = weddingDate    // 전달받은 weddingDate 값으로 이 객체의 weddingDate를 설정합니다.
        self.weddingLocation = weddingLocation // 전달받은 weddingLocation 값으로 이 객체의 weddingLocation을 설정합니다.
        self.greetingMessage = greetingMessage // 전달받은 greetingMessage 값으로 이 객체의 greetingMessage를 설정합니다.
        self.ceremonyProgram = ceremonyProgram // 전달받은 ceremonyProgram 값으로 이 객체의 ceremonyProgram을 설정합니다.
        self.accountInfo = accountInfo    // 전달받은 accountInfo 값으로 이 객체의 accountInfo를 설정합니다.
    }
}
