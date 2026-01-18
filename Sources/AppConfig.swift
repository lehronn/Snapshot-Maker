import Foundation

/// Configuration constants for the Snapshot Maker application
enum AppConfig {
    /// Default scan path for VM images
    static let defaultScanPath = NSHomeDirectory() + "/Library/Containers/"
    
    /// Application version
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }
    
    /// Application name
    static let appName = "Snapshot Maker"
    
    /// Author information
    static let authorName = "Mateusz Stomski"
    static let authorEmail = "mateusz.stomski@gmail.com"
    
    /// QEMU binary paths
    enum QEMU {
        /// System qemu-img path (Homebrew default on Apple Silicon)
        static let systemPath = "/opt/homebrew/bin/qemu-img"
        
        /// Embedded qemu-img path (bundled with app)
        static var embeddedPath: String? {
            Bundle.main.path(forAuxiliaryExecutable: "qemu-img")
        }
    }
}
