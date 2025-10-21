//
//  KeyboardBuilder.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit

public class KeyboardBuilder {
    
    private static let debugMode = false // Disable debug to reduce console noise
    
    // MARK: - Color Configuration
    private struct KeyboardColors {
        // Regular key colors
        static let lightModeRegularBackground = UIColor.white
        static let darkModeRegularBackground = UIColor.systemGray5
        
        // Modifier key colors
        static let lightModeModifierBackground = UIColor.systemGray4
        static let darkModeModifierBackground = UIColor.systemGray4
        
        // Text colors
        static let lightModeTextColor = UIColor.black
        static let darkModeTextColor = UIColor.white
        
        // Border colors
        static let lightModeBorderColor = UIColor.systemGray3
        static let darkModeBorderColor = UIColor.systemGray2
    }
    
    // MARK: - Color Helper Methods
    private static func getCurrentInterfaceStyle(from view: UIView) -> UIUserInterfaceStyle {
        return view.traitCollection.userInterfaceStyle
    }
    
    private static func getRegularKeyBackgroundColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeRegularBackground
        case .light, .unspecified:
            return KeyboardColors.lightModeRegularBackground
        @unknown default:
            return KeyboardColors.lightModeRegularBackground
        }
    }
    
    private static func getModifierKeyBackgroundColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeModifierBackground
        case .light, .unspecified:
            return KeyboardColors.lightModeModifierBackground
        @unknown default:
            return KeyboardColors.lightModeModifierBackground
        }
    }
    
    private static func getTextColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeTextColor
        case .light, .unspecified:
            return KeyboardColors.lightModeTextColor
        @unknown default:
            return KeyboardColors.lightModeTextColor
        }
    }
    
    private static func getBorderColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeBorderColor
        case .light, .unspecified:
            return KeyboardColors.lightModeBorderColor
        @unknown default:
            return KeyboardColors.lightModeBorderColor
        }
    }
    
    public static func buildKeyboard(
        layout: KeyboardLayout,
        containerView: UIView,
        theme: KeyboardTheme,
        shouldIncludeGlobeKey: Bool,
        viewController: UIViewController?,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = theme.rowSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        for row in layout.rows {
            // Skip iPad-specific rows for now
            if row.rowId == "pad" { continue }
            
            let rowView = createRowView(
                row: row,
                defaultKeyWidth: layout.keyWidth,
                containerView: containerView,
                theme: theme,
                shouldIncludeGlobeKey: shouldIncludeGlobeKey,
                viewController: viewController,
                keyPressHandler: keyPressHandler
            )
            
            mainStack.addArrangedSubview(rowView)
        }
        
        return mainStack
    }
    
    private static func createRowView(
        row: KeyboardRow,
        defaultKeyWidth: String,
        containerView: UIView,
        theme: KeyboardTheme,
        shouldIncludeGlobeKey: Bool,
        viewController: UIViewController?,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = theme.keySpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        let isFixedWidthRow = row.rowId == "fixed-width"
        let isCenteredRow = row.rowId == "centered"
        
        var keyWidths: [CGFloat] = []
        var adjustedKeys: [KeyboardKey] = []
        var globeKeyWidth: CGFloat = 0
        
        // First pass: identify globe key and collect widths
        for key in row.keys {
            if key.keyCode == -6 {
                if shouldIncludeGlobeKey {
                    adjustedKeys.append(key)
                    let width = parsePercentage(key.keyWidth ?? defaultKeyWidth)
                    keyWidths.append(width)
                } else {
                    globeKeyWidth = parsePercentage(key.keyWidth ?? defaultKeyWidth)
                }
                continue
            }
            
            if key.keyCode == 32 && !shouldIncludeGlobeKey && globeKeyWidth > 0 {
                let spaceWidth = parsePercentage(key.keyWidth ?? defaultKeyWidth)
                let newWidth = spaceWidth + globeKeyWidth
                let expandedKey = key.withKeyWidth("\(newWidth)%")
                adjustedKeys.append(expandedKey)
                keyWidths.append(newWidth)
            } else {
                adjustedKeys.append(key)
                let width = parsePercentage(key.keyWidth ?? defaultKeyWidth)
                keyWidths.append(width)
            }
        }
        
        var widthConstraints: [NSLayoutConstraint] = []
        var firstButtonIndex = -1
        var shiftSpacerView: UIView?
        var leadingSpacer: UIView?
        
        // Add leading spacer for centered rows
        if isCenteredRow {
            leadingSpacer = UIView()
            leadingSpacer!.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(leadingSpacer!)
        }
        
        // Create buttons for adjusted keys
        for (index, key) in adjustedKeys.enumerated() {
            // Add spacer BEFORE delete button for fixed-width rows
            if isFixedWidthRow && key.keyCode == -5 {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(spacer)
                
                if let shiftSpacer = shiftSpacerView {
                    let equalConstraint = spacer.widthAnchor.constraint(equalTo: shiftSpacer.widthAnchor)
                    equalConstraint.priority = UILayoutPriority(999)
                    widthConstraints.append(equalConstraint)
                }
            }
            
            let button = createKeyButton(
                key: key,
                containerView: containerView,
                theme: theme,  // Pass theme
                viewController: viewController,
                handler: keyPressHandler
            )
            stackView.addArrangedSubview(button)
            
            // Add spacer AFTER shift button for fixed-width rows
            if isFixedWidthRow && key.keyCode == -1 {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(spacer)
                shiftSpacerView = spacer
                
                let spacerConstraint = spacer.widthAnchor.constraint(
                    equalTo: button.widthAnchor,
                    multiplier: 0.35
                )
                spacerConstraint.priority = UILayoutPriority(998)
                widthConstraints.append(spacerConstraint)
            }
            
            if firstButtonIndex == -1 {
                firstButtonIndex = stackView.arrangedSubviews.firstIndex(of: button) ?? 0
                
                // Set leading spacer width for centered rows
                if isCenteredRow, let spacer = leadingSpacer {
                    let firstKeyWidth = keyWidths[0]
                    // Calculate horizontal gap from first key if present
                    let horizontalGap = parsePercentage(row.keys[0].horizontalGap ?? "0%")
                    let ratio = horizontalGap / firstKeyWidth
                    
                    let spacerConstraint = spacer.widthAnchor.constraint(
                        equalTo: button.widthAnchor,
                        multiplier: ratio
                    )
                    spacerConstraint.priority = UILayoutPriority(999)
                    widthConstraints.append(spacerConstraint)
                }
                continue
            }
            
            let firstButtonWidth = keyWidths[0]
            let currentButtonWidth = keyWidths[index]
            let ratio = currentButtonWidth / firstButtonWidth
            
            let firstButton = stackView.arrangedSubviews[firstButtonIndex]
            let widthConstraint = button.widthAnchor.constraint(
                equalTo: firstButton.widthAnchor,
                multiplier: ratio
            )
            widthConstraint.priority = UILayoutPriority(999)
            widthConstraints.append(widthConstraint)
        }
        
        // Add trailing spacer for centered rows
        if isCenteredRow, let leadingSpacer = leadingSpacer {
            let trailingSpacer = UIView()
            trailingSpacer.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(trailingSpacer)
            
            let equalConstraint = trailingSpacer.widthAnchor.constraint(equalTo: leadingSpacer.widthAnchor)
            equalConstraint.priority = UILayoutPriority(999)
            widthConstraints.append(equalConstraint)
        }
        
        NSLayoutConstraint.activate(widthConstraints)
        
        return stackView
    }
    
    private static func createKeyButton(
        key: KeyboardKey,
        containerView: UIView,
        theme: KeyboardTheme,
        viewController: UIViewController?,
        handler: @escaping (KeyboardKey) -> Void
    ) -> UIButton {
        
        // Create a custom button that can handle annotations
        let button = AnnotatedKeyButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme colors
        if key.isModifier == true {
            button.backgroundColor = theme.modifierKeyBackground
            button.setTitleColor(theme.modifierKeyText, for: .normal)
            button.tintColor = theme.modifierKeyText
            button.layer.borderWidth = theme.modifierKeyBorderWidth
            button.layer.borderColor = theme.modifierKeyBorder.cgColor
            button.layer.cornerRadius = theme.modifierKeyCornerRadius
            applyShadow(to: button.layer, shadow: theme.modifierKeyShadow)
        } else {
            button.backgroundColor = theme.regularKeyBackground
            button.setTitleColor(theme.regularKeyText, for: .normal)
            button.tintColor = theme.regularKeyText
            button.layer.borderWidth = theme.regularKeyBorderWidth
            button.layer.borderColor = theme.regularKeyBorder.cgColor
            button.layer.cornerRadius = theme.regularKeyCornerRadius
            applyShadow(to: button.layer, shadow: theme.regularKeyShadow)
        }
        
        // Store theme and key on button
        objc_setAssociatedObject(button, &AssociatedKeys.theme, theme, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(button, &AssociatedKeys.key, key, .OBJC_ASSOCIATION_RETAIN)
        
        // Handle special keys
        if isSpecialKey(key) {
            configureSpecialKey(button: button, key: key, theme: theme)
        } else {
            let displayLabel = localizeKeyLabel(key.displayText)
            button.setTitle(displayLabel, for: .normal)
            button.titleLabel?.font = theme.keyFont
            
            // Set up annotation if available
            if let annotation = key.annotation, !annotation.isEmpty {
                let annotationColor = button.titleColor(for: .normal)?.withAlphaComponent(0.6) ?? UIColor.gray
                button.setAnnotation(annotation, font: UIFont(name: "TamilSangamMN", size: 10) ?? UIFont.systemFont(ofSize: 10), color: annotationColor)
            }
            
            if isTamilCharacter(displayLabel) {
                let adjustedSize = theme.keyFont.pointSize * 1.1
                button.titleLabel?.font = UIFont(
                    name: theme.keyFont.fontName,
                    size: adjustedSize
                ) ?? UIFont.systemFont(ofSize: adjustedSize)
            }
        }
        
        // Special handling for globe key
        if key.keyCode == -6, let inputVC = viewController as? UIInputViewController {
            button.addTarget(inputVC,
                            action: #selector(UIInputViewController.handleInputModeList(from:with:)),
                            for: .allTouchEvents)
            return button
        }
        
        // Key repeat for repeatable keys
        if key.isRepeatable == true {
            let repeatHandler = KeyRepeatHandler(key: key, handler: handler)
            button.addTarget(repeatHandler, action: #selector(KeyRepeatHandler.touchDown), for: .touchDown)
            button.addTarget(repeatHandler, action: #selector(KeyRepeatHandler.touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            objc_setAssociatedObject(button, &AssociatedKeys.repeatHandler, repeatHandler, .OBJC_ASSOCIATION_RETAIN)
            
            // Visual feedback only
            button.addAction(UIAction { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    button.backgroundColor = theme.pressedKeyBackground
                }) { _ in
                    UIView.animate(withDuration: 0.1) {
                        if key.isModifier == true {
                            button.backgroundColor = theme.modifierKeyBackground
                        } else {
                            button.backgroundColor = theme.regularKeyBackground
                        }
                    }
                }
            }, for: .touchDown)
            
            return button
        }
        
        // POPUP HANDLING FOR REGULAR CHARACTER KEYS
        if !key.displayText.isEmpty && key.isModifier != true {
            let popupHandler = KeyPopupHandler(
                key: key,
                containerView: containerView,
                theme: theme,
                handler: handler
            )
            objc_setAssociatedObject(button, &AssociatedKeys.popupHandler, popupHandler, .OBJC_ASSOCIATION_RETAIN)
            
            // Add touch event handlers
            button.addTarget(popupHandler, action: #selector(KeyPopupHandler.handleTouchDown), for: .touchDown)
            button.addTarget(popupHandler, action: #selector(KeyPopupHandler.handleTouchUp), for: [.touchUpInside, .touchUpOutside])
            button.addTarget(popupHandler, action: #selector(KeyPopupHandler.handleTouchCancel), for: .touchCancel)
            
            // ONLY add long press gesture if key has variants
            if !key.popupCharactersList.isEmpty {
                let longPress = UILongPressGestureRecognizer(target: popupHandler, action: #selector(KeyPopupHandler.handleLongPress(_:)))
                longPress.minimumPressDuration = 0.4
                longPress.cancelsTouchesInView = false
                longPress.delegate = popupHandler
                button.addGestureRecognizer(longPress)
            }

            return button  // IMPORTANT: Return here so we don't add the action below
        }
        
        // Regular modifier keys without popups (123, space, return, etc.)
        button.addAction(UIAction { _ in
            if key.isModifier == true {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            UIView.animate(withDuration: 0.1, animations: {
                button.backgroundColor = theme.pressedKeyBackground
                button.transform = CGAffineTransform(scaleX: theme.pressedKeyScale, y: theme.pressedKeyScale)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    if key.isModifier == true {
                        button.backgroundColor = theme.modifierKeyBackground
                    } else {
                        button.backgroundColor = theme.regularKeyBackground
                    }
                    button.transform = .identity
                }
            }
            
            handler(key)
        }, for: .touchUpInside)
        
        return button
    }


    // Add helper method for shadow
    private static func applyShadow(to layer: CALayer, shadow: ShadowStyle) {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.blur / 2.0  // Convert blur to radius
        layer.shadowOpacity = Float(shadow.color.cgColor.alpha)
    }
    
    private static func isSpecialKey(_ key: KeyboardKey) -> Bool {
        let specialKeyCodes: Set<Int> = [-1, -2, -5, -6] // shift, mode, delete, globe
        let hasSpecialCode = specialKeyCodes.contains(key.keyCode)
        let hasHashLabel = key.keyLabel.hasPrefix("#")
        let isModifierKey = key.isModifier == true
        
        let isSpecial = hasSpecialCode || hasHashLabel || isModifierKey
        
        if isSpecial && debugMode {
            print("Key identified as special: code=\(key.keyCode), label='\(key.keyLabel)', isModifier=\(key.isModifier ?? false)")
            print("  - hasSpecialCode: \(hasSpecialCode)")
            print("  - hasHashLabel: \(hasHashLabel)")
            print("  - isModifierKey: \(isModifierKey)")
        }
        
        return isSpecial
    }
    
    
    private static func configureSpecialKey(button: UIButton, key: KeyboardKey, theme: KeyboardTheme) {
        button.setTitle("", for: .normal)
        button.setImage(nil, for: .normal)
        
        let textColor = key.isModifier == true ? theme.modifierKeyText : theme.regularKeyText
        
        switch key.keyCode {
        case -1: // Shift
            if let shiftImage = UIImage(systemName: "shift") {
                button.setImage(shiftImage, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
                
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            } else {
                button.setTitle("⬆", for: .normal)
                button.setTitleColor(textColor, for: .normal)
            }
            
        case -5: // Delete
            if let deleteImage = UIImage(systemName: "delete.left") {
                button.setImage(deleteImage, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
                
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            } else {
                button.setTitle("⌫", for: .normal)
                button.setTitleColor(textColor, for: .normal)
            }
            
        case -6: // Globe
            if let globeImage = UIImage(systemName: "globe") {
                button.setImage(globeImage, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
                
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            } else {
                button.setTitle("🌐", for: .normal)
                button.setTitleColor(textColor, for: .normal)
            }
            
        case 10: // Globe
            if #available(iOS 26.0, *) {
                if let globeImage = UIImage(systemName: "return") {
                    button.setImage(globeImage, for: .normal)
                    button.tintColor = textColor
                    button.imageView?.contentMode = .scaleAspectFit
                    
                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                    button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
                } else {
                    button.setTitle("return", for: .normal)
                    button.setTitleColor(textColor, for: .normal)
                }
            } else {
                button.setTitle("return", for: .normal)
                button.setTitleColor(textColor, for: .normal)
            }
        default:
            let displayText = getDisplayTextForKey(key)
            button.setTitle(displayText, for: .normal)
            button.titleLabel?.font = theme.modifierKeyFont
            button.setTitleColor(textColor, for: .normal)
        }
        
        button.tag = key.keyCode
    }
    
    private static func getDisplayTextForKey(_ key: KeyboardKey) -> String {
        switch key.keyCode {
        case -6: // Globe (should be removed from layout)
            return "🌐"
        case -2: // Mode change (123/ABC)
            return key.keyLabel == "123" ? "123" : "ABC"
        case 32: // Space
            return "space"
        case 10: // Return
            return "return"
        default:
            return key.keyLabel.replacingOccurrences(of: "#", with: "")
        }
    }
    
    // Method to update shift key appearance
    public static func updateShiftKeyAppearance(button: UIButton, shifted: Bool, locked: Bool = false, theme: KeyboardTheme) {
        guard button.tag == -1 else { return }
        
        button.setTitle("", for: .normal)
        
        let symbolName = shifted ? "shift.fill" : "shift"
        
        if let shiftImage = UIImage(systemName: symbolName) {
            button.setImage(shiftImage, for: .normal)
            button.tintColor = theme.modifierKeyText
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        if shifted {
            button.backgroundColor = theme.modifierKeyBackground.withAlphaComponent(0.8)
        } else {
            button.backgroundColor = theme.modifierKeyBackground
        }
    }
    
    private static func parsePercentage(_ percentString: String) -> CGFloat {
        let cleanString = percentString.replacingOccurrences(of: "%", with: "")
        return CGFloat(Double(cleanString) ?? 10.0)
    }
    
    private static func parsePixelValue(_ pixelString: String, defaultValue: CGFloat) -> CGFloat {
        let cleanString = pixelString.replacingOccurrences(of: "px", with: "")
        return CGFloat(Double(cleanString) ?? Double(defaultValue))
    }
    
    private static func localizeKeyLabel(_ label: String) -> String {
        // Handle special labels that start with #
        switch label {
        case "#space":
            return "space"
        case "#return":
            return "return"
        case "⬆️", "#shift":
            return "" // Will be handled by special key logic
        case "#delete":
            return "" // Will be handled by special key logic
        case "#123", "#ABC":
            return "" // Will be handled by special key logic
        case "#globe":
            return "" // Will be handled by special key logic
        default:
            // For regular characters (including Hindi, Tamil, etc.), return as-is
            return label
        }
    }
    
    private static func getFontSize(for key: KeyboardKey) -> CGFloat {
        if key.isModifier == true {
            if key.keyLabel.count > 2 {
                return 12.0 // For labels like "space", "return"
            } else {
                return 16.0 // For symbols
            }
        } else {
            return 18.0 // Normal character keys
        }
    }
    
    private static func isTamilCharacter(_ text: String) -> Bool {
        guard let firstScalar = text.unicodeScalars.first else { return false }
        return (0x0B80...0x0BFF).contains(firstScalar.value)
    }
    
    // Method to find and update all shift keys in a view hierarchy
    public static func updateAllShiftKeys(in view: UIView, shifted: Bool, locked: Bool = false, theme: KeyboardTheme) {
        for subview in view.subviews {
            if let button = subview as? UIButton, button.tag == -1 {
                updateShiftKeyAppearance(button: button, shifted: shifted, locked: locked, theme: theme)
            }
            updateAllShiftKeys(in: subview, shifted: shifted, locked: locked, theme: theme)
        }
    }
    
    // Debug method
    public static func debugLayout(_ layout: KeyboardLayout) {
        print("=== Layout Debug ===")
        print("Default key width: \(layout.keyWidth)")
        print("Horizontal gap: \(layout.horizontalGap)")
        
        for (rowIndex, row) in layout.rows.enumerated() {
            print("\nRow \(rowIndex):")
            print("  Height: \(row.keyHeight)")
            print("  Keys: \(row.keys.count)")
            
            let totalWidth = row.keys.reduce(0.0) { total, key in
                let width = key.keyWidth ?? layout.keyWidth
                return total + parsePercentage(width)
            }
            print("  Total width: \(totalWidth)%")
            
            for (keyIndex, key) in row.keys.enumerated() {
                let width = key.keyWidth ?? layout.keyWidth
                print("    Key \(keyIndex): '\(key.keyLabel)' width: \(width)")
            }
        }
    }
}


// MARK: - Popup Handler
private class KeyPopupHandler: NSObject, UIGestureRecognizerDelegate {
    private let key: KeyboardKey
    private weak var containerView: UIView?
    private let theme: KeyboardTheme
    private let handler: (KeyboardKey) -> Void
    
    private var previewPopup: KeyPreviewPopup?
    private var longPressPopup: LongPressPopup?
    private var isLongPressActive = false
    private var tapWorkItem: DispatchWorkItem?
    
    init(key: KeyboardKey, containerView: UIView, theme: KeyboardTheme, handler: @escaping (KeyboardKey) -> Void) {
        self.key = key
        self.containerView = containerView
        self.theme = theme
        self.handler = handler
    }

    @objc func handleTouchDown(_ sender: UIButton) {
        guard !isLongPressActive else { return }
        
        print("🔍 Touch down - Button frame: \(sender.frame)")
        print("🔍 Button superview: \(String(describing: sender.superview))")
        print("🔍 Container bounds: \(String(describing: containerView?.bounds))")

        showPreview(for: sender)
        
        UIView.animate(withDuration: 0.05) {
            sender.backgroundColor = self.theme.pressedKeyBackground
        }
    }
    
    @objc func handleTouchUp(_ sender: UIButton) {
        if isLongPressActive {
            if let popup = longPressPopup {
                let selectedVariant = popup.getSelectedVariant()
                let variantKey = key.withDisplayText(selectedVariant)
                handler(variantKey)
            }
            dismissLongPress()
            tapWorkItem?.cancel() // Cancel any pending tap
        } else {
            handler(key)
        }
        
        // Always dismiss preview on touch up
        dismissPreview()
        
        // Reset visual state
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = self.theme.regularKeyBackground
        }
        
        isLongPressActive = false
    }
    
    @objc func handleTouchCancel(_ sender: UIButton) {
        tapWorkItem?.cancel()
        dismissPreview()
        dismissLongPress()
        
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = self.theme.regularKeyBackground
        }
        
        isLongPressActive = false
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        
        switch gesture.state {
        case .began:
            // Check if key has variants - use the new property name
            let variants = key.popupCharactersList
            guard !variants.isEmpty else {
                print("   ⚠️ No variants, returning without dismissing preview")
                return
            }
                        
            // Cancel any pending tap
            tapWorkItem?.cancel()
            
            isLongPressActive = true
            dismissPreview()
            showLongPress(for: button, variants: variants)
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
        case .changed:
            // Update selection based on finger position
            guard let popup = longPressPopup, let containerView = containerView else { return }
            let location = gesture.location(in: containerView)
            let selected = popup.selectVariantAt(touchLocation: location)
            print("👆 Finger moved to: \(location), selected: \(selected ?? "nil")")
            
        case .ended:
            if let popup = longPressPopup {
                let selectedVariant = popup.getSelectedVariant()
                print("🟢 Selected variant: \(selectedVariant)")
                
                let variantKey = key.withDisplayText(selectedVariant)
                print("🟢 Original key displayText: '\(key.displayText)'")
                print("🟢 Variant key displayText: '\(variantKey.displayText)'")
                print("🟢 Calling handler...")
                
                handler(variantKey)
            }
            dismissLongPress()
            dismissPreview()
            isLongPressActive = false
            
            UIView.animate(withDuration: 0.1) {
                button.backgroundColor = self.theme.regularKeyBackground
            }
            break
            
        case .cancelled, .failed:
            dismissLongPress()
            dismissPreview()
            isLongPressActive = false
            
        default:
            break
        }
    }
    
    private var overlayContainer: UIView?

    private func showPreview(for button: UIButton) {
        guard let containerView = containerView else { return }
        
        // Create a passthrough container if it doesn't exist
        if overlayContainer == nil {
            overlayContainer = PassthroughView()
            overlayContainer!.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(overlayContainer!)
            
            NSLayoutConstraint.activate([
                overlayContainer!.topAnchor.constraint(equalTo: containerView.topAnchor),
                overlayContainer!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                overlayContainer!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                overlayContainer!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            containerView.layoutIfNeeded() // Force layout before first use
        }
        
        // Always bring to front in case other views were added
        containerView.bringSubviewToFront(overlayContainer!)
        
        let preview = KeyPreviewPopup(character: key.displayText, theme: theme)
        preview.show(above: button, in: overlayContainer!) // Add to overlay, not containerView
        self.previewPopup = preview
    }
    
    private func dismissPreview() {
        previewPopup?.dismiss()
        previewPopup = nil
    }
    
    private func showLongPress(for button: UIButton, variants: [String]) {
        guard let containerView = containerView else { return }
        
        let popup = LongPressPopup(
            variants: variants,
            baseCharacter: key.displayText,
            theme: theme
        )
        popup.show(above: button, in: containerView)
        self.longPressPopup = popup
    }
    
    private func dismissLongPress() {
        longPressPopup?.dismiss()
        longPressPopup = nil
    }
    
    // UIGestureRecognizerDelegate - allow simultaneous recognition
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Key Repeat Handler
private class KeyRepeatHandler {
    private let key: KeyboardKey
    private let handler: (KeyboardKey) -> Void
    private var timer: Timer?
    private let initialDelay: TimeInterval = 0.5  // Delay before repeat starts
    private let repeatInterval: TimeInterval = 0.1  // Time between repeats
    
    init(key: KeyboardKey, handler: @escaping (KeyboardKey) -> Void) {
        self.key = key
        self.handler = handler
    }
    
    @objc func touchDown() {
        // Fire immediately
        handler(key)
        
        // Start timer for repeat
        timer = Timer.scheduledTimer(withTimeInterval: initialDelay, repeats: false) { [weak self] _ in
            self?.startRepeating()
        }
    }
    
    @objc func touchUp() {
        // Stop repeating
        timer?.invalidate()
        timer = nil
    }
    
    private func startRepeating() {
        // Start continuous repeat
        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.handler(self.key)
        }
    }
}

// Associated keys for object association
private struct AssociatedKeys {
    static var repeatHandler: UInt8 = 0
    static var theme: UInt8 = 0
    static var key: UInt8 = 0
    static var popupHandler: UInt8 = 0
}


// TODO: Passthrough
private class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Never intercept touches - always pass through
        return nil
    }
}

// MARK: - Annotated Key Button
private class AnnotatedKeyButton: UIButton {
    private var annotationLabel: UILabel?
    private var annotationText: String = ""
    private var annotationFont: UIFont = UIFont.systemFont(ofSize: 10)
    private var annotationColor: UIColor = UIColor.gray
    
    func setAnnotation(_ text: String, font: UIFont, color: UIColor) {
        // Store annotation properties
        annotationText = text
        annotationFont = font
        annotationColor = color
        
        // Remove existing annotation label if any
        annotationLabel?.removeFromSuperview()
        
        // Create new annotation label (initially hidden)
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail // Enable ellipsis truncation
        label.isHidden = true // Initially hidden until we check dimensions
        
        addSubview(label)
        annotationLabel = label
        
        // Trigger layout update to check dimensions and show/hide appropriately
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position annotation label at bottom and check dimensions
        if let annotationLabel = annotationLabel {
            let labelHeight: CGFloat = 12
            let margin: CGFloat = 3
            let horizontalPadding: CGFloat = 6 // Total padding on left and right
            let minimumKeyHeight: CGFloat = 35 // Minimum key height to show annotations
            
            annotationLabel.frame = CGRect(
                x: horizontalPadding / 2,
                y: bounds.height - labelHeight - margin,
                width: bounds.width - horizontalPadding,
                height: labelHeight
            )
            
            // Check if key is tall enough to show annotations
            guard bounds.height >= minimumKeyHeight else {
                annotationLabel.isHidden = true
                resetTitlePosition()
                return
            }
            
            // Calculate the available width for annotation (key width minus padding)
            let availableWidth = bounds.width - horizontalPadding
            
            // Measure the actual text width
            let textSize = annotationText.size(withAttributes: [.font: annotationFont])
            
            if textSize.width <= availableWidth {
                // Text fits completely - show without truncation
                annotationLabel.text = annotationText
                showAnnotationAndAdjustTitle(labelHeight: labelHeight, margin: margin)
            } else {
                // Text doesn't fit - check if we can truncate with ellipsis
                let ellipsisText = "…"
                let ellipsisSize = ellipsisText.size(withAttributes: [.font: annotationFont])
                let availableForText = availableWidth - ellipsisSize.width
                
                if availableForText > 20 { // Only truncate if we have reasonable space
                    // Find the longest substring that fits with ellipsis
                    var truncatedText = annotationText
                    while !truncatedText.isEmpty {
                        let testText = truncatedText + ellipsisText
                        let testSize = testText.size(withAttributes: [.font: annotationFont])
                        
                        if testSize.width <= availableWidth {
                            annotationLabel.text = testText
                            showAnnotationAndAdjustTitle(labelHeight: labelHeight, margin: margin)
                            return
                        }
                        
                        // Remove last character and try again
                        truncatedText = String(truncatedText.dropLast())
                    }
                }
                
                // If we can't fit even a truncated version, hide the annotation
                annotationLabel.isHidden = true
                resetTitlePosition()
            }
        }
    }
    
    private func showAnnotationAndAdjustTitle(labelHeight: CGFloat, margin: CGFloat) {
        annotationLabel?.isHidden = false
        
        // Adjust main title position to make room for annotation
        if let titleLabel = titleLabel {
            let availableHeight = bounds.height - labelHeight - margin * 2
            titleLabel.frame = CGRect(
                x: titleLabel.frame.origin.x,
                y: (availableHeight - titleLabel.frame.height) / 2,
                width: titleLabel.frame.width,
                height: titleLabel.frame.height
            )
        }
        
        // Bring annotation to front
        if let annotationLabel = annotationLabel {
            bringSubviewToFront(annotationLabel)
        }
    }
    
    private func resetTitlePosition() {
        // Reset title label to center position since no annotation is shown
        if let titleLabel = titleLabel {
            titleLabel.frame = CGRect(
                x: titleLabel.frame.origin.x,
                y: (bounds.height - titleLabel.frame.height) / 2,
                width: titleLabel.frame.width,
                height: titleLabel.frame.height
            )
        }
    }
}
