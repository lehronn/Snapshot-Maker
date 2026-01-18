import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"
    @State private var selectedPath: String = ""
    @State private var showingFilePicker = false
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section(header: Text("scan_location".localized)) {
                    HStack {
                        TextField("scan_path".localized, text: $selectedPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("choose".localized) {
                            showingFilePicker = true
                        }
                    }
                    
                    Button("scan_button".localized) {
                        appState.scanPath = selectedPath
                        appState.scan()
                    }
                    .disabled(selectedPath.isEmpty)
                }
                
                Section(header: Text("qemu_status_label".localized)) {
                    if appState.missingDependencies {
                        Text("missing_dependencies_message".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if appState.usingEmbeddedQemu {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("qemu_status_embedded".localized)
                                .font(.body)
                                .foregroundColor(.orange)
                            
                            Text("qemu_warning_message".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("qemu_status_system".localized)
                            .font(.body)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .frame(width: 500, height: 350)
            .tabItem {
                Label("general_settings".localized, systemImage: "gear")
            }
            
            // Appearance Settings
            Form {
                Section(header: Text("appearance_label".localized)) {
                    Picker("appearance_label".localized, selection: $appAppearance) {
                        Text("appearance_system".localized).tag("system")
                        Text("appearance_light".localized).tag("light")
                        Text("appearance_dark".localized).tag("dark")
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Section(header: Text("language_label".localized)) {
                    Picker("language_label".localized, selection: $selectedLanguage) {
                        Text("language_system".localized).tag("system")
                        Text("language_en".localized).tag("en")
                        Text("language_pl".localized).tag("pl")
                        Text("language_de".localized).tag("de")
                        Text("language_fr".localized).tag("fr")
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            .padding()
            .frame(width: 500, height: 350)
            .tabItem {
                Label("appearance_settings".localized, systemImage: "paintbrush")
            }
        }
        .onAppear {
            selectedPath = appState.scanPath
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView(selectedPath: $selectedPath)
        }
    }
}

struct FilePickerView: NSViewRepresentable {
    @Binding var selectedPath: String
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
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedPath = url.path
            }
        }
        dismiss()
    }
}
