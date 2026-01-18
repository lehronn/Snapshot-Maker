import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var vms: [VirtualMachine] = []
    @Published var selectedVM: VirtualMachine?
    @AppStorage("scanPath") var scanPath: String = AppConfig.defaultScanPath
    @AppStorage("scanPathBookmark") var scanPathBookmark: Data = Data()
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"
    @Published var missingDependencies: Bool = false
    @Published var usingEmbeddedQemu: Bool = false
    
    private var lastScanUrl: URL?
    
    /// Scan the specified directory for VM images (.qcow2 and .utm)
    func scan() {
        let qemuStatus = QemuManager.shared.checkDependencies()
        
        DispatchQueue.main.async {
            self.usingEmbeddedQemu = qemuStatus.usingEmbedded
            self.missingDependencies = !qemuStatus.available
        }
        
        if !qemuStatus.available {
            return
        }
        
        // Resolve security scoped bookmark if available
        var url: URL?
        var isStale = false
        
        if !scanPathBookmark.isEmpty {
            do {
                url = try URL(resolvingBookmarkData: scanPathBookmark,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
                
                if let url = url {
                    if isStale {
                        // Bookmark is stale, we might want to regenerate it if possible,
                        // but for now we just use it.
                        print("Bookmark is stale")
                    }
                    
                    if url.startAccessingSecurityScopedResource() {
                        print("Accessed security scoped resource: \(url.path)")
                        // Remember to stop accessing later if needed, but for a long lived app
                        // keeping it open might be what we want for this session, or stop after scan.
                        // For this app, we'll keep it simple and just start accessing.
                        // Ideally we should defer stopAccessing.
                    } else {
                         print("Failed to access security scoped resource")
                    }
                }
            } catch {
                print("Error resolving bookmark: \(error)")
            }
        }
        
        // Fallback to path if bookmark failed or empty
        if url == nil {
             url = URL(fileURLWithPath: scanPath)
        }
        
        guard let scanUrl = url else { return }
        lastScanUrl = scanUrl
        
        DispatchQueue.global(qos: .userInitiated).async {
            let found = QemuManager.shared.scanForImages(at: scanUrl)
            
            // We can stop accessing here if we want to be strict, but if the user
            // wants to perform actions on these files later, we might need to keep it open
            // or resolve again. For scanning, this is fine.
            // scanUrl.stopAccessingSecurityScopedResource() 
            
            DispatchQueue.main.async {
                self.vms = found
            }
        }
    }
}
