//
//  DateExtensions.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Foundation

/// Date 타입의 확장 - 포맷팅 기능 추가
extension Date {
    /// CSV용 날짜 포맷팅 (한국 시간대 기준)
    /// - Returns: "yyyy-MM-dd HH:mm:ss" 형식의 문자열
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
    
    /// ISO 8601 포맷팅 (파일명용)
    /// - Returns: "yyyy-MM-dd" 형식의 문자열
    func formattedForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
}
