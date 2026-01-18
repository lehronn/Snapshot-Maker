import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with VM list
            sidebarView
        } detail: {
            if let vm = appState.selectedVM {
                VMDetailView(vm: vm, appState: appState)
                    .id(vm.id)
            } else {
                WelcomeView()
            }
        }
        .alert(isPresented: $appState.missingDependencies) {
            Alert(
                title: Text("missing_dependencies_title".localized),
                message: Text("missing_dependencies_message".localized),
                dismissButton: .default(Text("ok_button".localized))
            )
        }
    }
    
    private var sidebarView: some View {
        List(appState.vms, selection: $appState.selectedVM) { vm in
            NavigationLink(value: vm) {
                HStack {
                    Image(systemName: vm.format == "utm" ? "desktopcomputer" : "internaldrive")
                    Text(vm.displayName)
                }
            }
        }
        .navigationTitle("vm_list_title".localized)
        .listStyle(SidebarListStyle())
        .safeAreaInset(edge: .bottom) {
            bottomToolbar
        }
    }
    
    private var bottomToolbar: some View {
        VStack {
            // Show warning banner if using embedded qemu
            if appState.usingEmbeddedQemu {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("qemu_status_embedded".localized)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
            
            Button(action: { appState.scan() }) {
                Label("scan_button".localized, systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct VMDetailView: View {
    let vm: VirtualMachine
    @ObservedObject var appState: AppState
    @State private var error: AlertMessage?
    @State private var selectedDisk: VirtualMachine?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            vmHeaderView
            if let disks = vm.disks, !disks.isEmpty {
                Divider()
                diskListView(disks: disks)
            }
            Divider()
            snapshotSectionView
        }
        .padding()
        .alert(item: $error) { alertMsg in
            Alert(
                title: Text("error_title".localized),
                message: Text(alertMsg.message),
                dismissButton: .default(Text("ok_button".localized))
            )
        }
        .onAppear {
            autoSelectFirstDisk()
        }
    }
    
    private var vmHeaderView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: vm.format == "utm" ? "desktopcomputer" : "internaldrive")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(vm.displayName)
                        .font(.largeTitle)
                    
                    Text("Format: \(vm.format)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let configPath = vm.configPath {
                        Button("view_config".localized) {
                            openConfigWindow(path: configPath)
                        }
                        .padding(.top, 5)
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
            }
            
            pathInfoView
        }
        .padding()
    }
    
    private var pathInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("path_label".localized + ": \(vm.path)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: showInFinder) {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Show VM description/notes if available
            if let desc = vm.vmDescription, !desc.isEmpty {
                Text("Notatki: \(desc)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
    
    private func diskListView(disks: [VirtualMachine]) -> some View {
        VStack(alignment: .leading) {
            Text("disks_label".localized)
                .font(.headline)
                .padding(.horizontal)
            
            List(disks, selection: $selectedDisk) { disk in
                VStack(alignment: .leading) {
                    Text(disk.displayName)
                        .font(.body)
                    
                    Text("Size: \(disk.size)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(disk.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Button(action: { showDiskInFinder(disk) }) {
                            Image(systemName: "folder")
                                .font(.caption)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .tag(disk)
            }
            .frame(height: 150)
        }
    }
    
    private var snapshotSectionView: some View {
        SnapshotView(vm: selectedDisk ?? (vm.disks?.first ?? vm))
            .id(selectedDisk?.id ?? (vm.disks?.first?.id ?? vm.id))
    }
    
    private func showInFinder() {
        NSWorkspace.shared.selectFile(vm.path, inFileViewerRootedAtPath: "")
    }
    
    private func showDiskInFinder(_ disk: VirtualMachine) {
        NSWorkspace.shared.selectFile(disk.path, inFileViewerRootedAtPath: "")
    }
    
    private func openConfigWindow(path: String) {
        let configView = ConfigView(configPath: path)
        let controller = NSHostingController(rootView: configView)
        let window = NSWindow(contentViewController: controller)
        window.title = "config_title".localized
        window.styleMask = [.titled, .closable, .resizable]
        window.minSize = NSSize(width: 400, height: 500)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    private func autoSelectFirstDisk() {
        if let disks = vm.disks, !disks.isEmpty {
            selectedDisk = disks.first
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)
            
            Text("welcome_title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("welcome_message".localized)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
            
            Divider()
                .frame(width: 300)
            
            VStack(spacing: 8) {
                Text("welcome_default_path_prefix".localized)
                    .font(.headline)
                
                Text(AppConfig.defaultScanPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
                
                Text("welcome_settings_hint".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Spacer()
                .frame(height: 20)
            
            Text("welcome_footer".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}
