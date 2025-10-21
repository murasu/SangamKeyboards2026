//
//  TamilAnjalKeyboardViewController.swift
//  TamilAnjal
//
//  Created by Muthu Nedumaran on 30/09/2025.
//

import UIKit
import KeyboardCore

class TamilAnjalKeyboardViewController: KeyboardViewController {
    override var keyboardLanguage: LanguageId {
        return .tamilAnjal
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
