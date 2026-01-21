//
//  ChatMessage.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    var messageTypeRaw: String
    var relatedGoalId: UUID?

    var messageType: MessageType {
        get { MessageType(rawValue: messageTypeRaw) ?? .text }
        set { messageTypeRaw = newValue.rawValue }
    }

    enum MessageType: String, Codable {
        case text
        case goalSuggestion
        case budgetAdvice
        case celebration
        case question
        case planGenerated
    }

    init(
        content: String,
        isFromUser: Bool,
        messageType: MessageType = .text
    ) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.isFromUser = isFromUser
        self.messageTypeRaw = messageType.rawValue
    }
}
