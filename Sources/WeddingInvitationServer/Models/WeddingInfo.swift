//
//  WeddingInfo.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/13/25.
//
import Fluent
import Vapor

final class WeddingInfo: Model, @unchecked Sendable, Content  {
    static let schema = "wedding_infos"
    
    @ID(key: .id)
    var id: UUID?
    
    // === 기본 정보 ===
    @Field(key: "groom_name")
    var groomName: String

    @Field(key: "bride_name")
    var brideName: String

    @Field(key: "wedding_date")
    var weddingDate: Date

    // === 웨딩홀 정보 (재설계된 부분) ===
    @Field(key: "venue_name")
    var venueName: String              // "그랜드볼룸 웨딩홀"

    @Field(key: "venue_address")
    var venueAddress: String           // "서울 강남구 테헤란로 123"

    @Field(key: "venue_detail")
    var venueDetail: String            // "3층 그레이스홀"

    @Field(key: "venue_phone")
    var venuePhone: String?            // "02-1234-5678"

    // === 지도 및 길찾기 정보 ===
    @Field(key: "kakao_map_url")
    var kakaoMapUrl: String?           // 카카오맵 공유 링크

    @Field(key: "naver_map_url")
    var naverMapUrl: String?           // 네이버지도 공유 링크

    @Field(key: "google_map_url")
    var googleMapUrl: String?          // 구글맵 링크 (해외 하객용)

    // === 교통 및 주차 정보 ===
    @Field(key: "parking_info")
    var parkingInfo: String?           // "지하 1-3층 무료주차 (3시간)"

    @Field(key: "transport_info")
    var transportInfo: String?         // 대중교통 안내

    // === 기존 필드들 ===
    @Field(key: "greeting_message")
    var greetingMessage: String

    @Field(key: "ceremony_program")
    var ceremonyProgram: String

    @Field(key: "account_info")
    var accountInfo: [String]
    
    init() { }

    // 확장된 생성자
    init(
        id: UUID? = nil,
        groomName: String,
        brideName: String,
        weddingDate: Date,
        venueName: String,
        venueAddress: String,
        venueDetail: String,
        venuePhone: String?,
        kakaoMapUrl: String?,
        naverMapUrl: String?,
        googleMapUrl: String?,
        parkingInfo: String?,
        transportInfo: String?,
        greetingMessage: String,
        ceremonyProgram: String,
        accountInfo: [String]
    ) {
        self.id = id
        self.groomName = groomName
        self.brideName = brideName
        self.weddingDate = weddingDate
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.venueDetail = venueDetail
        self.venuePhone = venuePhone
        self.kakaoMapUrl = kakaoMapUrl
        self.naverMapUrl = naverMapUrl
        self.googleMapUrl = googleMapUrl
        self.parkingInfo = parkingInfo
        self.transportInfo = transportInfo
        self.greetingMessage = greetingMessage
        self.ceremonyProgram = ceremonyProgram
        self.accountInfo = accountInfo
    }
}
