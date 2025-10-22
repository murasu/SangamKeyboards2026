import SwiftUI
import AnjalKeyTranslator

struct ContentView: View {
    @State private var translator: MultilingualKeyTranslator?
    @State private var selectedLanguage: MultilingualKeyTranslator.Language = .tamil
    @State private var selectedLayout: MultilingualKeyTranslator.KeyboardLayout = .anjal
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Multilingual Key Translator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Language and Layout Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Language:")
                        .fontWeight(.medium)
                    
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(MultilingualKeyTranslator.Language.allCases, id: \.self) { language in
                            Text(language.name).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedLanguage) { newValue in
                        setupTranslator()
                    }
                }
                
                HStack {
                    Text("Layout:")
                        .fontWeight(.medium)
                    
                    Picker("Layout", selection: $selectedLayout) {
                        ForEach(MultilingualKeyTranslator.KeyboardLayout.allCases, id: \.self) { layout in
                            Text(layout.name).tag(layout)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedLayout) { newValue in
                        translator?.setLayout(newValue)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Input (Key Codes):")
                    .fontWeight(.medium)
                
                TextField("Enter key codes (space-separated)", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        translateInput()
                    }
                
                Button("Translate") {
                    translateInput()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Output Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Output:")
                    .fontWeight(.medium)
                
                ScrollView {
                    Text(outputText.isEmpty ? "Translation will appear here..." : outputText)
                        .foregroundColor(outputText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
                .frame(minHeight: 100)
            }
            
            // Error Display
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            setupTranslator()
        }
    }
    
    private func setupTranslator() {
        do {
            translator = try MultilingualKeyTranslator(
                language: selectedLanguage,
                layout: selectedLayout
            )
            errorMessage = ""
        } catch {
            errorMessage = "Failed to initialize translator: \(error.localizedDescription)"
            translator = nil
        }
    }
    
    private func translateInput() {
        guard let translator = translator else {
            errorMessage = "Translator not initialized"
            return
        }
        
        let keyCodes = inputText
            .split(separator: " ")
            .compactMap { Int32($0) }
        
        guard !keyCodes.isEmpty else {
            errorMessage = "Please enter valid key codes"
            return
        }
        
        var results: [String] = []
        var totalDeletions = 0
        
        for keyCode in keyCodes {
            let result = translator.translateKey(keyCode: keyCode)
            if !result.text.isEmpty {
                results.append(result.text)
            }
            totalDeletions += result.deletions
        }
        
        outputText = results.joined()
        
        if totalDeletions > 0 {
            outputText += " (Deletions needed: \(totalDeletions))"
        }
        
        errorMessage = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}