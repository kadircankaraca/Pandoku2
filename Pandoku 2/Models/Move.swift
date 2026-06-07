//
//  Move.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation

/// Oyun hamlesi türleri
enum MoveType: Codable {
    case valueChange
    case noteChange
    case hint
}

/// Oyun hamlesini temsil eder (undo/redo için)
struct Move: Codable, Equatable {
    let type: MoveType
    let cellIndex: Int
    let oldValue: Int
    let newValue: Int
    let oldNotes: Set<Int>
    let newNotes: Set<Int>

    private init(type: MoveType, cellIndex: Int, oldValue: Int, newValue: Int, oldNotes: Set<Int>, newNotes: Set<Int>) {
        self.type = type
        self.cellIndex = cellIndex
        self.oldValue = oldValue
        self.newValue = newValue
        self.oldNotes = oldNotes
        self.newNotes = newNotes
    }

    static func valueChange(cellIndex: Int, oldValue: Int, newValue: Int, oldNotes: Set<Int>, newNotes: Set<Int>) -> Move {
        Move(type: .valueChange, cellIndex: cellIndex, oldValue: oldValue, newValue: newValue, oldNotes: oldNotes, newNotes: newNotes)
    }

    static func noteChange(cellIndex: Int, oldNotes: Set<Int>, newNotes: Set<Int>) -> Move {
        Move(type: .noteChange, cellIndex: cellIndex, oldValue: 0, newValue: 0, oldNotes: oldNotes, newNotes: newNotes)
    }

    static func hint(cellIndex: Int, value: Int) -> Move {
        Move(type: .hint, cellIndex: cellIndex, oldValue: 0, newValue: value, oldNotes: [], newNotes: [])
    }
}
