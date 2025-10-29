import Foundation
import MurasuIMEngine

// Error handling
enum PredictorError: Error {
    case initializationFailed
    case invalidArgument
    case outOfMemory
    case internalError
    case unknown(code: Int32)
    
    init(status: PredictorStatus) {
        switch status {
            case PREDICTOR_ERROR_INITIALIZATION: self = .initializationFailed
            case PREDICTOR_ERROR_INVALID_ARGUMENT: self = .invalidArgument
            case PREDICTOR_ERROR_OUT_OF_MEMORY: self = .outOfMemory
            case PREDICTOR_ERROR_INTERNAL: self = .internalError
            default: self = .unknown(code: status.rawValue)
        }
    }
}

struct PredictorOptions {
    var allowVariations: Bool = false
    var enableUserDictionary: Bool = false
    var scoreThreshold: Float = 1.0  // Default to 1.0 to maintain default weights
    
    func toCOptions() -> MurasuIMEngine.PredictorOptions {  // ← Return C struct
        var options = MurasuIMEngine.PredictorOptions()     // ← Create C struct
        options.allow_variations = allowVariations ? 1 : 0
        options.enable_user_dictionary = enableUserDictionary ? 1 : 0
        options.score_threshold = scoreThreshold
        return options
    }
}

extension TargetScript {
    static let tamil = TargetScript(rawValue: 0)
    static let brahmi = TargetScript(rawValue: 1)
    static let vatteluttu = TargetScript(rawValue: 2)
    static let jawi = TargetScript(rawValue: 3)
}

extension AnnotationDataType {
    static let notrequired = AnnotationDataType(rawValue: 0)
    static let meaning = AnnotationDataType(rawValue: 1)
    static let transliterated = AnnotationDataType(rawValue: 2)
}

public struct PredictionResult {
    let word: String
    let annotation: String
    let frequency: Double
    let wordId: Int32
    let finalScore: Float
    let userWord: Bool
    let isEmoji: Bool
    
    init(_ cResult: PredictorResult) {
        // The word
        if let ptr = cResult.word {
            // Get the UTF-16 characters directly from memory
            let uint16Ptr = UnsafeRawPointer(ptr).bindMemory(to: UInt16.self, capacity: 50)
            // Find string length
            var length = 0
            while uint16Ptr[length] != 0 { length += 1 }
            // Create string directly from the buffer
            self.word = String(decoding: UnsafeBufferPointer(start: uint16Ptr, count: length), as: UTF16.self)
        } else {
            self.word = ""
        }
        // The annotation
        if let ptr = cResult.annotation {
            let uint16Ptr = UnsafeRawPointer(ptr).bindMemory(to: UInt16.self, capacity: 50)
            var length = 0
            while uint16Ptr[length] != 0 { length += 1 }
            self.annotation = String(decoding: UnsafeBufferPointer(start: uint16Ptr, count: length), as: UTF16.self)
        } else {
            self.annotation = ""
        }

        self.frequency = cResult.frequency
        self.wordId = cResult.word_id
        self.finalScore = cResult.final_score
        self.userWord = cResult.user_word
        self.isEmoji = cResult.is_emoji
    }
    
    // Manual initializer for creating fallback predictions
    public init(word: String, annotation: String, frequency: Double, wordId: Int32, finalScore: Float, userWord: Bool, isEmoji: Bool) {
        self.word = word
        self.annotation = annotation
        self.frequency = frequency
        self.wordId = wordId
        self.finalScore = finalScore
        self.userWord = userWord
        self.isEmoji = isEmoji
    }
}

// Main wrapper class
class Predictor {
    private var handle: PredictorRef? {
        willSet {
            NSLog("About to set handle to: \(String(describing: newValue))")
        }
        didSet {
            NSLog("Handle set completed. Old: \(String(describing: oldValue)), New: \(String(describing: handle))")
        }
    }
    
    init(debugMode: Bool = false) throws {
        var status = PREDICTOR_SUCCESS
        guard let ptr = Predictor_Create(debugMode ? 1 : 0, &status) else {
            throw PredictorError(status: status)
        }
        self.handle = ptr
    }
    
    deinit {
        if let handle = handle {
            Predictor_Destroy(handle)
        }
    }
    
    func initialize(triePath: String) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        let status = triePath.withCString { path in
            Predictor_Initialize(handle, path)
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    func setUserDictionary(path: String) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        let status = path.withCString { cPath in
            Predictor_SetUserDictionary(handle, cPath)
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    func getWordPredictions(prefix: String, targetScript: TargetScript, annotationType: AnnotationDataType, maxResults: Int) throws -> [PredictionResult] {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        print("Getting word predictions for prefix: '\(prefix)', targetScript: '\(targetScript)', annotationType: '\(annotationType)', maxResuts: \(maxResults)")
        
        var results: UnsafeMutablePointer<PredictorResult>?
        var count: size_t = 0
        
        let status = Array(prefix.utf16 + [0]).withUnsafeBufferPointer { prefixBuf in
            prefixBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: prefixBuf.count) { prefixPtr in
                Predictor_GetWordPredictions(
                    handle,
                    prefixPtr,
                    targetScript,
                    annotationType,
                    size_t(maxResults),
                    &results,
                    &count
                )
            }
        }
        
        defer {
            if let results = results {
                Predictor_FreeResults(results)
            }
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        
        guard let resultPtr = results else { return [] }
        let resultsArray =  Array(UnsafeBufferPointer(start: resultPtr, count: count))
            .map(PredictionResult.init)
        print("   Results: \(resultsArray)")
        return resultsArray
    }
    
    // Not very useful. See the C++ implementation for more info
    // We don't need to use this function
    func configure(options: PredictorOptions) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        var cOptions = options.toCOptions()
        let status = Predictor_Configure(handle, &cOptions)
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    func getNgramPredictions(baseWord: String, secondWord: String, prefix: String, targetScript: TargetScript, annotationType: AnnotationDataType, maxResults: Int) throws -> [PredictionResult] {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        var results: UnsafeMutablePointer<PredictorResult>?
        var count: size_t = 0
        
        // Convert all words to null-terminated UTF-16
        let baseWordUTF16 = Array(baseWord.utf16 + [0])
        let secondWordUTF16 = Array(secondWord.utf16 + [0])
        let prefixUTF16 = Array(prefix.utf16 + [0])
        
        // Rebind the pointers to wchar_t
        var status: PredictorStatus = PREDICTOR_SUCCESS
        baseWordUTF16.withUnsafeBufferPointer { baseWordBuf in
            secondWordUTF16.withUnsafeBufferPointer { secondWordBuf in
                prefixUTF16.withUnsafeBufferPointer { prefixBuf in
                    let baseWordPtr = baseWordBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: baseWordBuf.count) { $0 }
                    let secondWordPtr = secondWordBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: secondWordBuf.count) { $0 }
                    let prefixPtr = prefixBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: prefixBuf.count) { $0 }
                    
                    // Call the C function and capture the return value
                    status = Predictor_GetNgramPredictions(
                        handle,
                        baseWordPtr,
                        secondWordPtr,
                        prefixPtr,
                        targetScript,
                        annotationType,
                        size_t(maxResults),
                        &results,
                        &count
                    )
                }
            }
        }
        
        defer {
            if let results = results {
                Predictor_FreeResults(results)
            }
        }
        
        // Check the status
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        
        guard let resultPtr = results else { return [] }
        return Array(UnsafeBufferPointer(start: resultPtr, count: count))
            .map(PredictionResult.init)
    }
    
    func addWord(_ word: String) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        let status = Array(word.utf16 + [0]).withUnsafeBufferPointer { wordBuf in
            wordBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: wordBuf.count) { wordPtr in
                Predictor_AddWord(handle, wordPtr)
            }
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    func addBigram(word1: String, word2: String) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        let status = Array(word1.utf16 + [0]).withUnsafeBufferPointer { word1Buf in
            Array(word2.utf16 + [0]).withUnsafeBufferPointer { word2Buf in
                word1Buf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: word1Buf.count) { word1Ptr in
                    word2Buf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: word2Buf.count) { word2Ptr in
                        Predictor_AddBigram(handle, word1Ptr, word2Ptr)
                    }
                }
            }
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    func addTrigram(word1: String, word2: String, word3: String) throws {
        guard let handle = handle else { throw PredictorError.initializationFailed }
        
        // Convert strings to null-terminated UTF-16
        let utf16Word1 = Array(word1.utf16 + [0])
        let utf16Word2 = Array(word2.utf16 + [0])
        let utf16Word3 = Array(word3.utf16 + [0])
        
        var status = PREDICTOR_SUCCESS
        
        utf16Word1.withUnsafeBufferPointer { word1Buf in
            guard let word1Base = word1Buf.baseAddress else {
                status = PREDICTOR_ERROR_INVALID_ARGUMENT
                return
            }
            
            utf16Word2.withUnsafeBufferPointer { word2Buf in
                guard let word2Base = word2Buf.baseAddress else {
                    status = PREDICTOR_ERROR_INVALID_ARGUMENT
                    return
                }
                
                utf16Word3.withUnsafeBufferPointer { word3Buf in
                    guard let word3Base = word3Buf.baseAddress else {
                        status = PREDICTOR_ERROR_INVALID_ARGUMENT
                        return
                    }
                    
                    let word1Ptr = word1Base.withMemoryRebound(to: wchar_t.self,
                                                             capacity: word1Buf.count) { $0 }
                    let word2Ptr = word2Base.withMemoryRebound(to: wchar_t.self,
                                                             capacity: word2Buf.count) { $0 }
                    let word3Ptr = word3Base.withMemoryRebound(to: wchar_t.self,
                                                             capacity: word3Buf.count) { $0 }
                    
                    status = Predictor_AddTrigram(handle, word1Ptr, word2Ptr, word3Ptr)
                }
            }
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
    }
    
    // Annotations from user dict
    func getAnnotationsCount() throws -> Int {
        guard let handle else { return 0 }
        
        var count: size_t = 0  // Changed from Int to size_t
        
        let status = Predictor_GetAnnotationsCount(handle, &count)
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        return Int(count)  // Convert back to Int for Swift API
    }

    func importAnnotations(fromTextFile: String) throws -> Int {
        guard let handle else { return 0 }
        
        var count: size_t = 0  // Changed from Int to size_t
        
        let status = fromTextFile.withCString { path in  // Added string conversion
            Predictor_ImportAnnotationsFromTextFile(handle, path, &count)
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        return Int(count)  // Convert back to Int for Swift API
    }
    
    func importShortcuts(fromTextFile: String) throws -> Int {
        guard let handle else { return 0 }
        
        var count: size_t = 0  // Changed from Int to size_t
        
        let status = fromTextFile.withCString { path in  // Added string conversion
            Predictor_ImportShortcutsFromTextFile(handle, path, &count)
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        return Int(count)  // Convert back to Int for Swift API
    }
    
    func importBlacklist(fromTextFile: String) throws -> Int {
        guard let handle else { return 0 }
        
        var count: size_t = 0  // Changed from Int to size_t
        
        let status = fromTextFile.withCString { path in  // Added string conversion
            Predictor_ImportBlacklistFromTextFile(handle, path, &count)
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        return Int(count)  // Convert back to Int for Swift API
    }
    
    func remove(word: String) throws -> Int {
        guard let handle else { return 0 }
        
        var remove_result: size_t = 0

        let status = Array(word.utf16 + [0]).withUnsafeBufferPointer { wordBuf in
            wordBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: wordBuf.count) { wordPtr in
                Predictor_RemoveWord(handle, wordPtr, &remove_result)
            }
        }
        
        if status != PREDICTOR_SUCCESS {
            throw PredictorError(status: status)
        }
        
        return Int(remove_result)
    }
    
    static func convertToBrahmi(_ word: String) throws -> String {
        var output: UnsafeMutablePointer<wchar_t>?
        
        let status = Array(word.utf16 + [0]).withUnsafeBufferPointer { wordBuf in
            wordBuf.baseAddress!.withMemoryRebound(to: wchar_t.self, capacity: wordBuf.count) { wordPtr in
                Predictor_ConvertToBrahmi(wordPtr, &output)
            }
        }
        
        // Check status and convert result
        guard status == PREDICTOR_SUCCESS, let outputBuffer = output else {
            throw PredictorError(status: status)
        }
                
        // Process as UTF-16 surrogate pairs
        var utf16CodeUnits: [UInt16] = []
        var index = 0
        while outputBuffer[index] != 0 {
            withUnsafeBytes(of: outputBuffer[index]) { ptr in
                // Each wchar_t contains both high and low surrogate
                // Extract high surrogate (first two bytes)
                let highSurrogate = UInt16(ptr[1]) << 8 | UInt16(ptr[0])
                utf16CodeUnits.append(highSurrogate)
                
                // Extract low surrogate (last two bytes)
                let lowSurrogate = UInt16(ptr[3]) << 8 | UInt16(ptr[2])
                utf16CodeUnits.append(lowSurrogate)
            }
            index += 1
        }
        
        return String(decoding: utf16CodeUnits, as: UTF16.self)
    }
    
    func setDebugMode(_ enable: Bool) {
        if let handle = handle {
            Predictor_SetDebugMode(handle, enable ? 1 : 0)
        }
    }
}


