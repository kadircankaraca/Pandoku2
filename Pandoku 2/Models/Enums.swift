//
//  Enums.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation

/// Zorluk seviyeleri
enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"

    /// Bu zorluk seviyesindeki verilen hücre sayısı
    var cluesCount: Int {
        switch self {
        case .easy: return 40
        case .medium: return 32
        case .hard: return 26
        case .expert: return 21
        }
    }

    /// Kalan boş hücre sayısı
    var emptyCellsCount: Int {
        81 - cluesCount
    }

    /// Lokalizasyon anahtarı
    var localizedKey: String {
        switch self {
        case .easy: return "difficulty.easy"
        case .medium: return "difficulty.medium"
        case .hard: return "difficulty.hard"
        case .expert: return "difficulty.expert"
        }
    }

    /// Gösterim adı (localizable)
    var displayName: String {
        localizedKey.localized
    }
}

/// Oyun durumu
enum GameStatus: String, Codable {
    case inProgress
    case completed
    case abandoned
}
