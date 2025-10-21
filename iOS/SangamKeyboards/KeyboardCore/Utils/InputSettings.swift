//
//  InputSettings.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public enum AnnotationType: String, CaseIterable, Identifiable {
    case meaning = "meaning"
    case transliteration = "transliteration"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .meaning:
            return "Meaning"
        case .transliteration:
            return "Transliteration"
        }
    }
}

public enum ScriptType: String, CaseIterable, Identifiable {
    case tamil = "tamil"
    case tamili = "tamili"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .tamil:
            return "Tamil"
        case .tamili:
            return "Tamili/Brahmi"
        }
    }
}

public struct InputSettings {
    // Basic input settings
    public let predictionsEnabled: Bool
    public let nextWordPredictionsEnabled: Bool
    public let autoCommitEnabled: Bool
    public let autoCorrectEnabled: Bool
    public let soundsEnabled: Bool
    public let emojisEnabled: Bool
    
    // Learning settings
    public let learnMyTypedWords: Bool
    public let shortcutForPeriod: Bool
    
    // Annotation settings
    public let showAnnotations: Bool
    public let annotationType: AnnotationType
    
    // Script and theme settings
    public let script: ScriptType
    
    public init(
        predictionsEnabled: Bool = true,
        nextWordPredictionsEnabled: Bool = true,
        autoCommitEnabled: Bool = false,
        autoCorrectEnabled: Bool = true,
        soundsEnabled: Bool = true,
        emojisEnabled: Bool = true,
        learnMyTypedWords: Bool = true,
        shortcutForPeriod: Bool = true,
        showAnnotations: Bool = true,
        annotationType: AnnotationType = .meaning,
        script: ScriptType = .tamil
    ) {
        self.predictionsEnabled = predictionsEnabled
        self.nextWordPredictionsEnabled = nextWordPredictionsEnabled
        self.autoCommitEnabled = autoCommitEnabled
        self.autoCorrectEnabled = autoCorrectEnabled
        self.soundsEnabled = soundsEnabled
        self.emojisEnabled = emojisEnabled
        self.learnMyTypedWords = learnMyTypedWords
        self.shortcutForPeriod = shortcutForPeriod
        self.showAnnotations = showAnnotations
        self.annotationType = annotationType
        self.script = script
    }
    
    public static let `default` = InputSettings()
}

