import Foundation

/// Manager class for interacting with qemu-img
class QemuManager {
    static let shared = QemuManager()
    
    // MARK: - Configuration
    
    /// Active qemu-img path (determined at runtime)
    private var qemuImgPath: String = ""
    private var isUsingEmbedded: Bool = false
    
    private init() {
        // Determine which qemu-img to use
        let fileManager = FileManager.default
        
        // Prefer system installation
        if fileManager.fileExists(atPath: AppConfig.QEMU.systemPath) {
            qemuImgPath = AppConfig.QEMU.systemPath
            isUsingEmbedded = false
        }
        // Fall back to embedded
        else if let embeddedPath = AppConfig.QEMU.embeddedPath,
                fileManager.fileExists(atPath: embeddedPath) {
            qemuImgPath = embeddedPath
            isUsingEmbedded = true
        }
    }
    
    // MARK: - Dependency Checking
    
    /// Check if qemu-img is available
    /// - Returns: Tuple with availability status and whether embedded binary is being used
    func checkDependencies() -> (available: Bool, usingEmbedded: Bool) {
        return (!qemuImgPath.isEmpty, isUsingEmbedded)
    }
    
    // MARK: - Disk Path Resolution
    
    private func resolveDiskPath(for vm: VirtualMachine) throws -> String {
        if vm.format == "utm" {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: vm.path), includingPropertiesForKeys: nil)
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension == "qcow2" {
                    return fileURL.path
                }
            }
            throw NSError(domain: "QemuManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No qcow2 image found inside .utm package"])
        }
        return vm.path
    }
    
    // MARK: - VM Scanning
    
    func scanForImages(at url: URL) -> [VirtualMachine] {
        var vms: [VirtualMachine] = []
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            // Check for .utm DIRECTORIES first
            if fileURL.pathExtension == "utm" {
                // Find all .qcow2 files inside this .utm package
                var disks: [VirtualMachine] = []
                let utmEnumerator = fileManager.enumerator(at: fileURL, includingPropertiesForKeys: [.fileSizeKey])
                
                while let diskURL = utmEnumerator?.nextObject() as? URL {
                    if diskURL.pathExtension == "qcow2" {
                        let diskSize = getFileSize(url: diskURL)
                        disks.append(VirtualMachine(
                            name: diskURL.lastPathComponent,
                            path: diskURL.path,
                            format: "qcow2",
                            size: diskSize,
                            disks: nil,
                            configPath: nil
                        ))
                    }
                }
                
                // Create UTM entry with disks as children
                let utmSize = getFileSize(url: fileURL)
                
                // Check for config.plist
                var configPath: String? = nil
                let potentialConfig = fileURL.appendingPathComponent("config.plist")
                if fileManager.fileExists(atPath: potentialConfig.path) {
                    configPath = potentialConfig.path
                }
                
                vms.append(VirtualMachine(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    format: "utm",
                    size: utmSize,
                    disks: disks.isEmpty ? nil : disks,
                    configPath: configPath
                ))
                
                // Skip descending into .utm since we already processed it
                enumerator?.skipDescendants()
            }
            // Check for standalone .qcow2 FILES
            else if fileURL.pathExtension == "qcow2" {
                let size = getFileSize(url: fileURL)
                vms.append(VirtualMachine(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    format: "qcow2",
                    size: size,
                    disks: nil,
                    configPath: nil
                ))
            }
        }
        return vms
    }
    
    private func getFileSize(url: URL) -> String {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            print("Error getting size: \(error)")
        }
        return "Unknown"
    }
    
    // MARK: - Snapshot Operations
    
    func createSnapshot(vm: VirtualMachine, name: String) throws {
        let path = try resolveDiskPath(for: vm)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: qemuImgPath)
        process.arguments = ["snapshot", "-c", name, path]
        
        try runProcess(process)
    }
    
    func deleteSnapshot(vm: VirtualMachine, name: String) throws {
        let path = try resolveDiskPath(for: vm)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: qemuImgPath)
        process.arguments = ["snapshot", "-d", name, path]
        
        try runProcess(process)
    }
    
    func restoreSnapshot(vm: VirtualMachine, name: String) throws {
        let path = try resolveDiskPath(for: vm)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: qemuImgPath)
        process.arguments = ["snapshot", "-a", name, path]
        
        try runProcess(process)
    }
    
    func listSnapshots(vm: VirtualMachine) -> [Snapshot] {
        guard let path = try? resolveDiskPath(for: vm) else { return [] }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: qemuImgPath)
        process.arguments = ["snapshot", "-l", path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return parseSnapshotOutput(output)
            }
        } catch {
            print("Error listing snapshots: \(error)")
        }
        return []
    }
    
    // MARK: - Helper Methods
    
    private func runProcess(_ process: Process) throws {
        let errPipe = Pipe()
        process.standardError = errPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "QemuManager", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errStr])
        }
    }
    
    private func parseSnapshotOutput(_ output: String) -> [Snapshot] {
        var snapshots: [Snapshot] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Expected format: ID TAG VM-SIZE DATE TIME
            if parts.count >= 5 {
                // Check if first column is a digit (snapshot ID)
                if let _ = Int(parts[0]) {
                     let id = parts[0]
                     let tag = parts[1]
                     let size = parts[2]
                     let dateCode = parts[3] + " " + parts[4]
                     snapshots.append(Snapshot(id: id, tag: tag, date: dateCode, vmSize: size))
                }
            }
        }
        return snapshots
    }
}
