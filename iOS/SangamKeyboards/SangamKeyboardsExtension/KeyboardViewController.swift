//
//  KeyboardViewController.swift
//  SangamKeyboardsExtension
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit
import KeyboardCore
import AudioToolbox

class KeyboardViewController: UIInputViewController, UIScrollViewDelegate {
    
    // MARK: - Abstract property - subclasses must override
    var keyboardLanguage: LanguageId {
        fatalError("Subclasses must override keyboardLanguage")
    }
    
    // MARK: - Logic Controller
    private var logicController: KeyboardLogicController!
    
    // MARK: - UI Components
    private var keyboardContainer: UIView!
    private var candidateBarContainer: UIView!
    private var currentKeyboardView: UIView?
    private var candidateBarHeightConstraint: NSLayoutConstraint? // Add this to track the constraint
    
    // MARK: - Configuration
    public var usesCandidateBar: Bool = true  // Based on language needs
    public var usesAnnotatedCandidates: Bool = false  // True for languages needing annotations
    public var animateCandidates: Bool = true  // Animation preference (loaded from UserDefaults)
    
    // MARK: - Candidate Display Configuration
    private let minVisibleCandidates: Int = 5  // Minimum candidates to show (pad with dummies if fewer)
    private let maxVisibleCandidates: Int = 12 // Maximum visible at once
    private let optimalCandidates: Int = 7     // Optimal number for centering

    private var hasCheckedGlobeKey = false
    private var shouldShowGlobeKey = true  // Default to true
    
    // MARK: - Candidate Management
    private var candidateScrollView: UIScrollView!
    private var candidateStackView: UIStackView!
    private var leftGradientView: UIView?
    private var rightGradientView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load animation preference from app group UserDefaults
        loadAnimationPreference()
        
        // To test app groups
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.murasu.Sangam"
        ) {
            print("✅ App Group container found at: \(containerURL)")
            
            // Try writing a test file
            let testFile = containerURL.appendingPathComponent("test.txt")
            try? "test".write(to: testFile, atomically: true, encoding: .utf8)
            
            if FileManager.default.fileExists(atPath: testFile.path) {
                print("✅ Successfully wrote to app group container")
            }
        } else {
            print("❌ App Group container not accessible")
        }
        
        // UNCOMMENT THIS LINE TO DEBUG AVAILABLE FONTS (especially Tamil fonts)
        // debugAvailableFonts()
        
        // End test app groups
        
        setupLogicController()
        setupUI()
        buildKeyboard()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyBackgroundGradient()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Check if size class changed (portrait ↔ landscape)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            updateLandscapePadding()
            view.setNeedsUpdateConstraints()
            updateViewConstraints() // Force constraint update immediately
            buildKeyboard()
        }
        
        // Update keyboard when interface style changes (light/dark mode)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            buildKeyboard()  // Theme system handles light/dark automatically
        }
    }
    
    private func updateLandscapePadding() {
        guard let mainContainer = view.viewWithTag(999) else { return }
        
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        // Only apply padding on iPhone in landscape
        let horizontalPadding: CGFloat = (isLandscape && isPhone) ? 80 : 0
        let verticalPadding: CGFloat = 6

        // Update existing constraints
        for constraint in view.constraints {
            if constraint.firstItem === mainContainer {
                if constraint.firstAttribute == .leading {
                    constraint.constant = horizontalPadding
                } else if constraint.firstAttribute == .trailing {
                    constraint.constant = -horizontalPadding
                } else if constraint.firstAttribute == .top {
                    constraint.constant = verticalPadding
                } else if constraint.firstAttribute == .bottom {
                    constraint.constant = -verticalPadding
                }
            }
        }
        
        // Update candidate bar height constraint for orientation change
        updateCandidateBarHeight()
    }
    
    private func updateCandidateBarHeight() {
        guard let heightConstraint = candidateBarHeightConstraint else { return }
        
        let newHeight = KeyboardMetrics.candidateBarHeight(
            for: traitCollection,
            useAnnotatedCandidates: usesAnnotatedCandidates
        )
        
        print("🔄 Updating candidate bar height: \(heightConstraint.constant) → \(newHeight)")
        heightConstraint.constant = newHeight
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        // This is called when VC is properly connected to parent
        // At this point, needsInputModeSwitchKey is reliable
        if parent != nil && !hasCheckedGlobeKey {
            hasCheckedGlobeKey = true
            shouldShowGlobeKey = needsInputModeSwitchKey
            // Rebuild keyboard with correct value
            buildKeyboard()
        }
    }
    
    // MARK: - Candidate Data Structure
    struct Candidate: Equatable {
        let text: String
        let annotation: String? // For pronunciation, meaning, etc.
        let confidence: Float   // 0.0 to 1.0, for scoring/sorting
        let isDummy: Bool       // For invisible padding candidates
        
        init(_ text: String, annotation: String? = nil, confidence: Float = 1.0, isDummy: Bool = false) {
            self.text = text
            self.annotation = annotation
            self.confidence = confidence
            self.isDummy = isDummy
        }
        
        // Create dummy candidate for padding
        static func dummy() -> Candidate {
            return Candidate("", annotation: nil, confidence: 0.0, isDummy: true)
        }
        
        // Equatable conformance - two candidates are equal if they have the same text and confidence
        static func == (lhs: Candidate, rhs: Candidate) -> Bool {
            return lhs.text == rhs.text && 
                   lhs.annotation == rhs.annotation && 
                   lhs.confidence == rhs.confidence && 
                   lhs.isDummy == rhs.isDummy
        }
    }
    
    // MARK: - User Preferences Management
    
    private func loadAnimationPreference() {
        if let appGroupDefaults = UserDefaults(suiteName: "group.murasu.Sangam") {
            // Default to true if no preference is set
            animateCandidates = appGroupDefaults.object(forKey: "animateCandidates") as? Bool ?? true
            print("📱 Loaded animation preference: \(animateCandidates)")
        } else {
            // Fallback to standard UserDefaults
            animateCandidates = UserDefaults.standard.bool(forKey: "animateCandidates")
            if UserDefaults.standard.object(forKey: "animateCandidates") == nil {
                animateCandidates = true // Default to true
            }
            print("📱 Loaded animation preference from standard defaults: \(animateCandidates)")
        }
    }
    
    public func setAnimationPreference(_ enabled: Bool) {
        animateCandidates = enabled
        
        // Save to app group UserDefaults
        if let appGroupDefaults = UserDefaults(suiteName: "group.murasu.Sangam") {
            appGroupDefaults.set(enabled, forKey: "animateCandidates")
            print("📱 Saved animation preference to app group: \(enabled)")
        } else {
            // Fallback to standard UserDefaults
            UserDefaults.standard.set(enabled, forKey: "animateCandidates")
            print("📱 Saved animation preference to standard defaults: \(enabled)")
        }
    }
    
    // MARK: - Candidate Arrangement Methods
    
    /**
     * Advanced Candidate Bar Features:
     * 
     * 1. ✅ getCandidates() sorts candidates by confidence score (highest first)
     * 2. ✅ Radial distribution places highest confidence in center, others distributed symmetrically
     * 3. ✅ Auto-scrolling centers highest confidence candidate when content overflows
     * 4. ✅ Dummy candidate padding ensures proper centering with fewer candidates
     * 5. ✅ Keystroke-triggered refresh updates candidates on every text change
     * 6. ✅ Animation preference (stored in UserDefaults) controls smooth transitions
     * 
     * Performance optimizations:
     * - Efficient view recycling for animations
     * - Minimal layout calculations
     * - Optimized scroll positioning
     * - Lightweight dummy candidate rendering
     */
    
    /// Arranges candidates with highest confidence in the middle, distributing others radially
    /// Adds padding dummies if needed for centering, or drops lowest confidence candidates if they would overflow
    private func arrangedCandidatesForDisplay(_ candidates: [Candidate]) -> [Candidate] {
        guard !candidates.isEmpty else { return [] }
        
        print("🔍 ARRANGEMENT - Step 1: Input candidates")
        print("Input (\(candidates.count)): \(candidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        let actualCandidates = candidates.filter { !$0.isDummy }
        
        print("🔍 ARRANGEMENT - Step 2: After filtering dummies")
        print("Actual candidates (\(actualCandidates.count)): \(actualCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        // If we have fewer than minimum, pad with dummies for better centering
        let displayCandidates: [Candidate]
        if actualCandidates.count < minVisibleCandidates {
            let dummiesNeeded = minVisibleCandidates - actualCandidates.count
            let dummies = Array(0..<dummiesNeeded).map { _ in Candidate.dummy() }
            displayCandidates = actualCandidates + dummies
            
            print("🔍 ARRANGEMENT - Step 3: Added \(dummiesNeeded) dummies")
            print("Display candidates (\(displayCandidates.count)): \(displayCandidates.map { $0.isDummy ? "DUMMY" : "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        } else {
            displayCandidates = actualCandidates
            print("🔍 ARRANGEMENT - Step 3: No dummies needed")
        }
        
        // Arrange with highest confidence in center, others distributed radially
        var arranged = distributeRadially(displayCandidates)
        
        // Check if arrangement would cause overflow when content fits entirely
        arranged = optimizeArrangementForFitting(arranged)
        
        print("🔍 ARRANGEMENT - Step 4: Final arranged candidates")
        print("Arranged (\(arranged.count)): \(arranged.map { $0.isDummy ? "DUMMY" : "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        return arranged
    }
    
    /// Distributes candidates radially with highest confidence in center
    private func distributeRadially(_ candidates: [Candidate]) -> [Candidate] {
        guard candidates.count > 1 else { 
            print("🔍 RADIAL DISTRIBUTION - Only 1 candidate, no distribution needed")
            return candidates 
        }
        
        print("🔍 RADIAL DISTRIBUTION - Step 1: Input")
        print("Input (\(candidates.count)): \(candidates.map { $0.isDummy ? "DUMMY" : "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        // Sort by confidence (highest first) - but keep dummies at the end
        let realCandidates = candidates.filter { !$0.isDummy }.sorted { $0.confidence > $1.confidence }
        let dummies = candidates.filter { $0.isDummy }
        
        print("🔍 RADIAL DISTRIBUTION - Step 2: Separated and sorted")
        print("Real (\(realCandidates.count)): \(realCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        print("Dummies (\(dummies.count)): \(dummies.map { _ in "DUMMY" }.joined(separator: ", "))")
        
        guard !realCandidates.isEmpty else { return dummies }
        
        // Create result array with proper size
        var arranged: [Candidate] = Array(repeating: Candidate.dummy(), count: candidates.count)
        let centerIndex = candidates.count / 2
        
        print("🔍 RADIAL DISTRIBUTION - Step 3: Center calculation")
        print("Total candidates: \(candidates.count), Center index: \(centerIndex)")
        
        // Place the highest confidence candidate in center
        if let highest = realCandidates.first {
            arranged[centerIndex] = highest
            print("🔍 RADIAL DISTRIBUTION - Step 4: Placed highest '\(highest.text)' at center index \(centerIndex)")
        }
        
        // Distribute the remaining real candidates, ensuring we don't go out of bounds
        print("🔍 RADIAL DISTRIBUTION - Step 5: Placing remaining candidates")
        
        var leftOffset = 1
        var rightOffset = 1
        var placeRight = true
        
        for (i, candidate) in realCandidates.dropFirst().enumerated() {
            var targetIndex: Int
            var placed = false
            
            // Try to place the candidate, alternating between right and left
            while !placed {
                if placeRight {
                    targetIndex = centerIndex + rightOffset
                    if targetIndex < arranged.count {
                        arranged[targetIndex] = candidate
                        print("   Candidate \(i+2) '\(candidate.text)' -> RIGHT at index \(targetIndex) (center+\(rightOffset))")
                        rightOffset += 1
                        placed = true
                    } else {
                        // Right side is full, try left
                        placeRight = false
                    }
                } else {
                    targetIndex = centerIndex - leftOffset  
                    if targetIndex >= 0 {
                        arranged[targetIndex] = candidate
                        print("   Candidate \(i+2) '\(candidate.text)' -> LEFT at index \(targetIndex) (center-\(leftOffset))")
                        leftOffset += 1
                        placed = true
                    } else {
                        // Left side is full, try right
                        placeRight = true
                    }
                }
                
                // Safety check: if both sides are full, place in any remaining dummy slot
                if !placed && leftOffset + rightOffset > candidates.count {
                    // Find first dummy slot
                    if let dummyIndex = arranged.firstIndex(where: { $0.isDummy && $0.text.isEmpty }) {
                        arranged[dummyIndex] = candidate
                        print("   Candidate \(i+2) '\(candidate.text)' -> FALLBACK at index \(dummyIndex)")
                        placed = true
                    } else {
                        print("   ⚠️ No space for candidate '\(candidate.text)', dropping")
                        break
                    }
                }
                
                // Toggle for next iteration (only if we placed successfully through normal radial logic)
                if placed && (placeRight && targetIndex == centerIndex + (rightOffset - 1)) || 
                   (!placeRight && targetIndex == centerIndex - (leftOffset - 1)) {
                    placeRight.toggle()
                }
            }
        }
        
        print("🔍 RADIAL DISTRIBUTION - Step 6: Final arrangement")
        print("Final arranged (\(arranged.count)): \(arranged.enumerated().map { "[\($0.offset)]\($0.element.isDummy ? "DUMMY" : "\($0.element.text)[\(String(format: "%.3f", $0.element.confidence))]")" }.joined(separator: ", "))")
        print("🎯 Radial arrangement: center=\(centerIndex), total=\(arranged.count)")
        print("🎯 Arranged confidences: \(arranged.map { $0.isDummy ? "D" : String(format: "%.2f", $0.confidence) }.joined(separator: ", "))")
        
        return arranged
    }
    
    /// Optimizes candidate arrangement to prevent overflow when content fits entirely within scroll view
    /// Drops lowest confidence candidates if centering would push candidates outside visible bounds
    private func optimizeArrangementForFitting(_ candidates: [Candidate]) -> [Candidate] {
        guard !candidates.isEmpty else { return candidates }
        
        print("🔍 OPTIMIZATION - Step 1: Analyzing arrangement")
        print("Total candidates: \(candidates.count)")
        
        let realCandidates = candidates.filter { !$0.isDummy }
        guard realCandidates.count > 5 else {
            print("🔍 OPTIMIZATION - 5 or fewer candidates, no optimization needed")
            return candidates
        }
        
        guard let highestConfidenceCandidate = realCandidates.max(by: { $0.confidence < $1.confidence }) else {
            print("🔍 OPTIMIZATION - No highest confidence candidate found")
            return candidates
        }
        
        // Check if we would need a negative scroll offset to center this arrangement
        // This is the key insight: we need to predict what the scroll calculation will determine
        
        // Simulate the scroll offset calculation that will happen later
        // Use actual scroll view if available, otherwise skip optimization
        guard let scrollView = candidateScrollView else {
            print("🔍 OPTIMIZATION - No scroll view available for simulation")
            return candidates
        }
        
        let scrollViewWidth = scrollView.bounds.width > 0 ? scrollView.bounds.width : 474.0 // Fallback
        let scrollViewCenterX = scrollViewWidth / 2
        
        // Estimate where the highest confidence candidate will be positioned
        // This is a simplified calculation based on even spacing
        let estimatedCandidateWidth: CGFloat = 60 // Reasonable average
        let spacing: CGFloat = 8
        let leadingPadding: CGFloat = 8
        
        guard let highestIndex = candidates.firstIndex(where: { candidate in
            !candidate.isDummy && candidate.text == highestConfidenceCandidate.text && candidate.confidence == highestConfidenceCandidate.confidence
        }) else {
            print("🔍 OPTIMIZATION - Could not find highest confidence candidate in array")
            return candidates
        }
        
        // Estimate the center position of the highest confidence candidate
        let estimatedCandidateCenterX = leadingPadding + (CGFloat(highestIndex) * (estimatedCandidateWidth + spacing)) + (estimatedCandidateWidth / 2)
        let estimatedDesiredOffset = estimatedCandidateCenterX - scrollViewCenterX
        
        print("🔍 OPTIMIZATION - Step 2: Scroll offset simulation")
        print("Highest confidence candidate at index: \(highestIndex)")
        print("Estimated candidate center X: \(estimatedCandidateCenterX)")
        print("Scroll view center X: \(scrollViewCenterX)")
        print("Estimated desired offset: \(estimatedDesiredOffset)")
        
        // If the estimated desired offset is significantly negative (would require negative scrolling),
        // then we should optimize by removing the leftmost candidate
        let negativeOffsetThreshold: CGFloat = -20.0 // Only optimize if offset would be significantly negative
        
        if estimatedDesiredOffset < negativeOffsetThreshold {
            print("🔍 OPTIMIZATION - Step 3: Estimated negative scroll offset detected, optimizing")
            
            // Remove the lowest confidence candidate to improve balance
            let sortedRealCandidates = realCandidates.sorted { $0.confidence > $1.confidence }
            let candidatesToKeep = max(5, realCandidates.count - 1) // Keep at least 5, remove at most 1
            let keptCandidates = Array(sortedRealCandidates.prefix(candidatesToKeep))
            
            print("🔍 OPTIMIZATION - Step 4: Removing lowest confidence candidate")
            print("Removing: \(sortedRealCandidates.last?.text ?? "none")")
            print("Keeping \(keptCandidates.count): \(keptCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
            
            // Re-arrange with the reduced set
            let rebalanced = distributeRadially(keptCandidates)
            
            print("🔍 OPTIMIZATION - Step 5: Rebalanced arrangement")
            print("Rebalanced (\(rebalanced.count)): \(rebalanced.map { $0.isDummy ? "DUMMY" : "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
            
            return rebalanced
        }
        
        print("🔍 OPTIMIZATION - No significant negative offset predicted, no optimization needed")
        return candidates
    }
    
    /// Calculates scroll position to center the highest confidence candidate
    private func calculateScrollPositionForHighestConfidence(_ candidates: [Candidate], in scrollView: UIScrollView, stackView: UIStackView) -> CGPoint {
        print("\n🔍 SCROLL CALCULATION - Step 1: Finding highest confidence candidate")
        
        // Find the highest confidence non-dummy candidate
        guard let highestConfidenceCandidate = candidates.filter({ !$0.isDummy }).max(by: { $0.confidence < $1.confidence }) else {
            print("❌ No highest confidence candidate found")
            return scrollView.contentOffset
        }
        
        print("Found highest: '\(highestConfidenceCandidate.text)' with confidence \(String(format: "%.3f", highestConfidenceCandidate.confidence))")
        
        // Check if content fits entirely within scroll view (with small tolerance for minor overflow)
        let contentWidth = scrollView.contentSize.width
        let scrollViewWidth = scrollView.bounds.width
        let tolerance: CGFloat = 10.0 // Allow up to 10 points of overflow to still be considered "fits entirely"
        let contentFitsEntirely = contentWidth <= (scrollViewWidth + tolerance)
        
        print("🔍 SCROLL CALCULATION - Step 2: Content size analysis")
        print("Content width: \(contentWidth), ScrollView width: \(scrollViewWidth)")
        print("Tolerance: \(tolerance), Effective threshold: \(scrollViewWidth + tolerance)")
        print("Content fits entirely: \(contentFitsEntirely)")
        
        if contentFitsEntirely {
            print("🔍 SCROLL CALCULATION - Content fits entirely, but centering selected candidate instead of content")
            // Even when content fits entirely, center the selected candidate for visual consistency
            // This ensures the selected candidate always appears in the middle of the scroll view
        }
        
        // Always use candidate-based centering for visual consistency
        // Clear any existing content insets
        scrollView.contentInset = UIEdgeInsets.zero
        
        // Find the index of this candidate in the arranged candidates array
        guard let highestConfidenceIndex = candidates.firstIndex(where: { candidate in
            !candidate.isDummy && candidate.text == highestConfidenceCandidate.text && candidate.confidence == highestConfidenceCandidate.confidence
        }) else {
            print("❌ Could not find index for highest confidence candidate '\(highestConfidenceCandidate.text)'")
            return scrollView.contentOffset
        }
        
        print("🔍 SCROLL CALCULATION - Step 3: Found candidate at index \(highestConfidenceIndex)")
        print("Candidate array: \(candidates.enumerated().map { "[\($0.offset)]\($0.element.isDummy ? "DUMMY" : $0.element.text)" }.joined(separator: ", "))")
        
        // Ensure the index is valid for the stack view
        guard highestConfidenceIndex < stackView.arrangedSubviews.count else { 
            print("❌ Index \(highestConfidenceIndex) out of bounds for \(stackView.arrangedSubviews.count) views")
            return scrollView.contentOffset 
        }
        
        let candidateView = stackView.arrangedSubviews[highestConfidenceIndex]
        let candidateFrame = candidateView.frame
        
        print("🔍 SCROLL CALCULATION - Step 4: Frame analysis")
        print("Candidate view frame: \(candidateFrame)")
        print("Scroll view bounds: \(scrollView.bounds)")
        print("Scroll view content size: \(scrollView.contentSize)")
        print("Current scroll offset: \(scrollView.contentOffset)")
        
        // Calculate the center position of the candidate relative to the stack view
        let candidateCenterX = candidateFrame.midX
        
        // Calculate the desired scroll offset to center this candidate in the scroll view
        let scrollViewCenterX = scrollViewWidth / 2
        let desiredOffset = candidateCenterX - scrollViewCenterX
        
        // For overflow cases, ensure offset is within valid bounds
        // For fits-entirely cases, prevent negative offsets that would push candidates off-screen
        let clampedOffset: CGFloat
        if contentFitsEntirely {
            // When content fits entirely, we should avoid negative offsets that push candidates off-screen
            // Instead, we rely on the optimizeArrangementForFitting method to ensure good balance
            clampedOffset = max(0, desiredOffset)
        } else {
            // Standard clamping for overflow cases
            let maxOffset = max(0, contentWidth - scrollViewWidth)
            clampedOffset = max(0, min(desiredOffset, maxOffset))
        }
        
        print("🔍 SCROLL CALCULATION - Step 5: Position calculations")
        print("Candidate center X: \(candidateCenterX)")
        print("Scroll view center X: \(scrollViewCenterX)")
        print("Desired offset: \(desiredOffset)")
        if contentFitsEntirely {
            print("Content fits entirely - preventing negative offsets, relying on arrangement optimization")
        } else {
            let maxOffset = max(0, contentWidth - scrollViewWidth)
            print("Content overflows - clamping to bounds. Max offset: \(maxOffset)")
        }
        print("Final offset: \(clampedOffset)")
        
        print("🎯 FINAL: Centering candidate '\(highestConfidenceCandidate.text)' at index \(highestConfidenceIndex) with scroll offset \(clampedOffset)")
        
        return CGPoint(x: clampedOffset, y: scrollView.contentOffset.y)
    }
    
    // MARK: - Sample Data Method
    private func getCandidates() -> [Candidate] {
        // Sample Tamil words with annotations and realistic confidence scores
        let sampleWordsWithAnnotations: [(String, String?, Float)] = [
            ("காலை", "விடியல்", 0.95),
            ("காளை", "எருது", 0.88),
            ("கால்", "leg", 0.92),
            ("கல்", "stone", 0.85),
            ("அம்மா", "mother", 0.98),
            ("அப்பா", "father", 0.97),
            ("அண்ணா", "brother", 0.91),
            ("அக்கா", "sister", 0.89),
            ("தங்கை", "younger sister", 0.87),
            ("தம்பி", "younger brother", 0.86),
            ("வணக்கம்", "greeting", 0.94),
            ("நன்றி", "thanks", 0.96),
            ("மன்னிப்பு", "sorry", 0.83),
            ("இல்லை", "no", 0.99),
            ("ஆம்", "yes", 0.99),
            ("இங்கே", "here", 0.90),
            ("அங்கே", "there", 0.88),
            ("எங்கே", "where", 0.85),
            ("என்ன", "what", 0.93),
            ("எப்போது", "when", 0.82),
            ("எப்படி", "how", 0.84),
            ("யார்", "who", 0.91),
            ("எதற்கு", "why", 0.78),
            ("நல்லது", "good", 0.95),
            ("கெட்டது", "bad", 0.77),
            ("அழகு", "beauty", 0.86),
            ("பூ", "flower", 0.89),
            ("மரம்", "tree", 0.87),
            ("நீர்", "water", 0.92),
            ("வானம்", "sky", 0.88),
            ("நிலவு", "moon", 0.85),
            ("கதிரவன்", "sun", 0.83),
            ("மலை", "mountain", 0.81),
            ("கடல்", "sea", 0.84),
            ("பறவை", "bird", 0.80)
        ]
        
        // Randomly select 6-10 candidates
        let shuffled = sampleWordsWithAnnotations.shuffled()
        let candidateCount = Int.random(in: 6...10)
        let rawCandidates = Array(shuffled.prefix(candidateCount)).map { (word, annotation, confidence) in
            Candidate(word, annotation: annotation, confidence: confidence)
        }
        
        print("\n🔍 CANDIDATE GENERATION - Step 1: Raw candidates")
        print("Raw candidates (\(rawCandidates.count)): \(rawCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        // Sort by confidence score (highest first)
        let sortedCandidates = rawCandidates.sorted { $0.confidence > $1.confidence }
        
        print("🔍 CANDIDATE GENERATION - Step 2: After sorting")
        print("Sorted candidates (\(sortedCandidates.count)): \(sortedCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
        
        // Boost the top candidate's confidence to ensure it's uniquely the highest
        // This prevents duplicate confidence scores from causing centering issues
        if let topCandidate = sortedCandidates.first {
            let boostedTopCandidate = Candidate(
                topCandidate.text,
                annotation: topCandidate.annotation,
                confidence: topCandidate.confidence + 0.001, // Small boost to make it unique
                isDummy: topCandidate.isDummy
            )
            
            let finalCandidates = [boostedTopCandidate] + Array(sortedCandidates.dropFirst())
            
            print("🔍 CANDIDATE GENERATION - Step 3: After boosting top candidate")
            print("Final candidates (\(finalCandidates.count)): \(finalCandidates.map { "\($0.text)[\(String(format: "%.3f", $0.confidence))]" }.joined(separator: ", "))")
            print("🎯 TOP CANDIDATE: '\(boostedTopCandidate.text)' with confidence \(String(format: "%.3f", boostedTopCandidate.confidence)) (boosted)\n")
            
            return finalCandidates
        }
        
        print("🎯 Generated \(sortedCandidates.count) candidates, top confidence: \(sortedCandidates.first?.confidence ?? 0)")
        
        return sortedCandidates
    }
    
    // MARK: - Setup Methods
    private func setupLogicController() {
        // Initialize with Tamil as default - you can change this or make it configurable
        logicController = KeyboardLogicController(
            language: keyboardLanguage,  // Uses subclass's language
            appGroupIdentifier: "group.murasu.Sangam"
        )
        logicController.delegate = self
        logicController.themeObserver = self
    }
    
    private func setupUI() {
        // Main container
        let mainContainer = UIView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainContainer)
        
        // Calculate horizontal padding (iPhone landscape only)
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let horizontalPadding: CGFloat = (isLandscape && isPhone) ? 80 : 0
        
        // Add vertical padding (top and bottom)
        let verticalPadding: CGFloat = 6  // Adjust this value as needed (try 8-12)

        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalPadding),
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalPadding)
        ])
        
        mainContainer.tag = 999
        
        // Candidate bar container (if needed)
        if usesCandidateBar {
            candidateBarContainer = UIView()
            candidateBarContainer.translatesAutoresizingMaskIntoConstraints = false
            candidateBarContainer.backgroundColor = UIColor.systemGray6
            mainContainer.addSubview(candidateBarContainer)
            
            // Use the helper method to get correct height
            let candidateHeight = KeyboardMetrics.candidateBarHeight(
                for: traitCollection,
                useAnnotatedCandidates: usesAnnotatedCandidates
            )
            
            // Store reference to height constraint so we can update it on orientation change
            candidateBarHeightConstraint = candidateBarContainer.heightAnchor.constraint(equalToConstant: candidateHeight)
            
            NSLayoutConstraint.activate([
                candidateBarContainer.topAnchor.constraint(equalTo: mainContainer.topAnchor),
                candidateBarContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
                candidateBarContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
                candidateBarHeightConstraint!
            ])
            
            setupCandidateBar()
        }
        
        // Keyboard container
        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add horizontal padding for keyboard container
        keyboardContainer.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        
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
    
    private func applyBackgroundGradient() {
        guard let theme = logicController.getCurrentTheme() else { return }
        
        // Remove existing gradient layers
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        if let gradientColors = theme.keyboardBackgroundGradient, gradientColors.count > 1 {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = view.bounds
            gradientLayer.colors = gradientColors.map { $0.cgColor }
            
            // Set gradient direction
            switch theme.keyboardBackgroundGradientDirection {
            case .vertical:
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            case .horizontal:
                gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            case .diagonalTopLeftToBottomRight:
                gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
            case .diagonalTopRightToBottomLeft:
                gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
            @unknown default:
                // Default to vertical gradient for any unknown future cases
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            }
            
            // Apply corner radius to gradient layer as well
            gradientLayer.cornerRadius = theme.keyboardBackgroundCornerRadius
            gradientLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            view.layer.insertSublayer(gradientLayer, at: 0)
        } else {
            // Solid color background
            view.backgroundColor = theme.keyboardBackground
        }
        
        // Apply keyboard background corner radius
        applyKeyboardBackgroundCornerRadius(theme: theme)
    }
    
    private func applyKeyboardBackgroundCornerRadius(theme: KeyboardTheme) {
        // Use uniform corner radius only - more performant and reliable
        let cornerRadius = theme.keyboardBackgroundCornerRadius
        
        print("🔍 DEBUG: Applying keyboard background corner radius: \(cornerRadius)")
        print("🔍 DEBUG: View bounds: \(view.bounds)")
        
        if cornerRadius > 0 {
            view.layer.mask = nil // Remove any existing mask
            view.layer.cornerRadius = cornerRadius
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                       .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            print("🔍 DEBUG: Applied corner radius \(cornerRadius) to view layer")
        } else {
            // No corner radius
            view.layer.mask = nil
            view.layer.cornerRadius = 0
            view.layer.maskedCorners = []
            
            print("🔍 DEBUG: No corner radius applied (cornerRadius was \(cornerRadius))")
        }
    }
    
    private func applyCandidateBarCornerRadius(theme: KeyboardTheme) {
        let cornerRadius = theme.candidateBarCornerRadius
        
        if cornerRadius > 0 {
            candidateBarContainer.layer.cornerRadius = cornerRadius
            candidateBarContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                                         .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            // No corner radius
            candidateBarContainer.layer.cornerRadius = 0
            candidateBarContainer.layer.maskedCorners = []
        }
    }
    
    
    private func setupCandidateBar() {
        guard let theme = logicController.getCurrentTheme() else { return }
        
        // Clear the candidate bar background - we want it transparent
        candidateBarContainer.backgroundColor = .clear
        candidateBarContainer.layer.borderWidth = 0
        
        // Create left button (language switcher)
        let leftButton = createLanguageSwitcherButton()
        candidateBarContainer.addSubview(leftButton)
        
        // Create right button (options menu)
        let rightButton = createOptionsMenuButton()
        candidateBarContainer.addSubview(rightButton)
        
        // Create horizontal scroll view
        candidateScrollView = UIScrollView()
        candidateScrollView.translatesAutoresizingMaskIntoConstraints = false
        candidateScrollView.showsHorizontalScrollIndicator = false
        candidateScrollView.showsVerticalScrollIndicator = false
        candidateScrollView.bounces = true
        candidateScrollView.contentInsetAdjustmentBehavior = .never
        candidateScrollView.delegate = self
        
        candidateBarContainer.addSubview(candidateScrollView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Left button
            leftButton.leadingAnchor.constraint(equalTo: candidateBarContainer.leadingAnchor, constant: 8),
            leftButton.centerYAnchor.constraint(equalTo: candidateBarContainer.centerYAnchor),
            leftButton.widthAnchor.constraint(equalToConstant: 32),
            leftButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Right button
            rightButton.trailingAnchor.constraint(equalTo: candidateBarContainer.trailingAnchor, constant: -8),
            rightButton.centerYAnchor.constraint(equalTo: candidateBarContainer.centerYAnchor),
            rightButton.widthAnchor.constraint(equalToConstant: 32),
            rightButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Candidate scroll view (between buttons with reduced padding)
            candidateScrollView.topAnchor.constraint(equalTo: candidateBarContainer.topAnchor),
            candidateScrollView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 4), // Reduced from 8 to 4
            candidateScrollView.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: -4), // Reduced from -8 to -4
            candidateScrollView.bottomAnchor.constraint(equalTo: candidateBarContainer.bottomAnchor)
        ])
        
        // Create stack view for candidates
        candidateStackView = UIStackView()
        candidateStackView.axis = .horizontal
        candidateStackView.distribution = .fill
        candidateStackView.spacing = 8 // Space between candidate pills
        candidateStackView.translatesAutoresizingMaskIntoConstraints = false
        
        candidateScrollView.addSubview(candidateStackView)
        
        // Adjust vertical positioning based on iOS version and device orientation
        let topPadding: CGFloat
        let bottomPadding: CGFloat
        
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        if isLandscape && isPhone {
            // iPhone landscape: minimal padding to maximize candidate space
            topPadding = 2
            bottomPadding = 2
        } else if #available(iOS 26.0, *) {
            // iOS 26+: Push candidates up, more padding below than top
            topPadding = 2
            bottomPadding = 10
        } else {
            // iOS 15 and earlier: Centered padding
            topPadding = 6
            bottomPadding = 6
        }
        
        NSLayoutConstraint.activate([
            candidateStackView.topAnchor.constraint(equalTo: candidateScrollView.topAnchor, constant: topPadding),
            candidateStackView.leadingAnchor.constraint(equalTo: candidateScrollView.leadingAnchor, constant: 8),
            candidateStackView.trailingAnchor.constraint(equalTo: candidateScrollView.trailingAnchor, constant: -8),
            candidateStackView.bottomAnchor.constraint(equalTo: candidateScrollView.bottomAnchor, constant: -bottomPadding),
            candidateStackView.heightAnchor.constraint(equalTo: candidateScrollView.heightAnchor, constant: -(topPadding + bottomPadding))
        ])
        
        // Add gradient overlays
        addGradientOverlays(to: candidateBarContainer, leftButton: leftButton, rightButton: rightButton)
        
        // Get candidates and populate
        let candidates = getCandidates()
        populateCandidates(candidates, theme: theme)
        
        // Update gradient visibility after layout (no animation)
        DispatchQueue.main.async {
            self.updateGradientVisibility(animated: false)
        }
    }
    
    private func addGradientOverlays(to container: UIView, leftButton: UIButton, rightButton: UIButton) {
        guard let theme = logicController.getCurrentTheme() else { return }
        
        // Get the button background color to match the gradient fade
        // Since candidateBarContainer is transparent (.clear), the gradient should fade
        // to the button background color to create seamless blending effect
        let fadeColor: UIColor
        if traitCollection.userInterfaceStyle == .dark {
            fadeColor = UIColor.systemGray6.withAlphaComponent(0.3)
        } else {
            fadeColor = UIColor.systemGray5.withAlphaComponent(0.3)
        }
        
        // Create left gradient overlay (fades from candidate bar background to transparent)
        let leftGradient = UIView()
        leftGradient.translatesAutoresizingMaskIntoConstraints = false
        leftGradient.isUserInteractionEnabled = false // Allow touches to pass through
        leftGradient.backgroundColor = .clear
        
        // Create right gradient overlay (fades from transparent to candidate bar background)
        let rightGradient = UIView()
        rightGradient.translatesAutoresizingMaskIntoConstraints = false
        rightGradient.isUserInteractionEnabled = false // Allow touches to pass through  
        rightGradient.backgroundColor = .clear
        
        // Add to container
        container.addSubview(leftGradient)
        container.addSubview(rightGradient)
        
        // Store references for later visibility control
        leftGradientView = leftGradient
        rightGradientView = rightGradient
        
        // Make them wider and overlap the buttons slightly to eliminate any visible line
        let gradientWidth: CGFloat = 24
        
        NSLayoutConstraint.activate([
            // Left gradient overlay - start slightly overlapping the button
            leftGradient.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: -2),
            leftGradient.topAnchor.constraint(equalTo: container.topAnchor),
            leftGradient.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            leftGradient.widthAnchor.constraint(equalToConstant: gradientWidth),
            
            // Right gradient overlay - end slightly overlapping the button  
            rightGradient.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: 2),
            rightGradient.topAnchor.constraint(equalTo: container.topAnchor),
            rightGradient.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            rightGradient.widthAnchor.constraint(equalToConstant: gradientWidth)
        ])
        
        // Add gradient layers after layout
        DispatchQueue.main.async {
            // Ensure views have proper frames before adding gradients
            container.layoutIfNeeded()
            
            if leftGradient.bounds.width > 0 && leftGradient.bounds.height > 0 {
                let leftGradientLayer = CAGradientLayer()
                leftGradientLayer.frame = leftGradient.bounds
                leftGradientLayer.colors = [
                    fadeColor.cgColor, // Start with full button background color
                    fadeColor.withAlphaComponent(0.8).cgColor, // Gradual fade
                    fadeColor.withAlphaComponent(0.4).cgColor, // More fade
                    UIColor.clear.cgColor // End transparent towards candidates
                ]
                leftGradientLayer.locations = [0.0, 0.3, 0.7, 1.0] // Control fade curve
                leftGradientLayer.startPoint = CGPoint(x: 0, y: 0.5) // Start at left (button side)
                leftGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)   // End at right (candidate side)
                leftGradient.layer.addSublayer(leftGradientLayer)
                print("🎨 Added LEFT fade gradient with overlap")
            }
            
            if rightGradient.bounds.width > 0 && rightGradient.bounds.height > 0 {
                let rightGradientLayer = CAGradientLayer()
                rightGradientLayer.frame = rightGradient.bounds
                rightGradientLayer.colors = [
                    UIColor.clear.cgColor, // Start transparent towards candidates
                    fadeColor.withAlphaComponent(0.4).cgColor, // Start fading in
                    fadeColor.withAlphaComponent(0.8).cgColor, // More color
                    fadeColor.cgColor // End with full button background color
                ]
                rightGradientLayer.locations = [0.0, 0.3, 0.7, 1.0] // Control fade curve
                rightGradientLayer.startPoint = CGPoint(x: 0, y: 0.5) // Start at left (candidate side)
                rightGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)   // End at right (button side)
                rightGradient.layer.addSublayer(rightGradientLayer)
                print("🎨 Added RIGHT fade gradient with overlap")
            }
            
            // Initially hide gradients - they'll be shown based on content
            leftGradient.alpha = 0
            rightGradient.alpha = 0
        }
    }
    
    // MARK: - Gradient Visibility Management
    
    private func updateGradientVisibility(animated: Bool = true) {
        guard let scrollView = candidateScrollView,
              let leftGradient = leftGradientView,
              let rightGradient = rightGradientView else { return }
        
        // Force layout to ensure correct measurements
        scrollView.layoutIfNeeded()
        
        let contentWidth = scrollView.contentSize.width
        let scrollViewWidth = scrollView.frame.width
        let currentOffset = scrollView.contentOffset.x
        
        // Determine if scrolling is possible or if content is offset (including negative offsets)
        let canScroll = contentWidth > scrollViewWidth
        let isContentOffset = abs(currentOffset) > 1 // Content is shifted from natural position
        
        // Calculate visibility states
        // Show left gradient if we can scroll right or if content is shifted left (negative offset)
        let showLeftGradient = (canScroll && currentOffset > 1) || (currentOffset < -1)
        // Show right gradient if we can scroll left or if content is shifted right beyond normal bounds
        let showRightGradient = (canScroll && currentOffset < (contentWidth - scrollViewWidth - 1)) || 
                               (!canScroll && currentOffset > 1)
        
        let duration = animated ? 0.25 : 0
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            leftGradient.alpha = showLeftGradient ? 1.0 : 0.0
            rightGradient.alpha = showRightGradient ? 1.0 : 0.0
        }
        
        print("🎨 Gradient visibility - Left: \(showLeftGradient), Right: \(showRightGradient)")
        print("🎨 Content: \(contentWidth), ScrollView: \(scrollViewWidth), Offset: \(currentOffset)")
        print("🎨 Can scroll: \(canScroll), Content offset detected: \(abs(currentOffset) > 1)")
    }
    
    private func populateCandidates(_ candidates: [Candidate], theme: KeyboardTheme) {
        print("\n🚀 POPULATE CANDIDATES - Starting new iteration")
        print("═══════════════════════════════════════════════════")
        
        // Arrange candidates for optimal display (highest confidence in center, padded if needed)
        let arrangedCandidates = arrangedCandidatesForDisplay(candidates)
        
        // Clear existing candidates immediately (no animations)
        candidateStackView.arrangedSubviews.forEach { view in
            candidateStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        print("🔍 POPULATE - Step 1: UI Setup")
        print("Cleared \(candidateStackView.arrangedSubviews.count) existing views from stack view")
        
        // Find the real highest confidence candidate (not dummy) for selection highlight
        let realCandidates = arrangedCandidates.filter { !$0.isDummy }
        let highestConfidenceCandidate = realCandidates.max { $0.confidence < $1.confidence }
        
        print("🔍 POPULATE - Step 2: Selection highlight calculation")
        if let highest = highestConfidenceCandidate {
            print("Highest for highlighting: '\(highest.text)' with confidence \(String(format: "%.3f", highest.confidence))")
        } else {
            print("No candidate found for highlighting")
        }
        
        // Create new candidate views
        print("🔍 POPULATE - Step 3: Creating UI views")
        for (index, candidate) in arrangedCandidates.enumerated() {
            let isSelected = candidate.text == highestConfidenceCandidate?.text && !candidate.isDummy
            let candidateView = createStyledCandidateView(
                candidate: candidate,
                isSelected: isSelected,
                theme: theme
            )
            
            // For dummy candidates, make them completely invisible (but keep layout space)
            if candidate.isDummy {
                candidateView.alpha = 0
                candidateView.isUserInteractionEnabled = false
                print("   [\(index)] DUMMY (invisible)")
            } else {
                print("   [\(index)] '\(candidate.text)' confidence: \(String(format: "%.3f", candidate.confidence)) \(isSelected ? "⭐ SELECTED" : "")")
            }
            
            candidateStackView.addArrangedSubview(candidateView)
        }
        
        // Force layout immediately and center highest confidence candidate
        print("🔍 POPULATE - Step 4: Layout and scrolling")
        candidateStackView.layoutIfNeeded()
        candidateScrollView.layoutIfNeeded()
        
        print("Stack view frame after layout: \(candidateStackView.frame)")
        print("Scroll view content size after layout: \(candidateScrollView.contentSize)")
        print("Scroll view bounds: \(candidateScrollView.bounds)")
        
        // Calculate and apply scroll position to center highest confidence candidate
        // Always center the highest confidence candidate, regardless of count
        print("🔍 POPULATE - Step 5: Calculating scroll position for highest confidence candidate")
        let targetScrollPosition = calculateScrollPositionForHighestConfidence(
            arrangedCandidates,
            in: candidateScrollView,
            stackView: candidateStackView
        )
        
        // Set scroll position immediately without animation
        let oldOffset = candidateScrollView.contentOffset
        candidateScrollView.contentOffset = targetScrollPosition
        
        print("Applied scroll position: \(oldOffset) → \(targetScrollPosition)")
        
        // Update gradient visibility immediately
        updateGradientVisibility(animated: false)
        
        print("🎯 POPULATE COMPLETE - \(arrangedCandidates.count) candidates (\(realCandidates.count) real, \(arrangedCandidates.count - realCandidates.count) dummies)")
        print("═══════════════════════════════════════════════════\n")
    }
    
    private func createStyledCandidateView(candidate: Candidate, isSelected: Bool, theme: KeyboardTheme) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Handle dummy candidates - make them invisible but maintain layout space
        if candidate.isDummy {
            // For debugging: show dummy candidates with theme color but very transparent
            // In production, these would be completely invisible
            container.backgroundColor = theme.candidateBarBackground.withAlphaComponent(0.1) // Very subtle for debugging
            container.layer.borderColor = UIColor.clear.cgColor
            container.layer.borderWidth = 0
            container.layer.cornerRadius = theme.candidateCornerRadius
            container.layer.masksToBounds = true
            
            // Add minimum width constraint to maintain spacing
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
            
            // Store empty identifier for dummy
            container.accessibilityIdentifier = ""
            container.isUserInteractionEnabled = false
            
            return container
        }
        
        // Individual background styling with padding
        if isSelected {
            container.backgroundColor = theme.candidateSelectedBackground
            container.layer.borderColor = theme.candidateSelectedBorder.cgColor
            container.layer.borderWidth = theme.candidateSelectedBorderWidth
        } else {
            container.backgroundColor = theme.candidateBarBackground.withAlphaComponent(0.8)
            container.layer.borderColor = theme.candidateBarBorder.cgColor
            container.layer.borderWidth = 1.0
        }
        
        // Apply themeable corner radius to individual candidates
        container.layer.cornerRadius = theme.candidateCornerRadius
        container.layer.masksToBounds = true
        
        // Main text label - always use same font size for consistency
        let label = UILabel()
        label.text = candidate.text
        label.textAlignment = .center
        label.font = theme.candidateFont
        label.textColor = isSelected ? theme.candidateSelectedText : theme.candidateText
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        container.addSubview(label)
        
        var constraints = [
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ]
        
        // Add annotation label if present and using annotated candidates
        // Skip annotations in iPhone landscape to save space
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let shouldShowAnnotation = !isLandscape || !isPhone
        
        if let annotation = candidate.annotation, usesAnnotatedCandidates, shouldShowAnnotation {
            let annotationLabel = UILabel()
            annotationLabel.text = annotation
            annotationLabel.textAlignment = .center
            annotationLabel.font = theme.candidateAnnotationFont
            annotationLabel.textColor = theme.candidateAnnotationText
            annotationLabel.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(annotationLabel)
            
            // Two-line layout: main text above, annotation below
            let topPadding: CGFloat = isLandscape && isPhone ? 4 : 8  // Reduced padding in iPhone landscape
            constraints.append(contentsOf: [
                // Position main text in upper portion (consistent Y position for all candidates)
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: topPadding),
                // Position annotation below main text
                annotationLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                annotationLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
                annotationLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
                annotationLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 8),
                annotationLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8)
            ])
        } else {
            // Single line layout: position main text at SAME Y position as annotated candidates for consistency
            let topPadding: CGFloat = isLandscape && isPhone ? 4 : 8  // Reduced padding in iPhone landscape
            let bottomPadding: CGFloat = isLandscape && isPhone ? -4 : -8  // Reduced padding in iPhone landscape
            constraints.append(contentsOf: [
                // Position at same Y as annotated candidates for visual alignment
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: topPadding),
                // Allow flexible bottom spacing since there's no annotation
                label.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: bottomPadding)
            ])
        }
        
        // Add horizontal padding constraints for main text
        constraints.append(contentsOf: [
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])
        
        NSLayoutConstraint.activate(constraints)
        
        // Add tap gesture (only for non-dummy candidates)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(candidateTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        // Store candidate text for retrieval
        container.accessibilityIdentifier = candidate.text
        
        return container
    }
    
    // MARK: - Candidate Bar Button Helpers
    
    private func createLanguageSwitcherButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the Tamil character
        button.setTitle("க", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        // Subtle appearance for both light and dark modes
        if traitCollection.userInterfaceStyle == .dark {
            button.setTitleColor(.systemGray, for: .normal)
            button.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        } else {
            button.setTitleColor(.systemGray2, for: .normal)
            button.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.3)
        }
        
        button.layer.cornerRadius = 6
        
        // Add tap action
        button.addAction(UIAction { [weak self] _ in
            self?.handleLanguageSwitcherTap()
        }, for: .touchUpInside)
        
        return button
    }
    
    private func createOptionsMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Use system ellipsis icon
        if let menuImage = UIImage(systemName: "ellipsis.circle") {
            button.setImage(menuImage, for: .normal)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        // Subtle appearance for both light and dark modes
        if traitCollection.userInterfaceStyle == .dark {
            button.tintColor = .systemGray
            button.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        } else {
            button.tintColor = .systemGray2
            button.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.3)
        }
        
        button.layer.cornerRadius = 6
        
        // Add tap action
        button.addAction(UIAction { [weak self] _ in
            self?.showOptionsMenu(from: button)
        }, for: .touchUpInside)
        
        return button
    }
    
    @objc private func handleLanguageSwitcherTap() {
        print("🌐 Second language switch functionality to be implemented. This will allow users to quickly switch between primary and secondary language layouts for multilingual typing support.")
    }
    
    private func showOptionsMenu(from sourceButton: UIButton) {
        // Create custom popup menu (no animation preference needed anymore)
        let menuView = OptionsMenuView { [weak self] action in
            switch action {
            case .theme:
                self?.switchToNextTheme()
            case .stickers:
                print("🎨 Stickers functionality to be implemented. This will provide access to emoji, stickers, and other visual elements for enhanced messaging experience.")
            case .dismiss:
                break // Just dismiss
            }
        }
        
        menuView.show(from: sourceButton, in: view)
    }

    
    private func switchToNextTheme() {
        let availableThemes = logicController.getAvailableThemes()
        let currentThemeId = logicController.getCurrentThemeId()
        
        // Find current theme index
        guard let currentIndex = availableThemes.firstIndex(where: { $0.id == currentThemeId }) else {
            print("⚠️ Current theme not found in available themes")
            return
        }
        
        // Calculate next theme index (wrap around to first if at end)
        let nextIndex = (currentIndex + 1) % availableThemes.count
        let nextTheme = availableThemes[nextIndex]
        
        // Switch to next theme
        logicController.setTheme(nextTheme.id)
        
        print("🎨 Switched to theme: \(nextTheme.name)")
        
        // Refresh the keyboard UI with new theme
        DispatchQueue.main.async {
            self.buildKeyboard()
        }
    }
    
    @objc private func candidateTapped(_ gesture: UITapGestureRecognizer) {
        guard let candidateView = gesture.view,
              let candidateText = candidateView.accessibilityIdentifier,
              !candidateText.isEmpty else { return } // Skip empty (dummy) candidates
        
        // Insert the selected candidate
        logicController.delegate?.insertText(candidateText)
        
        // Optionally update candidates after selection
        if let theme = logicController.getCurrentTheme() {
            let newCandidates = getCandidates()
            populateCandidates(newCandidates, theme: theme)
        }
        
        // Provide haptic feedback
        logicController.delegate?.performHapticFeedback(style: .light)
    }
    
    // MARK: - Public Candidate Methods (for future prediction engine integration)
    
    /// Updates the candidate bar with new candidates
    /// - Parameter candidates: Array of candidate structs
    public func updateCandidates(_ candidates: [Candidate]) {
        guard let theme = logicController.getCurrentTheme() else { return }
        DispatchQueue.main.async {
            self.populateCandidates(candidates, theme: theme)
        }
    }
    
    /// Refreshes candidates with new random sample data
    public func refreshCandidates() {
        guard let theme = logicController.getCurrentTheme() else { return }
        let candidates = getCandidates()
        DispatchQueue.main.async {
            self.populateCandidates(candidates, theme: theme)
        }
    }
    
    /// Clears all candidates from the candidate bar
    public func clearCandidates() {
        DispatchQueue.main.async {
            self.candidateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            self.updateGradientVisibility()
        }
    }
    
    /// Refreshes candidates for each keystroke - optimized for performance
    /// This method is called frequently so it's designed to be lightweight
    private func refreshCandidatesForKeystroke() {
        guard let theme = logicController.getCurrentTheme() else { return }
        
        // Generate new candidates (in a real implementation, this would come from prediction engine)
        let candidates = getCandidates()
        
        // Use efficient population method
        populateCandidates(candidates, theme: theme)
        
        print("🎯 Refreshed candidates for keystroke")
    }
    
    private func buildKeyboard() {
        // Remove existing keyboard view
        currentKeyboardView?.removeFromSuperview()
        currentKeyboardView = nil
        
        guard let layout = logicController.getCurrentLayout() else {
            print("Failed to get layout from logic controller")
            return
        }
        
        // Get current theme from logic controller
        guard let theme = logicController.getCurrentTheme() else {
            print("Failed to get theme from logic controller")
            return
        }
        
        print("🎨 Building keyboard with theme")
        
        // Rebuild candidate bar with new theme
        if usesCandidateBar {
            candidateBarContainer.subviews.forEach { $0.removeFromSuperview() }
            setupCandidateBar()
        }
        
        // Build new keyboard view with theme
        let keyboardView = KeyboardBuilder.buildKeyboard(
            layout: layout,
            containerView: keyboardContainer,
            theme: theme,
            shouldIncludeGlobeKey: shouldShowGlobeKey,
            viewController: self
        ) { [weak self] key in
            self?.logicController.handleKeyPress(key)
        }
        
        applyBackgroundGradient()
        
        keyboardContainer.addSubview(keyboardView)
        currentKeyboardView = keyboardView
        
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardContainer.layoutMarginsGuide.leadingAnchor),  // Changed
            keyboardView.trailingAnchor.constraint(equalTo: keyboardContainer.layoutMarginsGuide.trailingAnchor), // Changed
            keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor)
        ])
        
        // Force layout and apply background again to ensure proper bounds
        view.layoutIfNeeded()
        applyBackgroundGradient()
        
        // Update shift key appearance based on current state
        updateShiftKeyAppearance()
    }

    private func updateShiftKeyAppearance() {
        guard let keyboardView = currentKeyboardView,
              let theme = logicController.getCurrentTheme() else { return }
        
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: logicController.keyboardState == .shifted,
            locked: logicController.isShiftLocked,
            theme: theme
        )
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Remove existing height constraints
        view.constraints.forEach { constraint in
            if constraint.firstAttribute == .height && constraint.firstItem === view {
                view.removeConstraint(constraint)
            }
        }
        
        // Calculate proper height using new metrics system
        let keyboardHeight = KeyboardMetrics.keyboardHeight(
            for: traitCollection,
            includesCandidateBar: usesCandidateBar,
            useAnnotatedCandidates: usesAnnotatedCandidates
        )
        
        let heightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: keyboardHeight
        )
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.identifier = "KeyboardHeight"
        view.addConstraint(heightConstraint)
    }
}

// MARK: - UIScrollViewDelegate
extension KeyboardViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only update gradients for the candidate scroll view
        if scrollView === candidateScrollView {
            updateGradientVisibility()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Ensure gradients are properly updated when scrolling stops
        if scrollView === candidateScrollView {
            updateGradientVisibility()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Update gradients when user finishes dragging
        if scrollView === candidateScrollView && !decelerate {
            updateGradientVisibility()
        }
    }
}

// MARK: - KeyboardLogicDelegate
extension KeyboardViewController: KeyboardLogicDelegate {
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        
        // Update candidates for each keystroke (if using candidate bar)
        if usesCandidateBar {
            DispatchQueue.main.async {
                self.refreshCandidatesForKeystroke()
            }
        }
    }
    
    func deleteBackward(count: Int) {
        for _ in 0..<count {
            textDocumentProxy.deleteBackward()
        }
        
        // Update candidates for each deletion (if using candidate bar)
        if usesCandidateBar {
            DispatchQueue.main.async {
                self.refreshCandidatesForKeystroke()
            }
        }
    }
    
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Perform Haptic feedback only if iOS >= 16
        guard #available(iOS 16.0, *) else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func updateKeyboardView() {
        DispatchQueue.main.async {
            self.buildKeyboard()
        }
    }
    
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle {
        return traitCollection.userInterfaceStyle
    }
    
    func switchToNextKeyboard() {
        advanceToNextInputMode()
    }
    
    func playKeyClickSound(soundID: UInt32) {
        if #available(iOS 16.0, *) {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}

// MARK: - KeyboardThemeObserver
extension KeyboardViewController: KeyboardThemeObserver {
    func themeDidChange() {
        DispatchQueue.main.async {
            // Theme changed - rebuild keyboard with new theme
            self.buildKeyboard()
        }
    }
}

// MARK: - Custom Options Menu

enum OptionsMenuAction {
    case theme
    case stickers
    case dismiss
}

class OptionsMenuView: UIView {
    private let actionHandler: (OptionsMenuAction) -> Void
    private var backdropView: UIView?
    private var menuContainer: UIView!
    
    init(actionHandler: @escaping (OptionsMenuAction) -> Void) {
        self.actionHandler = actionHandler
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        // Create menu container
        menuContainer = UIView()
        menuContainer.backgroundColor = .systemBackground
        menuContainer.layer.cornerRadius = 12
        menuContainer.layer.shadowColor = UIColor.black.cgColor
        menuContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        menuContainer.layer.shadowRadius = 12
        menuContainer.layer.shadowOpacity = 0.3
        menuContainer.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(menuContainer)
        
        // Create buttons stack
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Theme button
        let themeButton = createMenuButton(title: "Theme", action: .theme)
        stackView.addArrangedSubview(themeButton)
        
        // Add separator
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stackView.addArrangedSubview(separator)
        
        // Stickers button
        let stickersButton = createMenuButton(title: "Stickers", action: .stickers)
        stackView.addArrangedSubview(stickersButton)
        
        menuContainer.addSubview(stackView)
        
        // Layout constraints - fill the entire view
        NSLayoutConstraint.activate([
            // Menu container fills this view
            menuContainer.topAnchor.constraint(equalTo: topAnchor),
            menuContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            menuContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Stack view inside container
            stackView.topAnchor.constraint(equalTo: menuContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: menuContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: menuContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: menuContainer.bottomAnchor)
        ])
    }
    
    private func createMenuButton(title: String, action: OptionsMenuAction) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Use modern UIButton.Configuration for iOS 15+
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 16)
                outgoing.foregroundColor = UIColor.label
                return outgoing
            }
            config.background.backgroundColor = .clear
            
            // Configure highlight behavior
            config.background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                return UIColor.systemGray5.withAlphaComponent(0.3)
            }
            
            button.configuration = config
            button.configurationUpdateHandler = { button in
                switch button.state {
                case .highlighted:
                    button.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.3)
                default:
                    button.backgroundColor = .clear
                }
            }
        } else {
            // Fallback for iOS 14 and earlier
            button.setTitle(title, for: .normal)
            button.setTitleColor(.label, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.backgroundColor = .clear
            button.setBackgroundColor(UIColor.systemGray5.withAlphaComponent(0.3), for: .highlighted)
        }
        
        button.addAction(UIAction { [weak self] _ in
            print("🎯 Menu button tapped: \(title)")
            self?.actionHandler(action)
            self?.dismiss()
        }, for: .touchUpInside)
        
        // Height constraint
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    func show(from sourceButton: UIButton, in containerView: UIView) {
        print("🎯 Showing options menu...")
        
        // Create backdrop
        backdropView = UIView()
        backdropView!.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        backdropView!.alpha = 0
        backdropView!.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(backdropView!)
        
        // Add tap to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
        backdropView!.addGestureRecognizer(tapGesture)
        
        // Add self to container
        containerView.addSubview(self)
        
        // Calculate position BELOW the button (within keyboard bounds)
        let buttonFrame = sourceButton.convert(sourceButton.bounds, to: containerView)
        let menuWidth: CGFloat = 120
        let menuHeight: CGFloat = 88 // 44 * 2 buttons
        let padding: CGFloat = 8
        
        print("🎯 Button frame: \(buttonFrame)")
        print("🎯 Container bounds: \(containerView.bounds)")
        
        // Calculate X position (centered on button, but ensure it fits in container)
        let preferredX = buttonFrame.midX - (menuWidth / 2)
        let minX: CGFloat = 8
        let maxX = containerView.bounds.width - menuWidth - 8
        let actualX = max(minX, min(preferredX, maxX))
        
        // Calculate Y position (BELOW button, within keyboard bounds)
        let actualY = buttonFrame.maxY + padding
        
        // Ensure menu doesn't go outside bottom of container
        let maxY = containerView.bounds.height - menuHeight - 8
        let finalY = min(actualY, maxY)
        
        print("🎯 Menu will be positioned at: (\(actualX), \(finalY))")
        
        NSLayoutConstraint.activate([
            // Backdrop fills entire container
            backdropView!.topAnchor.constraint(equalTo: containerView.topAnchor),
            backdropView!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backdropView!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backdropView!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Position menu below button (within keyboard bounds)
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: actualX),
            topAnchor.constraint(equalTo: containerView.topAnchor, constant: finalY),
            widthAnchor.constraint(equalToConstant: menuWidth),
            heightAnchor.constraint(equalToConstant: menuHeight)
        ])
        
        // Force layout before animation
        containerView.layoutIfNeeded()
        
        print("🎯 Menu frame after layout: \(frame)")
        print("🎯 Menu container frame: \(menuContainer.frame)")
        
        // Animate in (slide up from bottom instead of scale)
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 20) // Start slightly below
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut]) {
            print("🎯 Starting animation...")
            self.alpha = 1
            self.transform = .identity
            self.backdropView?.alpha = 1
        } completion: { finished in
            print("🎯 Animation finished: \(finished)")
        }
    }
    
    @objc private func backdropTapped() {
        print("🎯 Backdrop tapped - dismissing menu")
        actionHandler(.dismiss)
        dismiss()
    }
    
    private func dismiss() {
        print("🎯 Dismissing menu...")
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.backdropView?.alpha = 0
        } completion: { _ in
            print("🎯 Menu dismissed and removed")
            self.backdropView?.removeFromSuperview()
            self.removeFromSuperview()
        }
    }
}

// MARK: - UIButton Extension for iOS 14 compatibility
extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        setBackgroundImage(color.image(), for: state)
    }
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Font Debugging Utility
extension KeyboardViewController {
    
    /// Debug method to print all available fonts (especially Tamil fonts)
    private func debugAvailableFonts() {
        print("\n🔍 FONT DEBUGGING - Available Fonts:")
        print(String(repeating: "=", count: 50))
        
        let allFamilies = UIFont.familyNames.sorted()
        
        // First, show all Tamil-related fonts
        print("\n📝 TAMIL FONTS:")
        print(String(repeating: "-", count: 30))
        
        var tamilFonts: [String] = []
        
        for family in allFamilies {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            
            // Check if family or any font contains "tamil", "annai", or "mn"
            let isTamilRelated = family.lowercased().contains("tamil") ||
                                family.lowercased().contains("annai") ||
                                fontNames.contains { $0.lowercased().contains("tamil") || 
                                                    $0.lowercased().contains("annai") ||
                                                    $0.lowercased().contains("mn") }
            
            if isTamilRelated {
                print("\nFamily: \(family)")
                for fontName in fontNames {
                    print("  • \(fontName)")
                    tamilFonts.append(fontName)
                    
                    // Test if font loads
                    if let font = UIFont(name: fontName, size: 18) {
                        print("    ✅ Loads successfully")
                    } else {
                        print("    ❌ Failed to load")
                    }
                }
            }
        }
        
        print("\n📋 SUMMARY OF TAMIL-RELATED FONT NAMES:")
        print(String(repeating: "-", count: 40))
        for (index, fontName) in tamilFonts.enumerated() {
            print("\(index + 1). \(fontName)")
        }
        
        // Test the specific fonts mentioned
        print("\n🧪 TESTING SPECIFIC FONTS:")
        print(String(repeating: "-", count: 30))
        
        let fontsToTest = ["Tamil Sangam MN", "Annai MN", "TamilMN", "TamilSangamMN", "AnnaiMN"]
        
        for fontName in fontsToTest {
            if let font = UIFont(name: fontName, size: 18) {
                print("✅ '\(fontName)' - SUCCESS (actual: \(font.fontName))")
            } else {
                print("❌ '\(fontName)' - FAILED")
            }
        }
        
        print("\n" + String(repeating: "=", count: 50))
        print("🔍 Font debugging complete!")
    }
}

