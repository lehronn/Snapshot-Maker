import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var vms: [VirtualMachine] = []
    @Published var selectedVM: VirtualMachine?
    @AppStorage("scanPath") var scanPath: String = AppConfig.defaultScanPath
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
        
        let url = URL(fileURLWithPath: scanPath)
        lastScanUrl = url
        DispatchQueue.global(qos: .userInitiated).async {
            let found = QemuManager.shared.scanForImages(at: url)
            DispatchQueue.main.async {
                self.vms = found
            }
        }
    }
}
