# Anjal Multilingual Key Translator Library

A cross-platform C/C++ library with Swift wrapper for translating keystrokes to Indic scripts including Tamil, Devanagari (Hindi/Sanskrit), Malayalam, Kannada, Telugu, and Gurmukhi (Punjabi).

## Project Structure
```
AnjalKeyTranslatorLib/
├── README.md
├── Package.swift                       # Swift Package Manager
├── CMakeLists.txt                     # C/C++ build system
├── include/                           # Public headers
│   ├── AnjalKeyMap.h􀰓
│   ├── EncodingTamil.h􀰓
│   ├── AnjalKeyMapLookup.h􀰓
│   ├── IndicNotesIMEngine.h􀰓
│   ├── IndicIMEConstants.h􀰓
│   └── KeyTranslatorMultilingual.h    # Main C interface
├── src/                               # C source files
│   ├── tamil/
│   │   ├── AnjalKeyMap.c􀰓              # Tamil keyboard logic
│   │   └── KeyTranslatorTamil.c       # Tamil C wrapper
│   ├── indic/
│   │   ├── IndicNotesIMEngine.c       # Core Indic engine
│   │   ├── IndicDevanagariKeymap.c    # Hindi/Sanskrit
│   │   ├── IndicMalayalamKeymap.c     # Malayalam
│   │   ├── IndicKannadaKeymap.c       # Kannada
│   │   ├── IndicTeluguKeymap.c        # Telugu
│   │   └── IndicGurmukhiKeymap.c      # Punjabi
│   └── KeyTranslatorMultilingual.c   # Main C interface
├── Sources/                           # Swift Package structure
│   ├── CAnjalKeyTranslator/           # C module for Swift
│   │   ├── include/
│   │   │   ├── module.modulemap
│   │   │   └── [header files]
│   │   └── [C source files]
│   └── AnjalKeyTranslator/            # Swift wrapper
│       └── SwiftKeyTranslator.swift
├── Tests/
│   └── AnjalKeyTranslatorTests/
│       └── AnjalKeyTranslatorTests.swift
└── examples/
    ├── c_example.c
    ├── cpp_example.cpp
    └── swift_example/
```

## Supported Languages

- **Tamil** - Full keyboard layout support (Anjal, Tamil99, Tamil97, etc.)
- **Devanagari** - Hindi, Sanskrit, Marathi, Nepali
- **Malayalam** - Malayalam script
- **Kannada** - Kannada script
- **Telugu** - Telugu script  
- **Gurmukhi** - Punjabi script

## Current Status

### ✅ Completed
- Basic project structure
- Swift Package Manager configuration
- Core header file definitions
- Tamil keyboard logic (AnjalKeyMap.c - already working)
- Swift wrapper interface design

### ⚠️ In Progress (Compilation Errors to Fix)
- C source file conversions from Objective-C (.m to .c)
- Indic language keymap implementations
- Main multilingual C interface
- Swift-C bridging

### 📋 TODO
- Complete C file conversions
- Implement missing functions
- Add comprehensive tests
- Documentation
- Examples

## Known Compilation Issues

1. **Missing C implementations** - Several .c files need to be converted from .m files
2. **Function signatures** - Some functions declared in headers but not implemented
3. **Include paths** - Header dependencies need to be resolved
4. **Platform compatibility** - Windows/Linux compatibility defines

## Quick Start

### Building C Library Only

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

### Building Swift Package
```
swift build
```
## Current Build Errors

The Swift build currently fails due to missing C implementations. Priority fixes needed:

1. Convert remaining .m files to .c files
2. Implement missing functions in IndicNotesIMEngine.c
3. Create KeyTranslatorMultilingual.c implementation
4. Fix header include dependencies

## File Conversion Status

✅ Headers Ready
• include/IndicIMEConstants.h - IME type definitions
• include/IndicNotesIMEngine.h - Core engine interface
• include/KeyTranslatorMultilingual.h - Main C interface

🔄 Need Conversion (.m → .c)
• IndicDevanagariAnjalIMKeymap.m􀰓 → src/indic/IndicDevanagariKeymap.c
• IndicMalayalamAnjalIMKeymap.m􀰓 → src/indic/IndicMalayalamKeymap.c
• IndicKannadaAnjalIMKeymap.m􀰓 → src/indic/IndicKannadaKeymap.c
• IndicTeluguAnjalIMKeymap.m􀰓 → src/indic/IndicTeluguKeymap.c
• IndicGurmukhiAnjalIMKeymap.m􀰓 → src/indic/IndicGurmukhiKeymap.c
• IndicNotesIMEngine.m􀰓 → src/indic/IndicNotesIMEngine.c

📝 Need Creation
• src/KeyTranslatorMultilingual.c - Main interface implementation
• src/tamil/KeyTranslatorTamil.c - Tamil wrapper for AnjalKeyMap.c􀰓

## Objective-C to C Conversion Guide

### Key Changes Needed

1. Remove Objective-C imports
```
   // Remove
   #import "SomeHeader.h"
   // Add
   #include "SomeHeader.h"
```
2. Make arrays static
```
   // Change from
   UniChar DevaUV1Keys[] = {...};
   // To
   static UniChar DevaUV1Keys[] = {...};
```
3. Replace Objective-C functions
```
	// Replace NSLog with simple comment or printf
	NSLog(@"Debug: %@", value); → // Debug: message
   
	// Replace isnumber with isdigit
	isnumber(ch) → isdigit(ch)
```
4. Fix boolean values
```
	TRUE → true
	FALSE → false
```

## Usage Examples

### C Interface
```
#include "KeyTranslatorMultilingual.h"

// Create translator for Tamil with Anjal layout
MultilingualTranslatorRef translator = multilingual_translator_create(LANG_TAMIL, KBD_ANJAL);

// Translate a keystroke
wchar_t buffer[20];
int length = multilingual_translator_translate_key(translator, 'k', false, buffer, 20);

// Switch to Hindi
multilingual_translator_set_language(translator, LANG_DEVANAGARI);

// Cleanup
multilingual_translator_destroy(translator);
```

### Swift Interface
```
import AnjalKeyTranslator

// Create translator
let translator = SwiftKeyTranslator(language: .tamil, layout: .anjal)

// Translate keystroke  
let result = translator.translateKey(keyCode: 107) // 'k' → 'க'

// Switch language
translator.switchLanguage(to: .devanagari)

// Auto-detect language
if let detected = SwiftKeyTranslator.detectLanguage(from: "வணக்கம்") {
    print("Language: \(detected.displayName)")
}
```

### Integration to macOS input method
```
class MurasuAnjalInputController: IMKInputController {
    private var keyTranslator: SwiftKeyTranslator?
    
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        keyTranslator = SwiftKeyTranslator(language: .tamil, layout: .anjal)
    }
    
    func translateKeypress(keyCode: Int32, shifted: Bool) -> String {
        return keyTranslator?.translateKey(keyCode: keyCode, shifted: shifted) ?? ""
    }
}
```

## Next Steps for Development

1. Complete C conversions - Use the conversion patterns provided
2. Implement main interface - Create KeyTranslatorMultilingual.c
3. Fix compilation errors - Address missing functions and includes
4. Add tests - Create unit tests for each language
5. Platform testing - Test on macOS, iOS, Linux, Windows
6. Documentation - Add comprehensive API documentation

### Dependencies

C/C++ Build
• CMake 3.16+
• C11 compatible compiler
• Standard C library (wchar.h, stdbool.h, etc.)

### Swift Build
• Swift 5.9+
• Apple platforms: macOS 12.0+, iOS 15.0+
• Linux: Swift 5.9+ (C library only)


## Note: This library is extracted from a working macOS input method. The Tamil functionality (AnjalKeyMap.c) is production-tested. The multilingual extensions are new implementations that need testing and validation.
EOF

## Option 2: Using a Text Editor

1. Open any text editor (TextEdit, VS Code, nano, vim, etc.)
2. Copy the README content from my previous response
3. Paste it into the editor
4. Save as `README.md` in your project root directory

## Option 3: Using Xcode (if available)

1. Right-click in your project navigator
2. Select "New File..."
3. Choose "Empty" file
4. Name it `README.md`
5. Paste the content

## Option 4: Quick Command Line Method

```bash
# Navigate to your project directory
cd /path/to/your/AnjalKeyTranslatorLib

# Create and open the file in nano editor
nano README.md

# Or use vim
vim README.md

# Or use any text editor you prefer
open -a TextEdit README.md
```

## Verify the File

After creating it, you can verify with:
```
ls -la README.md
head -10 README.md
```


