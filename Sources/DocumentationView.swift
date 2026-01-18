import SwiftUI

struct DocumentationView: View {
    @State private var documentationContent: String = "Loading..."
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"

    var body: some View {
        ScrollView {
            Text(documentationContent)
                .font(.system(.body, design: .default))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            loadDocumentation()
        }
        .onChange(of: selectedLanguage) { _ in
            loadDocumentation()
        }
    }

    private func loadDocumentation() {
        // Determine which documentation to load based on language
        let docLanguage: String
        if selectedLanguage == "system" {
            // Get system language
            if let systemLang = Locale.preferredLanguages.first?.prefix(2) {
                docLanguage = String(systemLang)
            } else {
                docLanguage = "en"
            }
        } else {
            docLanguage = selectedLanguage
        }
        
        // Try to load language-specific documentation
        var docName = "DOCUMENTATION"
        if docLanguage == "pl" {
            docName = "DOCUMENTATION_PL"
        }
        // Default to English for de and fr until translations are available
        
        if let path = Bundle.main.path(forResource: docName, ofType: "md") {
            do {
                documentationContent = try String(contentsOfFile: path)
            } catch {
                documentationContent = "Error loading documentation: \(error.localizedDescription)"
            }
        } else {
            documentationContent = "Documentation file not found.\n\nPlease refer to README.md in the application repository."
        }
    }
}
