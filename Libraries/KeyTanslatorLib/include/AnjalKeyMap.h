/* keyboard driver for M5
 * Written by M. N. Muthu
 * (C) 1992, M. N. Muthu
 * Date : 27 October 1992
 * Modified for Windows  3.1
 *     on : 24 Jan 1993
 * Modified for M6 : Feb 1995
 * Ported to 32bit (Anjal 2.0) : 31 Dec 1997
 * Modified to process keystrokes independant of charset
 *   and to support Unicode (doublebyte characters)
 *   for Anjal2000 - 23 Sept 1999
 * Modified for Anjal 10 based on Text Services Framework
 *   to support Unicode only in Windows Xp and later Windows
 *   06 Dec 2008
 * Updated: Sept 29 2022
 *   Added Bamini and imporved WYTIWYG implementations
 *   Added macOS support
 * Updated: March 31 2022
 *   Added TN Typewriter based on specs published by TVA
 *   Imporved WYTIWYG implementations
 *   Added macOS support
 */

#ifndef ANJALKEYMAP_H
#define ANJALKEYMAP_H

// --- Not Windows, i.e. macOS/*nix
#ifndef _WIN32
#include <wchar.h>
#include <stdbool.h>

#define BOOL        bool
#define WORD        int
#define WCHAR       wchar_t

#ifndef TRUE
#define TRUE        true
#endif

#define sprintf_s   sprintf

#else // !WIN32

#include <ctype.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>

#endif // !WIN32

// character sets
#define MAX_ROWS           37  //35  //}  Applied to Tamil only
#define MAX_COLS           13  //}

// keyboard types
#define kbdNone             -1
#define MAX_KBDTYPES        10
#define kbdAnjal            0
#define kbdTamil99          1
#define kbdTamil97          2
#define kbdMylai            3
#define kbdTWNew            4
#define kbdTWOld            5
#define kbdAnjalIndic       6
#define kbdMurasu6          7
#define kbdBamini           8
#define kbdTNTWriter        9

// getKeyString results
#define KSR_DELETE_PREV_KS_LENGTH -1
#define KSR_DELETE_NONE            0

#define ZWSPACE         0x200B

void     ResetKeyStringGlobals(void);
void     ResetPrevKeyType(void);
void     UpdatePrevKeyTypesForLastChar(WCHAR lastChar); // 2022-02-10
void     DisableAutoPulli(void);
void     EnableAutoPulli(void);
bool     IsAutoPulliEnabled(void);
int      GetCharStringForKey(WCHAR key, WCHAR prevKey, WCHAR* s, bool prevKeyWasBackspace);
WCHAR* GetCompoundString(char conso, char vowel);
int      GetIndexInTable(char c, char* table);
WCHAR    GetKeyFromShift(WCHAR key, bool shiftState);
int      GetKeyPos(WCHAR key, char* table, WCHAR pKey, char* pTable, WCHAR fKey, char* fTable);
void     WStringCopy(WCHAR* pchDst, const WCHAR* pchSrc);
void     WStringCat(WCHAR* pchDst, const WCHAR* pchSrc);
void     doDebug(const char* log);
void     doDebug1(const char* log);
void     doDebugDumpArray(const WCHAR* log);
BOOL     OkToTerminateComposition(WCHAR ch, int kbdType, bool keyShifted);
BOOL     IsDependantVowel(WCHAR wch);
BOOL     IsBaseChar(WCHAR wch);
BOOL     IsKeyMapped(WCHAR key, int kbdType, bool keyShifted);
BOOL     IsKeyMappedEx(WCHAR key, int kbdType);
void     SetKeyboardLayout(int newLayout);
int      GetKeyboardLayout(void);
BOOL     IsSuggestionsKey(WCHAR key, bool isAltOn);
int      PrevKeyTypeFromLastChar(WCHAR lastChar);
BOOL     IsIndependantVowel(WCHAR c);
BOOL     IsConsonant(WCHAR c);
BOOL     IsVowelSign(WCHAR c);
BOOL     IsLeftVowelSign(WCHAR c);
BOOL     IsTwoPartVowelSign(WCHAR c);
BOOL     IsCurrentKeyboardWytiwyg(void);
WCHAR    LeftVowelSignFor(WCHAR twoPartVS);
void     SetWytiwygVowelLeftHalf(WCHAR lh);
void     SetWytiwygDeleteInReverseTypingOrder(BOOL reverseOrder);
int      GetUnmappedCharStringForKey(WCHAR key, WCHAR* s, WCHAR prevChar, bool isShifted);


// To be migrates
BOOL OkToTerminateCompositionOld(WCHAR wch, int kbdType);


#endif //ANJALKEYMAP_H
