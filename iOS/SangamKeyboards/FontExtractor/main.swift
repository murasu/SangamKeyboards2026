//
//  main.swift
//  FontExtractor
//
//  Created by Muthu Nedumaran on 18/10/2025.
//

import Foundation

func main() {
    let args = CommandLine.arguments
    
    guard args.count == 3 else {
        print("Usage: extract_fonts <fpk_file> <output_directory>")
        print("Example: extract_fonts fonts.fpk ./output")
        exit(1)
    }
    
    let fpkFile = args[1]
    let outputDir = args[2]
    
    // Check if FPK file exists
    guard FileManager.default.fileExists(atPath: fpkFile) else {
        print("Error: FPK file does not exist: \(fpkFile)")
        exit(1)
    }
    
    // Create output directory if it doesn't exist
    do {
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    } catch {
        print("Error: Cannot create output directory: \(error.localizedDescription)")
        exit(1)
    }
    
    print("Extracting fonts from: \(fpkFile)")
    print("Output directory: \(outputDir)")
    print("---")
    
    let extractor = FontExtractor()
    guard let packInfo = extractor.extractFontPack(fpkPath: fpkFile, outputPath: outputDir) else {
        print("\nExtraction failed!")
        exit(1)
    }
    
    print("---")
    print("Pack Name: \(packInfo.packName)")
    print("Extracted \(packInfo.fonts.count) font(s) with 'A' license")
    
    exit(0)
}

// Run the main function
main()
