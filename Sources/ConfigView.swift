import SwiftUI

struct ConfigView: View {
    let configPath: String
    @State private var configData: [String: Any] = [:]
    @State private var searchText = ""
    
    @State private var showExportSuccess = false
    @State private var exportError: String?
    
    var body: some View {
        VStack {
            if configData.isEmpty {
                Text("loading_config".localized)
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(sortedKeys, id: \.self) { key in
                        if let value = configData[key] {
                            VStack(alignment: .leading) {
                                Text(key)
                                    .font(.headline)
                                Text(formatValue(value))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .searchable(text: $searchText)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: exportConfig) {
                    Label("export_config".localized, systemImage: "square.and.arrow.up")
                }
            }
        }
        .alert(isPresented: $showExportSuccess) {
            Alert(title: Text("success_title".localized), message: Text("config_export_success".localized), dismissButton: .default(Text("ok".localized)))
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func formatValue(_ value: Any) -> String {
        if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number.stringValue
        } else if let array = value as? [Any] {
            return array.description
        } else if let dict = value as? [String: Any] {
            return dict.description
        }
        return String(describing: value)
    }

    private func exportConfig() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.propertyList]
        savePanel.nameFieldStringValue = "config.plist"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try FileManager.default.copyItem(atPath: configPath, toPath: url.path)
                showExportSuccess = true
            } catch {
                if let data = FileManager.default.contents(atPath: configPath) {
                    do {
                        try data.write(to: url)
                        showExportSuccess = true
                    } catch {
                        print("Export failed: \(error)")
                    }
                }
            }
        }
    }
    
    var sortedKeys: [String] {
        let keys = configData.keys.sorted()
        if searchText.isEmpty {
            return keys
        } else {
            return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func loadConfig() {
        guard let data = FileManager.default.contents(atPath: configPath) else { return }
        do {
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                self.configData = plist
            }
        } catch {
            print("Error parsing plist: \(error)")
        }
    }
}
