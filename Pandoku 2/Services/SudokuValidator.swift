//
//  SudokuValidator.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation

/// Sudoku kurallarını doğrulayan sınıf
class SudokuValidator {

    // MARK: - Validation Methods

    /// Hamlenin geçerli olup olmadığını kontrol eder
    /// - Parameters:
    ///   - board: Mevcut board (81 karakter string)
    ///   - index: Hücre index'i (0-80)
    ///   - value: Girilecek sayı (1-9)
    /// - Returns: Geçerli ise true
    func isValidMove(board: String, index: Int, value: Int) -> Bool {
        guard value >= 1 && value <= 9 else { return false }
        guard index >= 0 && index < 81 else { return false }

        let boardArray = stringToArray(board)
        let row = index / 9
        let col = index % 9

        return isValidPlacement(boardArray, row: row, col: col, num: value)
    }

    /// Board'un tamamlanıp tamamlanmadığını kontrol eder
    /// - Parameter board: Kontrol edilecek board
    /// - Returns: Tamamlanmış ise true
    func isBoardComplete(_ board: String) -> Bool {
        return !board.contains(".") && board.count == 81
    }

    /// Board'un geçerli bir çözüm olup olmadığını kontrol eder
    /// - Parameter board: Kontrol edilecek board
    /// - Returns: Geçerli çözüm ise true
    func isValidSolution(_ board: String) -> Bool {
        guard isBoardComplete(board) else { return false }

        let boardArray = stringToArray(board)

        // Tüm satırları kontrol et
        for row in 0..<9 {
            if !isValidSet(boardArray[row]) {
                return false
            }
        }

        // Tüm sütunları kontrol et
        for col in 0..<9 {
            var column = [Int]()
            for row in 0..<9 {
                column.append(boardArray[row][col])
            }
            if !isValidSet(column) {
                return false
            }
        }

        // Tüm 3x3 kutuları kontrol et
        for boxRow in 0..<3 {
            for boxCol in 0..<3 {
                var box = [Int]()
                for r in 0..<3 {
                    for c in 0..<3 {
                        box.append(boardArray[boxRow * 3 + r][boxCol * 3 + c])
                    }
                }
                if !isValidSet(box) {
                    return false
                }
            }
        }

        return true
    }

    /// Hatalı hücreleri bulur (çakışan sayılar)
    /// - Parameter board: Kontrol edilecek board
    /// - Returns: Hatalı hücre index'leri
    func findErrors(in board: String) -> [Int] {
        var errors = Set<Int>()
        let boardArray = stringToArray(board)

        // Her hücreyi kontrol et
        for row in 0..<9 {
            for col in 0..<9 {
                let value = boardArray[row][col]
                if value != 0 {
                    // Bu sayının aynı satır/sütun/kutuda başka yerde olup olmadığını kontrol et
                    if !isUniquePlacement(boardArray, row: row, col: col, num: value) {
                        errors.insert(row * 9 + col)
                    }
                }
            }
        }

        return Array(errors)
    }

    // MARK: - Private Methods

    /// Sayının placement'inin benzersiz olup olmadığını kontrol eder
    private func isUniquePlacement(_ board: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Satır kontrolü
        for c in 0..<9 {
            if c != col && board[row][c] == num {
                return false
            }
        }

        // Sütun kontrolü
        for r in 0..<9 {
            if r != row && board[r][col] == num {
                return false
            }
        }

        // 3x3 kutu kontrolü
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3

        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if (r != row || c != col) && board[r][c] == num {
                    return false
                }
            }
        }

        return true
    }

    /// Sayının placement'i geçerli olup olmadığını kontrol eder (boş hücreler dahil)
    private func isValidPlacement(_ board: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Satır kontrolü
        for c in 0..<9 {
            if board[row][c] == num {
                return false
            }
        }

        // Sütun kontrolü
        for r in 0..<9 {
            if board[r][col] == num {
                return false
            }
        }

        // 3x3 kutu kontrolü
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3

        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if board[r][c] == num {
                    return false
                }
            }
        }

        return true
    }

    /// Bir dizinin 1-9 arasındaki tüm sayıları içerip içermediğini kontrol eder
    private func isValidSet(_ numbers: [Int]) -> Bool {
        let sorted = numbers.sorted()
        return sorted == [1, 2, 3, 4, 5, 6, 7, 8, 9]
    }

    /// String'i 2D array'e çevirir
    private func stringToArray(_ string: String) -> [[Int]] {
        var board = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
        let chars = Array(string)

        for (index, char) in chars.prefix(81).enumerated() {
            let row = index / 9
            let col = index % 9

            if char == "." {
                board[row][col] = 0
            } else if let num = Int(String(char)) {
                board[row][col] = num
            }
        }

        return board
    }
}
