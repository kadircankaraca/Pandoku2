//
//  GameView.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import SwiftData
import Combine

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var selectedCellIndex: Int?
    @State private var showErrors = false
    @State private var isPencilMode = false
    @State private var showCompletionOverlay = false
    @State private var isPaused = false
    @State private var showSettings = false
    @State private var showExitConfirmation = false
    @State private var showComboAnimation = false
    
    // Animasyon state'leri
    @State private var lastChangedCellIndex: Int?
    @State private var errorShakeCellIndex: Int?
    @State private var shakeOffset: CGFloat = 0
    
    // Bölge tamamlama animasyonu
    @State private var glowingCells: Set<Int> = []
    
    // Floating Score Delta
    @State private var previousScore: Int = 0
    @State private var scoreDelta: Int = 0
    @State private var scoreDeltaID: UUID = UUID()
    @State private var showScoreDelta: Bool = false

    // Timer
    @State private var timerRunning = true
    @State private var elapsedSeconds = 0

    let gameSession: GameSession

    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    private var selectedDigit: Int? {
        gameSession.getSelectedDigit(at: selectedCellIndex)
    }

    var body: some View {
        ZStack {
            // MARK: - Ana Oyun Katmanı
            GeometryReader { geometry in
                let isCompact = geometry.size.height < 700 && !isIPad
                
                // iPad için özel boyut hesaplaması
                let gridSize: CGFloat = {
                    if isIPad {
                        return min(geometry.size.width * 0.6, geometry.size.height * 0.55, 550)
                    } else if isLandscape {
                        return min(geometry.size.width * 0.55, geometry.size.height - 80)
                    } else {
                        return min(geometry.size.width - 32, geometry.size.height * 0.50)
                    }
                }()

                Group {
                    if isIPad {
                        iPadLayout(geometry: geometry, gridSize: gridSize, isCompact: isCompact)
                    } else if isLandscape {
                        HStack(spacing: 20) {
                            VStack(spacing: 8) {
                                landscapeTopBar
                                Spacer(minLength: 0)
                                SudokuGridView(
                                    cells: gameSession.cells,
                                    solutionBoard: gameSession.solutionBoard,
                                    selectedCellIndex: $selectedCellIndex,
                                    showErrors: showErrors,
                                    selectedDigit: selectedDigit,
                                    lastChangedCellIndex: lastChangedCellIndex,
                                    errorShakeCellIndex: errorShakeCellIndex,
                                    shakeOffset: shakeOffset,
                                    isIPad: isIPad,
                                    glowingCells: glowingCells,
                                    completedRows: gameSession.completedRows,
                                    completedCols: gameSession.completedCols,
                                    completedBoxes: gameSession.completedBoxes
                                )
                                .frame(width: gridSize, height: gridSize)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)

                            LandscapeControlPad(
                                onNumberSelected: { enterNumber($0) },
                                onErase: { enterNumber(0) },
                                onUndo: { _ = gameSession.undo() },
                                onRedo: { _ = gameSession.redo() },
                                onTogglePencil: { isPencilMode.toggle() },
                                onToggleErrors: { showErrors.toggle() },
                                onHint: { useHint() },
                                isPencilMode: isPencilMode,
                                showErrors: showErrors,
                                canUndo: !gameSession.moveHistory.isEmpty,
                                canRedo: !gameSession.redoStack.isEmpty,
                                hintsUsed: gameSession.hintsUsed,
                                completedDigits: gameSession.completedDigits,
                                isIPad: isIPad
                            )
                            .frame(width: 280)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            topBar(isIPad: isIPad)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, isCompact ? 4 : 8)
                            
                            scoreBar(isIPad: isIPad)
                                .padding(.horizontal, isIPad ? 40 : 16)
                                .padding(.bottom, isCompact ? 4 : 12)

                            Spacer(minLength: 0)

                            SudokuGridView(
                                cells: gameSession.cells,
                                solutionBoard: gameSession.solutionBoard,
                                selectedCellIndex: $selectedCellIndex,
                                showErrors: showErrors,
                                selectedDigit: selectedDigit,
                                lastChangedCellIndex: lastChangedCellIndex,
                                errorShakeCellIndex: errorShakeCellIndex,
                                shakeOffset: shakeOffset,
                                isIPad: isIPad,
                                glowingCells: glowingCells,
                                completedRows: gameSession.completedRows,
                                completedCols: gameSession.completedCols,
                                completedBoxes: gameSession.completedBoxes
                            )
                            .frame(width: gridSize, height: gridSize)

                            Spacer(minLength: 0)

                            PortraitControlPad(
                                onNumberSelected: { enterNumber($0) },
                                onUndo: { _ = gameSession.undo() },
                                onTogglePencil: { isPencilMode.toggle() },
                                onToggleErrors: { showErrors.toggle() },
                                onHint: { useHint() },
                                isPencilMode: isPencilMode,
                                showErrors: showErrors,
                                canUndo: !gameSession.moveHistory.isEmpty,
                                hintsUsed: gameSession.hintsUsed,
                                availableWidth: geometry.size.width,
                                completedDigits: gameSession.completedDigits,
                                isIPad: isIPad
                            )
                            .padding(.horizontal, isIPad ? 40 : 8)
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 8 : 16)
                        }
                    }
                }
            }
            .blur(radius: (isPaused || showCompletionOverlay) ? 8 : 0)
            .disabled(isPaused || showCompletionOverlay)
            
            // MARK: - Pause Overlay
            if isPaused {
                PauseOverlayView(
                    difficulty: gameSession.difficulty.displayName,
                    elapsedTime: formattedTime,
                    mistakesCount: gameSession.mistakesCount,
                    hintsUsed: gameSession.hintsUsed,
                    score: gameSession.score,
                    isIPad: isIPad,
                    onResume: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPaused = false
                            timerRunning = true
                        }
                    },
                    onSaveAndExit: {
                        saveAndExit()
                    },
                    onAbandonAndExit: {
                        abandonAndExit()
                    },
                    onSettings: {
                        showSettings = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(2)
            }
            
            // MARK: - Completion Overlay
            if showCompletionOverlay {
                CompletionOverlayView(
                    baseScore: gameSession.score,
                    difficultyMultiplier: gameSession.difficultyMultiplier,
                    difficulty: gameSession.difficulty,
                    time: formattedTime,
                    timeElapsed: elapsedSeconds,
                    mistakes: gameSession.mistakesCount,
                    hintsUsed: gameSession.hintsUsed,
                    isPerfect: gameSession.isPerfectGame,
                    isIPad: isIPad,
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(3)
            }
            
            // MARK: - Combo Animation
            if showComboAnimation && gameSession.comboMultiplier > 1 {
                ComboAnimationView(
                    multiplier: gameSession.comboMultiplier,
                    isIPad: isIPad
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(4)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !showCompletionOverlay {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPaused = true
                            timerRunning = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: isIPad ? 20 : 16, weight: .semibold))
                            Text("game.back".localized)
                                .font(isIPad ? .title3 : .body)
                        }
                        .foregroundColor(.blue)
                    }
                    .opacity(isPaused ? 0 : 1)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPaused = true
                            timerRunning = false
                        }
                    } label: {
                        Image(systemName: "pause.circle")
                            .font(.system(size: isIPad ? 28 : 22))
                            .foregroundColor(.primary)
                    }
                    .opacity(isPaused ? 0 : 1)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
        }
        .onAppear {
            elapsedSeconds = gameSession.timeElapsed
            previousScore = gameSession.score
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerRunning, gameSession.status == .inProgress, !isPaused, !showCompletionOverlay {
                elapsedSeconds += 1
                gameSession.timeElapsed = elapsedSeconds
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive || newPhase == .background {
                if gameSession.status == .inProgress {
                    let dataManager = DataManager(modelContext: modelContext)
                    dataManager.saveGame(gameSession)
                    withAnimation {
                        isPaused = true
                        timerRunning = false
                    }
                }
            }
        }
        .onChange(of: gameSession.score) { oldValue, newValue in
            let delta = newValue - oldValue
            if delta != 0 {
                triggerScoreDeltaAnimation(delta: delta)
            }
        }
        .onChange(of: gameSession.comboMultiplier) { oldValue, newValue in
            if newValue > oldValue && newValue > 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showComboAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation {
                        showComboAnimation = false
                    }
                }
            }
        }
    }
    
    // MARK: - Score Delta Animation
    
    private func triggerScoreDeltaAnimation(delta: Int) {
        scoreDelta = delta
        scoreDeltaID = UUID()
        showScoreDelta = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showScoreDelta = false
        }
    }
    
    // MARK: - iPad Layout
    
    @ViewBuilder
    private func iPadLayout(geometry: GeometryProxy, gridSize: CGFloat, isCompact: Bool) -> some View {
        VStack(spacing: 20) {
            topBar(isIPad: true)
                .padding(.horizontal, 40)
                .padding(.top, 16)
            
            scoreBar(isIPad: true)
                .padding(.horizontal, 60)
            
            Spacer(minLength: 0)
            
            SudokuGridView(
                cells: gameSession.cells,
                solutionBoard: gameSession.solutionBoard,
                selectedCellIndex: $selectedCellIndex,
                showErrors: showErrors,
                selectedDigit: selectedDigit,
                lastChangedCellIndex: lastChangedCellIndex,
                errorShakeCellIndex: errorShakeCellIndex,
                shakeOffset: shakeOffset,
                isIPad: true,
                glowingCells: glowingCells,
                completedRows: gameSession.completedRows,
                completedCols: gameSession.completedCols,
                completedBoxes: gameSession.completedBoxes
            )
            .frame(width: gridSize, height: gridSize)
            
            Spacer(minLength: 0)
            
            iPadControlPad(availableWidth: geometry.size.width)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - iPad Control Pad
    
    private func iPadControlPad(availableWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                iPadToolButton(icon: "arrow.uturn.backward", label: "game.undo".localized, isActive: false, isDisabled: gameSession.moveHistory.isEmpty) {
                    _ = gameSession.undo()
                }
                iPadToolButton(icon: "pencil.tip", label: "game.notes".localized, isActive: isPencilMode, isDisabled: false) {
                    isPencilMode.toggle()
                }
                iPadToolButton(icon: "exclamationmark.triangle.fill", label: "game.errors".localized, isActive: showErrors, isDisabled: false) {
                    showErrors.toggle()
                }
                iPadToolButton(icon: "lightbulb.fill", label: "game.hint".localized, isActive: false, isDisabled: gameSession.hintsUsed >= 5) {
                    useHint()
                }
            }
            
            HStack(spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    iPadNumberButton(number)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func iPadNumberButton(_ number: Int) -> some View {
        let isCompleted = gameSession.completedDigits.contains(number)
        
        return Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            enterNumber(number)
        }) {
            Text("\(number)")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(isCompleted ? .secondary : (isPencilMode ? .orange : .blue))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? Color(.systemGray5) : Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                )
        }
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.5 : 1.0)
    }
    
    private func iPadToolButton(icon: String, label: String, isActive: Bool, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isDisabled ? .secondary.opacity(0.5) : (isActive ? .blue : .primary))
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.blue.opacity(0.2) : Color(.systemBackground))
            )
        }
        .disabled(isDisabled)
    }
    
    // MARK: - Score Bar
    
    private func scoreBar(isIPad: Bool) -> some View {
        HStack {
            // Score with Floating Delta
            ZStack(alignment: .topTrailing) {
                HStack(spacing: isIPad ? 8 : 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(isIPad ? .title3 : .caption)
                    Text("\(gameSession.score)")
                        .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: gameSession.score)
                }
                
                // Floating Score Delta
                if showScoreDelta {
                    FloatingScoreDelta(
                        delta: scoreDelta,
                        isIPad: isIPad
                    )
                    .id(scoreDeltaID)
                    .offset(x: isIPad ? 50 : 35, y: isIPad ? -8 : -6)
                }
            }
            
            Spacer()
            
            if gameSession.comboMultiplier > 1 {
                HStack(spacing: isIPad ? 6 : 4) {
                    Text("x\(gameSession.comboMultiplier)")
                        .font(.system(size: isIPad ? 22 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(isIPad ? .title3 : .caption)
                }
                .padding(.horizontal, isIPad ? 12 : 8)
                .padding(.vertical, isIPad ? 8 : 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
            
            Spacer()
            
            HStack(spacing: isIPad ? 8 : 4) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(gameSession.mistakesCount > 0 ? .red : .secondary)
                    .font(isIPad ? .title3 : .caption)
                Text("\(gameSession.mistakesCount)")
                    .font(.system(size: isIPad ? 22 : 16, weight: .medium, design: .rounded))
                    .foregroundColor(gameSession.mistakesCount > 0 ? .red : .secondary)
            }
        }
        .padding(.horizontal, isIPad ? 24 : 16)
        .padding(.vertical, isIPad ? 14 : 8)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 14 : 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Save and Exit
    
    private func saveAndExit() {
        let dataManager = DataManager(modelContext: modelContext)
        dataManager.saveGame(gameSession)
        dismiss()
    }
    
    // MARK: - Abandon and Exit
    
    private func abandonAndExit() {
        gameSession.abandon()
        let dataManager = DataManager(modelContext: modelContext)
        dataManager.saveGame(gameSession)
        dismiss()
    }
    
    // MARK: - Landscape Top Bar

    private var landscapeTopBar: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(gameSession.difficulty.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            // Score with Floating Delta for Landscape
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text("\(gameSession.score)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: gameSession.score)
                }
                
                if showScoreDelta {
                    FloatingScoreDelta(delta: scoreDelta, isIPad: false, isCompact: true)
                        .id(scoreDeltaID)
                        .offset(x: 25, y: -4)
                }
            }
            
            if gameSession.comboMultiplier > 1 {
                Text("x\(gameSession.comboMultiplier)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                Text("\(max(0, 5 - gameSession.hintsUsed))")
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(gameSession.hintsUsed >= 5 ? .secondary : .orange)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Top Bar

    private func topBar(isIPad: Bool) -> some View {
        HStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: isIPad ? 4 : 2) {
                Text(formattedTime)
                    .font(.system(size: isIPad ? 42 : 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(gameSession.difficulty.displayName)
                    .font(isIPad ? .title3 : .caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func enterNumber(_ number: Int) {
        guard let index = selectedCellIndex else { return }
        let cell = gameSession.cells[index]
        
        if cell.isInitial { return }
        
        if number != 0 && gameSession.completedDigits.contains(number) {
            return
        }
        
        if isPencilMode {
            if number != 0 {
                gameSession.toggleNote(number, at: index)
            }
        } else {
            let previousMistakes = gameSession.mistakesCount
            gameSession.setValue(number, at: index)
            
            if number != 0 {
                triggerInputAnimation(at: index)
                
                if gameSession.mistakesCount > previousMistakes {
                    triggerErrorShake(at: index)
                } else {
                    // Doğru hamle - bölge tamamlama kontrolü
                    let completed = gameSession.checkRegionCompletion(at: index)
                    if !completed.isEmpty {
                        triggerRegionCompleteAnimation(completed)
                    }
                }
            }
            
            checkGameCompletion()
        }
    }
    
    private func useHint() {
        guard let selectedIndex = selectedCellIndex,
              gameSession.cells[selectedIndex].isEmpty else { return }
        
        if gameSession.useHint(at: selectedIndex) {
            triggerInputAnimation(at: selectedIndex)
            
            // Hint sonrası da bölge tamamlama kontrolü
            let completed = gameSession.checkRegionCompletion(at: selectedIndex)
            if !completed.isEmpty {
                triggerRegionCompleteAnimation(completed)
            }
            
            checkGameCompletion()
        }
    }
    
    private func checkGameCompletion() {
        if gameSession.isSolved {
            timerRunning = false
            let dataManager = DataManager(modelContext: modelContext)
            dataManager.completeGame(gameSession)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showCompletionOverlay = true
                }
            }
        }
    }
    
    // MARK: - Animation Triggers
    
    private func triggerInputAnimation(at index: Int) {
        lastChangedCellIndex = index
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if lastChangedCellIndex == index {
                lastChangedCellIndex = nil
            }
        }
    }
    
    private func triggerRegionCompleteAnimation(_ regions: CompletedRegions) {
        let affectedCells = regions.allAffectedCellIndices()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Parlama animasyonunu başlat
        withAnimation(.easeIn(duration: 0.3)) {
            glowingCells = affectedCells
        }
        
        // 1.5 saniye sonra parlamayı kaldır
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                glowingCells.removeAll()
            }
        }
    }
    
    private func triggerErrorShake(at index: Int) {
        errorShakeCellIndex = index
        
        withAnimation(.linear(duration: 0.05)) {
            shakeOffset = 8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 6
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -6
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            errorShakeCellIndex = nil
        }
    }
}

// MARK: - Floating Score Delta View

struct FloatingScoreDelta: View {
    let delta: Int
    var isIPad: Bool = false
    var isCompact: Bool = false
    
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.5
    
    private var isPositive: Bool { delta > 0 }
    
    private var displayText: String {
        isPositive ? "+\(delta)" : "\(delta)"
    }
    
    private var textColor: Color {
        isPositive ? .green : .red
    }
    
    private var fontSize: CGFloat {
        if isCompact {
            return 12
        }
        return isIPad ? 18 : 14
    }
    
    var body: some View {
        Text(displayText)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .shadow(color: textColor.opacity(0.3), radius: 2, y: 1)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                // Pop-in effect
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                
                // Settle to normal size
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
                
                // Float up and fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        offsetY = isIPad ? -30 : -20
                        opacity = 0
                    }
                }
            }
    }
}

// MARK: - Pause Overlay View

struct PauseOverlayView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let difficulty: String
    let elapsedTime: String
    let mistakesCount: Int
    let hintsUsed: Int
    let score: Int
    var isIPad: Bool = false
    let onResume: () -> Void
    let onSaveAndExit: () -> Void
    let onAbandonAndExit: () -> Void
    let onSettings: () -> Void
    
    @State private var showExitOptions = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: isIPad ? 32 : 24) {
                VStack(spacing: isIPad ? 16 : 12) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: isIPad ? 100 : 70))
                        .foregroundStyle(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                    
                    Text("game.paused".localized)
                        .font(isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 8)
                
                VStack(spacing: isIPad ? 20 : 16) {
                    HStack {
                        GameStatRow(icon: "speedometer", label: "game.difficulty".localized, value: difficulty, isIPad: isIPad)
                        Spacer()
                        GameStatRow(icon: "clock.fill", label: "game.time".localized, value: elapsedTime, isIPad: isIPad)
                    }
                    
                    Divider()
                    
                    HStack {
                        GameStatRow(icon: "star.fill", label: "game.score".localized, value: "\(score)", valueColor: .yellow, isIPad: isIPad)
                        Spacer()
                        GameStatRow(icon: "xmark.circle.fill", label: "game.mistakes".localized, value: "\(mistakesCount)", valueColor: mistakesCount > 0 ? .red : .green, isIPad: isIPad)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        GameStatRow(icon: "lightbulb.fill", label: "game.hints".localized, value: "\(hintsUsed)/5", valueColor: .orange, isIPad: isIPad)
                        Spacer()
                    }
                }
                .padding(isIPad ? 24 : 16)
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                .padding(.horizontal, isIPad ? 80 : 32)
                
                Spacer().frame(height: 8)
                
                VStack(spacing: isIPad ? 16 : 12) {
                    Button(action: onResume) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(isIPad ? .title2 : .title3)
                            Text("game.resume".localized)
                                .font(isIPad ? .title2.bold() : .title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: isIPad ? 400 : .infinity)
                        .padding(.vertical, isIPad ? 20 : 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(isIPad ? 20 : 16)
                        .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal, isIPad ? 80 : 32)
                    
                    Button(action: onSettings) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                            Text("menu.settings".localized)
                        }
                        .font(isIPad ? .title3 : .headline)
                        .foregroundColor(.primary)
                        .padding(.vertical, isIPad ? 16 : 12)
                        .padding(.horizontal, isIPad ? 32 : 24)
                        .background(
                            RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                                .fill(Color(.systemGray5))
                        )
                    }
                    
                    if showExitOptions {
                        VStack(spacing: isIPad ? 12 : 8) {
                            Button(action: onSaveAndExit) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("game.save_and_exit".localized)
                                }
                                .font(isIPad ? .headline : .subheadline)
                                .foregroundColor(.green)
                                .padding(.vertical, isIPad ? 14 : 10)
                                .padding(.horizontal, isIPad ? 24 : 16)
                                .background(
                                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10)
                                        .fill(Color.green.opacity(0.15))
                                )
                            }
                            
                            Button(action: onAbandonAndExit) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                    Text("game.abandon_and_exit".localized)
                                }
                                .font(isIPad ? .headline : .subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, isIPad ? 14 : 10)
                                .padding(.horizontal, isIPad ? 24 : 16)
                                .background(
                                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10)
                                        .fill(Color.red.opacity(0.15))
                                )
                            }
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showExitOptions = false
                                }
                            } label: {
                                Text("game.cancel".localized)
                                    .font(isIPad ? .subheadline : .caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showExitOptions = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(isIPad ? .body : .subheadline)
                                Text("game.exit_to_menu".localized)
                            }
                            .font(isIPad ? .title3 : .headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(.vertical, isIPad ? 60 : 40)
        }
    }
}

// MARK: - Completion Overlay View

struct CompletionOverlayView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let baseScore: Int
    let difficultyMultiplier: Double
    let difficulty: Difficulty
    let time: String
    let timeElapsed: Int
    let mistakes: Int
    let hintsUsed: Int
    let isPerfect: Bool
    let isIPad: Bool
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var animateScore = false
    
    private var timeBonus: Int {
        max(0, 3000 - (timeElapsed * 5))
    }
    
    private var perfectBonus: Int {
        isPerfect ? 1000 : 0
    }
    
    private var subtotal: Int {
        baseScore + timeBonus + perfectBonus
    }
    
    private var difficultyBonus: Int {
        Int(Double(subtotal) * (difficultyMultiplier - 1.0))
    }
    
    private var finalScore: Int {
        Int(Double(subtotal) * difficultyMultiplier)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            if showConfetti {
                ConfettiView(pieces: confettiPieces)
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: isIPad ? 28 : 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isPerfect ? [.yellow, .orange] : [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: isIPad ? 120 : 90, height: isIPad ? 120 : 90)
                            .shadow(color: isPerfect ? .orange.opacity(0.5) : .green.opacity(0.5), radius: 15)
                            .scaleEffect(animateScore ? 1.0 : 0.5)
                        
                        Image(systemName: isPerfect ? "crown.fill" : "checkmark.circle.fill")
                            .font(.system(size: isIPad ? 60 : 45))
                            .foregroundColor(.white)
                            .scaleEffect(animateScore ? 1.0 : 0.5)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateScore)
                    
                    VStack(spacing: isIPad ? 10 : 6) {
                        Text("game.congratulations".localized)
                            .font(isIPad ? .largeTitle : .title)
                            .fontWeight(.bold)
                            .opacity(animateScore ? 1 : 0)
                            .offset(y: animateScore ? 0 : 20)
                        
                        if isPerfect {
                            Text("game.perfect_game".localized)
                                .font(isIPad ? .title2 : .headline)
                                .foregroundColor(.orange)
                                .opacity(animateScore ? 1 : 0)
                        }
                        
                        Text(difficulty.displayName)
                            .font(isIPad ? .title3 : .subheadline)
                            .foregroundColor(.secondary)
                            .opacity(animateScore ? 1 : 0)
                    }
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateScore)
                    
                    VStack(spacing: isIPad ? 16 : 12) {
                        ScoreDetailRow(
                            title: "game.move_score".localized,
                            value: "\(baseScore)",
                            color: .primary,
                            isIPad: isIPad
                        )
                        
                        ScoreDetailRow(
                            title: "game.time_bonus".localized,
                            value: "+\(timeBonus)",
                            color: .blue,
                            isIPad: isIPad
                        )
                        
                        if isPerfect {
                            ScoreDetailRow(
                                title: "game.perfect_bonus".localized,
                                value: "+\(perfectBonus)",
                                color: .orange,
                                isIPad: isIPad
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("game.difficulty_bonus".localized)
                                    .font(isIPad ? .body : .subheadline)
                                    .foregroundColor(.secondary)
                                Text("(\(difficulty.displayName) x\(String(format: "%.1f", difficultyMultiplier)))")
                                    .font(isIPad ? .subheadline : .caption)
                                    .foregroundColor(.purple.opacity(0.8))
                            }
                            Spacer()
                            Text("+\(difficultyBonus)")
                                .font(isIPad ? .title3 : .body)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("game.total_score".localized)
                                .font(isIPad ? .title2 : .title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(finalScore)")
                                .font(isIPad ? .largeTitle : .title)
                                .fontWeight(.black)
                                .foregroundColor(.green)
                                .scaleEffect(animateScore ? 1.0 : 0.8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.5), value: animateScore)
                        }
                    }
                    .padding(isIPad ? 24 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    )
                    .padding(.horizontal, isIPad ? 60 : 24)
                    .opacity(animateScore ? 1 : 0)
                    .offset(y: animateScore ? 0 : 30)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateScore)
                    
                    HStack(spacing: isIPad ? 30 : 20) {
                        MiniStatBox(icon: "clock.fill", value: time, color: .blue, isIPad: isIPad)
                        MiniStatBox(icon: "xmark.circle.fill", value: "\(mistakes)", color: mistakes == 0 ? .green : .red, isIPad: isIPad)
                        MiniStatBox(icon: "lightbulb.fill", value: "\(hintsUsed)", color: hintsUsed == 0 ? .green : .orange, isIPad: isIPad)
                    }
                    .opacity(animateScore ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateScore)
                    
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("game.exit_to_menu".localized)
                        }
                        .font(isIPad ? .title2.bold() : .title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: isIPad ? 400 : .infinity)
                        .padding(.vertical, isIPad ? 20 : 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(isIPad ? 20 : 16)
                        .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal, isIPad ? 60 : 32)
                    .opacity(animateScore ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animateScore)
                }
                .padding(.vertical, isIPad ? 50 : 30)
            }
        }
        .onAppear {
            confettiPieces = (0..<(isIPad ? 80 : 50)).map { _ in ConfettiPiece() }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateScore = true
                    showConfetti = true
                }
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let rotation: Double
    let scale: CGFloat
    let duration: Double
    let delay: Double
    
    init() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        self.color = colors.randomElement() ?? .blue
        self.startX = CGFloat.random(in: 0...1)
        self.rotation = Double.random(in: 0...360)
        self.scale = CGFloat.random(in: 0.5...1.2)
        self.duration = Double.random(in: 2.0...4.0)
        self.delay = Double.random(in: 0...0.5)
    }
}

struct ConfettiView: View {
    let pieces: [ConfettiPiece]
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, animate: animate)
                        .position(
                            x: piece.startX * geometry.size.width,
                            y: animate ? geometry.size.height + 50 : -50
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3)) {
                animate = true
            }
        }
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let animate: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: 10 * piece.scale, height: 10 * piece.scale)
            .rotationEffect(.degrees(animate ? piece.rotation + 720 : piece.rotation))
            .animation(
                .linear(duration: piece.duration).delay(piece.delay),
                value: animate
            )
    }
}

// MARK: - Score Detail Row

struct ScoreDetailRow: View {
    let title: String
    let value: String
    let color: Color
    var isIPad: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isIPad ? .body : .subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(isIPad ? .title3 : .body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Mini Stat Box

struct MiniStatBox: View {
    let icon: String
    let value: String
    let color: Color
    var isIPad: Bool = false
    
    var body: some View {
        VStack(spacing: isIPad ? 8 : 4) {
            Image(systemName: icon)
                .font(isIPad ? .title2 : .title3)
                .foregroundColor(color)
            Text(value)
                .font(isIPad ? .title3 : .headline)
                .fontWeight(.bold)
        }
        .frame(width: isIPad ? 90 : 60)
        .padding(.vertical, isIPad ? 16 : 10)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Combo Animation View

struct ComboAnimationView: View {
    let multiplier: Int
    var isIPad: Bool = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        Text("x\(multiplier)")
            .font(.system(size: isIPad ? 120 : 80, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .orange.opacity(0.5), radius: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // 1. Pop-in (Görünür Olma ve Büyüme)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                    opacity = 1.0
                }

                // 2. Haptic
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                // 3. Bir süre ekranda kalıp sonra Fade-out (Kaybolma)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                        scale = 0.8
                    }
                }
            }
    }
}

// MARK: - Game Stat Row

struct GameStatRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isIPad: Bool = false
    
    var body: some View {
        VStack(spacing: isIPad ? 8 : 4) {
            Image(systemName: icon)
                .font(isIPad ? .title2 : .title3)
                .foregroundColor(.secondary)
            Text(label)
                .font(isIPad ? .subheadline : .caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(isIPad ? .title3 : .headline)
                .foregroundColor(valueColor)
        }
        .frame(minWidth: isIPad ? 120 : 80)
    }
}

// MARK: - Sudoku Grid View

struct SudokuGridView: View {
    let cells: [CellModel]
    let solutionBoard: String
    @Binding var selectedCellIndex: Int?
    let showErrors: Bool
    let selectedDigit: Int?
    let lastChangedCellIndex: Int?
    let errorShakeCellIndex: Int?
    let shakeOffset: CGFloat
    var isIPad: Bool = false
    var glowingCells: Set<Int> = []
    var completedRows: Set<Int> = []
    var completedCols: Set<Int> = []
    var completedBoxes: Set<Int> = []
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 9
            
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(.systemBackground))
                )
                
                let thickLineWidth: CGFloat = isIPad ? 3 : 2
                context.stroke(
                    Path { path in
                        for i in 0...3 {
                            let x = CGFloat(i) * cellSize * 3
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            
                            let y = CGFloat(i) * cellSize * 3
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                    },
                    with: .color(Color(.label)),
                    lineWidth: thickLineWidth
                )
                
                context.stroke(
                    Path { path in
                        for i in 0..<9 {
                            if i % 3 != 0 {
                                let x = CGFloat(i) * cellSize
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                                
                                let y = CGFloat(i) * cellSize
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            }
                        }
                    },
                    with: .color(Color(.separator)),
                    lineWidth: isIPad ? 1 : 0.5
                )
            }
            .overlay {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                let index = row * 9 + col
                                let cell = cells[index]
                                let isWrong = isWrongValue(for: cell, at: index)
                                let isSameDigit = selectedDigit != nil && cell.value == selectedDigit && cell.value != 0
                                let isLastChanged = lastChangedCellIndex == index
                                let isShaking = errorShakeCellIndex == index
                                let isGlowing = glowingCells.contains(index)
                                let isInCompletedRegion = checkInCompletedRegion(row: row, col: col)
                                
                                CellView(
                                    cell: cell,
                                    isSelected: selectedCellIndex == index,
                                    isHighlighted: shouldHighlight(cell: cell, at: index),
                                    hasConflict: showErrors && checkConflict(for: cell, at: index),
                                    isWrong: isWrong,
                                    isSameDigit: isSameDigit,
                                    isLastChanged: isLastChanged,
                                    isIPad: isIPad,
                                    isGlowing: isGlowing,
                                    isInCompletedRegion: isInCompletedRegion
                                )
                                .equatable()
                                .frame(width: cellSize, height: cellSize)
                                .offset(x: isShaking ? shakeOffset : 0)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCellIndex = index
                                }
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: isIPad ? 12 : 8))
            .shadow(color: .black.opacity(0.1), radius: isIPad ? 12 : 8, y: isIPad ? 4 : 2)
        }
    }
    
    private func checkInCompletedRegion(row: Int, col: Int) -> Bool {
        let box = (row / 3) * 3 + (col / 3)
        return completedRows.contains(row) || completedCols.contains(col) || completedBoxes.contains(box)
    }
    
    private func isWrongValue(for cell: CellModel, at index: Int) -> Bool {
        guard !cell.isEmpty, !cell.isInitial else { return false }
        guard index < solutionBoard.count else { return false }
        let solutionIndex = solutionBoard.index(solutionBoard.startIndex, offsetBy: index)
        let correctValue = Int(String(solutionBoard[solutionIndex])) ?? 0
        return cell.value != correctValue
    }
    
    private func shouldHighlight(cell: CellModel, at index: Int) -> Bool {
        guard let selectedIndex = selectedCellIndex else { return false }
        
        let selectedRow = selectedIndex / 9
        let selectedCol = selectedIndex % 9
        let selectedBox = (selectedRow / 3) * 3 + (selectedCol / 3)
        
        let cellRow = cell.row
        let cellCol = cell.column
        let cellBox = cell.boxIndex
        
        return cellRow == selectedRow || cellCol == selectedCol || cellBox == selectedBox
    }
    
    private func checkConflict(for cell: CellModel, at index: Int) -> Bool {
        guard !cell.isEmpty else { return false }
        
        let row = index / 9
        let col = index % 9
        
        for c in 0..<9 where c != col {
            if cells[row * 9 + c].value == cell.value { return true }
        }
        
        for r in 0..<9 where r != row {
            if cells[r * 9 + col].value == cell.value { return true }
        }
        
        let boxRowStart = (row / 3) * 3
        let boxColStart = (col / 3) * 3
        for r in boxRowStart..<(boxRowStart + 3) {
            for c in boxColStart..<(boxColStart + 3) {
                let checkIndex = r * 9 + c
                if checkIndex != index && cells[checkIndex].value == cell.value {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - Cell View

struct CellView: View, Equatable {
    let cell: CellModel
    let isSelected: Bool
    let isHighlighted: Bool
    let hasConflict: Bool
    let isWrong: Bool
    let isSameDigit: Bool
    let isLastChanged: Bool
    var isIPad: Bool = false
    var isGlowing: Bool = false
    var isInCompletedRegion: Bool = false

    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            backgroundColor

            // Parlama efekti
            if isGlowing {
                RoundedRectangle(cornerRadius: isIPad ? 4 : 2)
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.6), Color.green.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: isIPad ? 30 : 20
                        )
                    )
                    .opacity(glowOpacity)
            }

            if !cell.isEmpty {
                Text("\(cell.value)")
                    .font(.system(size: isIPad ? 36 : 22, weight: cell.isInitial ? .bold : .medium, design: .rounded))
                    .foregroundColor(foregroundColor)
                    .scaleEffect(scale)
            } else if !cell.notes.isEmpty {
                NotesView(notes: cell.notes, isIPad: isIPad)
            }

            if isSelected {
                RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                    .stroke(Color.blue, lineWidth: isIPad ? 4 : 3)
                    .padding(isIPad ? 2 : 1)
            }
        }
        .onChange(of: isLastChanged) { oldValue, newValue in
            if newValue {
                scale = 0.5
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }
        }
        .onChange(of: isGlowing) { oldValue, newValue in
            if newValue {
                // 1. Parlamayı aç
                withAnimation(.easeIn(duration: 0.2)) {
                    glowOpacity = 1.0
                }
                // 2. Bir süre sonra yavaşça söndür
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        glowOpacity = 0.0
                    }
                }
            } else {
                // ViewModel'dan false gelirse direkt sıfırla
                glowOpacity = 0.0
            }
        }
    }
    
    private var backgroundColor: Color {
        // Kalıcı tamamlanmış bölge rengi
        if isInCompletedRegion && !isGlowing {
            if isWrong { return Color.red.opacity(0.15) }
            if isSelected { return Color.green.opacity(0.18) }
            if isSameDigit { return Color.green.opacity(0.12) }
            return Color.green.opacity(0.05)
        }
        
        if isWrong { return Color.red.opacity(0.15) }
        if isSelected { return Color.blue.opacity(0.25) }
        if isSameDigit { return Color.blue.opacity(0.20) }
        if isHighlighted { return Color.blue.opacity(0.08) }
        return .clear
    }
    
    private var foregroundColor: Color {
        if isWrong || hasConflict { return .red }
        return cell.isInitial ? .primary : .blue
    }

    // MARK: - Equatable
    static func == (lhs: CellView, rhs: CellView) -> Bool {
        lhs.cell.value == rhs.cell.value &&
        lhs.cell.notes == rhs.cell.notes &&
        lhs.cell.isInitial == rhs.cell.isInitial &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isHighlighted == rhs.isHighlighted &&
        lhs.hasConflict == rhs.hasConflict &&
        lhs.isWrong == rhs.isWrong &&
        lhs.isSameDigit == rhs.isSameDigit &&
        lhs.isLastChanged == rhs.isLastChanged &&
        lhs.isGlowing == rhs.isGlowing &&
        lhs.isInCompletedRegion == rhs.isInCompletedRegion
    }
}

// MARK: - Notes View

struct NotesView: View {
    let notes: Set<Int>
    var isIPad: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let fontSize = geometry.size.width / (isIPad ? 4.0 : 4.5)
            
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(1...3, id: \.self) { col in
                            let num = row * 3 + col
                            Text(notes.contains(num) ? "\(num)" : " ")
                                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .padding(isIPad ? 4 : 2)
        }
    }
}

// MARK: - Landscape Control Pad

struct LandscapeControlPad: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let onNumberSelected: (Int) -> Void
    let onErase: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onTogglePencil: () -> Void
    let onToggleErrors: () -> Void
    let onHint: () -> Void
    let isPencilMode: Bool
    let showErrors: Bool
    let canUndo: Bool
    let canRedo: Bool
    let hintsUsed: Int
    let completedDigits: Set<Int>
    var isIPad: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("game.controls".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                    Text("\(max(0, 5 - hintsUsed))/5")
                        .font(.caption2)
                }
                .foregroundColor(hintsUsed >= 5 ? .secondary : .orange)
            }
            .padding(.bottom, 8)

            LazyVGrid(columns: columns, spacing: 8) {
                gridNumberButton(1)
                gridNumberButton(2)
                gridFunctionButton(icon: "arrow.uturn.backward", label: "game.undo".localized, isActive: false, isDisabled: !canUndo, action: onUndo)

                gridNumberButton(3)
                gridNumberButton(4)
                gridFunctionButton(icon: "pencil.tip", label: "game.notes".localized, isActive: isPencilMode, isDisabled: false, action: onTogglePencil)

                gridNumberButton(5)
                gridNumberButton(6)
                gridFunctionButton(icon: "arrow.uturn.forward", label: "game.redo".localized, isActive: false, isDisabled: !canRedo, action: onRedo)

                gridNumberButton(7)
                gridNumberButton(8)
                gridFunctionButton(icon: "exclamationmark.triangle.fill", label: "game.errors".localized, isActive: showErrors, isDisabled: false, action: onToggleErrors)

                gridNumberButton(9)
                gridEraseButton()
                gridFunctionButton(icon: "lightbulb.fill", label: "game.hint".localized, isActive: false, isDisabled: hintsUsed >= 5, action: onHint)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func gridNumberButton(_ number: Int) -> some View {
        let isCompleted = completedDigits.contains(number)
        
        return Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onNumberSelected(number)
        }) {
            Text("\(number)")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(isCompleted ? .secondary : .white)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCompleted ? Color(.systemGray4) : (isPencilMode ? Color.orange : Color.blue))
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                )
        }
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.6 : 1.0)
    }

    private func gridEraseButton() -> some View {
        Button(action: onErase) {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.85))
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                )
        }
    }

    private func gridFunctionButton(icon: String, label: String, isActive: Bool, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isDisabled ? .secondary.opacity(0.5) : (isActive ? .blue : .primary))
            .frame(maxWidth: .infinity, minHeight: 55)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.blue.opacity(0.2) : Color(.systemGray5))
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - Portrait Control Pad

struct PortraitControlPad: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let onNumberSelected: (Int) -> Void
    let onUndo: () -> Void
    let onTogglePencil: () -> Void
    let onToggleErrors: () -> Void
    let onHint: () -> Void
    let isPencilMode: Bool
    let showErrors: Bool
    let canUndo: Bool
    let hintsUsed: Int
    let availableWidth: CGFloat
    let completedDigits: Set<Int>
    var isIPad: Bool = false

    private var numpadButtonSize: CGFloat {
        if isIPad {
            return 60
        }
        let spacing: CGFloat = 8
        let totalSpacing = spacing * 8 + 16 * 2
        return min(50, (availableWidth - totalSpacing) / 9)
    }

    var body: some View {
        VStack(spacing: isIPad ? 16 : 8) {
            HStack(spacing: isIPad ? 24 : 16) {
                portraitToolButton(icon: "arrow.uturn.backward", label: "game.undo".localized, isActive: false, isDisabled: !canUndo, action: onUndo)
                portraitToolButton(icon: "pencil.tip", label: "game.notes".localized, isActive: isPencilMode, isDisabled: false, action: onTogglePencil)
                portraitToolButton(icon: "exclamationmark.triangle.fill", label: "game.errors".localized, isActive: showErrors, isDisabled: false, action: onToggleErrors)
                portraitToolButton(icon: "lightbulb.fill", label: "game.hint".localized, isActive: false, isDisabled: hintsUsed >= 5, action: onHint)
            }

            HStack(spacing: isIPad ? 12 : 8) {
                ForEach(1...9, id: \.self) { number in
                    portraitNumberButton(number)
                }
            }
        }
        .padding(.bottom, isIPad ? 16 : 8)
    }

    private func portraitNumberButton(_ number: Int) -> some View {
        let isCompleted = completedDigits.contains(number)
        
        return Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onNumberSelected(number)
        }) {
            Text("\(number)")
                .font(.system(size: isIPad ? 32 : numpadButtonSize * 0.55, weight: .semibold, design: .rounded))
                .foregroundColor(isCompleted ? .secondary : (isPencilMode ? .orange : .blue))
                .frame(width: numpadButtonSize, height: numpadButtonSize)
                .background(
                    isCompleted ?
                    Circle().fill(Color(.systemGray5)) :
                    nil
                )
        }
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.5 : 1.0)
    }

    private func portraitToolButton(icon: String, label: String, isActive: Bool, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: isIPad ? 8 : 4) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 28 : 20, weight: .medium))
                Text(label)
                    .font(isIPad ? .caption : .caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isDisabled ? .secondary.opacity(0.5) : (isActive ? .blue : .primary))
            .frame(width: isIPad ? 80 : 50)
            .padding(.vertical, isIPad ? 12 : 8)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 14 : 10)
                    .fill(isActive ? Color.blue.opacity(0.2) : Color(.systemGray6))
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GameSession.self, configurations: config)

    let cells = [CellModel].from(puzzleString: "530070000600195000098000060800060003400803001700020006060000280000419005000080079")
    let game = GameSession(difficulty: .medium, cells: cells, solutionBoard: "534678912672195348198342567859761423426853791713924856961537284287419635345286179")

    return GameView(gameSession: game)
        .modelContainer(container)
        .environmentObject(LocalizationManager.shared)
}

