//
//  ContentView.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        NavigationStack {
            MenuView()
        }
    }
}

// MARK: - Menu View

struct MenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var inProgressGame: GameSession?
    @State private var navigationPath = NavigationPath()
    @State private var showStats = false
    @State private var showSettings = false
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: isIPad ? 180 : 120, height: isIPad ? 180 : 120)
                .clipShape(RoundedRectangle(cornerRadius: isIPad ? 36 : 24))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

            Spacer()

            // Continue Game Button
            if let game = inProgressGame {
                NavigationLink(value: game) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("menu.continue_game".localized)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(game.difficulty.displayName)
                                .font(.caption)
                            Text(formatTime(game.timeElapsed))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
            }

            // New Game Button
            NavigationLink(value: "difficulty") {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("menu.new_game".localized)
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }

            // Statistics Button
            Button {
                showStats = true
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("menu.statistics".localized)
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }

            // Settings Button
            Button {
                showSettings = true
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("menu.settings".localized)
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding(24)
        .navigationDestination(for: String.self) { value in
            if value == "difficulty" {
                DifficultySelectionView()
            }
        }
        .navigationDestination(for: GameSession.self) { game in
            GameView(gameSession: game)
        }
        .sheet(isPresented: $showStats) {
            StatsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
        .onAppear {
            checkInProgressGame()
        }
    }

    private func checkInProgressGame() {
        let dataManager = DataManager(modelContext: modelContext)
        inProgressGame = dataManager.getInProgressGame()
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)d \(secs)s"
        }
        return "\(secs)s"
    }
}

// MARK: - Difficulty Selection View

struct DifficultySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var navigateToGame: GameSession?
    @State private var isLoading = false
    @State private var selectedDifficulty: Difficulty?

    var body: some View {
        ZStack {
            // Ana içerik
            ScrollView {
                VStack(spacing: 20) {
                    Text("difficulty.title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)

                    ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                        Button {
                            startNewGame(difficulty: difficulty)
                        } label: {
                            DifficultyCard(difficulty: difficulty)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isLoading)
                    }
                }
                .padding()
            }
            .blur(radius: isLoading ? 3 : 0)
            .disabled(isLoading)
            
            // Loading Overlay
            if isLoading {
                LoadingOverlayView(difficulty: selectedDifficulty)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .navigationTitle("menu.new_game".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigateToGame) { game in
            GameView(gameSession: game)
        }
    }

    private func startNewGame(difficulty: Difficulty) {
        selectedDifficulty = difficulty
        
        // 1. Loading'i hemen başlat
        withAnimation {
            isLoading = true
        }
        
        Task {
            // 2. Kısa bir yapay gecikme ekle ki animasyon başlasın (0.3 sn)
            // Bu kullanıcıya "İşlem başladı" hissi verir ve glitch'i önler
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // 3. Bulmaca üretimini arka planda yap
            let game = await generateGame(difficulty: difficulty)
            
            // 4. Minimum loading süresi (kullanıcı deneyimi için)
            // Çok hızlı biterse bile en az 0.5 sn loading göster
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            await MainActor.run {
                withAnimation {
                    isLoading = false
                    navigateToGame = game
                }
            }
        }
    }
    
    @MainActor
    private func generateGame(difficulty: Difficulty) async -> GameSession {
        // DataManager MainActor gerektiriyor, bu yüzden burada çağırıyoruz
        // Ama asıl ağır işlem (SudokuGenerator) arka planda çalışacak
        return await Task.detached(priority: .userInitiated) {
            let generator = SudokuGenerator()
            let (puzzle, solution) = generator.generate(difficulty: difficulty)
            
            return await MainActor.run {
                let dataManager = DataManager(modelContext: self.modelContext)
                
                // Önce mevcut devam eden oyunları abandoned yap
                dataManager.abandonAllInProgressGames()
                
                // Yeni oyun oluştur
                let initialCells = [CellModel].from(puzzleString: puzzle)
                let gameSession = GameSession(difficulty: difficulty, cells: initialCells, solutionBoard: solution)
                
                self.modelContext.insert(gameSession)
                
                // İstatistikleri güncelle
                dataManager.ensureStatisticExists(for: difficulty).recordGameStarted()
                
                try? self.modelContext.save()
                
                return gameSession
            }
        }.value
    }
}

// MARK: - Loading Overlay View

struct LoadingOverlayView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    let difficulty: Difficulty?
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Buzlu cam arkaplan
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animasyonlu ikon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "number.square.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }
                
                VStack(spacing: 8) {
                    Text("loading.preparing".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let difficulty = difficulty {
                        Text(difficulty.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ProgressView()
                    .controlSize(.large)
                    .tint(.blue)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20)
            )
        }
    }
}

// MARK: - Difficulty Card

struct DifficultyCard: View {
    let difficulty: Difficulty
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(difficulty.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("difficulty.clues".localized + ": \(difficulty.cluesCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let bestTime = bestTimeForDifficulty {
                    Text("difficulty.best_time".localized + ": \(bestTime)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Image(systemName: iconNameForDifficulty)
                .font(.largeTitle)
                .foregroundStyle(colorForDifficulty)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var iconNameForDifficulty: String {
        switch difficulty {
        case .easy: return "star.fill"
        case .medium: return "star.fill"
        case .hard: return "star.fill"
        case .expert: return "flame.fill"
        }
    }

    private var colorForDifficulty: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .blue
        case .hard: return .orange
        case .expert: return .red
        }
    }

    private var bestTimeForDifficulty: String? {
        let dataManager = DataManager(modelContext: modelContext)
        guard let statistic = dataManager.getStatistic(for: difficulty),
              let bestTime = statistic.bestTime else {
            return nil
        }
        return Statistic.formatTime(bestTime)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GameSession.self, inMemory: true)
        .environmentObject(LocalizationManager.shared)
}
