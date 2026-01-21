//
//  Double+Extensions.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation

extension Double {
    /// Format as currency (USD)
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// Format as compact currency ($1.2K, $3.4M)
    var asCompactCurrency: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""

        switch absValue {
        case 1_000_000...:
            return "\(sign)$\(String(format: "%.1fM", absValue / 1_000_000))"
        case 1_000...:
            return "\(sign)$\(String(format: "%.1fK", absValue / 1_000))"
        default:
            return asCurrency
        }
    }

    /// Format as percentage (0.0 to 1.0 range)
    var asPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }

    /// Format as percentage with decimals
    var asDetailedPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }
}
