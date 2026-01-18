import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"
    @State private var selectedPath: String = ""
    @State private var showingFilePicker = false
    
    var body: some View {
        TabView {
            generalSettingsTab
            appearanceSettingsTab
        }
        .onAppear {
            selectedPath = appState.scanPath
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView(selectedPath: $selectedPath, 
                         initialPath: AppConfig.defaultScanPath) { url in
                saveBookmark(for: url)
            }
        }
    }
    
    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope,
                                          includingResourceValuesForKeys: nil,
                                          relativeTo: nil)
            appState.scanPathBookmark = data
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
    
    private var generalSettingsTab: some View {
        Form {
            GroupBox(label: Label("scan_location".localized, systemImage: "folder")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("scan_path".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("", text: $selectedPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("choose".localized) {
                            showingFilePicker = true
                        }
                    }
                    
                    // Grant Access Button for Settings
                    Button(action: { showingFilePicker = true }) {
                        Label("grant_access_button".localized, systemImage: "key.fill")
                    }
                    .controlSize(.small)
                     .padding(.top, 4)
                    
                    Button("scan_button".localized) {
                        appState.scanPath = selectedPath
                        appState.scan()
                    }
                    .disabled(selectedPath.isEmpty)
                }
                .padding(8)
            }
            
            GroupBox(label: Label("qemu_status_label".localized, systemImage: "terminal")) {
                VStack(alignment: .leading, spacing: 12) {
                    if appState.missingDependencies {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("qemu_status_missing_title".localized)
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("qemu_status_missing_desc".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    } else if appState.usingEmbeddedQemu {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("qemu_status_embedded_title".localized)
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("qemu_status_embedded_desc".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("qemu_status_system_title".localized)
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("qemu_status_system_desc".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(8)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 550, height: 400)
        .tabItem {
            Label("settings_tab_general".localized, systemImage: "gear")
        }
    }
    
    private var appearanceSettingsTab: some View {
        Form {
            GroupBox(label: Label("appearance_label".localized, systemImage: "paintbrush")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("settings_appearance_desc".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $appAppearance) {
                        Label("appearance_system".localized, systemImage: "computermouse").tag("system")
                        Label("appearance_light".localized, systemImage: "sun.max").tag("light")
                        Label("appearance_dark".localized, systemImage: "moon").tag("dark")
                    }
                    .pickerStyle(.radioGroup)
                }
                .padding(8)
            }
            
            GroupBox(label: Label("language_label".localized, systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("settings_language_desc".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedLanguage) {
                        Label("language_system".localized, systemImage: "globe").tag("system")
                        Label("language_en".localized, systemImage: "flag").tag("en")
                        Label("language_pl".localized, systemImage: "flag").tag("pl")
                        Label("language_de".localized, systemImage: "flag").tag("de")
                        Label("language_fr".localized, systemImage: "flag").tag("fr")
                        Label("language_es".localized, systemImage: "flag").tag("es")
                        Label("language_it".localized, systemImage: "flag").tag("it")
                    }
                    .pickerStyle(.radioGroup)
                }
                .padding(8)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 550, height: 400)
        .tabItem {
            Label("settings_tab_appearance".localized, systemImage: "paintbrush")
        }
    }}

struct FilePickerView: NSViewRepresentable {
    @Binding var selectedPath: String
    var initialPath: String? = nil
    var onSelect: ((URL) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.showPicker()
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func showPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "scan_location".localized
        
        if let initialPath = initialPath, !initialPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: initialPath)
        } else if !selectedPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: selectedPath)
        } else {
            // Default to Home if nothing set
            panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
        }
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedPath = url.path
                onSelect?(url)
            }
        }
        dismiss()
    }
}
