//
//  KeyboardLogicController.swift
//  KeyboardCore
//
//  Created by Muthu Nedumaran on 26/09/2025.
//

import UIKit
import Foundation

// MARK: - Delegate Protocol
public protocol KeyboardLogicDelegate: AnyObject {
    func insertText(_ text: String)
    func deleteBackward(count: Int)
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle)
    func updateKeyboardView()
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle
    func switchToNextKeyboard()
    func playKeyClickSound(soundID: UInt32)
}

// MARK: - Theme Notification Protocol
public protocol KeyboardThemeObserver: AnyObject {
    func themeDidChange()
}

// MARK: - Main Controller
public class KeyboardLogicController {
    
    // MARK: - Properties
    public weak var delegate: KeyboardLogicDelegate?
    public weak var themeObserver: KeyboardThemeObserver?
    
    // MARK: - State Management
    public private(set) var currentLanguage: LanguageId {
        didSet {
            if currentLanguage != oldValue {
                updateTranslator()
                loadCurrentLayout()
            }
        }
    }
    
    public private(set) var keyboardState: KeyboardState = .normal {
        didSet {
            if keyboardState != oldValue {
                loadCurrentLayout()
                delegate?.updateKeyboardView()
            }
        }
    }
    
    public private(set) var isShiftLocked: Bool = false
    public private(set) var currentComposition: String = ""
    
    // MARK: - Internal Components
    private var currentTranslator: KeyTranslator?
    private var currentLayout: KeyboardLayout?

    // MARK: - Theme Management (around line 30)
    private var themeManager: ThemeManager
    private var themeObservation: NSKeyValueObservation?
    
    // MARK: - Initialization
    public init(language: LanguageId, appGroupIdentifier: String? = nil) {
        self.currentLanguage = language
        self.themeManager = ThemeManager(appGroupIdentifier: appGroupIdentifier)
        
        setupInitialState()
        observeThemeChanges()
    }
    
    deinit {
        themeObservation?.invalidate()
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        updateTranslator()
        loadCurrentLayout()
    }
    
    private func updateTranslator() {
        currentTranslator = KeyTranslatorFactory.getTranslator(for: currentLanguage)
    }
    
    private func loadCurrentLayout() {
        currentLayout = LayoutParser.loadLayout(for: currentLanguage, state: keyboardState)
        
        if currentLayout == nil {
            print("Warning: Failed to load layout for \(currentLanguage) - \(keyboardState)")
        } else {
            print("Successfully loaded layout for \(currentLanguage) - \(keyboardState)")
            // Notify delegate that layout changed and view needs updating
            delegate?.updateKeyboardView()
        }
    }
    
    // MARK: - Theme Management
    private func observeThemeChanges() {
        themeObservation = themeManager.observe(\.currentThemeId, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.themeObserver?.themeDidChange()
                self?.delegate?.updateKeyboardView()
            }
        }
    }
    
    public func getCurrentTheme() -> KeyboardTheme? {
        let interfaceStyle = delegate?.getCurrentInterfaceStyle() ?? .unspecified
        return themeManager.getCurrentTheme(for: interfaceStyle)
    }
    
    public func setTheme(_ themeId: String) {
        themeManager.setTheme(themeId)
    }

    public func getAvailableThemes() -> [(id: String, name: String)] {
        return themeManager.getAvailableThemes()
    }
    
    public func getCurrentThemeId() -> String {
        return themeManager.currentThemeId
    }
    
    /// Update all existing themes to use Tamil Sangam MN font
    public func updateAllThemesToTamilFont() {
        themeManager.updateAllThemesToTamilFont()
    }
    
    // MARK: - Public State Management
    public func setLanguage(_ language: LanguageId) {
        currentLanguage = language
    }
    
    public func getCurrentLayout() -> KeyboardLayout? {
        return currentLayout
    }
    
    // MARK: - Key Press Handling
    public func handleKeyPress(_ key: KeyboardKey) {
        //TODO: Remove after debug
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let keyCode = key.keyCode
        
        playClickSound(for: keyCode)
        
        switch keyCode {
        case -1: // Shift
            handleShift()
            
        case -2: // Mode change (123/ABC)
            handleModeChange()
            
        case -5: // Delete
            let deleteStart = CFAbsoluteTimeGetCurrent()
            handleDelete()
            let deleteEnd = CFAbsoluteTimeGetCurrent()
            print("🔴 Delete time: \((deleteEnd - deleteStart) * 1000)ms")
            autoUnshift()
            
        case -6: // Globe
            handleGlobe()
            
        case 32: // Space
            handleSpace()
            autoUnshift()
            
        case 10: // Return
            handleReturn()
            
        default:
            // Regular character input
            let translateStart = CFAbsoluteTimeGetCurrent()
            
            handleCharacterInput(keyCode: keyCode, label: key.keyLabel)
            
            let translateEnd = CFAbsoluteTimeGetCurrent()
            print("🔴 Translation time: \((translateEnd - translateStart) * 1000)ms")
            
            autoUnshift()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("🔴 Total handleKeyPress time: \((endTime - startTime) * 1000)ms")
    }
    
    private func playClickSound(for keyCode: Int) {
        if keyCode == -5 { // Delete
            delegate?.playKeyClickSound(soundID: 1155)
        } else if keyCode == 10 || keyCode == -6 || keyCode == -2 || keyCode == 32 || keyCode == -1 {
            // Return, Globe, Mode Change, Space, Shift
            delegate?.playKeyClickSound(soundID: 1156)
        } else {
            // Regular character keys
            delegate?.playKeyClickSound(soundID: 1123)
        }
    }
    
    // MARK: - Individual Key Handlers
    private func handleShift() {
        let previousState = keyboardState
        
        switch keyboardState {
        case .normal:
            keyboardState = .shifted
            isShiftLocked = false
            
        case .shifted:
            // Skip caps lock - go directly back to normal
            keyboardState = .normal
            isShiftLocked = false
            
        case .symbols:
            if hasShiftedSymbolsLayout() {
                keyboardState = .shiftedSymbols
            }
            
        case .shiftedSymbols:
            keyboardState = .symbols
        }
        
        // Only rebuild if switching between letter/symbol modes
        let needsRebuild = (previousState == .normal || previousState == .shifted) &&
                          (keyboardState == .symbols || keyboardState == .shiftedSymbols) ||
                          (previousState == .symbols || previousState == .shiftedSymbols) &&
                          (keyboardState == .normal || keyboardState == .shifted)
        
        if needsRebuild {
            loadCurrentLayout()
            delegate?.updateKeyboardView()
        }
        
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleModeChange() {
        switch keyboardState {
        case .normal, .shifted:
            keyboardState = .symbols
            
        case .symbols:
            if hasShiftedSymbolsLayout() {
                keyboardState = .shiftedSymbols
            } else {
                keyboardState = .normal
            }
            
        case .shiftedSymbols:
            keyboardState = .normal
        }
        
        isShiftLocked = false
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleDelete() {
        guard let translator = currentTranslator else { return }
        
        // Direct synchronous call
        let result = translator.processDelete(composition: currentComposition)
        
        self.currentComposition = result.newComposition
        self.delegate?.deleteBackward(count: result.charactersToDelete)
        
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleSpace() {
        delegate?.insertText(" ")
        currentComposition = ""
    }
    
    private func handleReturn() {
        delegate?.insertText("\n")
        currentComposition = ""
    }
    
    private func handleGlobe() {
        // This will be handled by the delegate (extension-specific)
        delegate?.switchToNextKeyboard()
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleCharacterInput(keyCode: Int, label: String) {
        guard let translator = currentTranslator else { return }
        
        // TODO: Remove after debug
        let t1 = CFAbsoluteTimeGetCurrent()
        
        // Direct synchronous call - no Task wrapper
        let result = translator.translateKey(
            keyCode: keyCode,
            isShifted: keyboardState == .shifted,
            currentComposition: currentComposition
        )
        
        let t2 = CFAbsoluteTimeGetCurrent()
        print("🔴 Translator.translateKey: \((t2 - t1) * 1000)ms")
        let t3 = CFAbsoluteTimeGetCurrent()

        self.currentComposition = result.newComposition
        self.delegate?.insertText(result.displayText)
        
        let t4 = CFAbsoluteTimeGetCurrent()
        print("🔴 InsertText: \((t4 - t3) * 1000)ms")
    }
    
    // MARK: - Helper Methods
    private func autoUnshift() {
        if keyboardState == .shifted && !isShiftLocked {
            keyboardState = .normal
        }
    }
    
    private func hasShiftedSymbolsLayout() -> Bool {
        // Languages with shifted symbols layouts
        let languagesWithShiftedSymbols: Set<LanguageId> = [
            .punjabi, .hindi, .bengali, .gujarati
            // Add other languages as needed
        ]
        return languagesWithShiftedSymbols.contains(currentLanguage)
    }
    
    // MARK: - Public Utility Methods
    public func getStateDisplayText() -> String {
        switch keyboardState {
        case .normal:
            return "Normal"
        case .shifted:
            return "Shift" // Removed caps lock text since it's disabled
        case .symbols:
            return "123"
        case .shiftedSymbols:
            return "#+="
        }
    }
    
    public func clearComposition() {
        currentComposition = ""
    }
    
    // MARK: - RTL Support
    public func isRightToLeft() -> Bool {
        return currentLanguage == .jawi || currentLanguage == .qwertyJawi
    }
}
