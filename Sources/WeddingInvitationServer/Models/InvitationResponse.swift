//
//  InvitationResponse.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/21/25.
//

import Fluent
import Vapor
import Foundation

/// 청첩장 조회 API의 응답 데이터
struct InvitationResponse: Content {
    let groupInfo: InvitationGroup
    let weddingInfo: FilteredWeddingInfo
    let availableFeatures: FeatureFlags
}

/// 그룹별로 필터링된 결혼식 정보
struct FilteredWeddingInfo: Content {
    let groomName: String
    let brideName: String
    let weddingDate: Date
    let weddingLocation: String?    // 결혼식 초대 그룹만
    let greetingMessage: String
    let ceremonyProgram: String?    // 7일 전 + 결혼식 초대 그룹만
    let accountInfo: [String]?      // 부모님 그룹만
    
    /// WeddingInfo를 그룹 타입에 따라 필터링해서 생성
    init(from weddingInfo: WeddingInfo, groupType: GroupType, daysToCeremony: Int) {
        self.groomName = weddingInfo.groomName
        self.brideName = weddingInfo.brideName
        self.weddingDate = weddingInfo.weddingDate
        self.greetingMessage = weddingInfo.greetingMessage
        
        // 그룹 타입별 정보 필터링
        switch groupType {
        case .weddingGuest:
            self.weddingLocation = weddingInfo.weddingLocation
            // 7일 전 공개 로직
            self.ceremonyProgram = daysToCeremony <= 7 ? weddingInfo.ceremonyProgram : nil
            self.accountInfo = nil
            
        case .parentsGuest:
            self.weddingLocation = nil
            self.ceremonyProgram = nil
            self.accountInfo = weddingInfo.accountInfo
            
        case .companyGuest:
            self.weddingLocation = nil
            self.ceremonyProgram = nil
            self.accountInfo = nil
        }
    }
}

/// 날짜 계산 유틸리티
extension Date {
    /// 현재 날짜로부터 특정 날짜까지의 일수 계산
    /// - Parameter targetDate: 목표 날짜
    /// - Returns: 남은 일수 (음수면 이미 지난 날짜)
    func daysBetween(and targetDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: targetDate)
        return components.day ?? 0
    }
}

/// 청첩장 조회 시 사용할 헬퍼 함수들
extension InvitationResponse {
    /// WeddingInfo와 InvitationGroup으로부터 응답 생성
    static func create(
        from weddingInfo: WeddingInfo,
        and group: InvitationGroup
    ) -> InvitationResponse {
        
        // 그룹 타입 파싱
        guard let groupType = GroupType(rawValue: group.groupType) else {
            // 기본값으로 회사 그룹 (가장 제한적)
            let features = GroupType.companyGuest.availableFeatures
            let filteredInfo = FilteredWeddingInfo(
                from: weddingInfo,
                groupType: .companyGuest,
                daysToCeremony: 0
            )
            return InvitationResponse(
                groupInfo: group,
                weddingInfo: filteredInfo,
                availableFeatures: features
            )
        }
        
        // 결혼식까지 남은 일수 계산
        let daysToCeremony = Date().daysBetween(and: weddingInfo.weddingDate)
        
        // 그룹 타입별 기능 플래그
        let features = groupType.availableFeatures
        
        // 필터링된 결혼식 정보
        let filteredInfo = FilteredWeddingInfo(
            from: weddingInfo,
            groupType: groupType,
            daysToCeremony: daysToCeremony
        )
        
        return InvitationResponse(
            groupInfo: group,
            weddingInfo: filteredInfo,
            availableFeatures: features
        )
    }
}
