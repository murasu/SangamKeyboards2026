#ifndef ANJALKEYMAPLOOKUP_H
#define ANJALKEYMAPLOOKUP_H

//-----------------------------------------------------------------------------
// Start of Character Matrix Tables
//-----------------------------------------------------------------------------
char ColumnSequence[] = "aAiIuUeEXoOQq";
char RowSequence[] = "akcdtpRyrlvzLgGNwmnjsShxWH123456789^";

const WCHAR* encTable[MAX_ROWS][MAX_COLS] = {
    // Anjal Roman Table
        {L"\x0b85", L"\x0b86", L"\x0b87", L"\x0b88", L"\x0b89", L"\x0b8a", L"\x0b8e", L"\x0b8f", L"\x0b90", L"\x0b92", L"\x0b93", L"\x0b94", L"\x0b83"},

        {L"\x0b95", L"\x0b95\x0bbe", L"\x0b95\x0bbf", L"\x0b95\x0bc0", L"\x0b95\x0bc1", L"\x0b95\x0bc2", L"\x0b95\x0bc6", L"\x0b95\x0bc7", L"\x0b95\x0bc8", L"\x0b95\x0bca", L"\x0b95\x0bcb", L"\x0b95\x0bcc", L"\x0b95\x0bcd"},
        {L"\x0b9a", L"\x0b9a\x0bbe", L"\x0b9a\x0bbf", L"\x0b9a\x0bc0", L"\x0b9a\x0bc1", L"\x0b9a\x0bc2", L"\x0b9a\x0bc6", L"\x0b9a\x0bc7", L"\x0b9a\x0bc8", L"\x0b9a\x0bca", L"\x0b9a\x0bcb", L"\x0b9a\x0bcc", L"\x0b9a\x0bcd"},
        {L"\x0b9f", L"\x0b9f\x0bbe", L"\x0b9f\x0bbf", L"\x0b9f\x0bc0", L"\x0b9f\x0bc1", L"\x0b9f\x0bc2", L"\x0b9f\x0bc6", L"\x0b9f\x0bc7", L"\x0b9f\x0bc8", L"\x0b9f\x0bca", L"\x0b9f\x0bcb", L"\x0b9f\x0bcc", L"\x0b9f\x0bcd"},
        {L"\x0ba4", L"\x0ba4\x0bbe", L"\x0ba4\x0bbf", L"\x0ba4\x0bc0", L"\x0ba4\x0bc1", L"\x0ba4\x0bc2", L"\x0ba4\x0bc6", L"\x0ba4\x0bc7", L"\x0ba4\x0bc8", L"\x0ba4\x0bca", L"\x0ba4\x0bcb", L"\x0ba4\x0bcc", L"\x0ba4\x0bcd"},
        {L"\x0baa", L"\x0baa\x0bbe", L"\x0baa\x0bbf", L"\x0baa\x0bc0", L"\x0baa\x0bc1", L"\x0baa\x0bc2", L"\x0baa\x0bc6", L"\x0baa\x0bc7", L"\x0baa\x0bc8", L"\x0baa\x0bca", L"\x0baa\x0bcb", L"\x0baa\x0bcc", L"\x0baa\x0bcd"},
        {L"\x0bb1", L"\x0bb1\x0bbe", L"\x0bb1\x0bbf", L"\x0bb1\x0bc0", L"\x0bb1\x0bc1", L"\x0bb1\x0bc2", L"\x0bb1\x0bc6", L"\x0bb1\x0bc7", L"\x0bb1\x0bc8", L"\x0bb1\x0bca", L"\x0bb1\x0bcb", L"\x0bb1\x0bcc", L"\x0bb1\x0bcd"},

        {L"\x0baf", L"\x0baf\x0bbe", L"\x0baf\x0bbf", L"\x0baf\x0bc0", L"\x0baf\x0bc1", L"\x0baf\x0bc2", L"\x0baf\x0bc6", L"\x0baf\x0bc7", L"\x0baf\x0bc8", L"\x0baf\x0bca", L"\x0baf\x0bcb", L"\x0baf\x0bcc", L"\x0baf\x0bcd"},
        {L"\x0bb0", L"\x0bb0\x0bbe", L"\x0bb0\x0bbf", L"\x0bb0\x0bc0", L"\x0bb0\x0bc1", L"\x0bb0\x0bc2", L"\x0bb0\x0bc6", L"\x0bb0\x0bc7", L"\x0bb0\x0bc8", L"\x0bb0\x0bca", L"\x0bb0\x0bcb", L"\x0bb0\x0bcc", L"\x0bb0\x0bcd"},
        {L"\x0bb2", L"\x0bb2\x0bbe", L"\x0bb2\x0bbf", L"\x0bb2\x0bc0", L"\x0bb2\x0bc1", L"\x0bb2\x0bc2", L"\x0bb2\x0bc6", L"\x0bb2\x0bc7", L"\x0bb2\x0bc8", L"\x0bb2\x0bca", L"\x0bb2\x0bcb", L"\x0bb2\x0bcc", L"\x0bb2\x0bcd"},
        {L"\x0bb5", L"\x0bb5\x0bbe", L"\x0bb5\x0bbf", L"\x0bb5\x0bc0", L"\x0bb5\x0bc1", L"\x0bb5\x0bc2", L"\x0bb5\x0bc6", L"\x0bb5\x0bc7", L"\x0bb5\x0bc8", L"\x0bb5\x0bca", L"\x0bb5\x0bcb", L"\x0bb5\x0bcc", L"\x0bb5\x0bcd"},
        {L"\x0bb4", L"\x0bb4\x0bbe", L"\x0bb4\x0bbf", L"\x0bb4\x0bc0", L"\x0bb4\x0bc1", L"\x0bb4\x0bc2", L"\x0bb4\x0bc6", L"\x0bb4\x0bc7", L"\x0bb4\x0bc8", L"\x0bb4\x0bca", L"\x0bb4\x0bcb", L"\x0bb4\x0bcc", L"\x0bb4\x0bcd"},
        {L"\x0bb3", L"\x0bb3\x0bbe", L"\x0bb3\x0bbf", L"\x0bb3\x0bc0", L"\x0bb3\x0bc1", L"\x0bb3\x0bc2", L"\x0bb3\x0bc6", L"\x0bb3\x0bc7", L"\x0bb3\x0bc8", L"\x0bb3\x0bca", L"\x0bb3\x0bcb", L"\x0bb3\x0bcc", L"\x0bb3\x0bcd"},

        {L"\x0b99", L"\x0b99\x0bbe", L"\x0b99\x0bbf", L"\x0b99\x0bc0", L"\x0b99\x0bc1", L"\x0b99\x0bc2", L"\x0b99\x0bc6", L"\x0b99\x0bc7", L"\x0b99\x0bc8", L"\x0b99\x0bca", L"\x0b99\x0bcb", L"\x0b99\x0bcc", L"\x0b99\x0bcd"},
        {L"\x0b9e", L"\x0b9e\x0bbe", L"\x0b9e\x0bbf", L"\x0b9e\x0bc0", L"\x0b9e\x0bc1", L"\x0b9e\x0bc2", L"\x0b9e\x0bc6", L"\x0b9e\x0bc7", L"\x0b9e\x0bc8", L"\x0b9e\x0bca", L"\x0b9e\x0bcb", L"\x0b9e\x0bcc", L"\x0b9e\x0bcd"},
        {L"\x0ba3", L"\x0ba3\x0bbe", L"\x0ba3\x0bbf", L"\x0ba3\x0bc0", L"\x0ba3\x0bc1", L"\x0ba3\x0bc2", L"\x0ba3\x0bc6", L"\x0ba3\x0bc7", L"\x0ba3\x0bc8", L"\x0ba3\x0bca", L"\x0ba3\x0bcb", L"\x0ba3\x0bcc", L"\x0ba3\x0bcd"},
        {L"\x0ba8", L"\x0ba8\x0bbe", L"\x0ba8\x0bbf", L"\x0ba8\x0bc0", L"\x0ba8\x0bc1", L"\x0ba8\x0bc2", L"\x0ba8\x0bc6", L"\x0ba8\x0bc7", L"\x0ba8\x0bc8", L"\x0ba8\x0bca", L"\x0ba8\x0bcb", L"\x0ba8\x0bcc", L"\x0ba8\x0bcd"},
        {L"\x0bae", L"\x0bae\x0bbe", L"\x0bae\x0bbf", L"\x0bae\x0bc0", L"\x0bae\x0bc1", L"\x0bae\x0bc2", L"\x0bae\x0bc6", L"\x0bae\x0bc7", L"\x0bae\x0bc8", L"\x0bae\x0bca", L"\x0bae\x0bcb", L"\x0bae\x0bcc", L"\x0bae\x0bcd"},
        {L"\x0ba9", L"\x0ba9\x0bbe", L"\x0ba9\x0bbf", L"\x0ba9\x0bc0", L"\x0ba9\x0bc1", L"\x0ba9\x0bc2", L"\x0ba9\x0bc6", L"\x0ba9\x0bc7", L"\x0ba9\x0bc8", L"\x0ba9\x0bca", L"\x0ba9\x0bcb", L"\x0ba9\x0bcc", L"\x0ba9\x0bcd"},

        {L"\x0b9c", L"\x0b9c\x0bbe", L"\x0b9c\x0bbf", L"\x0b9c\x0bc0", L"\x0b9c\x0bc1", L"\x0b9c\x0bc2", L"\x0b9c\x0bc6", L"\x0b9c\x0bc7", L"\x0b9c\x0bc8", L"\x0b9c\x0bca", L"\x0b9c\x0bcb", L"\x0b9c\x0bcc", L"\x0b9c\x0bcd"},
        {L"\x0bb7", L"\x0bb7\x0bbe", L"\x0bb7\x0bbf", L"\x0bb7\x0bc0", L"\x0bb7\x0bc1", L"\x0bb7\x0bc2", L"\x0bb7\x0bc6", L"\x0bb7\x0bc7", L"\x0bb7\x0bc8", L"\x0bb7\x0bca", L"\x0bb7\x0bcb", L"\x0bb7\x0bcc", L"\x0bb7\x0bcd"},
        {L"\x0bb8", L"\x0bb8\x0bbe", L"\x0bb8\x0bbf", L"\x0bb8\x0bc0", L"\x0bb8\x0bc1", L"\x0bb8\x0bc2", L"\x0bb8\x0bc6", L"\x0bb8\x0bc7", L"\x0bb8\x0bc8", L"\x0bb8\x0bca", L"\x0bb8\x0bcb", L"\x0bb8\x0bcc", L"\x0bb8\x0bcd"},
        {L"\x0bb9", L"\x0bb9\x0bbe", L"\x0bb9\x0bbf", L"\x0bb9\x0bc0", L"\x0bb9\x0bc1", L"\x0bb9\x0bc2", L"\x0bb9\x0bc6", L"\x0bb9\x0bc7", L"\x0bb9\x0bc8", L"\x0bb9\x0bca", L"\x0bb9\x0bcb", L"\x0bb9\x0bcc", L"\x0bb9\x0bcd"},
        {L"\x0b95\x0bcd\x0bb7", L"\x0b95\x0bcd\x0bb7\x0bbe", L"\x0b95\x0bcd\x0bb7\x0bbf", L"\x0b95\x0bcd\x0bb7\x0bc0", L"\x0b95\x0bcd\x0bb7\x0bc1", L"\x0b95\x0bcd\x0bb7\x0bc2", L"\x0b95\x0bcd\x0bb7\x0bc6", L"\x0b95\x0bcd\x0bb7\x0bc7", L"\x0b95\x0bcd\x0bb7\x0bc8", L"\x0b95\x0bcd\x0bb7\x0bca", L"\x0b95\x0bcd\x0bb7\x0bcb", L"\x0b95\x0bcd\x0bb7\x0bcc", L"\x0b95\x0bcd\x0bb7\x0bcd"},
        {L"\x0bb8\x0bcd\x0bb0\x0bc0", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0bb8\x0bcd\x0bb0\x0bc0"},
        {L"\x0bb6", L"\x0bb6\x0bbe", L"\x0bb6\x0bbf", L"\x0bb6\x0bc0", L"\x0bb6\x0bc1", L"\x0bb6\x0bc2", L"\x0bb6\x0bc6", L"\x0bb6\x0bc7", L"\x0bb6\x0bc8", L"\x0bb6\x0bca", L"\x0bb6\x0bcb", L"\x0bb6\x0bcc", L"\x0bb6\x0bcd"},

        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0bb1\x0bcd\x0bb1\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0ba8\x0bcd\x0ba4\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0ba3\x0bcd\x0b9f\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0ba9\x0bcd\x0bb1\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0b9f\x0bcd\x0b9f\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0ba4\x0bcd\x0ba4\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0b9e\x0bcd\x0b9a\x0bcd"},
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0b95\x0bcd\x0b9a\x0bcd"},          // க்+ச added 2022-02-28 before ச becomes ஷ
        {L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"", L"\x0b95\x0bcd\x200C\x0bb7\x0bcd"},    // க்+ஷ் added 2022-02-28 after ச becomes ஷ

        // Modifiers
        {L"", L"\x0bbe", L"\x0bbf", L"\x0bc0", L"\x0bc1", L"\x0bc2", L"\x0bc6", L"\x0bc7", L"\x0bc8", L"\x0bca", L"\x0bcb", L"\x0bcc", L"\x0bcd"},
        // Tamil Symbols
        {L"\x0bf9", L"\x0bfa", L"\x0bf8", L"\x0bf3", L"\x0bf4", L"\x0bf5", L"\x0bf6", L"\x0bf7"}
};



// Keyboar Matrix Tables for different keyboards
// Previously in KTABLES.H

//-----------------------------------------------------------------------------
// Keyboard Matrix Tables
//-----------------------------------------------------------------------------

//  The folloing keys are fixed to single characters
//      tha - t         da  - d         cha - c         S   - S(Sa)
//      sh  - s(sha)    n-  - w         ng  - g         nj  - G
//      ka  - k         sri - W         ai  - X         au  - Q
//
//      Special sequence processing
//
//      tr  - 1         nth - 2         nd  - 3         ndr - 4
//      tt  - 5         tth - 6         njj - 7
//
//  escape character = '^'

#define Conso1stKeys     0
#define Conso2ndKeys     1
#define Conso3rdKeys     2
#define Conso1stChar     3
#define Conso2ndChar     4
#define Conso3rdChar     5
#define ConsoRsltant     6
#define Vowel1stKeys     7
#define Vowel2ndKeys     8
#define Vowel1stChar     9
#define Vowel2ndChar    10
#define OutOfMatrixKeys 11
#define outOfMatrixChar 12

#define MAX_TABLES      13
#define MAX_TABLESIZE   50

#define C1Keys  kbdTable[kbdType][Conso1stKeys]
#define C2Keys  kbdTable[kbdType][Conso2ndKeys]
#define C3Keys  kbdTable[kbdType][Conso3rdKeys]
#define C1Char  kbdTable[kbdType][Conso1stChar]
#define C2Char  kbdTable[kbdType][Conso2ndChar]
#define C3Char  kbdTable[kbdType][Conso3rdChar]
#define CReslt  kbdTable[kbdType][ConsoRsltant]
#define V1Keys  kbdTable[kbdType][Vowel1stKeys]
#define V2Keys  kbdTable[kbdType][Vowel2ndKeys]
#define V1Char  kbdTable[kbdType][Vowel1stChar]
#define V2Char  kbdTable[kbdType][Vowel2ndChar]
#define OMKeys  kbdTable[kbdType][OutOfMatrixKeys]
#define OMChar  kbdTable[kbdType][outOfMatrixChar]

// remap names for WYTIWYG keyboards
#define ConsoKeys kbdTable[kbdType][Conso1stKeys]   // base
#define ConsoChar kbdTable[kbdType][Conso1stChar]
#define wUyirKeys kbdTable[kbdType][Conso2ndKeys]   // WTYIWYG uyir
#define wUyirChar kbdTable[kbdType][Conso2ndChar]
#define ukaraKeys kbdTable[kbdType][Conso3rdKeys]
#define uKaraCons kbdTable[kbdType][Conso3rdChar]
#define uKaraVowl kbdTable[kbdType][ConsoRsltant]
#define wModiKeys kbdTable[kbdType][Vowel1stKeys]   // WYTIWYG modifier
#define wModiChar kbdTable[kbdType][Vowel1stChar]
#define mModiKeys kbdTable[kbdType][Vowel2ndKeys]   // Modifier keys
#define mModiChar kbdTable[kbdType][Vowel2ndChar]

char kbdTable[MAX_KBDTYPES][MAX_TABLES][MAX_TABLESIZE] = {

    // Anjal keyboard - this should always be first
    // Do not change the sequence as the user defined
    // keyboard map, overwrites the first three lines
    // kbdTable[0][0], [0][1] and [0][2].
    // Check anjalrtl_keyboard.cpp
    {
        {"RvlnnWyNztdtkgmpbtnwrLcsnnSSsjhsssxdtnnnnkk\\"}, // conso1stKey
        {"****=******h******-***h*gj*hh**rrR*rrtddjss*"},  // conso2ndKey
        {"********************************ii**hh*rj*h*"},  // conso3rdKey


        {"RvlnnnyNztdtkkmppdwwrLccgGSSsjhWWWxR12347kk^"},  // conso1stChar
        {"****n******t******w***ccgG*Hs**WWW*R1234788*"},  // conso2ndChar
        {"*******************************WWW***2*47*9*"},  // conso3rdChar
        {"************************************RtdRccs*"},  // consoRsltant

        {"aAiIuUeaEaooOaq"},  // vowel1stKey
        {"a*i*u*ee*ioa*u*"},  // vowel2ndKey

        {"aAiIuUeeEXooOQq"},  // vowel1stChar
        {"A*I*U*EE*XOO*Q*"},  // vowel2ndChar

        {"M"},               // outOfMatrixKeys
        {"M"}                // outOfMatrixChar
    },

    // Tamil99 keyboard
    {
        {"QWERTYyuiop[]hjkl;'vbnm/^"},  // conso1stKey
        {""},                           // conso2ndKey
        {""},                           // conso3rdKey

        {"SsjhxWLRndNcGkpmtwyvglrz^"},  // conso1stChar
        {""},                           // conso2ndChar
        {""},                           // conso3rdChar
        {""},                           // consoRsltant

        {"qwertasdfFgzxc"},             // vowel1stKey
        {"**************"},             // vowel2ndKey

        {"AIUXEaiuqqeQOo"},             // vowel1stChar
        {""},                           // vowel2ndChar

        {"OPKL:\"M"},                   // outOfMatrixKeys
        {"[]\":;'/"}                    // outOfMatrixChar
    },

    // TamilNet97 keyboard
    // http://www.tamilnation.org/digital/tamilnet97/standardisation.htm
    {
        {"tunop[bijkhl;m'y/]IOUPY{"},   // conso1stKey
        {"************************"},   // conso2ndKey
        {""},                           // conso3rdKey

        {"RvlnyNztkmpdwrLcgGSsjhWx"},   // conso1stChar
        {""},                           // conso2ndChar
        {""},                           // conso3rdChar
        {""},                           // consoRsltant

        {"csdxeqgravwzfF"},             // vowel1stKey
        {"**************"},             // vowel2ndKey

        {"aAiIuUeEXoOQqq"},             // vowel1stChar
        {""},                           // vowel2ndChar

        {"QWERKLZX<>"},                 // outOfMatrixKeys
        {"()()\"'<>;/"}                 // outOfMatrixChar
    },

    //----------------------------------------------------------------
    //  WYTIWYG Keyboards
    //--------------------
    //  These keyboards have ukara and uukaara uyirmeys mapped to keys.
    //  Also, the modifiers and uyirs have different keys.
    //
    //----------------------------------------------------------------

    // Mylai
    {
        {"!qwrtyp[]sdghjklzxXcvbnm"},  // Consos - base  (keys)
        {"`~;:uU'\"_oO$#"},            // non-modifier uyir  (keys)
        {"QWRTPDFGHJKLZCVBNM"},        // ukara, uukaara consos (keys)

        {"WLGrtyphjSdgNnklzsxcvRwm"},  // Consos - base   (char)
        {"aAiIuUeEXoOQq"},             // non-modifier uyir  (char)
        {"LGrtkdddNnklzccRwm"},        // ukara/uukaara : conso
        {"uuuuUuiIuuuuuuUuuu"},        // ukara/uukaara : vowel

        {"AeEa{}"},                    // WYTIWYG modifiers  (key)
        {"iI<>fY\\"},                  // Modifying modifiers (key)

        {"XeEAuU"},                    // WYTIWYG modifiers (char)
        {"iIuUqUU"},                   // Modifying modifiers (char)

        {"S|@^"},                      // outOfMatrixKeys. Index 0 key that maps Au-Length-Mark
        //{"S!�\""}                      // outOfMatrixChar. Index 0 is char that maps Au-Length-Mark, usually ignored  // Compiler complains the \uFFFD cannot be represented
        {"S!\""}                      // outOfMatrixChar. Index 0 is char that maps Au-Length-Mark, usually ignored
    },

    // Typewriter - New
    {
        {"|$&_+wertyuasdfgjkl'H\"z#"}, // Consos - base  (keys)
        {"mM/<cCvVIxX~"},              // non-modifier uyir  (keys)
        {"qoWERTYUOSDFGJKLN"},         // ukara, uukaara consos (keys)

        {"SjsWhRwcvlryLnkptmdgzGNx"},  // Consos - base   (char)
        {"aAiIuUeEXoOq"},              // non-modifier uyir  (char)
        {"NdRwcklrdLnkztmdc"},         // ukara/uukaara : conso
        {"uiuuuUuuIuuuuuuuU"},         // ukara/uukaara : vowel

        {"ibnh"},                      // WYTIWYG modifiers  (key)
        {"%^p[]P{};:"},                // Modifying modifiers (key)

        {"XeEA"},                      // WYTIWYG modifiers (char)
        {"uUiuXIUUqU"},                // Modifying modifiers (char)

        {"`>-#*:"},                   // outOfMatrixKeys. Index 0 key that maps Au-Length-Mark
        {"`-/%'\""}                   // outOfMatrixChar. Index 0 is char that maps Au-Length-Mark, usually ignored
    },

    // Typewriter - Old  : same as tw new
    {
        {"|$&_+wertyuasdfgjkl'H\"z#"}, // Consos - base  (keys)
        {"mM/<cCvVIxX~"},              // non-modifier uyir  (keys)
        {"qoWERTYUOSDFGJKLN"},         // ukara, uukaara consos (keys)

        {"SjsWhRwcvlryLnkptmdgzGNx"},  // Consos - base   (char)
        {"aAiIuUeEXoOq"},              // non-modifier uyir  (char)
        {"NdRwcklrdLnkztmdc"},         // ukara/uukaara : conso
        {"uiuuuUuuIuuuuuuuU"},         // ukara/uukaara : vowel

        {"ibnh"},                      // WYTIWYG modifiers  (key)
        {"%^p[]P{};:"},                // Modifying modifiers (key)

        {"XeEA"},                      // WYTIWYG modifiers (char)
        {"uUiuXIUUqU"},                // Modifying modifiers (char)

        {"`>-#*:"},                 // outOfMatrixKeys. Index 0 key that maps Au-Length-Mark
        {"`-/%'\""}                 // outOfMatrixChar. Index 0 is char that maps Au-Length-Mark, usually ignored
    },

    // Place holder for Anjal Indic.  This table will not be
    // used as AnjalIndic has it's own set of tables.
    {
        {""},   // conso1stKey
        {""},   // conso2ndKey
        {""},   // conso3rdKey

        {""},   // conso1stChar
        {""},   // conso2ndChar
        {""},   // conso3rdChar
        {""},   // consoRsltant

        {""},   // vowel1stKey
        {""},   // vowel2ndKey

        {""},   // vowel1stChar
        {""},   // vowel2ndChar

        {""},   // outOfMatrixKeys
        {""}    // outOfMatrixChar
    },

    // Murasu-6 Keyboard (Kaniyan Keyboard)
    // This will only be made available if Murasu Compatibilituy Pack is
    // Present.
    {
        {"YIOPLUmyo;[/Kjlkh'puJin]"},   // conso1stKey
        {"************************"},   // conso2ndKey
        {""},                           // conso3rdKey

        {"SsjhxWLRndNcGkpmtwyvglrz"},   // conso1stChar
        {""},                           // conso2ndChar
        {""},                           // conso3rdChar
        {""},                           // consoRsltant

        {"sewatvdfgzrxcb"},             // vowel1stKey
        {"**************"},             // vowel2ndKey

        {"AIUXEoiuqqeQOa"},             // vowel1stChar
        {""},                           // vowel2ndChar

        {"`~"},                         // outOfMatrixKeys
        {";'"}                          // outOfMatrixChar
    },

    // Bamini - Added 2022-01-23
    // Reference: https://help.keyman.com/keyboard/thamizha%20bamini/2.0/thamizha%20bamini
    {
        {"][\\=`wertyuasdfgjklqoQz~"},  // Consos - base  (keys)
        {"mM,<cCvVIxX/"},               // non-modifier uyir  (keys)
        {"bB#$%^&WERTYUOASDFGJKLZ"},    // ukara, uukaara consos (keys)

        {"SjsWhRwcvlryLnkptmdgzGNx"},   // Consos - base   (char)
        {"aAiIuUeEXoOq"},               // non-modifier uyir  (char)
        {"ddckmdrRwcvlrzyLnkptmdN"},    // ukara/uukaara : conso
        {"iIUUUUUuuuuuuuuuuuuuuuu"},    // ukara/uukaara : vowel

        {"inNhpP;_+"},                  // WYTIWYG modifiers  (key)
        {"%^p[]P{};:"},                 // Modifying modifiers (key)

        {"XeEAiIqUU"},                  // WYTIWYG modifiers (char)
        {"uUiuXIuUqU"},                 // Modifying modifiers (char)

        {"|>@#$%^&H"},                  // outOfMatrixKeys. UVWXYZ
        {"|,;UVWXYZ"}                   // outOfMatrixChar. சூகூமூடூரூர்
    },
    
    // Typewriter - TN  : Added 2022-03-31
    // Based on current typewriter keyboard. Some characters mapped to different keys
    // Eg VOWEL-I and Grantha letters
    {
        {"!$Z_]wertyuasdfgjkl'H\"zB"}, // Consos - base  (keys)
        {"mM,<cCvVIxX`"},              // non-modifier uyir  (keys)
        {"qoWERTYUOSDFGJKLN"},         // ukara, uukaara consos (keys)

        {"SjsWhRwcvlryLnkptmdgzGNx"},  // Consos - base   (char)
        {"aAiIuUeEXoOq"},              // non-modifier uyir  (char)
        {"NdRwcklrdLnkztmdc"},         // ukara/uukaara : conso
        {"uiuuuUuuIuuuuuuuU"},         // ukara/uukaara : vowel

        {"ibnh"},                      // WYTIWYG modifiers  (key)
        {"%^p[]P{};:"},                // Modifying modifiers (key)

        {"XeEA"},                      // WYTIWYG modifiers (char)
        {"uUiuXIUUqU"},                // Modifying modifiers (char)

        {"`~*-@#>./?"},                 // outOfMatrixKeys. Index 0 key that maps Au-Length-Mark
        {"`*'/\"%?,.-"}                 // outOfMatrixChar. Index 0 is char that maps Au-Length-Mark, usually ignored
    },
    // End of Tables

};

// arrays used only by the Tamil99 keyboard
char T99EscapesKey[] = ".c7890S^"; // these keys are pressed after '^'
char T99EscapesChar[] = ".c7890S^"; // TODO: Replace these chars with the actual values.  See keybd.h
char T99SymbolsKey[] = "ASDZXCVB";
char T99SymbolsTAM[] = "ASDZXCVB"; // TODO: Replace these chars with the actual values.  See keybd.h


#endif
