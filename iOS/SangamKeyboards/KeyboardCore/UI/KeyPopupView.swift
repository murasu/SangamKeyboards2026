//
//  KeyPopupView.swift
//  KeyboardCore
//
//  Popup preview and long-press variants matching iOS system keyboard
//

import UIKit

// MARK: - Key Preview Popup (single character - quick tap)
class KeyPreviewPopup: UIView {
    private let label: UILabel
    private let theme: KeyboardTheme
    
    init(character: String, theme: KeyboardTheme) {
        self.theme = theme
        self.label = UILabel()
        super.init(frame: .zero)
        
        self.isUserInteractionEnabled = false
        
        setupView(character: character)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(character: String) {
        backgroundColor = theme.previewBackground
        layer.cornerRadius = theme.previewCornerRadius
        layer.borderWidth = theme.previewBorderWidth
        layer.borderColor = theme.previewBorder.cgColor
        
        // Apply shadow
        layer.shadowColor = theme.previewShadow.color.cgColor
        layer.shadowOffset = theme.previewShadow.offset
        layer.shadowRadius = theme.previewShadow.blur / 2.0
        layer.shadowOpacity = Float(theme.previewShadow.color.cgColor.alpha)
        layer.masksToBounds = false
        
        // Setup label - positioned higher
        label.text = character
        label.font = theme.previewFont
        label.textColor = theme.previewText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -2), // Push letter higher (was 4)
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }
    
    
    func show(above button: UIButton, in containerView: UIView) {
        guard button.superview != nil else {
            print("⚠️ Button has no superview, cannot show preview")
            return
        }
        
        // Force layout to ensure frames are valid
        containerView.layoutIfNeeded()
        
        self.isUserInteractionEnabled = false
        containerView.addSubview(self)
        
        let buttonFrame = containerView.convert(button.frame, from: button.superview)
        
        // Validate frame
        guard buttonFrame.width > 0 && buttonFrame.height > 0 else {
            print("⚠️ Invalid button frame: \(buttonFrame)")
            self.removeFromSuperview()
            return
        }
        
        // Adaptive popup sizing based on device and orientation
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = containerView.frame.width > containerView.frame.height
        
        let popupWidth: CGFloat
        let popupHeight: CGFloat
        
        if isPad {
            // iPad: Fixed reasonable sizes, don't scale with button size
            popupWidth = 60
            popupHeight = 65
        } else if isLandscape {
            // iPhone landscape: Smaller but ensure minimum width for Tamil characters
            popupWidth = max(50, buttonFrame.width * 1.4) // Cap the scaling
            popupHeight = 55
        } else {
            // iPhone portrait: Standard sizing
            let minPopupWidth: CGFloat = 50 // Minimum width for wide characters like ண
            popupWidth = max(minPopupWidth, buttonFrame.width * 1.6)
            popupHeight = buttonFrame.height * 1.5
        }
        
        // FIXED ALIGNMENT: Center popup exactly on button center
        var popupCenterX = buttonFrame.midX
        let halfPopupWidth = popupWidth / 2
        
        // Only adjust if popup would go outside container bounds
        let containerMargin: CGFloat = 8
        if popupCenterX - halfPopupWidth < containerMargin {
            popupCenterX = containerMargin + halfPopupWidth
        } else if popupCenterX + halfPopupWidth > containerView.frame.width - containerMargin {
            popupCenterX = containerView.frame.width - containerMargin - halfPopupWidth
        }
        
        // Position popup ABOVE button - with extra frame height at top
        let overlapAmount: CGFloat = isLandscape ? 10 : 8 // More overlap in landscape for better connection
        let extraTopSpace: CGFloat = 8 // Additional space above the letter
        let popupY = buttonFrame.minY - popupHeight + overlapAmount - extraTopSpace // Move frame higher
        let popupX = popupCenterX - halfPopupWidth
        
        self.frame = CGRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight)

        // Set initial state and animate
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.08) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.08, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - Long Press Popup (iOS-style with tail)
class LongPressPopup: UIView {
    private let theme: KeyboardTheme
    private let variants: [String]
    private var variantButtons: [UIButton] = []
    private var selectedIndex: Int = 0
    private let tailView: UIView
    
    var onVariantSelected: ((String) -> Void)?
    
    init(variants: [String], baseCharacter: String, theme: KeyboardTheme) {
        self.theme = theme
        // Put base character first, then variants
        self.variants = variants
        self.tailView = UIView()
        super.init(frame: .zero)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Main popup container
        let popupContainer = UIView()
        popupContainer.backgroundColor = theme.popupBackground
        popupContainer.layer.cornerRadius = theme.popupCornerRadius
        popupContainer.layer.borderWidth = theme.popupBorderWidth
        popupContainer.layer.borderColor = theme.popupBorder.cgColor
        popupContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply shadow to container
        popupContainer.layer.shadowColor = theme.popupShadow.color.cgColor
        popupContainer.layer.shadowOffset = theme.popupShadow.offset
        popupContainer.layer.shadowRadius = theme.popupShadow.blur / 2.0
        popupContainer.layer.shadowOpacity = Float(theme.popupShadow.color.cgColor.alpha)
        popupContainer.layer.masksToBounds = false
        
        addSubview(popupContainer)
        
        // Tail (pointer) connecting to key below
        tailView.backgroundColor = theme.popupBackground
        tailView.layer.borderWidth = theme.popupBorderWidth
        tailView.layer.borderColor = theme.popupBorder.cgColor
        tailView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tailView)
        
        // Stack for variant buttons
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        popupContainer.addSubview(stackView)
        
        // Create variant buttons
        for (index, variant) in variants.enumerated() {
            let button = createVariantButton(variant: variant, index: index)
            variantButtons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            // Popup container
            popupContainer.topAnchor.constraint(equalTo: topAnchor),
            popupContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            popupContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            popupContainer.heightAnchor.constraint(equalToConstant: 52),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: popupContainer.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: popupContainer.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: popupContainer.trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: popupContainer.bottomAnchor, constant: -6),
            
            // Tail
            tailView.topAnchor.constraint(equalTo: popupContainer.bottomAnchor, constant: -1),
            tailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tailView.widthAnchor.constraint(equalToConstant: 24),
            tailView.heightAnchor.constraint(equalToConstant: 12),
            tailView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Select first variant by default
        updateSelection(index: 0)
    }
    
    private func createVariantButton(variant: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(variant, for: .normal)
        button.titleLabel?.font = theme.popupKeyFont
        button.layer.cornerRadius = theme.popupKeyCornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index
        
        // Min width for each variant
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        
        return button
    }
    
    func updateSelection(index: Int) {
        guard index >= 0 && index < variantButtons.count else { return }
        
        print("🔄 Updating selection to index: \(index) (\(variants[index]))")
        self.selectedIndex = index  // ← Make sure this line exists!
        
        // Update all buttons
        for (i, button) in variantButtons.enumerated() {
            if i == index {
                button.backgroundColor = theme.popupKeySelectedBackground
                button.setTitleColor(theme.popupKeySelectedText, for: .normal)
            } else {
                button.backgroundColor = theme.popupKeyBackground
                button.setTitleColor(theme.popupKeyText, for: .normal)
            }
        }
    }
    
    func selectVariantAt(touchLocation: CGPoint) -> String? {
        guard let containerView = superview else {
            print("⚠️ No superview for popup")
            return nil
        }
        
        // Convert touch location from container space to this popup's space
        let localTouch = convert(touchLocation, from: containerView)
        
        print("🎯 Touch at: \(touchLocation) in container space")
        print("🎯 Touch at: \(localTouch) in popup local space")
        
        for (index, button) in variantButtons.enumerated() {
            // Get button frame in popup's coordinate space
            guard let buttonSuperview = button.superview else { continue }
            let buttonFrame = convert(button.frame, from: buttonSuperview)
            
            print("   Button \(index) (\(variants[index])): frame = \(buttonFrame)")
            
            if buttonFrame.contains(localTouch) {
                print("   ✅ HIT! Selecting index \(index)")
                updateSelection(index: index)
                return variants[index]
            }
        }
        
        print("   ❌ No button hit")
        return nil
    }
    /*
    func selectVariantAt(touchLocation: CGPoint) -> String? {
        guard let containerView = superview else {
            print("⚠️ No superview for popup")
            return nil
        }
        
        print("🎯 Touch at: \(touchLocation) in container space")
        
        for (index, button) in variantButtons.enumerated() {
            let buttonFrame = containerView.convert(button.frame, from: button.superview)
            print("   Button \(index) (\(variants[index])): frame = \(buttonFrame)")
            
            if buttonFrame.contains(touchLocation) {
                print("   ✅ HIT! Selecting index \(index)")
                updateSelection(index: index)
                return variants[index]
            }
        }
        
        print("   ❌ No button hit")
        return nil
    }
    */
    
    func getSelectedVariant() -> String {
        print("🔵 getSelectedVariant called - selectedIndex: \(selectedIndex), returning: \(variants[selectedIndex])")
        return variants[selectedIndex]
    }
    
    func show(above button: UIButton, in containerView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        
        // Calculate popup width more accurately
        let variantCount = CGFloat(variants.count)
        let minButtonWidth: CGFloat = 40
        let spacing: CGFloat = 6
        let containerPadding: CGFloat = 12  // 6pt padding on each side inside popup container
        let popupMargin: CGFloat = 16  // 8pt margin on each side of popup itself
        
        let calculatedWidth = (minButtonWidth * variantCount) + (spacing * (variantCount - 1)) + containerPadding + popupMargin
        let popupWidth = min(calculatedWidth, containerView.frame.width - 40)
        
        // Get button position
        let buttonFrame = containerView.convert(button.frame, from: button.superview)
        var popupCenterX = buttonFrame.midX
        
        // Edge detection - 8pt margin
        let margin: CGFloat = 8
        let halfPopupWidth = popupWidth / 2
        
        if popupCenterX - halfPopupWidth < margin {
            popupCenterX = margin + halfPopupWidth
        } else if popupCenterX + halfPopupWidth > containerView.frame.width - margin {
            popupCenterX = containerView.frame.width - margin - halfPopupWidth
        }
        
        // Position above button (moved 2 points lower to avoid going above container)
        let popupBottom = buttonFrame.minY - 2
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: popupWidth),
            heightAnchor.constraint(equalToConstant: 64),
            centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: popupCenterX),
            bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: popupBottom)
        ])
        
        // Force layout before animation so frames are valid
        containerView.layoutIfNeeded()
        
        // Animate in
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

