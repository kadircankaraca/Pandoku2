<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Bu PRD format ve kapsam olarak oldukça profesyonel ve detaylı. Bir ürün yöneticisinin elinden çıkmış gibi duruyor.

Ancak, senin "ilk iOS projen" olduğu ve "SwiftData" seçtiğin gerçeğiyle örtüşmeyen, işi gereksiz yere zorlaştıracak (over-engineering) kısımlar var. Bir backend developer olarak sen de bilirsin ki; MVP (Minimum Viable Product) aşamasında en büyük düşman karmaşıklıktır.
İşte bu PRD'de kesinlikle değiştirmeni önerdiğim yerler ve nedenleri:
🚩 1. Kritik Düzeltme: Firebase vs. SwiftData (En Önemli Kısım)
PRD, backend olarak tamamen Firebase üzerine kurgulanmış. Ancak biz projeyi kurarken SwiftData seçtik.
Sorun: Firebase entegrasyonu, Auth, Cloud Functions... Bunlar şu an senin için "yakıt tankı taşımak" gibi olur. Sadece Swift öğrenmeye odaklanmalısın.
Çözüm: Firebase'i tamamen çıkar. "Local-First" (Önce Yerel) bir yapı kur.
Düzeltme:
Database: Cloud Firestore -> SwiftData (Local SQLite wrapper).
Auth: Firebase Auth -> Gerek Yok (Kullanıcı uygulamayı açsın ve oynasın. Login duvarı koyma).
Sync: Eğer ileride cloud istersen, SwiftData tek tıkla iCloud (CloudKit) ile senkronize olur. Apple'ın kendi ecosystem'ini kullanmak varken Firebase ile uğraşma.
🚩 2. Kritik Düzeltme: Bulmaca Üretimi (Cloud vs. Local)
PRD'de bulmacaların sunucuda (Cloud Functions) üretilip cache'lenmesi önerilmiş.
Sorun: Gereksiz maliyet ve latency.
Gerçek: Modern bir iPhone işlemcisi (A15/A16 çip), saniyenin 1/100'ünde Backtracking algoritmasıyla Sudoku üretebilir. Sunucuya ihtiyacın yok.
Düzeltme: Algoritmayı Swift ile yazıp cihazın içinde (Client-side) çalıştıracağız. Hem offline çalışır hem de bedavadır.
🚩 3. Kritik Düzeltme: Sosyal Özellikler (MVP Kapsamı)
PRD'de "Arkadaş Ekleme", "Canlı Yarışma" gibi özellikler Faz 1'e dahil edilmiş gibi duruyor.
Öneri: Bunları Faz 2 veya Faz 3'e ertele. İlk hedefimiz; kusursuz çalışan, hatasız, akıcı bir "Tek Oyunculu" deneyim olmalı.
📝 PRD İçin Revize Edilmiş Bölümler
Aşağıdaki kısımları PRD'deki ilgili alanlarla değiştirirsen proje çok daha yönetilebilir hale gelir:
6.1 Platform ve Araçlar (Revize)
Frontend: Swift 5.9+, SwiftUI
Backend: Yok (Serverless / Local-First)
Database (Persistence): SwiftData (Cihaz üzerinde yerel veritabanı)
Sync (Opsiyonel): iCloud / CloudKit (Gelecek fazda SwiftData üzerinden otomatik sync)
6.2 Mimari Tasarım (Revize)
Firebase servisleri yerine yerel servisler:
Plaintext
SudokuApp/
├── Models/ (SwiftData @Model sınıfları)
│   ├── GameSession.swift (Oyun durumu)
│   ├── BoardState.swift (Hücre verileri)
│   └── Statistic.swift (Kullanıcı istatistikleri)
├── Services/
│   ├── SudokuGenerator.swift (Yerel Backtracking Algoritması)
│   └── DataManager.swift (SwiftData işlemleri - CRUD)

5.3 Sosyal Özellikler (Revize - Kapsam Dışı)
Bu sürümde sosyal özellikler (arkadaş ekleme, online leaderboard) devre dışı bırakılmıştır. Sadece kullanıcının kendi "Kişisel Rekorları" (Local High Scores) tutulacaktır.
📊 SwiftData İçin Veri Şeması Taslağı
Backend developer olduğun için kafandaki tablo yapısını şimdiden kuralım. SwiftData'da sınıflarımız şöyle olacak:

1. Game (Oyun Tablosu)
Bu tablo, hem geçmiş oyunları hem de şu an devam eden (save edilmiş) oyunu tutar.
id: UUID
difficulty: Enum (Easy, Medium, Hard)
startTime: Date
status: Enum (InProgress, Completed, Abandoned)
timeElapsed: Int (Saniye cinsinden geçen süre)
initialBoard: String (Oyunun başındaki hali - örn: "53..7....")
currentBoard: String (Kullanıcının şu anki hali)
mistakes: Int (Yapılan hata sayısı)
2. Statistic (İstatistik Tablosu)
Agrege veri tutmak yerine, her biten oyundan sonra query atabiliriz ama performans için özet tablo tutabilirsin.
difficulty: Enum
gamesPlayed: Int
gamesWon: Int
bestTime: Int

Kesinlikle haklısın! Backend developer gözüyle MVP prensiplerini unutmuşum. "Büyük proje" derken over-engineering yaptım. İlk iOS projesi için **local-first, SwiftData odaklı, sosyal özellikleri kaldırılmış** bir PRD hazırlayayım.

***

# PRODUCT REQUIREMENTS DOCUMENT (PRD) - MVP

## Sudoku iOS Oyunu v1.0

**Proje Adı:** Sudoku iOS Game (MVP)
**Platform:** iOS (iPhone \& iPad)
**Teknoloji:** Swift, SwiftUI, SwiftData
**Yaklaşım:** Local-First (Serverless)
**Versiyon:** 1.0 MVP
**Tarih:** 13 Şubat 2026
**Durum:** Planning Phase

***

## 1. Proje Genel Bakış

İlk iOS projesi olarak, **Swift ve SwiftData** kullanılarak iPhone ve iPad için geliştirilecek **tek oyunculu, local-first** Sudoku oyunu. Tüm veriler cihazda tutulacak, backend veya authentication gereksinimleri yoktur.[^1]

### MVP Felsefesi

- ✅ **Basit ve hatasız çalışan oyun mekaniği**
- ✅ **Yerel veri saklama (SwiftData)**
- ✅ **Offline-first yaklaşım**
- ❌ **Backend kompleksitesi yok**
- ❌ **Sosyal özellikler yok (v2.0'a ertelendi)**

***

## 2. Amaç ve Hedefler

### Temel Amaçlar

- Swift, SwiftUI ve SwiftData öğrenmek
- Kusursuz çalışan tek oyunculu Sudoku deneyimi
- Kişisel istatistik ve rekor takibi
- %100 çevrimdışı çalışabilen uygulama


### Öğrenme Hedefleri

- SwiftUI view management
- SwiftData CRUD operasyonları
- Algoritma implementasyonu (Sudoku generation)
- iOS lifecycle ve state management

***

## 3. Hedef Kitle

### Birincil Kullanıcılar

- **Geliştirici ve yakın çevre (Sen ve arkadaşların)**
- **Yaş grubu:** 8-65 yaş
- **Deneyim seviyesi:** Başlangıç ve profesyonel


### MVP Odağı

İlk versiyonda kullanıcı kitlesi sınırlı tutulacak. Temel oyun döngüsü mükemmel çalıştıktan sonra sosyal özelliklerle genişleme hedefleniyor.

***

## 4. Başarı Metrikleri (KPIs)

### MVP Başarı Kriterleri

- ✅ Hatasız oyun mekaniği (crash rate: 0%)
- ✅ Bulmaca üretimi <500ms
- ✅ UI responsive (<50ms touch response)
- ✅ 10+ oyun üst üste kesintisiz oynama
- ✅ SwiftData operasyonları hatasız çalışıyor

***

## 5. Fonksiyonel Özellikler (MVP)

### 5.1 Çekirdek Oyun Özellikleri

#### Zorluk Seviyeleri

- **Kolay:** 38-42 önceden doldurulmuş hücre
- **Orta:** 30-35 önceden doldurulmuş hücre
- **Zor:** 24-28 önceden doldurulmuş hücre
- **Uzman:** 20-23 önceden doldurulmuş hücre


#### Bulmaca Üretimi (Client-Side Only)

**Algoritma:** Backtracking + Randomization[^2]

- Tüm bulmacalar cihazda anlık üretilir
- Modern iPhone işlemcileri (A15+) için <500ms hedef
- Algoritma:

1. Boş grid oluştur
2. Backtracking ile valid çözüm doldur
3. Rastgele hücreleri kaldır (zorluk seviyesine göre)
4. Unique solution kontrolü yap

```swift
// Pseudo-code
func generatePuzzle(difficulty: Difficulty) -> Board {
    var board = fillBoard() // Backtracking
    removeNumbers(count: difficulty.cluesCount)
    return board
}
```


#### Oyun Mekaniği

- **Sayı girişi:** Bottom toolbar (1-9 rakamlar)
- **Hücre seçimi:** Tap ile seçim, selected state
- **Validasyon:** Gerçek zamanlı çakışma kontrolü
- **Otomatik kayıt:** Her hamle SwiftData'ya yazılır


#### Yardım Sistemleri

- **İpucu:** Günlük 5 ipucu (UserDefaults ile sıfırlama)
    - İpucu: Boş bir hücreye doğru sayı yerleştirir
    - Kalan ipucu sayısı UI'da gösterilir
- **Hata Gösterimi:** Button ile aktif edilince yanlış hücreler kırmızı
- **Otomatik Notlar (Pencil Marks):** Toggle ile açılır/kapatılır
    - Her hücrede olası sayıları küçük fontla gösterir
- **Geri Al/İleri Al:** Son 10 hamle için stack tutar


### 5.2 Oyun Durumları

#### Oyun Kaydetme

- Kullanıcı uygulamayı kapatırsa otomatik devam edilebilir
- SwiftData'da `status: .inProgress` olan oyun tutulur
- Ana menüde "Devam Et" butonu gösterilir


#### Oyun Tamamlama

- Tüm hücreler dolduğunda validasyon
- Başarılı ise:
    - İstatistiklere kaydedilir
    - Tebrik ekranı gösterilir
    - Best time kontrolü yapılır


### 5.3 İstatistik Sistemi (Local Only)

#### Takip Edilen Metrikler

- Toplam çözülen bulmaca sayısı
- Zorluk seviyesine göre çözüm sayıları
- En iyi süreler (difficulty bazında)
- Ortalama çözüm süreleri
- Hatasız çözüm sayısı


#### İstatistik Sayfası

```
📊 İstatistiklerim

Toplam Oyun: 47
Tamamlanan: 42

Zorluk Bazında:
━━━━━━━━━━━━━━━━━━━━
Kolay:    18 oyun | En iyi: 3:24
Orta:     15 oyun | En iyi: 7:12
Zor:       7 oyun | En iyi: 12:45
Uzman:     2 oyun | En iyi: 18:33
```


### 5.4 Kullanıcı Arayüzü

#### Ekranlar

1. **Ana Menü**
    - Yeni Oyun
    - Devam Et (varsa)
    - İstatistiklerim
    - Ayarlar
2. **Zorluk Seçimi**
    - 4 zorluk kartı
    - Her kartın altında istatistik özeti
3. **Oyun Ekranı**
    - 9x9 Sudoku grid
    - Top bar: Süre, ipucu sayısı, pause
    - Bottom bar: Sayı inputları (1-9), erase
    - Action buttons: Undo, Redo, Pencil, Hint
4. **İstatistik Ekranı**
    - Özet metrikler
    - Zorluk bazında detaylar
    - En iyi süreler listesi
5. **Ayarlar**
    - Tema seçimi (Dark/Light/Auto)
    - Dil seçimi (TR/EN)
    - Otomatik kayıt (açık/kapalı)
    - Hakkında

#### Tema Sistemi

- **Aydınlık Mod:** Beyaz arka plan, koyu metinler
- **Karanlık Mod:** Koyu arka plan, açık metinler
- **Otomatik:** iOS sistem ayarı


#### Dil Desteği

- Türkçe (TR)
- İngilizce (EN)
- Localizable.strings ile yönetim


### 5.5 Oyun Akışı

```
Açılış → Ana Menü → Zorluk Seçimi → Oyun Ekranı → 
→ Tamamlama Ekranı → Ana Menü
```

**Devam Eden Oyun Akışı:**

```
Açılış → Ana Menü → "Devam Et" → Oyun Ekranı (restore state)
```


***

## 6. Teknik Gereksinimler

### 6.1 Platform ve Araçlar

#### Frontend

- **Dil:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData
- **IDE:** Xcode 15+
- **Minimum iOS:** iOS 17.0 (SwiftData requirement)
- **Desteklenen Cihazlar:**
    - iPhone (12+, SE 3rd gen+)
    - iPad (9th gen+, Air 4+, Pro)


#### Backend

- **❌ YOK** - Tamamen local-first


#### Local Storage

- **SwiftData:** Oyun verileri, istatistikler
- **UserDefaults:** Ayarlar (tema, dil), günlük ipucu counter


### 6.2 Mimari Tasarım

#### Mimari Pattern

- **MVVM (Model-View-ViewModel)**
- **SwiftData Container:** ModelContext yönetimi


#### Proje Yapısı

```
SudokuApp/
├── App/
│   └── SudokuApp.swift (@main, SwiftData container setup)
│
├── Models/ (SwiftData @Model classes)
│   ├── GameSession.swift
│   ├── Statistic.swift
│   └── Enums.swift (Difficulty, GameStatus)
│
├── ViewModels/
│   ├── GameViewModel.swift
│   ├── MenuViewModel.swift
│   └── StatsViewModel.swift
│
├── Views/
│   ├── MenuView.swift
│   ├── DifficultySelectionView.swift
│   ├── GameView.swift
│   │   ├── SudokuGridView.swift
│   │   ├── NumberInputView.swift
│   │   └── GameToolbarView.swift
│   ├── StatsView.swift
│   └── SettingsView.swift
│
├── Services/
│   ├── SudokuGenerator.swift (Backtracking algorithm)
│   ├── SudokuValidator.swift
│   └── DataManager.swift (SwiftData CRUD wrapper)
│
├── Utilities/
│   ├── Constants.swift
│   ├── Extensions.swift
│   └── ThemeManager.swift
│
└── Resources/
    ├── Localizations/
    │   ├── en.lproj/Localizable.strings
    │   └── tr.lproj/Localizable.strings
    └── Assets.xcassets
```


### 6.3 SwiftData Veri Modeli

#### GameSession Model

```swift
import SwiftData
import Foundation

@Model
final class GameSession {
    @Attribute(.unique) var id: UUID
    var difficulty: Difficulty
    var startTime: Date
    var endTime: Date?
    var status: GameStatus // .inProgress, .completed, .abandoned
    var timeElapsed: Int // Saniye
    
    // Board data (81 karakter string: "53..7...." formatında)
    var initialBoard: String // Oyunun başlangıç hali
    var currentBoard: String // Kullanıcının şu anki hali
    var solutionBoard: String // Çözüm (validation için)
    
    // Game stats
    var mistakesCount: Int
    var hintsUsed: Int
    var moveHistory: [String] // JSON array: [{action, cell, value}]
    
    init(difficulty: Difficulty, initialBoard: String, solutionBoard: String) {
        self.id = UUID()
        self.difficulty = difficulty
        self.startTime = Date()
        self.status = .inProgress
        self.timeElapsed = 0
        self.initialBoard = initialBoard
        self.currentBoard = initialBoard
        self.solutionBoard = solutionBoard
        self.mistakesCount = 0
        self.hintsUsed = 0
        self.moveHistory = []
    }
}
```


#### Statistic Model

```swift
@Model
final class Statistic {
    @Attribute(.unique) var id: UUID
    var difficulty: Difficulty
    var gamesPlayed: Int
    var gamesCompleted: Int
    var bestTime: Int? // Saniye (nil = henüz tamamlanmamış)
    var averageTime: Int?
    var totalTimeSpent: Int
    var perfectGames: Int // Hatasız oyunlar
    
    init(difficulty: Difficulty) {
        self.id = UUID()
        self.difficulty = difficulty
        self.gamesPlayed = 0
        self.gamesCompleted = 0
        self.totalTimeSpent = 0
        self.perfectGames = 0
    }
}
```


#### Enums

```swift
enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var cluesCount: Int {
        switch self {
        case .easy: return 40
        case .medium: return 32
        case .hard: return 26
        case .expert: return 21
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return NSLocalizedString("difficulty.easy", comment: "")
        case .medium: return NSLocalizedString("difficulty.medium", comment: "")
        case .hard: return NSLocalizedString("difficulty.hard", comment: "")
        case .expert: return NSLocalizedString("difficulty.expert", comment: "")
        }
    }
}

enum GameStatus: String, Codable {
    case inProgress
    case completed
    case abandoned
}
```


### 6.4 Sudoku Algoritmaları

#### Backtracking ile Board Generation

```swift
class SudokuGenerator {
    func generate(difficulty: Difficulty) -> (puzzle: String, solution: String) {
        var board = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
        fillBoard(&board)
        let solution = boardToString(board)
        
        removeNumbers(&board, count: 81 - difficulty.cluesCount)
        let puzzle = boardToString(board)
        
        return (puzzle, solution)
    }
    
    private func fillBoard(_ board: inout [[Int]]) -> Bool {
        // Backtracking algoritması
        // 1. Boş hücre bul
        // 2. 1-9 arası valid sayı dene
        // 3. Valid ise recursive devam et
        // 4. Tıkanırsa backtrack
    }
    
    private func removeNumbers(_ board: inout [[Int]], count: Int) {
        // Random hücreler seç ve kaldır
        // Unique solution kontrolü yap
    }
}
```


### 6.5 Performans Hedefleri

- Bulmaca üretimi: <500ms (iPhone 12+)
- Grid render: <100ms
- Touch response: <50ms
- SwiftData write: <20ms
- Bellek kullanımı: <100MB

***

## 7. Kapsam

### 7.1 Kapsam İçi (MVP v1.0)

#### ✅ Temel Özellikler

- 4 zorluk seviyeli klasik 9x9 Sudoku
- Client-side bulmaca üretimi (Backtracking)
- Sayı girişi ve validasyon
- Geri al/İleri al (10 hamle)
- Günlük limitli ipucu sistemi (5 ipucu)
- Hata gösterimi toggle
- Otomatik not alma (Pencil marks)
- Otomatik oyun kaydetme (SwiftData)


#### ✅ UI/UX

- Dark/Light/Auto tema
- TR/EN lokalizasyon
- iPhone ve iPad desteği
- Portrait ve landscape


#### ✅ İstatistikler (Local)

- Toplam oyun sayısı
- Zorluk bazında istatistikler
- En iyi süreler
- Ortalama süreler


### 7.2 Kapsam Dışı (v2.0+)

#### ❌ Ertelenen Özellikler

- **Sosyal:** Arkadaş ekleme, liderlik tabloları, yarışma
- **Backend:** Firebase, authentication, cloud sync
- **İleri Özellikler:**
    - Çocuk modu (4x4, 6x6)
    - Günlük challenge
    - Başarı rozetleri
    - Ses efektleri
    - Apple Watch app
    - Reklam/IAP


#### 🔮 v2.0 için Potansiyel Özellik: iCloud Sync

SwiftData'nın en büyük avantajı: Tek satır kodla iCloud senkronizasyonu aktif edebilirsin.

```swift
// v2.0'da aktif edilecek
let container = ModelContainer(
    for: [GameSession.self, Statistic.self],
    configurations: ModelConfiguration(isStoredInMemoryOnly: false, 
                                       cloudKitDatabase: .automatic) // 👈 Bu satır!
)
```


***

## 8. Bağımlılıklar

### 8.1 Harici Bağımlılıklar

- **❌ YOK** - Sıfır third-party dependency
- Tüm kod Swift standard library ile yazılacak


### 8.2 İç Bağımlılıklar

- SudokuGenerator → GameViewModel
- DataManager → SwiftData ModelContext
- GameViewModel → GameSession Model

***

## 9. Kilometre Taşları (Revize - MVP Odaklı)

### Faz 1: Proje Kurulumu (1 hafta)

- [x] Xcode projesi oluşturma
- [ ] SwiftData container setup
- [ ] Temel navigation yapısı (TabView/NavigationStack)
- [ ] Theme manager ve lokalizasyon setup


### Faz 2: Core Game Logic (2-3 hafta)

- [ ] Sudoku generation algoritması (Backtracking)
- [ ] Board validation logic
- [ ] GameSession SwiftData model
- [ ] Basic UI: 9x9 grid render


### Faz 3: Game UI Implementation (2-3 hafta)

- [ ] Number input toolbar
- [ ] Cell selection ve highlight
- [ ] Undo/Redo stack
- [ ] Hint system
- [ ] Error highlighting
- [ ] Pencil marks (auto notes)


### Faz 4: Persistence \& State (1-2 hafta)

- [ ] SwiftData CRUD operations
- [ ] Auto-save on every move
- [ ] Resume game functionality
- [ ] Game completion detection
- [ ] Statistic model ve update logic


### Faz 5: Statistics \& Settings (1-2 hafta)

- [ ] Stats screen UI
- [ ] Settings screen
- [ ] Theme switching
- [ ] Language switching
- [ ] Daily hint reset (UserDefaults + Timer)


### Faz 6: Polish \& Testing (2 hafta)

- [ ] iPad layout adaptasyonu
- [ ] Landscape mode
- [ ] Animasyonlar (transitions, confetti on win)
- [ ] Unit tests (Generator, Validator)
- [ ] UI tests (critical flows)
- [ ] Bug fixing


### Faz 7: Beta \& Launch (1 hafta)

- [ ] TestFlight beta
- [ ] App Store metadata
- [ ] Screenshots (iPhone + iPad)
- [ ] Privacy policy sayfası
- [ ] Final QA
- [ ] App Store submission

**Toplam Tahmini Süre:** 10-14 hafta (2.5-3.5 ay)

***

## 10. Öğrenme Yol Haritası

### Swift Temelleri (Zaten biliyorsun sanırım)

- ✅ Swift syntax
- ✅ Optionals, Generics
- ✅ Protocol-Oriented Programming


### SwiftUI (Öğrenilecekler)

- [ ] View lifecycle
- [ ] State management (@State, @Binding, @ObservedObject)
- [ ] List, Grid, Stack layouts
- [ ] Navigation (NavigationStack, NavigationSplitView)
- [ ] Animations


### SwiftData (Öğrenilecekler)

- [ ] @Model macro
- [ ] ModelContext operations (insert, delete, fetch)
- [ ] Predicate ve Descriptor (filtering/sorting)
- [ ] Relationships (eğer gerekirse)


### Algoritmalar

- [ ] Backtracking (Sudoku generation)
- [ ] Depth-first search (validation)

***

## 11. Riskler ve Azaltma

### Yüksek Risk

**Risk:** Sudoku generation algoritması yavaş çalışabilir
**Azaltma:** Early prototype test et, optimize et, gerekirse cache mekanizması ekle

**Risk:** SwiftData iOS 17 gerektiriyor (eski cihazlar desteklenmiyor)
**Azaltma:** Hedef kitle zaten modern cihaz kullanıyor, kabul edilebilir trade-off

### Orta Risk

**Risk:** iPad layout responsive olmayabilir
**Azaltma:** GeometryReader kullan, adaptive layouts

**Risk:** İlk iOS projesi, öğrenme eğrisi
**Azaltma:** Küçük adımlarla ilerle, her feature için test et

***

## 12. Başarı Kriterleri

### Minimum Viable Product Kriterleri

- ✅ Uygulamayı 10 kez üst üste crash olmadan açıp kapatabiliyorum
- ✅ Her zorluktan en az 5 bulmaca hatasız üretiliyor
- ✅ Bir oyunu baştan sona tamamlayıp istatistikleri görebiliyorum
- ✅ Oyunu yarıda bırakıp geri dönebiliyorum (state persistence)
- ✅ Dark mode ve lokalizasyon çalışıyor


### İlk Kullanıcı Testi

Arkadaşlarına ver, şu soruları sor:

1. Oyun akışını anladın mı?
2. Herhangi bir yerde takıldın mı?
3. Crash veya bug gördün mü?
4. Performans sorunu hissettiniz mi?

***

## 13. Sonraki Adımlar

### Şimdi Yapılacaklar

1. ✅ PRD revizyonu tamamlandı
2. **Hemen başla:** Xcode'da proje oluştur
3. SwiftData tutorial izle (Apple'ın kendi dökümanı)
4. Paper üzerinde board generation algoritmasını yaz
5. İlk hafta hedefi: Boş 9x9 grid ekranda göster

### Öğrenme Kaynakları

- **SwiftUI:** [Apple SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- **SwiftData:** [Meet SwiftData - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10187/)
- **Sudoku Algorithm:** [Algorithm X explanation](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X)[^2]

***

## 14. Veri Şeması Özeti (Backend Developer Gözüyle)

```
┌─────────────────────────────────────────────────┐
│ GameSession (SQLite Table)                      │
├─────────────────────────────────────────────────┤
│ id: UUID (PK)                                   │
│ difficulty: String (enum)                       │
│ startTime: Date                                 │
│ endTime: Date?                                  │
│ status: String (enum)                           │
│ timeElapsed: Int                                │
│ initialBoard: String (81 chars)                 │
│ currentBoard: String (81 chars)                 │
│ solutionBoard: String (81 chars)                │
│ mistakesCount: Int                              │
│ hintsUsed: Int                                  │
│ moveHistory: String (JSON array)                │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ Statistic (SQLite Table)                        │
├─────────────────────────────────────────────────┤
│ id: UUID (PK)                                   │
│ difficulty: String (enum) - UNIQUE INDEX        │
│ gamesPlayed: Int                                │
│ gamesCompleted: Int                             │
│ bestTime: Int?                                  │
│ averageTime: Int?                               │
│ totalTimeSpent: Int                             │
│ perfectGames: Int                               │
└─────────────────────────────────────────────────┘

Query Examples:
- Devam eden oyun: WHERE status = 'inProgress'
- En iyi 5 süre: ORDER BY timeElapsed ASC LIMIT 5
- İstatistik güncelle: UPDATE veya aggregate query
```


***

**Doküman Versiyonu:** 2.0 (MVP Revize)
**Son Güncelleme:** 13 Şubat 2026
**Hazırlayan:** Perplexity AI
**Durum:** MVP Focused ✅

***

## 🎯 Özet: Firebase'den SwiftData'ya Geçiş

| Özellik | Firebase (Önceki) | SwiftData (MVP) |
| :-- | :-- | :-- |
| **Auth** | Firebase Auth | ❌ Gerek yok |
| **Database** | Cloud Firestore | SwiftData (Local SQLite) |
| **Sync** | Realtime Database | ❌ v1.0'da yok (v2.0'da iCloud) |
| **Puzzle Gen** | Cloud Functions | Client-side (Swift) |
| **Offline** | Cache mekanizması | Native offline (her şey local) |
| **Maliyet** | \$\$ | \$0 |
| **Karmaşıklık** | 🔴 Yüksek | 🟢 Düşük |

Şimdi bu PRD ile rahatça başlayabilirsin! İlk adım: **SwiftData setup ve GameSession modelini yazmak**. Yardım istersen buradayım! 🚀

<div align="center">⁂</div>

[^1]: https://productschool.com/blog/product-strategy/product-template-requirements-document-prd

[^2]: https://github.com/sashankg/Sudoku

