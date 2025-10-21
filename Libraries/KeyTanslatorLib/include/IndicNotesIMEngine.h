#ifndef INDIC_NOTES_IM_ENGINE_H
#define INDIC_NOTES_IM_ENGINE_H

#include <stdint.h>
#include <stdbool.h>
#include <wchar.h>
#include <ctype.h>
#include "IndicIMEConstants.h"

// Platform compatibility
#ifndef _WIN32
typedef wchar_t UniChar;
#else
typedef unsigned short UniChar;
#endif

// Key types
#define CHARACTER_END_KEYTYPE       1
#define FIRST_VOWEL_KEYTYPE         2
#define SECOND_VOWEL_KEYTYPE        3
#define THIRD_VOWEL_KEYTYPE         4
#define FIRST_VOWELSIGN_KEYTYPE     5
#define SECOND_VOWELSIGN_KEYTYPE    6
#define THIRD_VOWELSIGN_KEYTYPE     7
#define FIRST_CONSO_KEYTYPE         8
#define SECOND_CONSO_KEYTYPE        9
#define THIRD_CONSO_KEYTYPE         10
#define INDIC_DEAD_KEYTYPE          11
#define WHITE_SPACE_KEYTYPE         12

// Character types
#define NON_INDIC_CHARTYPE          0
#define CONSO_CHARTYPE              1
#define VOWEL_CHARTYPE              2

#define BACKSPACEKEY                0x0008

// Data structure for key translation results
typedef struct {
    UniChar prevKey;
    UniChar prevKeyType;
    UniChar prevCharType;
    UniChar firstVowelKey;
    UniChar firstConsoKey;
    UniChar currentBaseChar;
    int     imeType;
    int     insertCount;
    int     deleteCount;
    bool    fixPrevious;
    UniChar contextBefore;
} getKeyStringResults;

#ifdef __cplusplus
extern "C" {
#endif

// Core functions
void getKeyStringUnicode(UniChar currKey, UniChar *s, getKeyStringResults *results);
int getKeyPos(UniChar key, UniChar table[], UniChar pKey, UniChar pTable[], UniChar fKey, UniChar fTable[]);
void clearResults(getKeyStringResults *results);

// Language-specific functions
void getKeyStringUnicodeDevanagariAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionDevanagariAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeMalayalamAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionMalayalamAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeKannadaAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionKannadaAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeTeluguAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionTeluguAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeGurmukhiAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionGurmukhiAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeTamilAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionTamilAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results);

void getKeyStringUnicodeDiacritic(UniChar currKey, UniChar *s, getKeyStringResults *results);
void startNewSessionDiacritic(UniChar currKey, UniChar *s, getKeyStringResults *results);

#ifdef __cplusplus
}
#endif

#endif // INDIC_NOTES_IM_ENGINE_H
