import SwiftUI
import UIKit
import KeyboardCore

struct KeyboardPreviewView: View {
    @State private var inputText: String = ""
    @State private var selectedLanguage: LanguageId = .tamil
    @State private var keyboardState: KeyboardState = .normal
    @State private var isShiftLocked: Bool = false
    @State private var currentComposition: String = ""
    
    // Available languages for testing
    private let availableLanguages: [LanguageId] = [
        .tamil, .tamilAnjal, .malayalam, .malayalamAnjal, .hindi, .bengali,
        .gujarati, .kannada, .kannadaAnjal, .punjabi, .telugu, .teluguAnjal,
        .marathi, .oriya, .assamese, .sinhala, .jawi, .qwertyJawi,
        .grantha, .sanskrit, .nepali, .english
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Language Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Keyboard:")
                    .font(.headline)
                
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(availableLanguages, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            
            // Input Text Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Text:")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .frame(minHeight: 100)
                    .font(.system(size: 18))
            }
            
            // Composition Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Composition:")
                    .font(.headline)
                
                Text(currentComposition.isEmpty ? "(empty)" : currentComposition)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                    .font(.system(size: 16))
            }
            
            // Keyboard State Display
            HStack {
                Text("State: \(keyboardStateText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    inputText = ""
                    currentComposition = ""
                }
                .buttonStyle(.bordered)
            }
            
            // Embedded Keyboard - Uses KeyboardMetrics for accurate height
            KeyboardPreviewContainer(
                selectedLanguage: $selectedLanguage,
                keyboardState: $keyboardState,
                isShiftLocked: $isShiftLocked,
                currentComposition: $currentComposition,
                onTextInput: { text in
                    inputText += text
                },
                onDeleteBackward: { count in
                    for _ in 0..<count {
                        if !inputText.isEmpty {
                            inputText.removeLast()
                        }
                    }
                }
            )
            .frame(height: keyboardPreviewHeight)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(8)
            .clipped()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Keyboard Preview")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var keyboardStateText: String {
        switch keyboardState {
        case .normal:
            return "Normal"
        case .shifted:
            return isShiftLocked ? "CAPS LOCK" : "Shifted"
        case .symbols:
            return "Symbols"
        case .shiftedSymbols:
            return "Shifted Symbols"
        @unknown default:
            return "Unknown"
        }
    }
    
    // Use KeyboardMetrics for consistent height calculation
    private var keyboardPreviewHeight: CGFloat {
        // Create a fake trait collection to pass to KeyboardMetrics
        // For preview, we'll use portrait orientation
        let traitCollection = UITraitCollection(verticalSizeClass: .regular)
        
        return KeyboardMetrics.keyboardHeight(
            for: traitCollection,
            includesCandidateBar: true,
            useAnnotatedCandidates: false
        )
    }
}

// MARK: - UIKit Container for Keyboard

struct KeyboardPreviewContainer: UIViewControllerRepresentable {
    @Binding var selectedLanguage: LanguageId
    @Binding var keyboardState: KeyboardState
    @Binding var isShiftLocked: Bool
    @Binding var currentComposition: String
    
    let onTextInput: (String) -> Void
    let onDeleteBackward: (Int) -> Void
    
    func makeUIViewController(context: Context) -> KeyboardPreviewViewController {
        let controller = KeyboardPreviewViewController()
        controller.selectedLanguage = selectedLanguage
        controller.onTextInput = onTextInput
        controller.onDeleteBackward = onDeleteBackward
        controller.onStateChange = { state, locked, composition in
            keyboardState = state
            isShiftLocked = locked
            currentComposition = composition
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: KeyboardPreviewViewController, context: Context) {
        // Update language if changed
        if uiViewController.selectedLanguage != selectedLanguage {
            uiViewController.updateLanguage(selectedLanguage)
        }
    }
}

// MARK: - Preview Controller

class KeyboardPreviewViewController: UIViewController {
    // MARK: - Properties
    var selectedLanguage: LanguageId = .tamil {
        didSet {
            if selectedLanguage != oldValue {
                logicController.setLanguage(selectedLanguage)
            }
        }
    }
    
    // MARK: - Configuration (matches KeyboardViewController)
    private var usesCandidateBar: Bool = true
    private var usesAnnotatedCandidates: Bool = false
    
    // MARK: - Logic Controller
    private var logicController: KeyboardLogicController!
    
    // MARK: - Callbacks
    var onTextInput: ((String) -> Void)?
    var onDeleteBackward: ((Int) -> Void)?
    var onStateChange: ((KeyboardState, Bool, String) -> Void)?
    
    // MARK: - UI Components
    private var keyboardContainer: UIView!
    private var candidateBarContainer: UIView!
    private var currentKeyboardView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLogicController()
        setupUI()
        buildKeyboard()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Rebuild keyboard when interface style changes (light/dark mode)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            buildKeyboard()
        }
    }
    
    private func setupLogicController() {
        logicController = KeyboardLogicController(
            language: selectedLanguage,
            appGroupIdentifier: "group.murasu.Sangam"
        )
        logicController.delegate = self
        logicController.themeObserver = self
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray5
        
        // Main container
        let mainContainer = UIView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Candidate bar (matching KeyboardViewController)
        if usesCandidateBar {
            candidateBarContainer = UIView()
            candidateBarContainer.translatesAutoresizingMaskIntoConstraints = false
            candidateBarContainer.backgroundColor = UIColor.systemGray6
            mainContainer.addSubview(candidateBarContainer)
            
            let candidateHeight = usesAnnotatedCandidates ?
                KeyboardMetrics.candidateBarHeightWithAnnotation :
                KeyboardMetrics.candidateBarHeight
            
            NSLayoutConstraint.activate([
                candidateBarContainer.topAnchor.constraint(equalTo: mainContainer.topAnchor),
                candidateBarContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
                candidateBarContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
                candidateBarContainer.heightAnchor.constraint(equalToConstant: candidateHeight)
            ])
            
            setupCandidateBar()
        }
        
        // Keyboard container
        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(keyboardContainer)
        
        NSLayoutConstraint.activate([
            keyboardContainer.topAnchor.constraint(
                equalTo: usesCandidateBar ? candidateBarContainer.bottomAnchor : mainContainer.topAnchor
            ),
            keyboardContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor)
        ])
    }
    
    private func setupCandidateBar() {
        // Simple placeholder for preview
        let label = UILabel()
        label.text = "Candidates (Preview Mode)"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        candidateBarContainer.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: candidateBarContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: candidateBarContainer.centerYAnchor)
        ])
    }
    
    private func buildKeyboard() {
        // Remove existing keyboard view
        currentKeyboardView?.removeFromSuperview()
        currentKeyboardView = nil
        
        guard let layout = logicController.getCurrentLayout() else {
            print("❌ Failed to get layout from logic controller for language: \(selectedLanguage)")
            showErrorMessage("Failed to load layout for \(selectedLanguage.displayName)")
            return
        }
        
        // Get theme from logic controller
        guard let theme = logicController.getCurrentTheme() else {
            print("❌ Failed to get theme from logic controller")
            showErrorMessage("Failed to load theme")
            return
        }
        
        let keyboardView = KeyboardBuilder.buildKeyboard(
            layout: layout,
            containerView: keyboardContainer,
            theme: theme,  // Pass theme
            shouldIncludeGlobeKey: true,
            viewController: nil
        ) { [weak self] key in
            self?.logicController.handleKeyPress(key)
        }
        
        keyboardContainer.addSubview(keyboardView)
        currentKeyboardView = keyboardView
        
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor)
        ])
        
        // Update shift key appearance with theme
        updateShiftKeys()
    }
    
    private func showErrorMessage(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        keyboardContainer.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: keyboardContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: keyboardContainer.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor, constant: -20)
        ])
    }
    
    private func updateShiftKeys() {
        guard let keyboardView = currentKeyboardView,
              let theme = logicController.getCurrentTheme() else { return }
        
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: logicController.keyboardState == .shifted,
            locked: logicController.isShiftLocked,
            theme: theme
        )
    }
    
    // MARK: - Public Methods
    func updateLanguage(_ language: LanguageId) {
        selectedLanguage = language
        logicController.setLanguage(language)
    }
    
    private func notifyStateChange() {
        onStateChange?(
            logicController.keyboardState,
            logicController.isShiftLocked,
            logicController.currentComposition
        )
    }
}

// MARK: - KeyboardLogicDelegate
extension KeyboardPreviewViewController: KeyboardLogicDelegate {
    func insertText(_ text: String) {
        onTextInput?(text)
        notifyStateChange()
    }
    
    func deleteBackward(count: Int) {
        onDeleteBackward?(count)
        notifyStateChange()
    }
    
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func updateKeyboardView() {
        DispatchQueue.main.async {
            self.buildKeyboard()
            self.notifyStateChange()
        }
    }
    
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle {
        return traitCollection.userInterfaceStyle
    }
    
    func switchToNextKeyboard() {
        print("🌐 Globe key tapped in preview mode")
    }
    
    func playKeyClickSound(soundID: UInt32) {
        // No sound in preview
    }
}

// MARK: - KeyboardThemeObserver
extension KeyboardPreviewViewController: KeyboardThemeObserver {
    func themeDidChange() {
        DispatchQueue.main.async {
            self.buildKeyboard()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        KeyboardPreviewView()
    }
}

