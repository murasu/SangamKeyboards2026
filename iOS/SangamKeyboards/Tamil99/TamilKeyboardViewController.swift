// TamilKeyboardViewController.swift
import UIKit
import KeyboardCore

class TamilKeyboardViewController: KeyboardViewController {
    override var keyboardLanguage: LanguageId {
        return .tamil
    }
    
    override func viewDidLoad() {
        usesCandidateBar = true
        usesAnnotatedCandidates = true
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
