//
//  SudokuGenerator.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import Foundation

/// Sudoku bulmacası üretici - Backtracking algoritması ile
class SudokuGenerator {

    // MARK: - Public Methods

    /// Belirtilen zorluk seviyesinde yeni bir bulmaca üretir
    /// - Parameter difficulty: Zorluk seviyesi
    /// - Returns: (bulmaca, çözüm) çifti
    func generate(difficulty: Difficulty) -> (puzzle: String, solution: String) {
        var board = createEmptyBoard()

        // 1. Rastgele bir çözüm üret (backtracking ile)
        _ = fillBoard(&board)

        // 2. Çözümü kaydet
        let solution = boardToString(board)

        // 3. Belirli sayıda hücreyi kaldır (zorluk seviyesine göre)
        //    - Her kaldırmada unique solution kontrolü yap
        let cellsToRemove = difficulty.emptyCellsCount
        removeNumbersWithUniqueCheck(&board, count: cellsToRemove)

        let puzzle = boardToString(board)

        return (puzzle, solution)
    }

    // MARK: - Private Methods

    /// Boş 9x9 board oluşturur
    private func createEmptyBoard() -> [[Int]] {
        return [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
    }

    /// Board'u backtracking ile doldurur (MRV optimized)
    /// - Parameter board: Doldurulacak board
    /// - Returns: Başarılı ise true, değilse false
    private func fillBoard(_ board: inout [[Int]]) -> Bool {
        // MRV: En az seçeneği olan hücreyi bul
        guard let (row, col) = findBestEmptyCell(board) else {
            // Eğer best cell nil dönüyorsa ve board doluysa bitmiştir
            if isBoardFull(board) { return true }
            return false // Çıkmaz sokak
        }

        // 1-9 arası sayıları karıştır ve dene
        let numbers = Array(1...9).shuffled()

        for num in numbers {
            if isValidPlacement(board, row: row, col: col, num: num) {
                board[row][col] = num

                if fillBoard(&board) {
                    return true
                }

                board[row][col] = 0 // Backtrack
            }
        }

        return false // Çözüm bulunamadı
    }

    /// Sayının placement'i geçerli olup olmadığını kontrol eder
    /// - Parameters:
    ///   - board: Kontrol edilecek board
    ///   - row: Satır
    ///   - col: Sütun
    ///   - num: Sayı
    /// - Returns: Geçerli ise true
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

    // MARK: - Unique Solution Control

    /// Board'dan belirli sayıda sayıyı kaldırır - Her kaldırmada unique solution kontrolü yapar
    private func removeNumbersWithUniqueCheck(_ board: inout [[Int]], count: Int) {
        var positions: [(row: Int, col: Int)] = []
        for row in 0..<9 {
            for col in 0..<9 {
                positions.append((row, col))
            }
        }
        positions.shuffle()

        var removed = 0
        var currentIndex = 0

        while removed < count && currentIndex < positions.count {
            let (row, col) = positions[currentIndex]
            currentIndex += 1

            if board[row][col] != 0 {
                let backup = board[row][col]
                board[row][col] = 0

                if hasUniqueSolution(board) {
                    removed += 1
                } else {
                    board[row][col] = backup
                }
            }
        }
    }

    /// Bulmacanın tek bir çözümü olup olmadığını kontrol eder
    private func hasUniqueSolution(_ board: [[Int]]) -> Bool {
        var solutions = 0
        var testBoard = board

        solveHelperOptimized(&testBoard, &solutions, limit: 2)

        return solutions == 1
    }

    // MARK: - Optimized Solver (MRV Heuristic)

    /// En az seçeneği olan boş hücreyi bulur (MRV - Minimum Remaining Values)
    private func findBestEmptyCell(_ board: [[Int]]) -> (row: Int, col: Int)? {
        var minOptions = 10
        var bestCell: (Int, Int)? = nil

        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == 0 {
                    let options = countValidOptions(board, row: r, col: c)
                    
                    if options == 0 {
                        return nil // Çıkmaz sokak
                    }

                    if options < minOptions {
                        minOptions = options
                        bestCell = (r, c)
                        
                        if minOptions == 1 {
                            return bestCell
                        }
                    }
                }
            }
        }
        return bestCell
    }

    /// Bir hücreye kaç farklı sayının gelebileceğini hesaplar
    private func countValidOptions(_ board: [[Int]], row: Int, col: Int) -> Int {
        var count = 0
        for num in 1...9 {
            if isValidPlacement(board, row: row, col: col, num: num) {
                count += 1
            }
        }
        return count
    }

    /// Board'un tamamen dolu olup olmadığını kontrol eder
    private func isBoardFull(_ board: [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == 0 {
                    return false
                }
            }
        }
        return true
    }

    /// Optimized solver helper - MRV heuristic ile
    private func solveHelperOptimized(_ board: inout [[Int]], _ count: inout Int, limit: Int) {
        if count >= limit { return }

        guard let (row, col) = findBestEmptyCell(board) else {
            if isBoardFull(board) {
                count += 1
            }
            return
        }

        for num in 1...9 {
            if isValidPlacement(board, row: row, col: col, num: num) {
                board[row][col] = num
                solveHelperOptimized(&board, &count, limit: limit)
                board[row][col] = 0
                if count >= limit { return }
            }
        }
    }

    // MARK: - Board Conversion

    /// Board'u string'e çevirir (81 karakter)
    private func boardToString(_ board: [[Int]]) -> String {
        return board.flatMap { $0 }.map { $0 == 0 ? "." : String($0) }.joined()
    }

    /// String'den board oluşturur
    func stringToBoard(_ string: String) -> [[Int]] {
        var board = createEmptyBoard()
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

    /// Board'u düzgün formatta yazdırır (debug için)
    func printBoard(_ board: [[Int]]) {
        for (index, row) in board.enumerated() {
            var line = ""
            for (colIndex, num) in row.enumerated() {
                let symbol = num == 0 ? "." : "\(num)"
                line += symbol + " "

                if colIndex == 2 || colIndex == 5 {
                    line += "| "
                }
            }
            print(line)

            if index == 2 || index == 5 {
                print("------+-------+------")
            }
        }
    }
}
