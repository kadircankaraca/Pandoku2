//
//  LocalizationManager.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("appLanguage") var currentLanguage: LanguageOption = .turkish {
        didSet {
            Bundle.setLanguage(currentLanguage.rawValue)
            objectWillChange.send()
        }
    }
    
    private init() {
        Bundle.setLanguage(currentLanguage.rawValue)
    }
    
    func localizedString(_ key: String) -> String {
        Bundle.localizedBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension Bundle {
    private static var bundleKey: UInt8 = 0
    
    static var localizedBundle: Bundle {
        if let bundle = objc_getAssociatedObject(Bundle.main, &bundleKey) as? Bundle {
            return bundle
        }
        return Bundle.main
    }
    
    static func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle.main, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// String extension for easy localization
extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }
}
