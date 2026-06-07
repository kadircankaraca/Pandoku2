//
//  GameSession.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation
import SwiftData

@Model
final class GameSession: Hashable {
    @Attribute(.unique) var id: UUID
    var difficultyRaw: String
    var statusRaw: String
    var startTime: Date
    var endTime: Date?
    var timeElapsed: Int

    // MARK: - Hashable

    static func == (lhs: GameSession, rhs: GameSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Type-safe board data
    var cells: [CellModel]
    var solutionBoard: String

    // Type-safe move history
    var moveHistory: [Move]
    var redoStack: [Move]

    // Game statistics
    var mistakesCount: Int
    var hintsUsed: Int
    
    // Skor ve Combo sistemi
    var score: Int
    var comboMultiplier: Int
    
    // Hint ile doldurulan hücreler (puan verilmemesi için)
    var hintFilledCells: Set<Int>
    
    // Tamamlanan bölgeler (kalıcı yeşil arka plan için)
    var completedRows: Set<Int>
    var completedCols: Set<Int>
    var completedBoxes: Set<Int>

    // MARK: - Computed Properties

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }

    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var isComplete: Bool { cells.filter { $0.value == 0 }.isEmpty }
    var isSolved: Bool { isComplete && cells.toPuzzleString() == solutionBoard }
    var isPerfectGame: Bool { status == .completed && mistakesCount == 0 && hintsUsed == 0 }
    var canResume: Bool { status == .inProgress }
    
    /// Her rakamdan tahtada kaç tane olduğunu hesaplar
    var digitCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for num in 1...9 {
            counts[num] = cells.filter { $0.value == num }.count
        }
        return counts
    }
    
    /// Tamamlanmış rakamları döndürür (9 adet olanlar)
    var completedDigits: Set<Int> {
        Set(digitCounts.filter { $0.value >= 9 }.map { $0.key })
    }
    
    /// Zorluk çarpanı
    var difficultyMultiplier: Double {
        switch difficulty {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 3.0
        }
    }
    
    /// Final skor (zorluk çarpanı uygulanmış)
    var finalScore: Int {
        Int(Double(score) * difficultyMultiplier)
    }
    
    // MARK: - Score Constants
    
    private static let basePoints = 50
    private static let penaltyPoints = 100
    private static let maxCombo = 5
    private static let hintPenalty = 150
    private static let maxTimeBonus = 3000
    private static let timePenaltyPerSecond = 5
    private static let perfectGameBonus = 1000
    private static let regionCompleteBonus = 100 // Satır/Sütun/Kutu tamamlama bonusu
    
    // MARK: - Initialization
    
    init(difficulty: Difficulty, cells: [CellModel], solutionBoard: String) {
        self.id = UUID()
        self.difficultyRaw = difficulty.rawValue
        self.statusRaw = GameStatus.inProgress.rawValue
        self.startTime = Date()
        self.timeElapsed = 0
        self.cells = cells
        self.solutionBoard = solutionBoard
        self.moveHistory = []
        self.redoStack = []
        self.mistakesCount = 0
        self.hintsUsed = 0
        self.score = 0
        self.comboMultiplier = 1
        self.hintFilledCells = []
        self.completedRows = []
        self.completedCols = []
        self.completedBoxes = []
    }
    
    // MARK: - Region Completion Check
    
    /// Belirli bir hücrenin bulunduğu satır, sütun ve kutuyu kontrol eder
    /// Yeni tamamlanan bölgeleri döndürür
    func checkRegionCompletion(at index: Int) -> CompletedRegions {
        let row = index / 9
        let col = index % 9
        let box = (row / 3) * 3 + (col / 3)
        
        var newlyCompleted = CompletedRegions()
        
        // Satır kontrolü
        if !completedRows.contains(row) && isRowComplete(row) {
            completedRows.insert(row)
            newlyCompleted.rows.insert(row)
            score += Self.regionCompleteBonus
        }
        
        // Sütun kontrolü
        if !completedCols.contains(col) && isColComplete(col) {
            completedCols.insert(col)
            newlyCompleted.cols.insert(col)
            score += Self.regionCompleteBonus
        }
        
        // Kutu kontrolü
        if !completedBoxes.contains(box) && isBoxComplete(box) {
            completedBoxes.insert(box)
            newlyCompleted.boxes.insert(box)
            score += Self.regionCompleteBonus
        }
        
        return newlyCompleted
    }
    
    /// Satırın doğru şekilde tamamlanıp tamamlanmadığını kontrol eder
    private func isRowComplete(_ row: Int) -> Bool {
        var values = Set<Int>()
        for col in 0..<9 {
            let index = row * 9 + col
            let value = cells[index].value
            if value == 0 { return false }
            
            // Çözümle karşılaştır
            let correctValue = getSolutionValue(at: index)
            if value != correctValue { return false }
            
            values.insert(value)
        }
        return values.count == 9
    }
    
    /// Sütunun doğru şekilde tamamlanıp tamamlanmadığını kontrol eder
    private func isColComplete(_ col: Int) -> Bool {
        var values = Set<Int>()
        for row in 0..<9 {
            let index = row * 9 + col
            let value = cells[index].value
            if value == 0 { return false }
            
            let correctValue = getSolutionValue(at: index)
            if value != correctValue { return false }
            
            values.insert(value)
        }
        return values.count == 9
    }
    
    /// 3x3 kutunun doğru şekilde tamamlanıp tamamlanmadığını kontrol eder
    private func isBoxComplete(_ box: Int) -> Bool {
        var values = Set<Int>()
        let boxRowStart = (box / 3) * 3
        let boxColStart = (box % 3) * 3
        
        for r in boxRowStart..<(boxRowStart + 3) {
            for c in boxColStart..<(boxColStart + 3) {
                let index = r * 9 + c
                let value = cells[index].value
                if value == 0 { return false }
                
                let correctValue = getSolutionValue(at: index)
                if value != correctValue { return false }
                
                values.insert(value)
            }
        }
        return values.count == 9
    }
    
    /// Belirli bir hücrenin tamamlanmış bir bölgede olup olmadığını kontrol eder
    func isInCompletedRegion(at index: Int) -> Bool {
        let row = index / 9
        let col = index % 9
        let box = (row / 3) * 3 + (col / 3)
        
        return completedRows.contains(row) || completedCols.contains(col) || completedBoxes.contains(box)
    }
    
    // MARK: - Game Actions
    
    func setValue(_ value: Int, at index: Int) {
        guard index >= 0, index < 81, !cells[index].isInitial else { return }
        
        let oldValue = cells[index].value
        let oldNotes = cells[index].notes
        let newValue = (value == oldValue) ? 0 : value
        
        cells[index].value = newValue
        cells[index].notes = []
        
        moveHistory.append(Move.valueChange(
            cellIndex: index,
            oldValue: oldValue,
            newValue: newValue,
            oldNotes: oldNotes,
            newNotes: []
        ))
        redoStack.removeAll()
        
        // Skor ve combo hesaplama
        if newValue != 0 {
            let correctValue = getSolutionValue(at: index)
            if newValue == correctValue {
                // Doğru hamle - puan ekle ve combo artır
                score += Self.basePoints * comboMultiplier
                comboMultiplier = min(comboMultiplier + 1, Self.maxCombo)
            } else {
                // Yanlış hamle - ceza puanı ve combo sıfırla
                mistakesCount += 1
                score = max(0, score - Self.penaltyPoints)
                comboMultiplier = 1
            }
        }
    }
    
    func toggleNote(_ note: Int, at index: Int) {
        guard index >= 0, index < 81, !cells[index].isInitial, cells[index].value == 0 else { return }
        
        let oldNotes = cells[index].notes
        var newNotes = oldNotes
        if newNotes.contains(note) {
            newNotes.remove(note)
        } else {
            newNotes.insert(note)
        }
        cells[index].notes = newNotes
        
        moveHistory.append(Move.noteChange(cellIndex: index, oldNotes: oldNotes, newNotes: newNotes))
        redoStack.removeAll()
    }
    
    func useHint(at index: Int) -> Bool {
        guard index >= 0, index < 81, !cells[index].isInitial, cells[index].value == 0 else { return false }
        
        let correctValue = getSolutionValue(at: index)
        guard correctValue != 0 else { return false }
        
        cells[index].value = correctValue
        cells[index].notes = []
        
        hintFilledCells.insert(index)
        
        moveHistory.append(Move.hint(cellIndex: index, value: correctValue))
        redoStack.removeAll()
        hintsUsed += 1
        
        score = max(0, score - Self.hintPenalty)
        comboMultiplier = 1
        
        return true
    }
    
    func undo() -> Bool {
        guard let lastMove = moveHistory.popLast() else { return false }
        
        if lastMove.type == .hint {
            hintFilledCells.remove(lastMove.cellIndex)
        }
        
        cells[lastMove.cellIndex].value = lastMove.oldValue
        cells[lastMove.cellIndex].notes = lastMove.oldNotes
        redoStack.append(lastMove)
        
        comboMultiplier = 1
        
        // Undo sonrası tamamlanmış bölgeleri yeniden hesapla
        recalculateCompletedRegions()
        
        return true
    }
    
    func redo() -> Bool {
        guard let move = redoStack.popLast() else { return false }
        
        if move.type == .hint {
            hintFilledCells.insert(move.cellIndex)
        }
        
        cells[move.cellIndex].value = move.newValue
        cells[move.cellIndex].notes = move.newNotes
        moveHistory.append(move)
        return true
    }
    
    /// Tamamlanmış bölgeleri sıfırdan hesaplar (undo sonrası için)
    private func recalculateCompletedRegions() {
        completedRows.removeAll()
        completedCols.removeAll()
        completedBoxes.removeAll()
        
        for row in 0..<9 {
            if isRowComplete(row) {
                completedRows.insert(row)
            }
        }
        
        for col in 0..<9 {
            if isColComplete(col) {
                completedCols.insert(col)
            }
        }
        
        for box in 0..<9 {
            if isBoxComplete(box) {
                completedBoxes.insert(box)
            }
        }
    }
    
    func complete() {
        guard isSolved else { return }
        status = .completed
        endTime = Date()
        
        let timeBonus = max(0, Self.maxTimeBonus - (timeElapsed * Self.timePenaltyPerSecond))
        score += timeBonus
        
        if isPerfectGame {
            score += Self.perfectGameBonus
        }
    }
    
    func abandon() {
        status = .abandoned
        endTime = Date()
    }
    
    // MARK: - Validation
    
    func hasConflict(at index: Int) -> Bool {
        let cell = cells[index]
        guard cell.value != 0 else { return false }
        
        let row = index / 9
        let col = index % 9
        
        for i in 0..<9 {
            let rowIndex = row * 9 + i
            if rowIndex != index && cells[rowIndex].value == cell.value { return true }
        }
        
        for i in 0..<9 {
            let colIndex = i * 9 + col
            if colIndex != index && cells[colIndex].value == cell.value { return true }
        }
        
        let boxRowStart = (row / 3) * 3
        let boxColStart = (col / 3) * 3
        for r in boxRowStart..<(boxRowStart + 3) {
            for c in boxColStart..<(boxColStart + 3) {
                let boxIndex = r * 9 + c
                if boxIndex != index && cells[boxIndex].value == cell.value { return true }
            }
        }
        
        return false
    }
    
    func getSelectedDigit(at index: Int?) -> Int? {
        guard let index = index, index >= 0, index < 81 else { return nil }
        let value = cells[index].value
        return value == 0 ? nil : value
    }
    
    // MARK: - Private Helpers
    
    private func getSolutionValue(at index: Int) -> Int {
        guard index < solutionBoard.count else { return 0 }
        let solutionIndex = solutionBoard.index(solutionBoard.startIndex, offsetBy: index)
        return Int(String(solutionBoard[solutionIndex])) ?? 0
    }
}
// MARK: - Completed Regions Struct

struct CompletedRegions {
    var rows: Set<Int> = []
    var cols: Set<Int> = []
    var boxes: Set<Int> = []
    
    var isEmpty: Bool {
        rows.isEmpty && cols.isEmpty && boxes.isEmpty
    }
    
    /// Tüm etkilenen hücre indekslerini döndürür
    func allAffectedCellIndices() -> Set<Int> {
        var indices = Set<Int>()
        
        for row in rows {
            for col in 0..<9 {
                indices.insert(row * 9 + col)
            }
        }
        
        for col in cols {
            for row in 0..<9 {
                indices.insert(row * 9 + col)
            }
        }
        
        for box in boxes {
            let boxRowStart = (box / 3) * 3
            let boxColStart = (box % 3) * 3
            for r in boxRowStart..<(boxRowStart + 3) {
                for c in boxColStart..<(boxColStart + 3) {
                    indices.insert(r * 9 + c)
                }
            }
        }
        
        return indices
    }
}

