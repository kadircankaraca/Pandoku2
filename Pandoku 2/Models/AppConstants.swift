//
//  AppConstants.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI

// MARK: - Theme Option

enum ThemeOption: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    var displayName: String {
        NSLocalizedString(localizedKey, comment: "")
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "iphone"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Language Option

enum LanguageOption: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .turkish: return "language.turkish"
        case .english: return "language.english"
        }
    }

    var displayName: String {
        NSLocalizedString(localizedKey, comment: "")
    }

    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇺🇸"
        }
    }

    var locale: Locale {
        switch self {
        case .turkish: return Locale(identifier: "tr_TR")
        case .english: return Locale(identifier: "en_US")
        }
    }
}
