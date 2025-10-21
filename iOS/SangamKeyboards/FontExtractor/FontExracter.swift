//
//  FontExracter.swift
//  KeyboardCore
//
//  Created by Muthu Nedumaran on 18/10/2025.
//

import Foundation

public struct FontInfo {
    public let fontName: String
    public let fontSize: Int
    public let licenseType: Character
    public var encryptedName: String = ""
    public var extractedPath: String = ""
    
    public init(fontName: String, fontSize: Int, licenseType: Character) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.licenseType = licenseType
    }
}

public struct PackInfo {
    public let packName: String
    public let packKey: String
    public var fonts: [FontInfo] = []
    
    public init(packName: String, packKey: String) {
        self.packName = packName
        self.packKey = packKey
    }
}

public class FontExtractor {
    
    public func extractFontPack(fpkPath: String, outputPath: String) -> PackInfo? {
        guard let fileHandle = FileHandle(forReadingAtPath: fpkPath) else {
            print("Can't open FPK file: \(fpkPath)")
            return nil
        }
        
        defer { fileHandle.closeFile() }
        
        // Skip first 50 bytes
        fileHandle.seek(toFileOffset: 50)
        
        // Read Font Pack Name (35 bytes)
        guard let packNameData = try? fileHandle.read(upToCount: 35),
              packNameData.count == 35 else {
            print("Error: FCT0002")
            return nil
        }
        let packName = String(data: packNameData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""
        
        // Read private key (10 bytes)
        guard let keyData = try? fileHandle.read(upToCount: 10),
              keyData.count == 10 else {
            print("Error: FCT0003")
            return nil
        }
        
        // Decrypt private key
        var decryptedKey = keyData.map { byte -> UInt8 in
            return byte == 0 ? 0 : byte - 9
        }
        let packKey = String(bytes: decryptedKey, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""
        
        // Read number of files (9 bytes)
        guard let numData = try? fileHandle.read(upToCount: 9),
              numData.count == 9,
              let numStr = String(data: numData, encoding: .utf8),
              let numFiles = Int(numStr.trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))) else {
            print("Error: FCT0004")
            return nil
        }
        
        var packInfo = PackInfo(packName: packName, packKey: packKey)
        
        // Process each font file
        for _ in 0..<numFiles {
            // Read file size (8 bytes)
            guard let sizeData = try? fileHandle.read(upToCount: 8),
                  sizeData.count == 8,
                  let sizeStr = String(data: sizeData, encoding: .utf8),
                  let fileSize = Int(sizeStr.trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))) else {
                print("Error: FCT0005")
                return nil
            }
            
            // Read filename and license type (34 bytes)
            guard let fileInfoData = try? fileHandle.read(upToCount: 34),
                  fileInfoData.count == 34 else {
                print("Error: FCT0006")
                return nil
            }
            
            let licenseType = Character(UnicodeScalar(fileInfoData[32]))
            
            // Decrypt filename (first 32 bytes)
            var fontName = ""
            for i in 0..<32 {
                let byte = fileInfoData[i]
                if byte == 0 { break }
                fontName.append(Character(UnicodeScalar(byte - 128)))
            }
            
            // Read font data
            guard let fontData = try? fileHandle.read(upToCount: fileSize),
                  fontData.count == fileSize else {
                print("Error: FCT009")
                return nil
            }
            
            // Only process 'R' license fonts
            if licenseType == "R" {
                var fontInfo = FontInfo(
                    fontName: fontName,
                    fontSize: fileSize,
                    licenseType: licenseType
                )
                
                // Extract font file
                let encryptedName = encryptExtractedName(fontName)
                fontInfo.encryptedName = encryptedName
                fontInfo.extractedPath = outputPath
                
                let outputFilePath = URL(fileURLWithPath: outputPath).appendingPathComponent(encryptedName)
                
                do {
                    try fontData.write(to: outputFilePath)
                    packInfo.fonts.append(fontInfo)
                    print("✓ Extracted: \(fontName)")
                } catch {
                    print("✗ Cannot write font file: \(outputFilePath.path)")
                    print("Error: FCT010")
                    return nil
                }
            }
        }
        
        return packInfo
    }
    
    /// Encrypts the extracted font name using a simple XOR cipher with a rotating key
    private func encryptExtractedName(_ name: String) -> String {
        let key: [UInt8] = [0x4B, 0x65, 0x79, 0x46, 0x6E, 0x74] // "KeyFnt" in hex
        var encrypted = ""
        
        for (index, character) in name.enumerated() {
            let charValue = character.asciiValue ?? 0
            let keyIndex = index % key.count
            let encryptedByte = charValue ^ key[keyIndex]
            
            // Convert to hexadecimal representation for safe filename
            encrypted += String(format: "%02X", encryptedByte)
        }
        
        return encrypted + ".dat" // Add extension for clarity
    }
    
    /// Decrypts an encrypted font name (useful for debugging or reverse operations)
    /*
    private func decryptExtractedName(_ encryptedName: String) -> String? {
        let key: [UInt8] = [0x4B, 0x65, 0x79, 0x46, 0x6E, 0x74] // Same key as encryption
        
        // Remove .font extension if present
        let hexString = encryptedName.replacingOccurrences(of: ".font", with: "")
        
        // Ensure even number of hex characters
        guard hexString.count % 2 == 0 else { return nil }
        
        var decrypted = ""
        var index = 0
        
        // Process each pair of hex characters
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let startIndex = hexString.index(hexString.startIndex, offsetBy: i)
            let endIndex = hexString.index(startIndex, offsetBy: 2)
            let hexByte = String(hexString[startIndex..<endIndex])
            
            if let byte = UInt8(hexByte, radix: 16) {
                let keyIndex = index % key.count
                let decryptedByte = byte ^ key[keyIndex]
                
                if let character = Character(UnicodeScalar(decryptedByte)) {
                    decrypted.append(character)
                }
                index += 1
            }
        }
        
        return decrypted
    } */
}

