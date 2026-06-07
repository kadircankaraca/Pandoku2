//
//  Statistic.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation
import SwiftData

@Model
final class Statistic {
    @Attribute(.unique) var id: UUID
    var difficultyRaw: String
    var gamesPlayed: Int
    var gamesCompleted: Int
    var perfectGames: Int
    var gamesAbandoned: Int
    var bestTime: Int?
    var totalTimeSpent: Int
    var currentWinStreak: Int
    var bestWinStreak: Int
    var totalHintsUsed: Int
    var gamesWithoutHints: Int
    
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }
    
    var averageTime: Int? {
        guard gamesCompleted > 0 else { return nil }
        return totalTimeSpent / gamesCompleted
    }
    
    var completionRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesCompleted) / Double(gamesPlayed) * 100
    }
    
    init(difficulty: Difficulty) {
        self.id = UUID()
        self.difficultyRaw = difficulty.rawValue
        self.gamesPlayed = 0
        self.gamesCompleted = 0
        self.perfectGames = 0
        self.gamesAbandoned = 0
        self.totalTimeSpent = 0
        self.currentWinStreak = 0
        self.bestWinStreak = 0
        self.totalHintsUsed = 0
        self.gamesWithoutHints = 0
    }
    
    func recordGameStarted() {
        gamesPlayed += 1
    }
    
    func recordGameCompleted(time: Int, mistakes: Int, hintsUsed: Int) {
        gamesCompleted += 1
        totalTimeSpent += time
        totalHintsUsed += hintsUsed
        
        if let currentBest = bestTime {
            if time < currentBest { bestTime = time }
        } else {
            bestTime = time
        }
        
        if mistakes == 0 { perfectGames += 1 }
        if hintsUsed == 0 { gamesWithoutHints += 1 }
        
        currentWinStreak += 1
        if currentWinStreak > bestWinStreak { bestWinStreak = currentWinStreak }
    }
    
    func recordGameAbandoned(time: Int) {
        gamesAbandoned += 1
        totalTimeSpent += time
        currentWinStreak = 0
    }
    
    static func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
