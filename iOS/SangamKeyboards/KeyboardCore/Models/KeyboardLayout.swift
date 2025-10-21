//
//  KeyboardLayout.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

// MARK: - Main Layout Structure
public struct KeyboardLayout: Codable {
    public let keyWidth: String
    public let horizontalGap: String
    public let rows: [KeyboardRow]
    
    public init(keyWidth: String, horizontalGap: String, rows: [KeyboardRow]) {
        self.keyWidth = keyWidth
        self.horizontalGap = horizontalGap
        self.rows = rows
    }
}

public struct KeyboardRow: Codable {
    public let verticalGap: String?
    public let keyHeight: String
    public let rowId: String?
    public let keys: [KeyboardKey]
    
    public init(verticalGap: String?, keyHeight: String, rowId: String?, keys: [KeyboardKey]) {
        self.verticalGap = verticalGap
        self.keyHeight = keyHeight
        self.rowId = rowId
        self.keys = keys
    }
}

public struct KeyboardKey: Codable {
    // Primary key identification - supports both formats
    public let codes: String?           // Tamil99 format: "2950", "-1", "32"
    public let unichar: String?         // Hindi format: "ौ", "ै"
    
    // Display information
    public let keyLabel: String         // Tamil99: "ஆ", Hindi: "" (empty)
    
    // Layout properties
    public let keyWidth: String?
    public let horizontalGap: String?
    public let keyEdgeFlags: String?
    
    // Behavior properties
    public let isModifier: Bool?
    public let isShifted: Bool?
    public let isRepeatable: Bool?
    
    // Additional properties for advanced layouts
    public let popupCharacters: String? // Format A: "\\u0bb0\\u0bb1"
    public let popupCodes: String?      // Format B: "लळऴऌ"
    
    // Annotation for keys (displayed at bottom in small font)
    public let annotation: String?

    // MARK: - Computed Properties
    
    /// Returns the key code as an integer, supporting both codes and unichar formats
    public var keyCode: Int {
        // Priority 1: Use codes field (Tamil99 format)
        if let codes = codes, let codeValue = Int(codes) {
            return codeValue
        }
        
        // Priority 2: Use unichar field (Hindi format)
        if let unichar = unichar, let firstScalar = unichar.unicodeScalars.first {
            return Int(firstScalar.value)
        }
        
        // Fallback
        return 0
    }
    
    /// Returns the display text for the key, supporting both formats
    public var displayText: String {
        // Priority 1: Use keyLabel if not empty (Tamil99 format)
        if !keyLabel.isEmpty {
            return keyLabel
        }
        
        // Priority 2: Use unichar if available (Hindi format)
        if let unichar = unichar, !unichar.isEmpty {
            return unichar
        }
        
        // Fallback to empty string
        return ""
    }
    
    /// Returns popup characters if available, supporting both formats
    public var popupCharactersList: [String] {
        // Format A: popupCharacters with escaped Unicode (e.g., "\\u0bb0\\u0bb1")
        if let popupChars = popupCharacters, !popupChars.isEmpty {
            return decodeUnicodeString(popupChars)
        }
        
        // Format B: popupCodes with direct characters (e.g., "लळऴऌ")
        if let codes = popupCodes, !codes.isEmpty {
            return codes.map { String($0) }
        }
        
        return []
    }
    
    /// Helper to decode Unicode escape sequences like \u0bb0
    private func decodeUnicodeString(_ input: String) -> [String] {
        var result: [String] = []
        var i = input.startIndex
        
        while i < input.endIndex {
            if i < input.index(input.endIndex, offsetBy: -5),
               input[i] == "\\",
               input[input.index(after: i)] == "u" {
                
                let hexStart = input.index(i, offsetBy: 2)
                let hexEnd = input.index(hexStart, offsetBy: 4)
                
                if hexEnd <= input.endIndex {
                    let hexString = String(input[hexStart..<hexEnd])
                    
                    if let hexValue = UInt32(hexString, radix: 16),
                       let scalar = UnicodeScalar(hexValue) {
                        result.append(String(scalar))
                    }
                    
                    i = hexEnd
                    continue
                }
            }
            
            i = input.index(after: i)
        }
        
        return result
    }
    
    /// Determines if this is a special/modifier key
    public var isSpecialKey: Bool {
        // Check if it's explicitly marked as modifier
        if isModifier == true {
            return true
        }
        
        // Check for special key codes (negative values)
        if let codes = codes, let codeValue = Int(codes), codeValue < 0 {
            return true
        }
        
        // Check for special labels
        return keyLabel.hasPrefix("#") || keyLabel.contains("⬆") || keyLabel.contains("⌫")
    }
    
    // MARK: - Initialization
    public init(
        codes: String? = nil,
        unichar: String? = nil,
        keyLabel: String,
        keyWidth: String? = nil,
        horizontalGap: String? = nil,
        keyEdgeFlags: String? = nil,
        isModifier: Bool? = nil,
        isShifted: Bool? = nil,
        isRepeatable: Bool? = nil,
        popupCharacters: String? = nil,
        popupCodes: String? = nil,
        annotation: String? = nil
    ) {
        self.codes = codes
        self.unichar = unichar
        self.keyLabel = keyLabel
        self.keyWidth = keyWidth
        self.horizontalGap = horizontalGap
        self.keyEdgeFlags = keyEdgeFlags
        self.isModifier = isModifier
        self.isShifted = isShifted
        self.isRepeatable = isRepeatable
        self.popupCharacters = popupCharacters
        self.popupCodes = popupCodes
        self.annotation = annotation
    }
}

// MARK: - Helper Extensions

extension KeyboardKey {
    /// Debug description showing key information
    public var debugDescription: String {
        let codeInfo = codes ?? "unichar:\(unichar ?? "nil")"
        let display = displayText.isEmpty ? "(empty)" : displayText
        return "Key[\(codeInfo)] = '\(display)'"
    }
    
    /// Returns true if this key represents a character that can be typed
    public var isCharacterKey: Bool {
        return !isSpecialKey && !displayText.isEmpty
    }
    
    /// Returns true if this key is a space key
    public var isSpaceKey: Bool {
        return keyCode == 32 || keyLabel == "#space"
    }
    
    /// Returns true if this key is a return/enter key
    public var isReturnKey: Bool {
        return keyCode == 10 || keyLabel == "#return"
    }
}

extension KeyboardKey {
    /// Returns a new KeyboardKey with modified keyWidth
    public func withKeyWidth(_ newWidth: String) -> KeyboardKey {
        return KeyboardKey(
            codes: self.codes,
            unichar: self.unichar,
            keyLabel: self.keyLabel,
            keyWidth: newWidth,
            horizontalGap: self.horizontalGap,
            keyEdgeFlags: self.keyEdgeFlags,
            isModifier: self.isModifier,
            isShifted: self.isShifted,
            isRepeatable: self.isRepeatable,
            popupCharacters: self.popupCharacters,
            popupCodes: self.popupCodes,
            annotation: self.annotation
        )
    }
    
    /// Helper extension to create a key with different display text
    public func withDisplayText(_ newText: String) -> KeyboardKey {
        return KeyboardKey(
            codes: self.codes,
            unichar: newText,
            keyLabel: newText, //self.keyLabel,
            keyWidth: self.keyWidth,
            horizontalGap: self.horizontalGap,
            keyEdgeFlags: self.keyEdgeFlags,
            isModifier: self.isModifier,
            isShifted: self.isShifted,
            isRepeatable: self.isRepeatable,
            popupCharacters: self.popupCharacters,  
            popupCodes: self.popupCodes,
            annotation: self.annotation
        )
    }
}

