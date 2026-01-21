//
//  ServiceContainer.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ServiceContainer {
    static let shared = ServiceContainer()

    let bankingService: BankingServiceProtocol
    let aiService: AIServiceProtocol
    let analyticsService: AnalyticsServiceProtocol

    init(
        bankingService: BankingServiceProtocol = MockBankingService(),
        aiService: AIServiceProtocol = MockAIService(),
        analyticsService: AnalyticsServiceProtocol = MockAnalyticsService()
    ) {
        self.bankingService = bankingService
        self.aiService = aiService
        self.analyticsService = analyticsService
    }
}

// MARK: - Environment Key

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
