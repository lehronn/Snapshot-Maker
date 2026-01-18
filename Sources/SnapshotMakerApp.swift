import SwiftUI

@main
struct SnapshotMakerApp: App {
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appearance(for: appAppearance))
                .id(selectedLanguage) // Force redraw on language change
                .onAppear {
                    // Apply language preference
                    applyLanguagePreference()
                    // Perform initial scan
                    appState.scan()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Modern look
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .id(selectedLanguage)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("menu_about".localized) {
                    openAboutWindow()
                }
            }
            CommandGroup(replacing: .help) {
                Button("menu_documentation".localized) {
                    openDocumentationWindow()
                }
            }
        }
    }
    
    func appearance(for selection: String) -> ColorScheme? {
        switch selection {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private func applyLanguagePreference() {
        if selectedLanguage != "system" {
            UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
        }
    }
    
    private func openAboutWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "about_window" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let aboutView = AboutView()
            let controller = NSHostingController(rootView: aboutView)
            let window = NSWindow(contentViewController: controller)
            window.title = "menu_about".localized
            window.identifier = NSUserInterfaceItemIdentifier("about_window")
            window.styleMask = [.titled, .closable]
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func openDocumentationWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "documentation_window" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let docView = DocumentationView()
            let controller = NSHostingController(rootView: docView)
            let window = NSWindow(contentViewController: controller)
            window.title = "menu_documentation".localized
            window.identifier = NSUserInterfaceItemIdentifier("documentation_window")
            window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            window.setContentSize(NSSize(width: 800, height: 600))
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
