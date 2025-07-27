//
//  InvitationGroup.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/15/25.
//

// 필요한 도구 상자(Fluent, Vapor)를 가져옵니다.
import Fluent
import Vapor
import Foundation

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
    
    // ✅ 새로 추가할 필드
    @Field(key: "greeting_message")
    var greetingMessage: String

    // 4. 기본 생성자: Fluent가 데이터베이스에서 데이터를 읽어올 때 사용합니다.
    init() { }
    
    // 기존 생성자 수정
    init(id: UUID? = nil, groupName: String, groupType: String) {
        self.id = id
        self.groupName = groupName
        self.groupType = groupType
        self.uniqueCode = Self.generateSecureCode()
        // ✅ 기본 인사말 추가
        self.greetingMessage = ""
    }

    // ✅ greetingMessage를 받는 새 생성자 추가
    init(groupName: String, groupType: String, greetingMessage: String) {
        self.id = nil
        self.groupName = groupName
        self.groupType = groupType
        self.uniqueCode = Self.generateSecureCode()
        self.greetingMessage = greetingMessage
    }
    
    // 5. 사용자 정의 생성자: 우리가 코드로 새로운 그룹을 만들 때 사용합니다.
    // self: 클래스 설계도 안에서 '이 코드를 실행하고 있는 실제 객체 자신'을 가리키는 대명사입니다.
    //       붕어빵 틀(클래스)의 레시피에서 "나 자신의 몸통"이라고 말하는 것과 같습니다.
    // 기존 생성자는 데이터베이스에서 읽어올 때만 사용 (internal)
    internal init(id: UUID? = nil, groupName: String, groupType: String, uniqueCode: String) {
        self.id = id
        self.groupName = groupName
        self.groupType = groupType
        self.uniqueCode = uniqueCode
    }
    
    /// 암호학적으로 안전한 고유 코드 생성
    /// - Returns: 24자리 Base64URL 인코딩된 안전한 랜덤 문자열
    static func generateSecureCode() -> String {
        // 18바이트(144비트)의 랜덤 데이터 생성
        let randomData = Data((0..<18).map { _ in UInt8.random(in: 0...255) })
        
        // Base64URL 인코딩 (URL-safe, padding 제거)
        return randomData
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}


// --- [새로 추가: 그룹 타입 열거형] ---
enum GroupType: String, CaseIterable, Content {
    case weddingGuest = "WEDDING_GUEST"
    case parentsGuest = "PARENTS_GUEST"
    case companyGuest = "COMPANY_GUEST"
    
    /// 그룹 타입별 사용 가능한 기능 반환
    var availableFeatures: FeatureFlags {
        switch self {
        case .weddingGuest:
            return FeatureFlags(
                showInvitationInfo: true,
                showDirections: true,
                showRsvpForm: true,
                showAccountInfo: false,
                showShareButton: false,
                showPhotoGallery: true,
                showGreeting: true
            )
        case .parentsGuest:
            return FeatureFlags(
                showInvitationInfo: false,
                showDirections: false,
                showRsvpForm: false,
                showAccountInfo: true,
                showShareButton: true,
                showPhotoGallery: true,
                showGreeting: true
            )
        case .companyGuest:
            return FeatureFlags(
                showInvitationInfo: false,
                showDirections: false,
                showRsvpForm: false,
                showAccountInfo: false,
                showShareButton: false,
                showPhotoGallery: true,
                showGreeting: true
            )
        }
    }
}

/// 그룹별 기능 제어를 위한 플래그 구조체
struct FeatureFlags: Content {
    let showInvitationInfo: Bool    // 초대 정보 (결혼식 초대 그룹만)
    let showDirections: Bool        // 오시는 길 (결혼식 초대 그룹만)
    let showRsvpForm: Bool          // 참석 여부 회신 (결혼식 초대 그룹만)
    let showAccountInfo: Bool       // 계좌 정보 (부모님 그룹만)
    let showShareButton: Bool       // 공유 기능 (부모님 그룹만)
    let showPhotoGallery: Bool      // 포토 갤러리 (모든 그룹)
    let showGreeting: Bool          // 인사말 (모든 그룹)
}
