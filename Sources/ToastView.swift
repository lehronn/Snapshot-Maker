import SwiftUI

struct Toast: Equatable {
    enum ToastType {
        case success
        case error
    }
    
    let message: String
    let type: ToastType
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var showToast = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toast, showToast {
                    VStack {
                        HStack {
                            Image(systemName: toast.type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(toast.type == .success ? .green : .red)
                            
                            Text(toast.message)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.top, 50)
                        
                        Spacer()
                    }
                    .transition(.move(edge: . top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
            .onChange(of: toast) { newToast in
                if newToast != nil {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showToast = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.toast = nil
                        }
                    }
                }
            }
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
