import Foundation

struct VirtualMachine: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let format: String // "qcow2" or "utm"
    let size: String 
    var disks: [VirtualMachine]? // For UTM packages containing multiple disks
    var configPath: String? // Path to config.plist if available
    
    // Derived property for display
    var displayName: String {
        if format == "utm" {
            return name.replacingOccurrences(of: ".utm", with: "")
        }
        return name
    }
}

struct Snapshot: Identifiable, Hashable {
    let id: String // The ID from qemu-img
    let tag: String
    let date: String
    let vmSize: String
}
