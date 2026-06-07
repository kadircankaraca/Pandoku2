//
//  StatsView.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var statistics: [Statistic] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Toplam özet
                    TotalSummaryCard(statistics: statistics)

                    // Zorluk bazında istatistikler
                    ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                        if let statistic = statistics.first(where: { $0.difficulty == difficulty }) {
                            DifficultyStatCard(statistic: statistic)
                        }
                    }

                    // Boş state
                    if statistics.isEmpty || statistics.allSatisfy({ $0.gamesPlayed == 0 }) {
                        EmptyStatsView()
                    }
                }
                .padding()
            }
            .navigationTitle("stats.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("stats.close".localized) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadStatistics()
        }
    }

    private func loadStatistics() {
        let dataManager = DataManager(modelContext: modelContext)
        statistics = dataManager.getAllStatistics().sorted { $0.difficulty.rawValue < $1.difficulty.rawValue }
    }
}

// MARK: - Empty Stats View

struct EmptyStatsView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("stats.empty_title".localized)
                .font(.headline)
            Text("stats.empty_message".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Total Summary Card

struct TotalSummaryCard: View {
    let statistics: [Statistic]
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var totalGames: Int {
        statistics.reduce(0) { $0 + $1.gamesPlayed }
    }

    private var completedGames: Int {
        statistics.reduce(0) { $0 + $1.gamesCompleted }
    }

    private var perfectGames: Int {
        statistics.reduce(0) { $0 + $1.perfectGames }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("stats.summary".localized)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                StatItem(
                    title: "stats.total_games".localized,
                    value: "\(totalGames)"
                )
                StatItem(
                    title: "stats.completed".localized,
                    value: "\(completedGames)"
                )
                StatItem(
                    title: "stats.perfect".localized,
                    value: "\(perfectGames)"
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Difficulty Stat Card

struct DifficultyStatCard: View {
    let statistic: Statistic
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Difficulty title
            HStack {
                Text(statistic.difficulty.displayName)
                    .font(.headline)
                Spacer()
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                StatItem(
                    title: "stats.games".localized,
                    value: "\(statistic.gamesPlayed)"
                )
                StatItem(
                    title: "stats.wins".localized,
                    value: "\(statistic.gamesCompleted)"
                )
                StatItem(
                    title: "stats.best".localized,
                    value: statistic.bestTime != nil ? formatTime(statistic.bestTime!) : "--"
                )
                StatItem(
                    title: "stats.average".localized,
                    value: statistic.averageTime != nil && statistic.averageTime! > 0 ? formatTime(statistic.averageTime!) : "--"
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: "time.seconds".localized, seconds)
        } else {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "time.minutes".localized, minutes, secs)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .environmentObject(LocalizationManager.shared)
        .modelContainer(for: [Statistic.self, GameSession.self], inMemory: true)
}
