import Foundation
import SwiftUI

extension String {
    /// Returns localized string for the current key
    var localized: String {
        return self.localized()
    }
    
    /// Returns localized string with proper locale detection
    private func localized(arguments: [CVarArg] = []) -> String {
        // Get selected language from UserDefaults
        let selectedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        
        // Determine which language to use
        let languageCode: String
        if selectedLang == "system" {
            // Auto-detect from system
            if let systemLang = Locale.preferredLanguages.first {
                languageCode = String(systemLang.prefix(2))
            } else {
                languageCode = "en"
            }
        } else {
            languageCode = selectedLang
        }
        
        // Try to load from bundle with specific language
        if let bundlePath = Bundle.main.path(forResource: "SnapshotMaker_SnapshotMaker", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath),
           let langPath = bundle.path(forResource: languageCode, ofType: "lproj"),
           let langBundle = Bundle(path: langPath) {
            let localizedString = NSLocalizedString(self, bundle: langBundle, comment: "")
            if arguments.isEmpty {
                return localizedString
            } else {
                return String(format: localizedString, arguments: arguments)
            }
        }
        
        // Fallback
        if arguments.isEmpty {
            return self
        } else {
            return String(format: self, arguments: arguments)
        }
    }
    
    /// Returns localized string with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        return self.localized(arguments: arguments)
    }
}
