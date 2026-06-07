// GameView.swift içinde
@State private var showCompletionOverlay = false  // ✅ OK - struct içinde

// Eğer class kullanıyorsanız
class SomeManager {
    var onComplete: (() -> Void)?  // ⚠️ Potansiyel leak
    
    // Düzeltme: weak closure veya deinit'te nil yapın
    deinit {
        onComplete = nil
    }
}
