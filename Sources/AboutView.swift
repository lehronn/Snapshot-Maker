import SwiftUI

struct AboutView: View {
    @State private var showLicense = false
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            if let iconImage = NSImage(named: "AppIcon") {
                Image(nsImage: iconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .cornerRadius(18)
            }
            
            VStack(spacing: 5) {
                Text(AppConfig.appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("v\(AppConfig.appVersion)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("\("about_author".localized): \(AppConfig.authorName)")
                    .font(.body)
                
                Link(AppConfig.authorEmail, destination: URL(string: "mailto:\(AppConfig.authorEmail)")!)
                    .font(.body)
                    .foregroundColor(.accentColor)
            }
            .padding(.vertical, 5)
            
            Text("about_disclaimer".localized)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Divider()
            
            Button("about_license_button".localized) {
                showLicense = true
            }
            .buttonStyle(.link)
            .padding(.bottom, 10)
        }
        .frame(width: 400, height: 450)
        .padding()
        .sheet(isPresented: $showLicense) {
            LicenseView()
        }
    }
}

struct LicenseView: View {
    @Environment(\.dismiss) var dismiss
    
    let mitLicense = """
    MIT License
    
    Copyright (c) 2026 Mateusz Stomski
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    """
    
    var body: some View {
        VStack {
            HStack {
                Text("license_title".localized)
                    .font(.headline)
                Spacer()
                Button("ok_button".localized) {
                    dismiss()
                }
            }
            .padding()
            
            ScrollView {
                Text(mitLicense)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .padding([.horizontal, .bottom])
        }
        .frame(width: 500, height: 400)
    }
}
