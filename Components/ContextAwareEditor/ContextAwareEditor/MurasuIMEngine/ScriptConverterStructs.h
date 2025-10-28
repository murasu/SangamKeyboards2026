//
//  ScriptConverterStructs.h
//  (Formerly in SangamIMEngine)
//
//  Created by Muthu Nedumaran on 01/09/2024.
//  Copyright © 2024 Murasu Systems. All rights reserved.
//

#ifndef ScriptConverterStructs_h
#define ScriptConverterStructs_h

enum TargetScript {
    Tamil = 0,
    Brahmi = 1,
    Vatteluttu = 2,
    Transliterated = 3,
    Jawi = 4
    // Add more scripts as needed, with unique integer values
};

enum AnnotationDataType {
    NotRequired = 0,
    Meaning = 1,
    Transliteration = 2
};

#endif /* ScriptConverterStructs_h */
