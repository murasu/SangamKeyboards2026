import Foundation
#if canImport(UIKit)
import UIKit
#endif

class PredictorManager {
    static let shared = PredictorManager()
    private var predictor: Predictor?
    
    private init() { }
    
    func getPredictor() -> Predictor? {
        if predictor == nil {
            initializePredictor()
        }
        return predictor
    }
    
    private func initializePredictor() {
        do {
            print("About to create predictor...")
            self.predictor = try Predictor(debugMode: false)
            print("Predictor created successfully")

            // Set the dictionary files
            if let trieFilePath = Bundle.main.path(forResource: "ta_main", ofType: "data") {
                print("Found trie file at: \(trieFilePath)")
                try self.predictor?.initialize(triePath: trieFilePath)
                print("Predictor initialized with trie successfully")
            } else {
                print("Trie dictionary file not found!!!")
            }
            
            // Platform-specific user dictionary setup
            let userFilePath = getUserDictionaryPath()
            if !userFilePath.isEmpty {
                print("Setting user dictionary to: \(userFilePath)")
                try self.predictor?.setUserDictionary(path: userFilePath)
            } else {
                print("Could not determine user dictionary path")
            }
            
            print("Predictor fully initialized!")
            
        } catch {
            print("Failed to initialize predictor: \(error)")
            self.predictor = nil
        }
    }
    
    private func getUserDictionaryPath() -> String {
        #if os(macOS)
        // macOS: Use Application Support directory
        if let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                       in: .userDomainMask).first {
            let userFileURL = appSupportDir.appendingPathComponent("anjaluser.data")
            return userFileURL.path
        }
        #else
        // iOS: Use Documents directory  
        if let documentsDir = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first {
            let userFileURL = documentsDir.appendingPathComponent("anjaluser.data")
            return userFileURL.path
        }
        #endif
        return ""
    }
}