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
            FilePickerView(selectedPath: $selectedPath)
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
                                Text("Brak qemu-img!")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("Zainstaluj qemu przez Homebrew: brew install qemu")
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
                                Text("Używa wbudowanej wersji qemu-img")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Dla lepszej kompatybilności zainstaluj najnowszą wersję przez Homebrew: brew install qemu")
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
                                Text("Używa systemowej instalacji qemu-img")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("Wszystko jest poprawnie skonfigurowane.")
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
            Label("Ogólne", systemImage: "gear")
        }
    }
    
    private var appearanceSettingsTab: some View {
        Form {
            GroupBox(label: Label("appearance_label".localized, systemImage: "paintbrush")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wybierz motyw kolorystyczny aplikacji")
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
                    Text("Wybierz język interfejsu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedLanguage) {
                        Label("language_system".localized, systemImage: "globe").tag("system")
                        Label("language_en".localized, systemImage: "flag").tag("en")
                        Label("language_pl".localized, systemImage: "flag").tag("pl")
                        Label("language_de".localized, systemImage: "flag").tag("de")
                        Label("language_fr".localized, systemImage: "flag").tag("fr")
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
            Label("Wygląd", systemImage: "paintbrush")
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
