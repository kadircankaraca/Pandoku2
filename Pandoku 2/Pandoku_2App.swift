//
//  Pandoku_2App.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import SwiftData

@main
struct Pandoku_2App: App {
    @AppStorage("appTheme") private var selectedTheme: ThemeOption = .system
    @StateObject private var localizationManager = LocalizationManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameSession.self,
            Statistic.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Migration hatası - veritabanını sıfırla
            print("❌ ModelContainer oluşturulamadı: \(error)")
            print("🔄 Veritabanı sıfırlanıyor...")
            
            resetDatabase()
            
            // Tekrar dene
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("ModelContainer ikinci denemede de oluşturulamadı: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(selectedTheme.colorScheme)
                .environmentObject(localizationManager)
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Database Reset
    
    private static func resetDatabase() {
        let fileManager = FileManager.default
        
        // Uygulamanın Application Support dizinini bul
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")
            
            // Varsayılan store dosyasını sil
            if fileManager.fileExists(atPath: storeURL.path) {
                try? fileManager.removeItem(at: storeURL)
                print("✅ default.store silindi")
            }
            
            // WAL ve SHM dosyalarını da sil
            let shmURL = appSupportURL.appendingPathComponent("default.store-shm")
            let walURL = appSupportURL.appendingPathComponent("default.store-wal")
            
            if fileManager.fileExists(atPath: shmURL.path) {
                try? fileManager.removeItem(at: shmURL)
                print("✅ default.store-shm silindi")
            }
            
            if fileManager.fileExists(atPath: walURL.path) {
                try? fileManager.removeItem(at: walURL)
                print("✅ default.store-wal silindi")
            }
        }
    }
}
