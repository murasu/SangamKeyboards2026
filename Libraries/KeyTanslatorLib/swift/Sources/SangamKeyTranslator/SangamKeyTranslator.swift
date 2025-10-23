//
//  SangamKeyTranslator.swift
//  KeyTranslator
//
//  Converted from KeyTranslatorAnjalWindows.m
//

import Foundation
import CAnjalKeyTranslator

// Constants from the original Objective-C code
private let DELCODE: UInt16 = 0x2421
private let ZWNJ: UInt16 = 0x200C
private let ZWSPACE: UInt16 = 0x200B

// Error types for Swift
public enum SangamTranslatorError: Error {
    case initializationFailed
    case invalidKeyCode
    case bufferTooSmall
}

public class SangamKeyTranslator {
    
    // Singleton instance
    public static let shared = SangamKeyTranslator()
    
    // MARK: - Private Properties
    private var prevKeyCode: Int32 = 0
    private var localComposing: String = ""
    private var translatedString: [wchar_t] = Array(repeating: 0, count: 10)
    private var prevTranslation: [wchar_t] = Array(repeating: 0, count: 10)
    private var prevKeyWasBackspace: Bool = false
    private var delInRevTypingOrder: Bool = false
    
    // MARK: - Initialization
    
    public init() {
        // Call the C function to set keyboard layout
        SetKeyboardLayout(kbdNone) // Default is -1 : so we know nothing has been set
        prevKeyWasBackspace = false
        clearResults()
        
        // Get the delete order preference from UserDefaults
        delInRevTypingOrder = UserDefaults.standard.bool(forKey: "kDeleteReverseTypingOrder")
        SetWytiwygDeleteInReverseTypingOrder(delInRevTypingOrder)
    }
    
    // MARK: - Public Methods
    
    public func setWytiwygDeleteInReverseTypingOrder(_ isSet: Bool) {
        delInRevTypingOrder = isSet
        SetWytiwygDeleteInReverseTypingOrder(isSet)
    }
    
    public func updateKeyStatesAfterDelete(forLastChar lastChar: wchar_t) {
        clearResults()
        UpdatePrevKeyTypesForLastChar(lastChar)
    }
    
    public func terminateComposition() {
        clearResults()
    }
    
    public func setLayout(_ kbdLayout: Int32) {
        SetKeyboardLayout(kbdLayout)
    }
    
    public func getLayout() -> Int32 {
        return GetKeyboardLayout()
    }
    
    public func translateComposition(in composing: String?, newKeyCode keyCode: Int32, shifted: Bool) -> String {
        var result = ""
        let postfix: String
        
        if let composing = composing, !composing.isEmpty {
            localComposing = composing
            if composing.count >= 2 {
                let startIndex = composing.index(composing.endIndex, offsetBy: -2)
                postfix = String(composing[startIndex...])
            } else {
                postfix = ""
            }
        } else {
            clearResults()
            postfix = ""
        }
        
        print("Calling with keyCode \(keyCode), prevKeyCode \(prevKeyCode)")
        
        // Call the C function to get the translation
        let ksr = GetCharStringForKey(keyCode, prevKeyCode, &translatedString, prevKeyWasBackspace)
        
        print("Translated string \(String(utf32String: translatedString) ?? "nil") Previous translation \(String(utf32String: prevTranslation) ?? "nil")")
        
        // Check if we have to delete chars
        if ksr == KSR_DELETE_PREV_KS_LENGTH {
            let delCount = wcslen(prevTranslation)
            var actualDelCount = Int(delCount)
            
            // Delete the whole string if it's X (KSHA). otherwise, delete just the last base char
            if delCount >= 4 && wcsncmp(prevTranslation, [0x0b95, 0x0bcd, 0x0bb7], 3) != 0 {
                actualDelCount = 2
            }
            result += "\(Character(UnicodeScalar(DELCODE)!))\(actualDelCount)"
        } else if ksr > 0 {
            result += "\(Character(UnicodeScalar(DELCODE)!))\(ksr)"
        }
        
        // If this is க் + ஷ append a ZWNJ first
        if translatedString[0] == 0x0bb7 && stringEndsWithKshaPrefix(localComposing) { // ஷ character
            result += "\(Character(UnicodeScalar(ZWNJ)!))"
        }
        
        // Append the translated characters
        if let translatedStr = String(utf32String: translatedString) {
            result += translatedStr
        }
        
        prevKeyCode = keyCode
        // Copy translated string to previous translation
        for i in 0..<min(translatedString.count, prevTranslation.count) {
            prevTranslation[i] = translatedString[i]
        }
        
        return result
    }
    
    public func deleteLastChar(in composition: String) -> String {
        var scalars = Array(composition.unicodeScalars)
        let len = scalars.count
        var shouldResetPrevKeyType = false
        
        if delInRevTypingOrder && IsCurrentKeyboardWytiwyg() && len >= 2 {
            let lastScalar = scalars[len - 1].value
            
            if IsLeftVowelSign(wchar_t(lastScalar)) {
                let secondLastScalar = scalars[len - 2].value
                
                if IsConsonant(wchar_t(secondLastScalar)) {
                    // Replace consonant with ZWSPACE
                    scalars.removeLast(2)
                    scalars.append(UnicodeScalar(ZWSPACE)!)
                    scalars.append(scalars.last!)
                } else if secondLastScalar == UInt32(ZWSPACE) {
                    // Delete the vowel sign and the ZWSPACE
                    scalars.removeLast(2)
                    SetWytiwygVowelLeftHalf(0)
                    shouldResetPrevKeyType = true
                } else {
                    // Just delete the last scalar
                    scalars.removeLast()
                }
            } else if IsTwoPartVowelSign(wchar_t(lastScalar)) {
                let secondLastScalar = scalars[len - 2].value
                
                if IsConsonant(wchar_t(secondLastScalar)) {
                    // Replace the vowel sign with the left component
                    let leftVowelSign = LeftVowelSignFor(wchar_t(lastScalar))
                    SetWytiwygVowelLeftHalf(leftVowelSign)
                    scalars.removeLast()
                    scalars.append(UnicodeScalar(UInt32(leftVowelSign))!)
                } else {
                    // Just delete the last scalar
                    scalars.removeLast()
                }
            } else {
                // Just delete the last scalar
                scalars.removeLast()
            }
        } else if len > 0 {
            // Just delete the last scalar
            scalars.removeLast()
            
            // If this is a WYTIWYG keyboard, check for place-holder ZWSPACE
            if !scalars.isEmpty && IsCurrentKeyboardWytiwyg() {
                let lastScalar = scalars.last!.value
                if IsVowelSign(wchar_t(lastScalar)) {
                    SetWytiwygVowelLeftHalf(0)
                    shouldResetPrevKeyType = true
                }
            }
        }
        
        // If we have a ZWNJ lingering as a result of deleting ஷ in க்+ஷ, delete it
        if !scalars.isEmpty && scalars.last!.value == UInt32(ZWNJ) {
            scalars.removeLast()
        }
        
        if !scalars.isEmpty {
            let lastScalar = scalars.last!.value
            UpdatePrevKeyTypesForLastChar(wchar_t(lastScalar))
            if shouldResetPrevKeyType {
                ResetPrevKeyType()
            }
        } else {
            ResetKeyStringGlobals()
        }
        
        return String(String.UnicodeScalarView(scalars))
    }
    
    public func cleanupStrayVowelSign(_ composition: String) -> String {
        var scalars = Array(composition.unicodeScalars)
        let len = scalars.count
        
        if IsCurrentKeyboardWytiwyg() && len >= 2 {
            let lastScalar = scalars[len - 1].value
            if IsLeftVowelSign(wchar_t(lastScalar)) {
                let secondLastScalar = scalars[len - 2].value
                if secondLastScalar == UInt32(ZWSPACE) {
                    // Delete the vowel sign and the ZWSPACE
                    scalars.removeLast(2)
                }
            }
        }
        
        return String(String.UnicodeScalarView(scalars))
    }
    
    public func getUnmappedChar(for keyCode: Int32, composing: String, shifted: Bool) -> String {
        print("Getting unmapped char for \(keyCode)")
        
        var result = ""
        var unmappedChar: [wchar_t] = Array(repeating: 0, count: 10)
        
        let prevChar: wchar_t = composing.isEmpty ? 0 : wchar_t(composing.last!.utf16.first!)
        let delCount = GetUnmappedCharStringForKey(keyCode, &unmappedChar, prevChar, shifted)
        
        if delCount > 0 {
            result += "\(Character(UnicodeScalar(DELCODE)!))\(delCount)"
        }
        
        if let unmappedStr = String(utf32String: unmappedChar) {
            result += unmappedStr
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func clearResults() {
        prevKeyCode = 0
        prevTranslation = Array(repeating: 0, count: 10)
        localComposing = ""
        
        // Reset the params in C
        ResetKeyStringGlobals()
    }
    
    private func stringEndsWithKshaPrefix(_ composition: String) -> Bool {
        var checking = composition
        
        while checking.count >= 2 {
            let lastChar = checking.last!.utf16.first!
            let secondLastChar = checking.dropLast().last!.utf16.first!
            
            if lastChar == 0x0bcd && secondLastChar == 0x0b95 { // pulli and ka
                return true
            }
            
            // WYTIWYG keyboards hold the left vowel sign separated by a ZWSPACE
            if IsLeftVowelSign(wchar_t(lastChar)) && secondLastChar == ZWSPACE {
                checking.removeLast(2)
            } else {
                break
            }
        }
        
        return false
    }
}

// MARK: - Extensions for C String Conversion

extension String {
    init?(utf32String: [wchar_t]) {
        let codeUnits = utf32String.prefix(while: { $0 != 0 })
        if codeUnits.isEmpty {
            return nil
        }
        
        let scalars = codeUnits.compactMap { UnicodeScalar(UInt32($0)) }
        self = String(String.UnicodeScalarView(scalars))
    }
}

// MARK: - C Function Declarations
// These need to be declared if not already available through a bridging header

/*
// Declare the C functions you're using - add these to a bridging header instead
@_silgen_name("SetKeyboardLayout")
func SetKeyboardLayout(_ layout: Int32)

@_silgen_name("GetKeyboardLayout") 
func GetKeyboardLayout() -> Int32

@_silgen_name("SetWytiwygDeleteInReverseTypingOrder")
func SetWytiwygDeleteInReverseTypingOrder(_ isSet: Bool)

@_silgen_name("UpdatePrevKeyTypesForLastChar")
func UpdatePrevKeyTypesForLastChar(_ char: wchar_t)

@_silgen_name("ResetKeyStringGlobals")
func ResetKeyStringGlobals()

@_silgen_name("GetCharStringForKey")
func GetCharStringForKey(_ keyCode: Int32, _ prevKeyCode: Int32, _ output: UnsafeMutablePointer<wchar_t>, _ prevKeyWasBackspace: Bool) -> Int32

@_silgen_name("IsCurrentKeyboardWytiwyg")
func IsCurrentKeyboardWytiwyg() -> Bool

@_silgen_name("IsLeftVowelSign")
func IsLeftVowelSign(_ char: wchar_t) -> Bool

@_silgen_name("IsConsonant") 
func IsConsonant(_ char: wchar_t) -> Bool

@_silgen_name("SetWytiwygVowelLeftHalf")
func SetWytiwygVowelLeftHalf(_ char: wchar_t)

@_silgen_name("IsTwoPartVowelSign")
func IsTwoPartVowelSign(_ char: wchar_t) -> Bool

@_silgen_name("LeftVowelSignFor")
func LeftVowelSignFor(_ char: wchar_t) -> wchar_t

@_silgen_name("IsVowelSign")
func IsVowelSign(_ char: wchar_t) -> Bool

@_silgen_name("ResetPrevKeyType")
func ResetPrevKeyType()

@_silgen_name("GetUnmappedCharStringForKey")
func GetUnmappedCharStringForKey(_ keyCode: Int32, _ output: UnsafeMutablePointer<wchar_t>, _ prevChar: wchar_t, _ shifted: Bool) -> Int32

// Constants that might need to be defined
let KSR_DELETE_PREV_KS_LENGTH: Int32 = 1 // Adjust this value based on your C code
*/
