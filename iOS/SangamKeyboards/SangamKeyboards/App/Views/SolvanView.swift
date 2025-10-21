import SwiftUI

struct SolvanView: View {
    @State private var text: String = ""
    @State private var isKeyboardVisible: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TextEditor(text: $text)
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "clear")
                    }
                    .disabled(text.isEmpty)
                    
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .disabled(!isKeyboardVisible)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
    }
}

#Preview {
    SolvanView()
}