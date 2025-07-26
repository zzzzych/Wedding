//
//  RsvpRequest.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/26/25.
//

import Vapor

/// 참석 여부 응답 제출 요청 데이터
struct RsvpRequest: Content {
    /// 응답자 이름 (필수)
    let responderName: String
    
    /// 참석 여부 (필수)
    /// - true: 참석
    /// - false: 불참
    let isAttending: Bool
    
    /// 성인 참석 인원 수 (기본값: 0)
    /// 불참인 경우에도 0으로 설정
    let adultCount: Int
    
    /// 자녀 참석 인원 수 (기본값: 0)
    /// 불참인 경우에도 0으로 설정
    let childrenCount: Int
    
    /// 추가 메시지 (선택사항)
    /// 특별한 요청사항이나 메시지가 있을 때 사용
    let message: String?
    
    /// 요청 데이터 유효성 검증
    /// - Throws: 유효하지 않은 데이터가 있을 때 ValidationError
    func validate() throws {
        // 응답자 이름 검증
        let trimmedName = responderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("응답자 이름은 필수입니다.")
        }
        
        guard trimmedName.count <= 50 else {
            throw ValidationError("응답자 이름은 50자 이내여야 합니다.")
        }
        
        // 인원수 검증
        guard adultCount >= 0 else {
            throw ValidationError("성인 인원수는 0 이상이어야 합니다.")
        }
        
        guard childrenCount >= 0 else {
            throw ValidationError("자녀 인원수는 0 이상이어야 합니다.")
        }
        
        guard adultCount <= 10 else {
            throw ValidationError("성인 인원수는 10명 이하여야 합니다.")
        }
        
        guard childrenCount <= 10 else {
            throw ValidationError("자녀 인원수는 10명 이하여야 합니다.")
        }
        
        // 참석하는 경우 최소 1명 이상이어야 함
        if isAttending && (adultCount + childrenCount) == 0 {
            throw ValidationError("참석하는 경우 최소 1명 이상의 인원을 입력해야 합니다.")
        }
        
        // 불참하는 경우 인원수는 0이어야 함
        if !isAttending && (adultCount + childrenCount) > 0 {
            throw ValidationError("불참하는 경우 인원수는 0이어야 합니다.")
        }
        
        // 메시지 길이 검증 (선택사항)
        if let message = message, message.count > 200 {
            throw ValidationError("메시지는 200자 이내여야 합니다.")
        }
    }
}

/// 참석 응답 수정 요청 데이터 (관리자용)
struct UpdateRsvpRequest: Content {
    /// 수정할 응답자 이름
    let responderName: String
    
    /// 수정할 참석 여부
    let isAttending: Bool
    
    /// 수정할 성인 인원 수
    let adultCount: Int
    
    /// 수정할 자녀 인원 수
    let childrenCount: Int
    
    /// 관리자 메모 (선택사항)
    let adminNote: String?
    
    /// 요청 데이터 유효성 검증
    func validate() throws {
        let trimmedName = responderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("응답자 이름은 필수입니다.")
        }
        
        guard adultCount >= 0, childrenCount >= 0 else {
            throw ValidationError("인원수는 0 이상이어야 합니다.")
        }
        
        if isAttending && (adultCount + childrenCount) == 0 {
            throw ValidationError("참석하는 경우 최소 1명 이상의 인원을 입력해야 합니다.")
        }
    }
}

/// 일괄 삭제 요청 데이터
struct BulkDeleteRequest: Content {
    /// 삭제할 응답 ID 목록 (문자열 형태의 UUID)
    let rsvpIds: [String]
    
    /// 삭제 사유 (선택사항)
    let reason: String?
    
    /// 강제 삭제 여부 (기본값: false)
    let force: Bool?
    
    /// 요청 유효성 검증
    func validate() throws {
        guard !rsvpIds.isEmpty else {
            throw ValidationError("삭제할 응답 ID가 필요합니다.")
        }
        
        guard rsvpIds.count <= 100 else {
            throw ValidationError("한 번에 최대 100개까지만 삭제할 수 있습니다.")
        }
        
        // UUID 형식 검증
        for idString in rsvpIds {
            guard UUID(uuidString: idString) != nil else {
                throw ValidationError("유효하지 않은 ID 형식입니다: \(idString)")
            }
        }
    }
}

/// 일괄 삭제 결과
struct BulkDeleteResult: Content {
    /// 요청된 삭제 개수
    let requestedCount: Int
    
    /// 실제 삭제된 개수
    let deletedCount: Int
    
    /// 찾을 수 없었던 개수
    let notFoundCount: Int
    
    /// 삭제 성공 여부
    var isSuccess: Bool {
        return deletedCount > 0
    }
    
    /// 부분 성공 여부 (일부만 삭제됨)
    var isPartialSuccess: Bool {
        return deletedCount > 0 && notFoundCount > 0
    }
}

/// 커스텀 검증 오류
struct ValidationError: Error, Content {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}
