//
//  KeyboardMetrics.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 01/10/2025.
//

import UIKit

struct KeyboardMetrics {
    // MARK: - Candidate Bar Heights
    static let candidateBarHeight: CGFloat = 48  // Reduced from 60
    static let candidateBarHeightWithAnnotation: CGFloat = 60  // Reduced from 74
    
    // iPhone landscape uses smaller candidate bar since annotations are never shown
    static let candidateBarHeightLandscape: CGFloat = 36  // Optimized for single-line candidates
    static let candidateBarHeightLandscapeWithAnnotation: CGFloat = 36  // Same as above (not used since annotations are hidden)
    
    // MARK: - Keys Area Heights
    
    // iPad Keys Area
    private static let iPadPortraitKeysArea: CGFloat = 264
    private static let iPadLandscapeKeysArea: CGFloat = 398
    
    // iPhone Keys Area by Device Class
    private enum DeviceClass {
        case notched
        case plus
        case standard
        case compact
        
        var portraitKeysArea: CGFloat {
            switch self {
            case .notched: return 216
            case .plus: return 226
            case .standard: return 213
            case .compact: return 208
            }
        }
        
        var landscapeKeysArea: CGFloat {
            return 177  // Increased by 2pt from 175 for better spacing in landscape
        }
    }
    
    // MARK: - Public Methods
    
    static func keyboardHeight(
        for traitCollection: UITraitCollection,
        includesCandidateBar: Bool = true,
        useAnnotatedCandidates: Bool = false
    ) -> CGFloat {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        let keysHeight: CGFloat
        
        if isPad {
            keysHeight = isLandscape ? iPadLandscapeKeysArea : iPadPortraitKeysArea
        } else {
            let deviceClass = identifyDeviceClass()
            keysHeight = isLandscape ? deviceClass.landscapeKeysArea : deviceClass.portraitKeysArea
        }
        
        let finalHeight: CGFloat
        if includesCandidateBar {
            let candidateHeight = candidateBarHeight(
                for: traitCollection,
                useAnnotatedCandidates: useAnnotatedCandidates
            )
            finalHeight = keysHeight + candidateHeight
        } else {
            finalHeight = keysHeight
        }
        
        // Debug logging for iPhone landscape
        if isPhone && isLandscape {
            print("🔍 KEYBOARD HEIGHT DEBUG - iPhone Landscape")
            print("   Keys height: \(keysHeight)")
            print("   Candidate height: \(includesCandidateBar ? candidateBarHeight(for: traitCollection, useAnnotatedCandidates: useAnnotatedCandidates) : 0)")
            print("   Final height: \(finalHeight)")
        }
        
        return finalHeight
    }
    
    static func candidateBarHeight(
        for traitCollection: UITraitCollection,
        useAnnotatedCandidates: Bool = false
    ) -> CGFloat {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        // Check if annotations will actually be shown
        // In iPhone landscape, annotations are hidden regardless of useAnnotatedCandidates setting
        let shouldShowAnnotation = useAnnotatedCandidates && (!isLandscape || !isPhone)
        
        if isLandscape && isPhone {
            // iPhone landscape: always use smaller height since annotations are never shown
            return candidateBarHeightLandscape
        } else {
            // Portrait or iPad: use annotation height only if annotations will be shown
            return shouldShowAnnotation ?
                candidateBarHeightWithAnnotation : candidateBarHeight
        }
    }
    
    // MARK: - Device Detection
    
    private static func identifyDeviceClass() -> DeviceClass {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenSize = max(screenWidth, screenHeight)
        
        if screenSize >= 926 {
            return .notched
        } else if screenSize >= 896 {
            return .notched
        } else if screenSize >= 844 {
            return .notched
        } else if screenSize >= 812 {
            return .notched
        } else if screenSize >= 736 {
            return .plus
        } else if screenSize >= 667 {
            return .standard
        } else {
            return .compact
        }
    }
}
