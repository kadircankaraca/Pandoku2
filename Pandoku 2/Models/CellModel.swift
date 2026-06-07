//
//  CellModel.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation

/// Tek bir Sudoku hücresini temsil eder
struct CellModel: Codable, Equatable, Hashable {
    let index: Int          // Hücrenin pozisyonu (0-80)
    var value: Int          // Hücredeki değer (0 = boş)
    let isInitial: Bool     // Başlangıçta verilmiş sayı mı?
    var notes: Set<Int>     // Not alınmış sayılar (pencil marks)
    
    var isEmpty: Bool { value == 0 }
    var row: Int { index / 9 }
    var column: Int { index % 9 }
    var boxIndex: Int { (row / 3) * 3 + (column / 3) }

    init(index: Int, value: Int = 0, isInitial: Bool = false, notes: Set<Int> = []) {
        self.index = index
        self.value = value
        self.isInitial = isInitial
        self.notes = notes
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case index, value, isInitial, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        value = try container.decode(Int.self, forKey: .value)
        isInitial = try container.decode(Bool.self, forKey: .isInitial)
        let notesArray = try container.decode([Int].self, forKey: .notes)
        notes = Set(notesArray)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(value, forKey: .value)
        try container.encode(isInitial, forKey: .isInitial)
        try container.encode(Array(notes).sorted(), forKey: .notes)
    }
}

// MARK: - Array Extensions for CellModel

extension Array where Element == CellModel {
    /// 81 elemanlı boş tahta oluşturur
    static func emptyBoard() -> [CellModel] {
        (0..<81).map { CellModel(index: $0) }
    }
    
    /// CellModel array'ini puzzle string'ine çevirir
    func toPuzzleString() -> String {
        map { $0.value == 0 ? "0" : String($0.value) }.joined()
    }

    /// Puzzle string'inden CellModel array'i oluşturur
    static func from(puzzleString: String) -> [CellModel] {
        return (0..<81).map { index in
            let value: Int
            if index < puzzleString.count {
                let charIndex = puzzleString.index(puzzleString.startIndex, offsetBy: index)
                let char = puzzleString[charIndex]
                if char == "." || char == "0" {
                    value = 0
                } else {
                    value = char.wholeNumberValue ?? 0
                }
            } else {
                value = 0
            }
            return CellModel(index: index, value: value, isInitial: value != 0)
        }
    }
}
