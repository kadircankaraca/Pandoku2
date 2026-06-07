//
//  DataManager.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation
import SwiftData

/// SwiftData işlemlerini yöneten sınıf
@MainActor
class DataManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - GameSession CRUD

    /// Yeni oyun oturumu oluşturur
    func createGameSession(difficulty: Difficulty) -> GameSession {
        // Önce mevcut devam eden oyunu abandoned yap
        abandonAllInProgressGames()
        
        let generator = SudokuGenerator()
        let (puzzle, solution) = generator.generate(difficulty: difficulty)

        let initialCells = [CellModel].from(puzzleString: puzzle)
        let gameSession = GameSession(difficulty: difficulty, cells: initialCells, solutionBoard: solution)

        modelContext.insert(gameSession)

        // İstatistikleri başlat veya güncelle
        ensureStatisticExists(for: difficulty).recordGameStarted()
        
        try? modelContext.save()

        return gameSession
    }
    
    /// Tüm devam eden oyunları abandoned yapar
    func abandonAllInProgressGames() {
        let inProgressGames = getAllInProgressGames()
        for game in inProgressGames {
            game.abandon()
            // İstatistikleri güncelle
            if let statistic = getStatistic(for: game.difficulty) {
                statistic.recordGameAbandoned(time: game.timeElapsed)
            }
        }
        try? modelContext.save()
    }
    
    /// Tüm devam eden oyunları getirir
    func getAllInProgressGames() -> [GameSession] {
        let inProgressStatus = "inProgress"
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { $0.statusRaw == inProgressStatus },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Devam eden oyunu getirir (en son başlatılan)
    func getInProgressGame() -> GameSession? {
        let inProgressStatus = "inProgress"
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { $0.statusRaw == inProgressStatus },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// ID'ye göre oyun getirir
    func getGameSession(id: UUID) -> GameSession? {
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { $0.id == id }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Tüm oyunları getirir
    func getAllGames() -> [GameSession] {
        let descriptor = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Tamamlanmış oyunları getirir
    func getCompletedGames(difficulty: Difficulty? = nil) -> [GameSession] {
        let completedStatus = "completed"
        let predicate: Predicate<GameSession>

        if let difficulty = difficulty {
            let difficultyRaw = difficulty.rawValue
            predicate = #Predicate<GameSession> { $0.statusRaw == completedStatus && $0.difficultyRaw == difficultyRaw }
        } else {
            predicate = #Predicate<GameSession> { $0.statusRaw == completedStatus }
        }

        let descriptor = FetchDescriptor<GameSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timeElapsed)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Oyunu günceller (otomatik kaydetme)
    func saveGame(_ game: GameSession) {
        // SwiftData otomatik olarak değişiklikleri takip eder
        try? modelContext.save()
    }

    /// Oyunu tamamlanmış olarak işaretler
    func completeGame(_ game: GameSession) {
        game.complete()
        try? modelContext.save()

        // İstatistikleri güncelle
        if let statistic = getStatistic(for: game.difficulty) {
            statistic.recordGameCompleted(
                time: game.timeElapsed,
                mistakes: game.mistakesCount,
                hintsUsed: game.hintsUsed
            )
        }
        try? modelContext.save()
    }

    /// Oyunu terk edilmiş olarak işaretler
    func abandonGame(_ game: GameSession) {
        game.abandon()
        try? modelContext.save()

        // İstatistikleri güncelle
        if let statistic = getStatistic(for: game.difficulty) {
            statistic.recordGameAbandoned(time: game.timeElapsed)
        }
        try? modelContext.save()
    }

    /// Oyunu siler
    func deleteGame(_ game: GameSession) {
        modelContext.delete(game)
        try? modelContext.save()
    }

    // MARK: - Statistic CRUD

    /// Zorluk seviyesi için istatistik getirir veya oluşturur
    func ensureStatisticExists(for difficulty: Difficulty) -> Statistic {
        if let existing = getStatistic(for: difficulty) {
            return existing
        }

        let newStatistic = Statistic(difficulty: difficulty)
        modelContext.insert(newStatistic)
        return newStatistic
    }

    /// Zorluk seviyesi için istatistik getirir
    func getStatistic(for difficulty: Difficulty) -> Statistic? {
        let difficultyRaw = difficulty.rawValue
        let descriptor = FetchDescriptor<Statistic>(
            predicate: #Predicate<Statistic> { $0.difficultyRaw == difficultyRaw }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Tüm istatistikleri getirir
    func getAllStatistics() -> [Statistic] {
        let descriptor = FetchDescriptor<Statistic>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Utility

    /// Tüm verileri siler (test için)
    func deleteAllGames() {
        do {
            try modelContext.delete(model: GameSession.self)
        } catch {
            print("Error deleting all games: \(error)")
        }
    }

    /// Devam eden oyun sayısını getirir
    func getInProgressGameCount() -> Int {
        let inProgressStatus = "inProgress"
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { $0.statusRaw == inProgressStatus }
        )

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Toplam tamamlanmış oyun sayısını getirir
    func getCompletedGameCount() -> Int {
        let completedStatus = "completed"
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { $0.statusRaw == completedStatus }
        )

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
