// DataManager.swift kontrol edin
final class DataManager {
    private let modelContext: ModelContext
    
    // Context'in düzgün yönetildiğinden emin olun
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
