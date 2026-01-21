//
//  Category.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var budgetAmount: Double?
    var isSystem: Bool

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        name: String,
        iconName: String,
        colorHex: String,
        budgetAmount: Double? = nil,
        isSystem: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.budgetAmount = budgetAmount
        self.isSystem = isSystem
    }

    static let systemCategories: [(String, String, String)] = [
        ("Food & Dining", "fork.knife", "#FF6B6B"),
        ("Transportation", "car.fill", "#4ECDC4"),
        ("Shopping", "bag.fill", "#45B7D1"),
        ("Entertainment", "tv.fill", "#96CEB4"),
        ("Bills & Utilities", "bolt.fill", "#FFEAA7"),
        ("Health", "heart.fill", "#DDA0DD"),
        ("Travel", "airplane", "#87CEEB"),
        ("Income", "dollarsign.circle.fill", "#98D8C8"),
        ("Transfer", "arrow.left.arrow.right", "#B8B8B8"),
        ("Other", "ellipsis.circle.fill", "#C9C9C9")
    ]

    static func createSystemCategories() -> [Category] {
        systemCategories.map { name, icon, color in
            Category(name: name, iconName: icon, colorHex: color, isSystem: true)
        }
    }
}
