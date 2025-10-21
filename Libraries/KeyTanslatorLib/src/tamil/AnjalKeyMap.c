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



//#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "AnjalKeyMap.h"
#include "EncodingTamil.h"
//#include "DebugOut.h"

#include "AnjalKeyMapLookup.h"

#define FRESH_SEQ           1
#define FIRST_VOWEL         2
#define SECOND_VOWEL        3
#define FIRST_CONSO         4
#define SECOND_CONSO        5
#define THIRD_CONSO         6
#define DEAD_KEY            7
#define LEFT_HALF_VOWEL     8 // used by WYTIWYG layouts
#define PRECOMPOSED_CONSO   9 // used by WYTIWYG leyouts for precomposed u/U modified consos

// -------------------------------------------------------------------------
// -------- Documentation for versions prior to Anjal2000
// -------------------------------------------------------------------------
// If the first key typed is in conso1stKeys [], the corresponding char in
// conso1stChar[] will replace 'key'. (i.e. a backspace will be preceed the
// replacing char)
//
// If the second key typed is in conso2ndKeys[], the corresponding char in
// conso2ndChar[] will replace the previous char. (a backspace will
// preceed the new char - to replace the previous char). If the second
// key typed is NOT in  conso2ndKeys[], the sequence is complete.  The
// next key will be treated as the first key.

// If the third key typed is in conso3ndKeys[], the corresponding char in
// conso3rdChar[] will replace the previous char. (a backspace will
// preceed the new char - to replace the previous char). If the third
// key typed is NOT in  conso3ndKeys[], the sequence is complete.  The
// next key will be treated as the first key.
//
// --- Start of Anjal2K doc
//
//  Each character is assigned a unique 7bit key.  Upon completion of
//  the processing, the resulting key (or set of keys) is then translated
//  according to the character set chosen. The assignment can be found in
//  ktables_inc.cpp
//
// -------------------------------------------------------------------------

// Global
char            lastConsoChar;              // The last conso key, added 2022-01-22
WORD            prevKeyType;                // The previous key type
WORD            firstConsoKey;              // The first conso key
char            vowelChar;
WCHAR           wytiwygVowelLeftHalf;
bool            startFreshSeq;
bool            T99PulliHandled;
static bool     autoPulliEnabled = true;    // Default Tamil99 mode
int             kbdType = kbdAnjal;         // Anjal is the default keyboard
WCHAR           compoundStringBuffer[20];   // 2022-01-24 : buffer to store compound string made global
bool            wytiwygDelInReverseTyping;  // 2022-02-13 : Delete in reverse typeing order in WYTIWYG kbds

void ResetKeyStringGlobals(void)
{
    vowelChar = '\0';
    wytiwygVowelLeftHalf = '\0';
    prevKeyType = 0;
    firstConsoKey = 0;
    startFreshSeq = true;
    T99PulliHandled = false;//true;
    lastConsoChar = '\0';
}

void UpdatePrevKeyTypesForLastChar(WCHAR lastChar)
{
    prevKeyType = PrevKeyTypeFromLastChar(lastChar);
    //printf("prevKeyType = %d", prevKeyType);
}

void ResetPrevKeyType(void)
{
    prevKeyType = FRESH_SEQ;
}

void DisableAutoPulli(void)
{
    autoPulliEnabled = false;
}

void EnableAutoPulli(void)
{
    autoPulliEnabled = true;
}

bool IsAutoPulliEnabled(void)
{
    return autoPulliEnabled;
}

void SetKeyboardLayout(int newLayout)
{
    kbdType = newLayout;
    ResetKeyStringGlobals();
}

int GetKeyboardLayout(void)
{
    return kbdType;
}

void SetWytiwygVowelLeftHalf(WCHAR lh)
{
    wytiwygVowelLeftHalf = lh;
}

void SetWytiwygDeleteInReverseTypingOrder(BOOL reverseOrder)
{
    // This is handled in ObjC. Passing it here just in case we need it later
    wytiwygDelInReverseTyping = reverseOrder;
}

// -- Returns the number of characters to delete
//     7 Apr 2010:  Added a new parameter prevKeyWasBackspace. Used to check for n->w conversion in Anjal keyboard
//    25 Feb 2022:  Added altPressed & shiftPressed to pick up keys without translating
int GetCharStringForKey(WCHAR key, WCHAR prevKey, WCHAR* s, bool prevKeyWasBackspace)
{
    int   vpos = 0;
    int   delCount = KSR_DELETE_PREV_KS_LENGTH;
    char  baseVowel;

    // --- for debugging
    char debugmsg[100];
    // --- end dbugging

    // reset flag
    startFreshSeq = false;

    // default is the character mapped to key
    s[0] = key;
    s[1] = 0;

    // mark the base modifier. Anjal keyboard is 'q' the rest is 'a'
    // this is used to pull out the conso before a vowel is typed
    baseVowel = (kbdType == kbdAnjal) ? 'q' : 'a';

    // if WYTIWYG keyboard jump straight to marker
    if (kbdType == kbdMylai || kbdType == kbdTWNew || kbdType == kbdTWOld || kbdType == kbdBamini || kbdType == kbdTNTWriter)
        goto WYTIWYG;


    // --- Handle OM for Anjal
    if (kbdType == kbdAnjal && prevKey == 'O' && key == 'M')
    {
        s[0] = 0x0BD0;
        s[1] = 0;
        return -1;
    }

    // --- Handle AYTHAM for T99
    if (kbdType == kbdTamil99 && key == 'F')
    {
        s[0] = 0x0B83;
        s[1] = 0;
        return KSR_DELETE_NONE;
    }

    // --- 11 Mar 2015 Handle AYTHAM for Anjal
    if (kbdType == kbdAnjal && key == 'q')
    {
        s[0] = 0x0B83;
        s[1] = 0;
        return KSR_DELETE_NONE;
    }

    // --- 11 Mar 2015 Handle vowel reset for Anjal
    if (kbdType == kbdAnjal && key == 'f')
    {
        s[0] = prevKey == 'f' ? 0x0BCD : 0; // eat the key
        prevKeyType = FRESH_SEQ;
        return KSR_DELETE_NONE;
    }

    // --- 25 Nov 2010: $$ => new rupee sign for non-WYTIWYG keyboards
    if (key == '$' && prevKey == '$') {
        s[0] = 0x20B9;
        s[1] = 0;
        return 1; // 1 = delete one char
    }

    switch (prevKeyType) {
    case (FRESH_SEQ):
        doDebug("- Prev key was FRESH_SEQ\n");
        // key has to be either a first vowel or a first conso. We must
        // always check for conso's first - as this will be the typing
        // sequence.

        startFreshSeq = true;
        /*
        sprintf(debugmsg, "Key value=%d, prevKey=%d", key, prevKey);
        MessageBox(NULL, debugmsg, "TextService", MB_OK);
        // Special case for 'n-'.  (w = n-) if it appears after a white
        // space change the current key to 'w'

        if (key == (WCHAR)'n' && kbdType == kbdAnjal) {
            if (prevKey == 0 || prevKey == (WCHAR)' ' || prevKey == (WCHAR)'\r' || prevKey == (WCHAR)'\t')
            key = (WCHAR)'w';
        }*/
        break;

    case (FIRST_VOWEL):
        //doDebug("- Prev key was FIRST_VOWEL\n");
        // Previous key was a vowel.  if key (the second key) is also
        // a vowel, modify the previous vowel with either a nedil, au
        // or ai.
        //MessageBox(NULL, "Prev key was FIRST_VOWEL", "TextService", MB_OK);
        //DebugOut(L"PrevKey is FIRST_VOWEL. Current key=%c", (WCHAR) key);
        if ((vpos = GetKeyPos(key, V2Keys, prevKey, V1Keys, 0, 0)) >= 0) {

            // Yeap, this key is 'also' a vowel.

            // if the key prior to the previous key is a consonant, the
            // compound needs to be regenerated (e.g. k + a + i becomes kai
            // (key = i, prevKey = a and consoChar = k)
            //MessageBox(NULL, "This key is also a Vowel", "TextService", MB_OK);
            if (lastConsoChar != 0) {
                // there is a conso key on which a modifier may not have
                // been applied (prevConsoCharSave) {

                // The consonant is prior to the previous key.
                // Here the previous key is a vowel.

                // if current and previous keys are the same vowel
                // nedil-ize the current vowel
//                    if (key == prevKey)
//                       vowelChar = V1Char[vpos+1];
//                    else
                vowelChar = V2Char[vpos];

                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            }
            else {

                // key is a second vowel with no prev conso.
                vowelChar = V2Char[vpos];
                WStringCopy(s, GetCompoundString(0, vowelChar));
            }

            // since key is a second vowel, complete the sequence (not in Anjal2)
            lastConsoChar = kbdType == kbdAnjal ? lastConsoChar : 0;
            prevKeyType = SECOND_VOWEL;// FRESH_SEQ;  //TODO

            break;
        }

        // Anjal2: If key is a vowel, pretend as if the firstvowel was not typed
        if (kbdType == kbdAnjal && (vpos = GetKeyPos(key, V1Keys, 0, 0, 0, 0)) >= 0) {
            //DebugOut(L"   key is not second vowel but a first one. Let's see if I can overwrite the first vowel");
            vowelChar = V1Char[vpos];
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            prevKeyType = FIRST_VOWEL; // remains as first vowel
        }
        else {
            // key is not a  vowel, break for fresh sequence processing
            startFreshSeq = true;
        }
        break;

    case (SECOND_VOWEL):
        //doDebug("- Prev key was SECOND_VOWEL\n");
        // Prev. key was a 2nd vowel. So key must be a first vowel or
        // a first conso - same as FRESH_SEQ  since there is no 3rd vowel
        //DebugOut(L"PrevKey is SECOND_VOWEL. Current key=%c", (WCHAR) key);
        // Anjal2: If key is a vowel, pretend as if the earlier vowel was not typed
        if (kbdType == kbdAnjal && (vpos = GetKeyPos(key, V1Keys, 0, 0, 0, 0)) >= 0) {
            //DebugOut(L"Current key is vowel and lastConsoChar is %c. How do I handle this?", lastConsoChar);
            vowelChar = V1Char[vpos];
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            prevKeyType = FIRST_VOWEL; // becomes first vowel
        }
        else {
            startFreshSeq = true;
            break;
        }

    case (FIRST_CONSO):
        doDebug("- Prev key was FIRST_CONSO\n");
        // return if both prev and current keys are escape chars
        if ((kbdType == kbdTamil99 || kbdType == kbdAnjal) && prevKey == '^') {
            doDebug("-- Processing escape\n");
            if ((vpos = GetKeyPos(key, T99EscapesKey, 0, NULL, 0, 0)) >= 0) {
                s[0] = T99EscapesChar[vpos]; //'^';
                s[1] = '\0';
                // delete the prev char
                //prevKey = ' ';
                prevKeyType = FRESH_SEQ;
                break;
            }
        }

        // Prev. Char was a 1st conso.  Check if key is 2nd conso,
        // if it is not than the seq is complete - start a fresh seq.

        if ((vpos = GetKeyPos(key, C2Keys, prevKey, C1Keys, 0, 0)) >= 0) {
            //sprintf(debugmsg, "-- key in C2Keys and prevKey in C1Keys. vpos=%d\n", vpos);
            sprintf_s(debugmsg, "-- key in C2Keys and prevKey in C1Keys. vpos=%d\n", vpos);
            doDebug(debugmsg);
            // key is a second conso. Send the new character with a
            // backspace flag

            lastConsoChar = C2Char[vpos];
            prevKeyType = (lastConsoChar == 'W') ? FRESH_SEQ : SECOND_CONSO; // terminate if this is a SRI

            WStringCopy(s, GetCompoundString(lastConsoChar, baseVowel));

            // the value of consoChar could be a special character
            // for sepcial sequence processing - place the resulting conso
            if (CReslt[vpos] != '*') {
                lastConsoChar = CReslt[vpos];
                delCount = 2;
            }

            break;

        }
        else if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
            doDebug("-- key in V1Keys\n");
            // if key is a vowel, apply modifier
            // can't be a second vowel since the prevKey is a conso
            vowelChar = V1Char[vpos];
            prevKeyType = FIRST_VOWEL;

            if (T99PulliHandled)
            {
                // --- if auto-pulli was handled just before this vowel, we just
                //     need to delete the last base & not the entire prev string
                delCount = 1;
                // --- reset the flag
                T99PulliHandled = false;
            }

            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));

            break;

        }
        doDebug("-- key not in C2Keys or V1Keys\n");
        // if code gets here, it must be a fresh seq. - break
        startFreshSeq = true;
        break;

    case (SECOND_CONSO):
        doDebug("- Prev key was SECOND_CONSO\n");
        // Prev. Char was a 2nd conso.  If key is NOT a 3rd conso, the
        // sequence is complete - start a frest seq.
        if ((vpos = GetKeyPos(key, C3Keys, prevKey, C2Keys,
            firstConsoKey, C1Keys)) >= 0) {
            // key is a third conso. Send the new character with a b/s flag
            prevKeyType = THIRD_CONSO;
            lastConsoChar = C3Char[vpos]; //conso1stChar[vpos];

            WStringCopy(s, GetCompoundString(lastConsoChar, baseVowel));
            // the value of consoChar could be a special character
            // for sepcial sequence processing - place the resulting conso
            if (CReslt[vpos] != '*') {
                lastConsoChar = CReslt[vpos];
                delCount = lastConsoChar == 'c' ? 2 : 4; // njj only deletes 2
            }

            break;

        }
        else if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
            // if key is a vowel, apply modifier
            // can't be a second vowel since the prevKey is a conso
            vowelChar = V1Char[vpos];
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            prevKeyType = FIRST_VOWEL;
            break;
        }

        // break for fresh sequence processing
        startFreshSeq = true;
        break;

    case (THIRD_CONSO):
        doDebug("- Prev key was THIRD_CONSO\n");
        // Prev char is a 3rd conso - if key is a vowel, apply modifier
        if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
            // if key is a vowel, apply modifier
            // can't be a second vowel since the prevKey is a conso
            vowelChar = V1Char[vpos];
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            prevKeyType = FIRST_VOWEL;
            break;
        }
        // otherwise seq. is complete.  start a fresh seq.
        startFreshSeq = true;
        break;

    default:
        doDebug("- Prev key UNKNOWN\n");
        startFreshSeq = true;
        break;
    }


    if (!startFreshSeq) {
        if (prevKeyType != SECOND_CONSO)
            firstConsoKey = '0';
        return delCount;
    }

    //--------------------------------------------------------------
    // If code gets here, it is a fresh sequence.
    //--------------------------------------------------------------
    doDebug("--- Starting a fresh squence\n");

    delCount = KSR_DELETE_NONE;

    // Special case for 'n-'.  (w = n-) if it appears after a white
    // space change the current key to 'w'
    // 7 April 2010 : added check for prevKeyWasBackspace
    if (key == (WCHAR)'n' && kbdType == kbdAnjal && !prevKeyWasBackspace) {
        if (prevKey == 0 || prevKey == (WCHAR)' ' || prevKey == (WCHAR)'\r' || prevKey == (WCHAR)'\t')
            key = (WCHAR)'w';
    }

    // check if key is a vowel or a consonant or a out-of-matrix key
    if ((vpos = GetKeyPos(key, C1Keys, 0, NULL, 0, 0)) >= 0)
    {
        doDebug("---- key is a conso. checking for autopulli\n");

        // key is in conso. set flag and get the key
        lastConsoChar = C1Char[vpos];
        prevKeyType = FIRST_CONSO;

        // --------------------------------------------------------------
        // Tamil99 Specific handling
        // --------------------------------------------------------------
        if (autoPulliEnabled && (!T99PulliHandled) && kbdType == kbdTamil99)
        {
            char sb[100];
            //sprintf(sb, "----- Enabled: %d, Handled %d, Type %d\n", autoPulliEnabled, T99PulliHandled, kbdType);
            sprintf_s(sb, "----- Enabled: %d, Handled %d, Type %d\n", autoPulliEnabled, T99PulliHandled, kbdType);
            doDebug(sb);

            // get the prev conso
            vpos = GetKeyPos(prevKey, C1Keys, 0, NULL, 0, 0);
            unsigned char prevChar = C1Char[vpos];

            if ((prevKey == 'b' && key == 'h') ||  // ng + ka
                (prevKey == ']' && key == '[') ||  // nj + ca
                (prevKey == ';' && key == 'l') ||  // n- + tha
                (prevKey == 'p' && key == 'o') ||  // N + da
                (prevKey == 'k' && key == 'j') ||  // m + pa
                (prevKey == 'i' && key == 'u') ||  // n + Ra
                (prevKey == key)) {

                if (key != 'Y' && key != '^')
                { // does not apply or escape and SRI
                    doDebug("------ Adding (auto)pulli\n");
                    WStringCopy(s, GetCompoundString(prevChar, 'q'));
                    //prevKeyType = SECOND_CONSO;
                    T99PulliHandled = true;
                    delCount = KSR_DELETE_PREV_KS_LENGTH;
                }
            }
            else {
                s[0] = 0;
                delCount = KSR_DELETE_NONE;
            }
        }
        else {
            T99PulliHandled = false;
            s[0] = 0;
            delCount = KSR_DELETE_NONE; // no deleting of previous characters
        }

        firstConsoKey = key;
        vowelChar = baseVowel;  // first conso is always a mei !
        if (T99PulliHandled)
            WStringCat(s, GetCompoundString(lastConsoChar, vowelChar));
        else
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));

        return delCount;

    }
    else if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {

        //MessageBox(NULL, "Character is a Vowel", "DLL", MB_OK);

        prevKeyType = FIRST_VOWEL;
        // reset the conso char
        lastConsoChar = 0;
        firstConsoKey = 0;
        vowelChar = V1Char[vpos];

        WStringCopy(s, GetCompoundString(0, vowelChar));
        //MessageBox(NULL, "Returning 0 as delCount", "TextService", MB_OK);
        return delCount;
    }
    else if ((vpos = GetKeyPos(key, OMKeys, 0, NULL, 0, 0)) >= 0) {

        // key does not translate to an alphabet - but requires translation.
        // typically tamil numerals or remapping of keyboard
        prevKeyType = FRESH_SEQ;
        s[0] = OMChar[vpos];
        s[1] = '\0';
        delCount = KSR_DELETE_NONE;

        return delCount;
    }

WYTIWYG:

    // Mylai and Typewriter (New) keyboard uses the conso3key to directly
    // map WYTIWYG alphabets (typically ukaram & uukaaram).  The result
    // is a map of conso3char (conso) and consoRsltChar (vowel)
    if (kbdType == kbdMylai || kbdType == kbdTWNew || kbdType == kbdTWOld || kbdType == kbdBamini || kbdType == kbdTNTWriter ) {

        //char m[100];  // used only for debugging

        // 2022-01-25 Elongate double vowel signs in Bamini
        if (kbdType == kbdBamini && (prevKeyType == FIRST_VOWEL || (prevKeyType == LEFT_HALF_VOWEL && wytiwygVowelLeftHalf != 0))) {
            if ((key == 'p' || key == 'P') && prevKey == 'p') {
                s[0] = tgm_ii;
                s[1] = '\0';
                vowelChar = 'I';
                return 1; // delete prev char
            }
            else if ((key == '{' || key == '+') && prevKey == '{') {
                s[0] = tgm_uu;
                s[1] = '\0';
                vowelChar = 'U';
                return 1; // delete prev char
            }
            else if ((key == 'n' || key == 'N') && prevKey == 'n') {
                // --- this is a left half dependant vowel sign (AI-sign, kombu, 2kombu)
                s[0] = ZWSPACE; //---zero width space added as a "place-holder"
                s[1] = tgm_ee;
                s[2] = '\0';
                vowelChar = 'E';
                wytiwygVowelLeftHalf = s[1];
                return 1; // delete prev char
            }
            // Handle அ இ உ எ ஒ
            else if (key == 'm' && prevKey == 'm') { // aa->A
                s[0] = tgv_aa;
                s[1] = 0;
                return 1;
            }
            else if (key == ',' && prevKey == ',') { // ii->I
                s[0] = tgv_ii;
                s[1] = 0;
                return 1;
            }
            else if (key == 'c' && prevKey == 'c') { // uu->=U
                s[0] = tgv_uu;
                s[1] = 0;
                return 1;
            }
            else if (key == 'v' && prevKey == 'v') { // ee->E
                s[0] = tgv_ee;
                s[1] = 0;
                return 1;
            }
            else if (key == 'x' && prevKey == 'x') { // oo->O
                s[0] = tgv_oo;
                s[1] = 0;
                return 1;
            }
        }
        // End Bamini
        
        // TN Typewriter accepts UU-Kaal, mapped to '}' AFTER tu, nu, nnu, nnnu, lu, rru, nyu
        // Our Old Typewriter is in the reverse. Handle TN's as an exception
        if ( kbdType == kbdTNTWriter ) {
            if ( (key == '}' || key=='h') && (prevKey=='W' || prevKey=='E' || prevKey=='Y' || prevKey=='D' || prevKey=='J' || prevKey=='q' ) ) {
                s[0] = tgm_uu;
                s[1] = 0;
                return 1; // Don't delete nya if that was the prev key
            }
            if ( (key == '%' || key == '^') && (prevKey=='!' || prevKey=='$' || prevKey=='Z' || prevKey=='B' || prevKey==']' || prevKey=='"') ) {
                s[0] = key == '%' ? tgm_u : tgm_uu;
                s[1] = 0;
                return 0; // Don't delete the base
            }
        }

        // 2025-08-06: Old and New TW, convert ` to ' and `` to "
        if ( (kbdType == kbdTWOld || kbdType == kbdTWNew) && key == '`' ) {
            if ( prevKey == '`') {
                s[0] = '"';
                s[1] = 0;
                return 1; // delete prev
            }
            else {
                s[0] = '\'';
                s[1] = 0;
                return 0;
            }
        }
        
        // Base conso ?
        if ((vpos = GetKeyPos(key, ConsoKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; // default
            lastConsoChar = ConsoChar[vpos];
            vowelChar = (prevKeyType == DEAD_KEY) ? vowelChar : baseVowel;
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));

            if (prevKeyType == LEFT_HALF_VOWEL && wytiwygVowelLeftHalf != 0)
            {
                // --- if prev key was a left half-vowel mark, swap it's position with the base
                int sl = (int)wcslen(s);
                s[sl] = wytiwygVowelLeftHalf;
                s[sl + 1] = '\0';
                delCount = 2; // count is 2 because there is a 'place-holder' (0x200B) char after the left half-vowel
                prevKeyType = FIRST_VOWEL;
            }
            else
            {
                // --- delete the modifier with place-holder base, if there is one
                if (prevKeyType == DEAD_KEY)
                    delCount = 2;

                if (prevKeyType == FIRST_CONSO || prevKeyType == FIRST_VOWEL) {
                    //sprintf(m,"PrevKeytype is also first conso with wytiwygVowelLeftHalf as %d\n", wytiwygVowelLeftHalf);
                    //doDebug(m);
                    // --- clear the left half vowel sign
                    wytiwygVowelLeftHalf = 0;
                }

                prevKeyType = FIRST_CONSO;
            }

            return delCount;

            // WYTIWYG Uyir ?
        }
        else if ((vpos = GetKeyPos(key, wUyirKeys, 0, NULL, 0, 0)) >= 0) {

            // 2022-01-27 : Don't allow uyir if the prev key is a left-half vowelsign
            if (prevKeyType != LEFT_HALF_VOWEL) {
                vowelChar = wUyirChar[vpos];
                WStringCopy(s, GetCompoundString(0, vowelChar));
                if (s[0] == L'\x0B92') // save O-VOWEL for possible AU
                    wytiwygVowelLeftHalf = L'\x0B92';
                prevKeyType = FIRST_VOWEL;
                return KSR_DELETE_NONE;
            }
            else {
                s[0] = '\0';
                return KSR_DELETE_NONE;
            }

            // ukara, UkAra uyirmai ? (these are pre-composed 'keys' on WYTIWYG keyboards)
            // also includes tti & ttii
        }
        else if ((vpos = GetKeyPos(key, ukaraKeys, 0, NULL, 0, 0)) >= 0)
        {
            // 2022-02-16 : reset the left-half vowel sign if this is a precomposed key
            wytiwygVowelLeftHalf = 0;

            // 2022-01-27 : Don't u/uu modified consos if the prev key is a left-half vowelsign
            if (prevKeyType != LEFT_HALF_VOWEL) {
                delCount = (prevKeyType == DEAD_KEY) ? 1 : KSR_DELETE_NONE;
                // key is in conso. set flag and get the key
                lastConsoChar = uKaraCons[vpos];
                vowelChar = (prevKeyType == DEAD_KEY) ? vowelChar : uKaraVowl[vpos];
                // vowelChar = uKaraVowl[vpos];
                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                prevKeyType = PRECOMPOSED_CONSO; // FIRST_CONSO;
                return delCount;
            }
            else {
                s[0] = '\0';
                return KSR_DELETE_NONE;
            }

            // WYTIWYG Modifier ?
        }
        else if ((vpos = GetKeyPos(key, wModiKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; // default

            // get the modifiers from the 'ja' row
            vowelChar = wModiChar[vpos];
            WStringCopy(s, GetCompoundString('j', vowelChar));

            if (vpos < 3)// && prevKeyType == FIRST_CONSO )
            {
                // --- this is a left half dependant vowel sign (AI-sign, kombu, 2kombu)
                if (prevKeyType != LEFT_HALF_VOWEL) {
                    s[0] = ZWSPACE; //---zero width space added as a "place-holder"
                    s[1] = s[wcslen(s) - 1];
                    s[2] = '\0';
                    prevKeyType = LEFT_HALF_VOWEL;
                    wytiwygVowelLeftHalf = s[1];
                }
                else {
                    s[0] = '\0';
                    return KSR_DELETE_NONE;
                }
            }
            else
            {
                //doDebug("  Not a left half vs\n");

                WCHAR cw = s[wcslen(s) - 1];
                if (wytiwygVowelLeftHalf != L'\x0' && (cw == L'\x0BBE' || cw == L'\x0BD7')) // Kaal or Au-Mark
                {
                    if (prevKeyType != LEFT_HALF_VOWEL) {
                        // --- if there is a left half-vowel, substitute kaal & au-marks
                        if (wytiwygVowelLeftHalf == L'\x0BC6' && cw == L'\x0BBE') // single kombu+kaal
                        {
                            cw = L'\x0BCA';  // O-Modifier
                        }
                        /* --- this is never realised. au-mark is handled as Out of Matrix key in WYTIWYG keyboards
                         else if (wytiwygVowelLeftHalf==L'\x0BC6' && cw==L'\x0BD7') // single kombu+au_mark
                         {
                         cw = L'\x0BCC';  // AU-Modifier
                         }
                         */
                        else if (wytiwygVowelLeftHalf == L'\x0BC7' && cw == L'\x0BBE') // double kombu+kaal
                        {
                            //doDebug("      Double kombu + kaal\n");
                            cw = L'\x0BCB';  // OO-Modifier
                        }

                        s[0] = cw;
                        s[1] = '\0';
                        prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                        delCount = 1; // delete the half-vowel
                    }
                    else {
                        s[0] = '\0';
                        return KSR_DELETE_NONE;
                    }
                }
                else if (kbdType == kbdBamini && (key == 'h' || key == '+' || key == '{') && prevKey != 0 && wcschr(L"ZJEGKAUYTCSWD", prevKey) != NULL) {
                    // 2022-01-23 The kaal lenghtens the u-vowelsign in Bamini
                    s[0] = tgm_uu; // L'\x0BC2';
                    s[1] = '\0';
                    delCount = 1; // delete the u-vowelsign
                }
                else if (kbdType == kbdBamini && (key == 'p' || key == 'P') && prevKey == 'b') {
                    // 2022-01-26 lenghten the i-vowelsign in Bamini
                    s[0] = tgm_ii;
                    s[1] = '\0';
                    delCount = 1; // delete the i-vowelsign
                }
                // TODO: At this point, we can ignore vowel signs if there is already a vowel sign earlier
                else
                {
                    // Not a kaal or au-mark.
                    // 2022-01-27 : Only translate if prevKeyType is first conso
                    if (prevKeyType == FIRST_CONSO) {
                        s[0] = s[wcslen(s) - 1];
                        s[1] = '\0';
                        prevKeyType = FIRST_VOWEL;
                    }
                    else {
                        // Don't translate and forget this key unless it's a left half vowel
                        s[0] = '\0';
                        if (prevKeyType != LEFT_HALF_VOWEL)
                            prevKeyType = FRESH_SEQ;
                        return KSR_DELETE_NONE;
                    }
                }
                wytiwygVowelLeftHalf = 0;
            }

            return delCount; // KSR_DELETE_NONE;//KSR_DELETE_PREV_KS_LENGTH;

        // modifying modifier  ?
        }
        else if ((vpos = GetKeyPos(key, mModiKeys, 0, NULL, 0, 0)) >= 0) {

            delCount = KSR_DELETE_PREV_KS_LENGTH; // default

            vowelChar = mModiChar[vpos];
            if ( !(kbdType == kbdTWOld || kbdType == kbdTNTWriter) ) {
                if (prevKeyType == FIRST_CONSO || prevKeyType == PRECOMPOSED_CONSO) {
                    WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                }
                else {
                    WStringCopy(s, L"");  // nothing to modify
                    delCount = KSR_DELETE_NONE;
                }
                prevKeyType = FIRST_VOWEL;
            }
            else {
                // for oldtypewriter, this is a dead key
                //WStringCopy(s, L"");
                // --- put the modifier w dotted-circle as a place-holder
                WStringCopy(s, GetCompoundString('j', vowelChar));
                s[0] = ZWSPACE; //---zero width space added as a "place-holder" base
                s[1] = s[wcslen(s) - 1];
                s[2] = '\0';
                prevKeyType = DEAD_KEY;
                delCount = KSR_DELETE_NONE;
            }

            return delCount;

            // out of matrix key ?
        }
        else if ((vpos = GetKeyPos(key, OMKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; //default
            // Could be an au-length-mark (index=0) for AU-Modifier
            if (wytiwygVowelLeftHalf == L'\x0BC6' && vpos == 0)
            {
                s[0] = L'\x0BCC';
                s[1] = '\0';
                prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                delCount = 1; // delete the half-vowel
            }
            // Could be an au-mark for Vowel AU
            else if (wytiwygVowelLeftHalf == L'\x0B92' && vpos == 0)
            {
                s[0] = L'\x0B94';
                s[1] = '\0';
                prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                delCount = 1; // delete the O-vowek
            }
            else
            {
                // key does not translate to an alphabet - but requires translation.
                // typically tamil numerals or remapping of keyboard
                prevKeyType = FRESH_SEQ;
                s[0] = OMChar[vpos];
                s[1] = '\0';

                if (kbdType == kbdBamini) {
                    // 2022-01-27 : Bamini maps H to ர். I have used Z for ர் just for this
                    if (s[0] == 'Z') {
                        s[0] = tgc_ra;
                        s[1] = tgm_pulli;
                        s[2] = '\0';
                    }
                    // 2022-02-23 : Likewise UVWXY maps respectively to சூகூமூடூரூ
                    if (s[0] == 'U') {
                        s[0] = tgc_ca;
                        s[1] = tgm_uu;
                        s[2] = '\0';
                    }
                    if (s[0] == 'V') {
                        s[0] = tgc_ka;
                        s[1] = tgm_uu;
                        s[2] = '\0';
                    }
                    if (s[0] == 'W') {
                        s[0] = tgc_ma;
                        s[1] = tgm_uu;
                        s[2] = '\0';
                    }
                    if (s[0] == 'X') {
                        s[0] = tgc_tta;
                        s[1] = tgm_uu;
                        s[2] = '\0';
                    }
                    if (s[0] == 'Y') {
                        s[0] = tgc_ra;
                        s[1] = tgm_uu;
                        s[2] = '\0';
                    }
                }
            }
            wytiwygVowelLeftHalf = 0;
            return delCount;
        }
        else
        {
            delCount = KSR_DELETE_NONE;
        }
    }   // end of WYTIWYG (Mylai & TWNew procesing)

    //--------------------------------------------------------------
    // If code gets here, character cannot be converted.
    // must be a white-space, numerical or punct.  Reset flags
    //--------------------------------------------------------------

    lastConsoChar = '\0';
    firstConsoKey = 0;
    prevKeyType = FRESH_SEQ;
    //delCount=0;
    return delCount;
}

int GetKeyPos(WCHAR key, char* table, WCHAR pKey, char* pTable, WCHAR fKey, char* fTable)
{
    if (strlen(table) == 0)
        return -1;

    int vpos = 0;
    bool done = false;

    do {    // loop until some condition is reached
        while (table[vpos] != key) {
            if (table[vpos] == 0) break;
            vpos++;
        }

        if (table[vpos] == 0)
            // key not in table - so just return error (-1)
            return -1;

        // Key is in table.  Check if prev. key is given.
        if (pTable != NULL) { //(pKey > 0) {
            // Prev. key is given, match it against the
            // previous table so that the correct entry is taken
            if (pTable[vpos] == pKey)
                done = true;
            else {
                // fall through and loop until a match is found
                vpos++;
                continue;
            }
        }
        else {
            // if no prev. key is given, return the current position
            return vpos;
        }

        // Prev key matched.  Check if first key given
        if (fTable != NULL) {//(fKey > 0) {
            done = false;   // reset done flag
            // first key is given, match it against the
            // first table so that the correct entry is taken
            if (fTable[vpos] == fKey)
                done = true;
            else {
                // fall through and loop until a match is found
                vpos++;
                continue;
            }
        }

        if (done) return vpos;

    } while (true);

}


//---------------------------------------------------------------------------
#define     MAXCHANGE    21

WCHAR GetKeyFromShift(WCHAR key, bool shiftState)
{
    int       vpos;
    WCHAR   changeShift[22] = L"\xC0\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30\xBD\xBB\xDB\xDD\xBA\xDE\xBC\xBE\xBF\xDC";
    WCHAR   changeShiftON[22] = L"~!@#$%^&*()_+{}:\"<>?|";
    WCHAR   changeShiftOFF[22] = L"`1234567890-=[];',./\\";


    if (key == 16) // shift key has been depressed - do nothing, just return
        return 0;
    else if (isspace((int)key)) // if it's a white space, just return it's value
        return key;


    // convert if chars shift key needs to be processed
    vpos = 0;
    // check if this is a non-alphabet
    while (changeShift[vpos] != key && vpos != MAXCHANGE + 1) {
        vpos++;
    }

    if (shiftState == true) {
        if (vpos < MAXCHANGE + 1) {
            // yes - it's a non-alphabet, get the actual key from array
            key = changeShiftON[vpos];
        }
        else if (isalpha((int)key))
        {
            // don't need to worry about alphabets here as they are
            // always in upper case
        }
        else
            return 0;

    }
    else {
        if (vpos < MAXCHANGE + 1)
            // for non-alphabets, get the actual keycode from array
            key = changeShiftOFF[vpos];
        else if (isalpha((int)key))
        {
            // it's an alphabet, convert using to-lower
            key = (WORD)tolower((int)key);
        }
        else
            return 0;
    }

    // return with the value returned
    return key;
}


WCHAR* GetCompoundString(char conso, char vowel)
{
    int    row, col;

    row = (conso == 0) ? 0 : GetIndexInTable(conso, RowSequence);
    col = GetIndexInTable(vowel, ColumnSequence);

    if (row == -1) return (wchar_t*)L"";
    if (col == -1) return (wchar_t*)L"";

    const WCHAR* r = encTable[row][col];
    int slen = (int)(wcslen(r) * 2);
    //WCHAR *s = new WCHAR[slen+1];
    //WCHAR s[slen+1];

    if (slen > 0)
    {
#ifdef _WIN32
        // Windows
        wcsncpy_s(compoundStringBuffer, slen, (WCHAR*)r, slen);
#else
        // macOS
        wcsncpy(compoundStringBuffer, r, slen);
#endif
        compoundStringBuffer[wcslen(r)] = 0;
    }
    else compoundStringBuffer[0] = 0;

    return &compoundStringBuffer[0];
}

BOOL OkToTerminateComposition(WCHAR wch, int kbdType, bool keyShifted)
{
    /*
    if ( wch>0 && kbdType == kbdAnjal )
    {
        if ( strchr(" `1234567890-=[]\\;',./~!@#$%^&*()_+{}|:\"<>?\n\r\t", (char) wch) != NULL )
            return true;
    }

    return false;
    */

    if (wch != 0 && keyShifted/*GetKeyState(VK_SHIFT)<0*/ && kbdType == kbdTamil99 && wcschr(L"KL\xde\xbf", wch) != NULL)
    {
        return true;
    }

    // --- don't terminate composition if this key is mapped
    if (IsKeyMapped(wch, kbdType, keyShifted))
        return false;
    // --- terminate otherwise
    return true;
}

// 2022-01-26 : Called when shift state is not considered (macOS)
//              This is when shift state is handled when key event
//              is received.
BOOL IsKeyMappedEx(WCHAR wParam, int kbdType)
{
    // Send true for any character in WYTIWYG keyboards
    if (kbdType == kbdTWOld || kbdType == kbdTWNew) {
        //const wchar_t* unmappedKeys = L",.?​​`1234567890=!@​​()​​\\";
        const wchar_t* unmappedKeys = L",.?​​1234567890=!@​​()​​\\";
        return (wParam > 32 && wParam < 127) && (wcschr(unmappedKeys, wParam) == NULL);
    }
    if (kbdType == kbdTNTWriter ) {
        const wchar_t* unmappedKeys = L"&()=+|";
        return (wParam > 32 && wParam < 127) && (wcschr(unmappedKeys, wParam) == NULL);
    }
    else if (kbdType == kbdMylai) {
        const wchar_t* unmappedKeys = L",./?1234567890-=%&*()+";
        return (wParam > 32 && wParam < 127) && (wcschr(unmappedKeys, wParam) == NULL);
    }

    int wParamShift = toupper(wParam);
    // Search in both shifted and unshifted
    return IsKeyMapped(wParamShift, kbdType, true) || IsKeyMapped(wParamShift, kbdType, false);
}

BOOL IsKeyMapped(WCHAR wParam, int kbdType, bool keyShifted)
{
    bool mapped = false;

    if (keyShifted)
    {
        // Only eat the affected keys when shift is pressed
        if (kbdType == kbdAnjal && wcschr(L"ERUIOASLNM$W", wParam) != NULL)
            mapped = TRUE;
        else if (kbdType == kbdTamil99 && wcschr(L"QWERTYOPFKLM$:\"", wParam) != NULL) //\xde\xbf
            mapped = TRUE;
        else if (kbdType == kbdTamil97 && wcschr(L"QWERYUIOPFKLZX{<>", wParam) != NULL)  //\xbc\xbe\xdb
            mapped = TRUE;
        else if (kbdType == kbdMurasu6 && wcschr(L"YUIOPJKL", wParam) != NULL)
            mapped = TRUE;
        else if (kbdType == kbdMylai && wcschr(L"12346QWERTYUIOPASDFGHJKLZXCVBNM\xc0\xbd\xdb\xdd\xdc\xba\xde\xbc\xbe\xbf", wParam) != NULL)
            mapped = TRUE;
        else if ((kbdType == kbdTWOld || kbdType == kbdTWNew) && wcschr(L"47H3SWRLGNXEA3856OPWRTPDFGHJKLZCVBNMYUI\xdc\xbd\xbb\xde\xbe\xba\xc0\xdb\xdd\xba\xbc", wParam) != NULL)
            mapped = TRUE;
        else if (kbdType == kbdBamini && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"`_=+[]{}\\;,/<>@#$%^&~", wParam) != NULL))
            mapped = TRUE;
    }
    else
    {
        if (kbdType == kbdAnjal && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"-=\\", wParam) != NULL)) // -, = and backslash
            mapped = TRUE;
        else if (kbdType == kbdTamil99 && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"[];'/", wParam) != NULL)) // \xdb\xdd\xba\xde\xbf
            mapped = TRUE;
        else if (kbdType == kbdTamil97 && (wcschr(L"QWERTYUIOPASDFGHJKLZXCVBNM[;'/]", wParam) != NULL))  //\xbf\xdb\xdd\xba\xde
            mapped = TRUE;
        else if (kbdType == kbdMurasu6 && wcschr(L"WERTYUIOPASDFGHJKLZXCVBNM;[/']", wParam) != NULL) //\xdb\xdd\xba\xde\xbf
            mapped = TRUE;
        else if (kbdType == kbdMylai && wcschr(L"QWERTYUIOPASDFGHJKLZXCVBNM\xc0\xdb\xdd\xdc\xba\xde", wParam) != NULL)
            mapped = TRUE;
        else if ((kbdType == kbdTWOld || kbdType == kbdTWNew) && wcschr(L"QWERTYUASDFGJKLZJSHWCVLRYNKOPTMDGZXIBNHEP\xde\xbd\xdb\xdd\xba\xc0\xbf", wParam) != NULL)
            mapped = TRUE;
        else if (kbdType == kbdBamini && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"`_=+[]{}\\;,/<>@#$%^&~", wParam) != NULL))
            mapped = TRUE;
    }

    return mapped;
}

BOOL IsSuggestionsKey(WCHAR key, bool isAltOn)
{
    if (kbdType == kbdBamini) {
        return (isAltOn && key == '\\');
    }
    else {
        return  !isAltOn && (key == '\\' || key == '`');
    }

    return false;
}

BOOL IsDependantVowel(WCHAR wch)
{
    return (wcschr(L"\x0bbe\x0bbf\x0bc0\x0bc1\x0bc2\xbc6\x0bc7\x0bc8\x0bca\x0bcb\x0bcc\x0bcd\x0bd7", (wchar_t)wch) != NULL);
}

BOOL IsBaseChar(WCHAR wch)
{
    return (wcschr(L"\x0b95\x0b99\x0b9a\x0b9c\x0b9e\x0b9f\x0ba3\x0ba4\x0ba8\x0ba9\x0baa\x0bae\x0baf\x0bb0\x0bb1\x0bb2\x0bb3\x0bb4\x0bb5\x0bb6\x0bb7\x0bb8\x0bb9", (wchar_t)wch) != NULL);
}

int GetIndexInTable(char c, char* table)
{
    int i = 0;

    while (table[i] != '\0') {
        if (table[i] == c) break;
        i++;
    }

    return (table[i] == '\0') ? -1 : i;
}

void WStringCopy(WCHAR* dst, const WCHAR* src)
{
    int i = 0;

    for (int d = 0; d < (int)wcslen(src); d++)
    {
        dst[i++] = src[d];
    }

    dst[i] = '\0';
}

void WStringCat(WCHAR* dst, const WCHAR* src)
{
    int i = (int)wcslen(dst);

    for (int d = 0; d < (int)wcslen(src); d++)
    {
        dst[i++] = src[d];
    }

    dst[i] = '\0';
}

// 2022-01-11
// Get the prevKeyType from the character given
// Currently used for Bamini only
int PrevKeyTypeFromLastChar(WCHAR lastChar)
{
    if (IsIndependantVowel(lastChar)) {
        return FIRST_VOWEL;
    }
    else if (IsConsonant(lastChar)) {
        return FIRST_CONSO;
    }
    else if (IsLeftVowelSign(lastChar)) {
        return LEFT_HALF_VOWEL;
    }
    else if (IsVowelSign(lastChar)) {
        return FIRST_VOWEL;
    }

    return FRESH_SEQ;
}

BOOL IsIndependantVowel(WCHAR c)
{
    return wcschr(L"அஆஇஈஉஊஎஏஐஒஓஔ", c) != NULL;
}

BOOL IsConsonant(WCHAR c)
{
    return wcschr(L"கசடதபறயரலவழளஙஞணநமனஜஹஸஶஷ", c) != NULL;
}

BOOL IsVowelSign(WCHAR c)
{
    return wcschr(L"ாிீுூெேைொோௌ்", c) != NULL;
}

BOOL IsLeftVowelSign(WCHAR c)
{
    return wcschr(L"ெேை", c) != NULL;
}

BOOL IsTwoPartVowelSign(WCHAR c)
{
    return wcschr(L"ொோௌ", c) != NULL;
}

WCHAR LeftVowelSignFor(WCHAR twoPartVS)
{
    if (twoPartVS == tgm_o || twoPartVS == tgm_au) {
        return tgm_e;
    }
    else if (twoPartVS == tgm_oo) {
        return tgm_ee;
    }

    return 0;
}

BOOL IsCurrentKeyboardWytiwyg(void)
{
    return kbdType == kbdMylai || kbdType == kbdTWNew || kbdType == kbdTWOld || kbdType == kbdBamini || kbdType == kbdTNTWriter;
}

// Added : 2022-02-25
int GetUnmappedCharStringForKey(WCHAR key, WCHAR* s, WCHAR prevChar, bool isShifted)
{
    WCHAR* keystroke = (WCHAR*)L"abcdefghijklmnopqrstuvwxyz´¨ˆ˜`1234567890-=[]\\;',./";
    WCHAR* unshifted = (WCHAR*)L"abcdefghijklmnopqrstuvwxyzeuin`௧௨௩௪௫௬௭௮௯௦-=[]\\;',./";
    WCHAR* shifted = (WCHAR*)L"ABCDEFGHIJKLMNOPQRSTUVWXYZEUIN~!@#$%^&*()_+{}|:\"<>?";

    int delCount = KSR_DELETE_NONE;
    WCHAR sKey = key;

    int p = (int)(wcschr(keystroke, key) - keystroke);

    if (p >= 0) {
        sKey = isShifted ? shifted[p] : unshifted[p];
    }

    s[0] = sKey;
    s[1] = '\0';

    return delCount;
}

void doDebug(const char* log)
{
    /*
    FILE *f;
    if ( (f = fopen("\\Users\\muthu\\ime_debug.log", "a")) == NULL )
    {
        MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    }
    else
    {
        fprintf(f, "%s", log);
        fclose(f);
    }
    //*/

    printf("Debug: %s", log);
}

void doDebug1(const char* log)
{
    /*
    FILE *f;
    if ( (f = fopen("\\Users\\muthu\\ime_debug.log", "a")) == NULL )
    {
        MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    }
    else
    {
        fprintf(f, "%s", log);
        fclose(f);
    }
    */
}

void doDebugDumpArray(const WCHAR* log)
{
    /*
    FILE *f;
    if ( (f = fopen("c:\\ime_debug.log", "a")) == NULL )
    {
        MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    }
    else
    {
        fprintf(f, "   ");
        for ( int i=0; i<(int)wcslen(log); i++)
            fprintf(f, "%04X ", log[i]);
        fprintf(f, "\n");
        fclose(f);
    }
    //*/
}

// Need to migrate these to the keytranslator class
BOOL OkToTerminateCompositionOld(WCHAR wch, int kbdType)
{
    //if ( wch>0 && kbdType == kbdAnjal )
    //{
    //    if ( strchr(" `1234567890-=[]\\;',./~!@#$%^&*()_+{}|:\"<>?\n\r\t", (char) wch) != NULL )
    //        return true;
    //}

    //return false;
#ifdef WIN32
    if (wch != 0 && GetKeyState(VK_SHIFT) < 0 && kbdType == kbdTamil99 && wcschr(L"KL\xde\xbf", wch) != NULL)
    {
        return true;
    }
#endif
    
    // --- don't terminate composition if this key is mapped
    if (IsKeyMappedEx(wch, kbdType))
        return false;
    // --- terminate otherwise
    return true;
}




/*  --- Old Code
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "AnjalKeyMap.h"
#include "DebugOut.h"

#include "AnjalKeyMapLookup.inc"

#define FRESH_SEQ         1
#define FIRST_VOWEL         2
#define SECOND_VOWEL      3
#define FIRST_CONSO         4
#define SECOND_CONSO     5
#define THIRD_CONSO         6
#define DEAD_KEY         7
#define LEFT_HALF_VOWEL  8 // used by WYTIWYG layouts

// -------------------------------------------------------------------------
// -------- Documentation for versions prior to Anjal2000
// -------------------------------------------------------------------------
// If the first key typed is in conso1stKeys [], the corresponding char in
// conso1stChar[] will replace 'key'. (i.e. a backspace will be preceed the
// replacing char)
//
// If the second key typed is in conso2ndKeys[], the corresponding char in
// conso2ndChar[] will replace the previous char. (a backspace will
// preceed the new char - to replace the previous char). If the second
// key typed is NOT in  conso2ndKeys[], the sequence is complete.  The
// next key will be treated as the first key.

// If the third key typed is in conso3ndKeys[], the corresponding char in
// conso3rdChar[] will replace the previous char. (a backspace will
// preceed the new char - to replace the previous char). If the third
// key typed is NOT in  conso3ndKeys[], the sequence is complete.  The
// next key will be treated as the first key.
//
// --- Start of Anjal2K doc
//
//  Each character is assigned a unique 7bit key.  Upon completion of
//  the processing, the resulting key (or set of keys) is then translated
//  according to the character set chosen. The assignment can be found in
//  ktables_inc.cpp
//
// -------------------------------------------------------------------------

WORD prevKeyType;            // the previous key type
WORD firstConsoKey;
char vowelChar;
WCHAR wytiwygVowelLeftHalf;
bool startFreshSeq;
bool T99PulliHandled;
static bool autoPulliEnabled = true;

void ResetKeyStringGlobals()
{
    vowelChar = '\0';
    wytiwygVowelLeftHalf = '\0';
    prevKeyType = 0;
    firstConsoKey = 0;
    startFreshSeq = true;
    T99PulliHandled = false;//true;
}

void DisableAutoPulli()
{
    autoPulliEnabled = false;
}

void EnableAutoPulli()
{
    autoPulliEnabled = true;
}

bool IsAutoPulliEnabled()
{
    return autoPulliEnabled;
}

// -- Returns the number of characters to delete
//    7 April 2010:  Added a new parameter prevKeyWasBackspace. Used to check for n->w conversion in Anjal keyboard
int GetCharStringForKey(WCHAR key, WCHAR prevKey, WCHAR *s, char &lastConsoChar, int kbdType, bool prevKeyWasBackspace)
{
    int   vpos = 0;
    int   delCount = KSR_DELETE_PREV_KS_LENGTH;
    int   baseCharCount = kbdType == kbdAnjal ? 2 : 1;
    char  baseVowel;
    char  lConsoChar = lastConsoChar;


    //if ( key != 0 )
    //{
    //s[0]=L'A';
    //s[1]=0;
    //return KSR_DELETE_NONE;
    //}

    // --- for debugging
    char debugmsg[100];
    // --- end dbugging

    //sprintf(debugmsg, "Enabled: %d, Handled %d, Type %d", autoPulliEnabled, T99PulliHandled, kbdType);
    //MessageBox(NULL, debugmsg, "IME", MB_OK);
    //doDebug(debugmsg);

    //sprintf(debugmsg, "   Key: %c, PrevKey: %c, LastConso: %c\n", key>0?(char)key:'0', prevKey>0?(char)prevKey:'0', lConsoChar>0?lConsoChar:'0');
    //MessageBox(NULL, debugmsg, "IME", MB_OK);
    //doDebug(debugmsg);

    // reset flag
    startFreshSeq = false;

    // default is the character mapped to key
    s[0] = key;
    s[1] = 0;

    // mark the base modifier. Anjal keyboard is 'q' the rest is 'a'
    // this is used to pull out the conso before a vowel is typed
    baseVowel = (kbdType == kbdAnjal) ? 'q' : 'a';

    // if WYTIWYG keyboard jump straight to marker
    if (kbdType == kbdMylai || kbdType == kbdTWNew || kbdType == kbdTWOld)
        goto WYTIWYG;


    // --- Handle OM for Anjal
    if (kbdType==kbdAnjal && prevKey=='O' && key=='M')
    {
        s[0] = 0x0BD0;
        s[1] = 0;
        return -1;
    }

    // --- Handle AYTHAM for T99
    if (kbdType==kbdTamil99 && key=='F')
    {
        s[0] = 0x0B83;
        s[1] = 0;
        return KSR_DELETE_NONE;
    }

    // --- 11 Mar 2015 Handle AYTHAM for Anjal
    if (kbdType == kbdAnjal && key == 'q')
    {
        s[0] = 0x0B83;
        s[1] = 0;
        return KSR_DELETE_NONE;
    }

    // --- 11 Mar 2015 Handle vowel reset for Anjal
    if (kbdType == kbdAnjal && key == 'f')
    {
        s[0] = prevKey == 'f' ? 0x0BCD : 0; // eat the key
        prevKeyType = FRESH_SEQ;
        return KSR_DELETE_NONE;
    }

    // --- 25 Nov 2010: $$ => new rupee sign for non-WYTIWYG keyboards
    if ( key=='$' && prevKey=='$') {
        s[0] = 0x20B9;
        s[1] = 0;
        return 1; // 1 = delete one char
    }

    switch (prevKeyType) {
        case (FRESH_SEQ) :
            doDebug("- Prev key was FRESH_SEQ\n");
            // key has to be either a first vowel or a first conso. We must
            // always check for conso's first - as this will be the typing
            // sequence.

            startFreshSeq = true;
            
            //sprintf(debugmsg, "Key value=%d, prevKey=%d", key, prevKey);
            //MessageBox(NULL, debugmsg, "TextService", MB_OK);
            //// Special case for 'n-'.  (w = n-) if it appears after a white
   //         // space change the current key to 'w'
   //
            //if (key == (WCHAR)'n' && kbdType == kbdAnjal) {
            //    if (prevKey == 0 || prevKey == (WCHAR)' ' || prevKey == (WCHAR)'\r' || prevKey == (WCHAR)'\t')
            //    key = (WCHAR)'w';
            //}
            break;

        case (FIRST_VOWEL) :
            //doDebug("- Prev key was FIRST_VOWEL\n");
            // Previous key was a vowel.  if key (the second key) is also
            // a vowel, modify the previous vowel with either a nedil, au
            // or ai.
            //MessageBox(NULL, "Prev key was FIRST_VOWEL", "TextService", MB_OK);
            //DebugOut("PrevKey is FIRST_VOWEL. Current key=%c", (WCHAR) key);
            if ( (vpos = GetKeyPos(key, V2Keys, prevKey, V1Keys, 0, 0)) >= 0) {

                // Yeap, this key is 'also' a vowel.

                // if the key prior to the previous key is a consonant, the
                // compound needs to be regenerated (e.g. k + a + i becomes kai
                // (key = i, prevKey = a and consoChar = k)
                //MessageBox(NULL, "This key is also a Vowel", "TextService", MB_OK);
                if  (lastConsoChar != 0) {
                    // there is a conso key on which a modifier may not have
                    // been applied (prevConsoCharSave) {

                    // The consonant is prior to the previous key.
                    // Here the previous key is a vowel.

                    // if current and previous keys are the same vowel
                    // nedil-ize the current vowel
//                    if (key == prevKey)
//                       vowelChar = V1Char[vpos+1];
//                    else
                        vowelChar = V2Char[vpos];

                    WStringCopy(s, GetCompoundString(lastConsoChar,vowelChar));
                } else {

                    // key is a second vowel with no prev conso.
                    vowelChar = V2Char[vpos];
                    WStringCopy(s,GetCompoundString(0, vowelChar));
                }

                // since key is a second vowel, complete the sequence (not in Anjal2)
                lastConsoChar = kbdType == kbdAnjal ? lastConsoChar : 0;
                prevKeyType = SECOND_VOWEL;// FRESH_SEQ;  //TODO

                break;
            }

            // Anjal2: If key is a vowel, pretend as if the firstvowel was not typed
            if (kbdType==kbdAnjal && (vpos = GetKeyPos(key, V1Keys, 0, 0, 0, 0)) >= 0) {
                //DebugOut("   key is not second vowel but a first one. Let's see if I can overwrite the first vowel");
                vowelChar = V1Char[vpos];
                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                prevKeyType = FIRST_VOWEL; // remains as first vowel
            }
            else {
                // key is not a  vowel, break for fresh sequence processing
                startFreshSeq = true;
            }
            break;

        case (SECOND_VOWEL) :
            //doDebug("- Prev key was SECOND_VOWEL\n");
            // Prev. key was a 2nd vowel. So key must be a first vowel or
            // a first conso - same as FRESH_SEQ  since there is no 3rd vowel
            //DebugOut("PrevKey is SECOND_VOWEL. Current key=%c", (WCHAR) key);
            // Anjal2: If key is a vowel, pretend as if the earlier vowel was not typed
            if (kbdType == kbdAnjal && (vpos = GetKeyPos(key, V1Keys, 0, 0, 0, 0)) >= 0) {
                //DebugOut("Current key is vowel and lastConsoChar is %c. How do I handle this?", lastConsoChar);
                vowelChar = V1Char[vpos];
                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                prevKeyType = FIRST_VOWEL; // becomes first vowel
            }
            else {
                startFreshSeq = true;
                break;
            }

        case (FIRST_CONSO) :
            doDebug("- Prev key was FIRST_CONSO\n");
            // return if both prev and current keys are escape chars
            if ((kbdType == kbdTamil99 || kbdType == kbdAnjal ) && prevKey == '^') {
                doDebug("-- Processing escape\n");
                if ( (vpos = GetKeyPos(key, T99EscapesKey, 0, NULL, 0, 0)) >= 0) {
                    s[0] = T99EscapesChar[vpos]; //'^';
                    s[1] = '\0';
                    // delete the prev char
                    //prevKey = ' ';
                    prevKeyType = FRESH_SEQ;
                    break;
                }
            }

            // Prev. Char was a 1st conso.  Check if key is 2nd conso,
            // if it is not than the seq is complete - start a fresh seq.

            if ( (vpos = GetKeyPos(key, C2Keys, prevKey, C1Keys, 0, 0)) >= 0) {
                sprintf(debugmsg, "-- key in C2Keys and prevKey in C1Keys. vpos=%d\n", vpos);
                doDebug(debugmsg);
                // key is a second conso. Send the new character with a
                // backspace flag
                
                lastConsoChar = C2Char[vpos];
                prevKeyType = (lastConsoChar=='W') ? FRESH_SEQ : SECOND_CONSO; // terminate if this is a SRI

                WStringCopy(s, GetCompoundString(lastConsoChar, baseVowel) );

                // the value of consoChar could be a special character
                // for sepcial sequence processing - place the resulting conso
                if (CReslt[vpos] != '*') {
                    lastConsoChar = CReslt[vpos];
                    delCount = 2;
                }

                break;

            } else if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
                doDebug("-- key in V1Keys\n");
                // if key is a vowel, apply modifier
                // can't be a second vowel since the prevKey is a conso
                vowelChar = V1Char[vpos];
                prevKeyType = FIRST_VOWEL;

                if (T99PulliHandled)
                {
                    // --- if auto-pulli was handled just before this vowel, we just
                    //     need to delete the last base & not the entire prev string
                    delCount = 1;
                    // --- reset the flag
                    T99PulliHandled = false;
                }

                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));

                break;

            }
            doDebug("-- key not in C2Keys or V1Keys\n");
            // if code gets here, it must be a fresh seq. - break
            startFreshSeq =  true;
            break;

        case (SECOND_CONSO) :
            doDebug("- Prev key was SECOND_CONSO\n");
            // Prev. Char was a 2nd conso.  If key is NOT a 3rd conso, the
            // sequence is complete - start a frest seq.
             if ( (vpos = GetKeyPos(key, C3Keys, prevKey, C2Keys,
                  firstConsoKey, C1Keys)) >= 0) {
                // key is a third conso. Send the new character with a b/s flag
                prevKeyType = THIRD_CONSO;
                lastConsoChar = C3Char[vpos]; //conso1stChar[vpos];

                WStringCopy(s, GetCompoundString(lastConsoChar, baseVowel));
                // the value of consoChar could be a special character
                // for sepcial sequence processing - place the resulting conso
                if (CReslt[vpos] != '*') {
                    lastConsoChar = CReslt[vpos];
                    delCount = lastConsoChar=='c' ? 2 : 4; // njj only deletes 2
                }

                break;

            } else if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
                // if key is a vowel, apply modifier
                // can't be a second vowel since the prevKey is a conso
                vowelChar = V1Char[vpos];
                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                prevKeyType = FIRST_VOWEL;

                break;

            }

            // break for fresh sequence processing
            startFreshSeq = true;
            break;

        case (THIRD_CONSO) :
            doDebug("- Prev key was THIRD_CONSO\n");
            // Prev char is a 3rd conso - if key is a vowel, apply modifier
            if ((vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {
                // if key is a vowel, apply modifier
                // can't be a second vowel since the prevKey is a conso
                vowelChar = V1Char[vpos];
                WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
                prevKeyType = FIRST_VOWEL;
                break;

            }
            // otherwise seq. is complete.  start a fresh seq.
            startFreshSeq = true;
            break;

        default :
            doDebug("- Prev key UNKNOWN\n");
            startFreshSeq = true;
            break;
    }


    if (!startFreshSeq) {
        if (prevKeyType != SECOND_CONSO)
            firstConsoKey = '0';
        return delCount;
    }

    //--------------------------------------------------------------
    // If code gets here, it is a fresh sequence.
    //--------------------------------------------------------------
    doDebug("--- Starting a fresh squence\n");

    delCount = KSR_DELETE_NONE;

    // Special case for 'n-'.  (w = n-) if it appears after a white
    // space change the current key to 'w'
    // 7 April 2010 : added check for prevKeyWasBackspace
    if (key == (WCHAR)'n' && kbdType == kbdAnjal && !prevKeyWasBackspace) {
        if (prevKey == 0 || prevKey == (WCHAR)' ' || prevKey == (WCHAR)'\r' || prevKey == (WCHAR)'\t')
            key = (WCHAR)'w';
    }

    // check if key is a vowel or a consonant or a out-of-matrix key
    if ( (vpos = GetKeyPos(key, C1Keys, 0, NULL, 0, 0)) >= 0)
    {
        doDebug("---- key is a conso. checking for autopulli\n");

        // key is in conso. set flag and get the key
        lastConsoChar = C1Char[vpos];
        prevKeyType = FIRST_CONSO;

        // --------------------------------------------------------------
        // Tamil99 Specific handling
        // --------------------------------------------------------------
        if (autoPulliEnabled && (!T99PulliHandled) && kbdType == kbdTamil99)
        {
            char sb[100];
            sprintf(sb, "----- Enabled: %d, Handled %d, Type %d\n", autoPulliEnabled, T99PulliHandled, kbdType);
            doDebug(sb);

            // get the prev conso
            vpos = GetKeyPos(prevKey, C1Keys, 0, NULL, 0, 0);
            unsigned char prevChar = C1Char[vpos];

            if ( (prevKey == 'b' && key == 'h') ||  // ng + ka
                 (prevKey == ']' && key == '[') ||  // nj + ca
                 (prevKey == ';' && key == 'l') ||  // n- + tha
                 (prevKey == 'p' && key == 'o') ||  // N + da
                 (prevKey == 'k' && key == 'j') ||  // m + pa
                 (prevKey == 'i' && key == 'u') ||  // n + Ra
                 (prevKey == key) ) {

                if (key != 'Y' && key != '^')
                { // does not apply or escape and SRI
                    doDebug("------ Adding (auto)pulli\n");
                    WStringCopy(s,GetCompoundString(prevChar, 'q'));
                    //prevKeyType = SECOND_CONSO;
                    T99PulliHandled = true;
                    delCount = KSR_DELETE_PREV_KS_LENGTH;
                }
            } else {
                s[0]=0;
                delCount = KSR_DELETE_NONE;
            }
        } else {
            T99PulliHandled = false;
            s[0]=0;
            delCount=KSR_DELETE_NONE; // no deleting of previous characters
        }

        firstConsoKey = key;
        vowelChar = baseVowel;  // first conso is always a mei !
        if ( T99PulliHandled )
            WStringCat(s, GetCompoundString(lastConsoChar, vowelChar));
        else
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));

        return delCount;

    } else if ( (vpos = GetKeyPos(key, V1Keys, 0, NULL, 0, 0)) >= 0) {

        //MessageBox(NULL, "Character is a Vowel", "DLL", MB_OK);

        prevKeyType = FIRST_VOWEL;
        // reset the conso char
        lastConsoChar = 0;
        firstConsoKey = 0;
        vowelChar = V1Char[vpos];

        WStringCopy(s, GetCompoundString(0, vowelChar));
        //MessageBox(NULL, "Returning 0 as delCount", "TextService", MB_OK);
        return delCount;
    } else if ( (vpos = GetKeyPos(key, OMKeys, 0, NULL, 0, 0)) >= 0) {

        // key does not translate to an alphabet - but requires translation.
        // typically tamil numerals or remapping of keyboard
        prevKeyType = FRESH_SEQ;
        s[0] = OMChar[vpos];
        s[1] = '\0';
        delCount=KSR_DELETE_NONE;

        return delCount;
    }

WYTIWYG:

    // Mylai and Typewriter (New) keyboard uses the conso3key to directly
    // map WYTIWYG alphabets (typically ukaram & uukaaram).  The result
    // is a map of conso3char (conso) and consoRsltChar (vowel)
    if ( kbdType == kbdMylai || kbdType == kbdTWNew || kbdType == kbdTWOld ) {

        //char m[100];  // used only for debugging

        // base conso ?
        if ( (vpos = GetKeyPos(key, ConsoKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; // default
            lastConsoChar = ConsoChar[vpos];
            vowelChar = (prevKeyType == DEAD_KEY) ? vowelChar : baseVowel;
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            
            //sprintf(m,"Conso key %c[%d], prevKeyType %d\n", key, key, prevKeyType);
            //doDebug(m);

            if ( prevKeyType == LEFT_HALF_VOWEL )
            {
                //doDebug ("prevKeyType is left_half_vowel\n");

                // --- if prev key was a left half-vowel mark, swap it's position with the base
                int sl = wcslen(s);
                s[sl] = wytiwygVowelLeftHalf;
                s[sl+1] = '\0';
                delCount = 2; // count is 2 because there is a 'place-holder' (0x200B) char after the left half-vowel
                prevKeyType = FIRST_VOWEL;
            }
            else
            {
                // --- delete the modifier with place-holder base, if there is one
                if (prevKeyType == DEAD_KEY)
                    delCount = 2;

                if ( prevKeyType == FIRST_CONSO || prevKeyType == FIRST_VOWEL) {
                    //sprintf(m,"PrevKeytype is also first conso with wytiwygVowelLeftHalf as %d\n", wytiwygVowelLeftHalf);
                    //doDebug(m);
                    // --- clear the left half vowel sign
                    wytiwygVowelLeftHalf = 0;
                }

                prevKeyType = FIRST_CONSO;
            }

            return delCount;

        // WYTIWYG Uyir ?
        } else if ( (vpos = GetKeyPos(key, wUyirKeys, 0, NULL, 0, 0)) >= 0) {

            vowelChar = wUyirChar[vpos];
            WStringCopy(s, GetCompoundString(0, vowelChar));
            if ( s[0] == L'\x0B92' ) // save O-VOWEL for possible AU
                wytiwygVowelLeftHalf = L'\x0B92';
            prevKeyType = FIRST_VOWEL;

            return KSR_DELETE_NONE;

        // ukara, UkAra uyirmai ? (these are pre-composed 'keys' on WYTIWYG keyboards)
        } else if ( (vpos = GetKeyPos(key, ukaraKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = (prevKeyType == DEAD_KEY) ? 1 : KSR_DELETE_NONE;
            // key is in conso. set flag and get the key
            lastConsoChar = uKaraCons[vpos];
            vowelChar = (prevKeyType == DEAD_KEY) ? vowelChar : uKaraVowl[vpos];
            // vowelChar = uKaraVowl[vpos];
            WStringCopy(s, GetCompoundString(lastConsoChar, vowelChar));
            prevKeyType = FIRST_CONSO;

            return delCount;

        // WYTIWYG Modifier ?
        } else if ( (vpos = GetKeyPos(key, wModiKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; // default

            // get the modifiers from the 'ja' row
            vowelChar = wModiChar[vpos];
            WStringCopy(s, GetCompoundString('j', vowelChar));

            //sprintf(m, "Key: %c[%d], Char: %d. vPos: %d\n", key, key, vowelChar, vpos);
            //doDebug(m);

            if ( vpos < 3 )// && prevKeyType == FIRST_CONSO )
            {
                //sprintf(m, "  Left half dependant vowel sign\n");
                //doDebug(m);

                // --- this is a left half dependant vowel sign (AI-sign, kombu, 2kombu)
                s[0] = 0x200B; //---zero width space added as a "place-holder"
                s[1] = s[wcslen(s)-1];
                s[2] = '\0';
                prevKeyType = LEFT_HALF_VOWEL;
                wytiwygVowelLeftHalf = s[1];
            }
            else
            {
                //doDebug("  Not a left half vs\n");

                WCHAR cw = s[wcslen(s)-1];
                if ( wytiwygVowelLeftHalf != L'\x0' && (cw==L'\x0BBE' || cw==L'\x0BD7') ) // Kaal or Au-Mark
                {
                    //sprintf(m,"    Either kaal or aumark. left vs was %d\n", wytiwygVowelLeftHalf );
                    //doDebug(m);

                    // --- if there is a left half-vowel, substitute kaal & au-marks
                    if (wytiwygVowelLeftHalf==L'\x0BC6' && cw==L'\x0BBE') // single kombu+kaal
                    {
                        //doDebug("      Single kombu + kaal\n");
                        cw = L'\x0BCA';  // O-Modifier
                    }
                    // --- this is never realised. au-mark is handled as Out of Matrix key in WYTIWYG keyboards
                    //else if (wytiwygVowelLeftHalf==L'\x0BC6' && cw==L'\x0BD7') // single kombu+au_mark
                    //{
                    //    cw = L'\x0BCC';  // AU-Modifier
                    //}
                    
                    else if (wytiwygVowelLeftHalf==L'\x0BC7' && cw==L'\x0BBE') // double kombu+kaal
                    {
                        //doDebug("      Double kombu + kaal\n");
                        cw = L'\x0BCB';  // OO-Modifier
                    }
                    
                    s[0] = cw;
                    s[1] = '\0';
                    prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                    delCount = 1; // delete the half-vowel
                }
                else
                {
                    //doDebug("    Not a kaal or aumark\n");
                    s[0] = s[wcslen(s)-1];
                    s[1] = '\0';
                    prevKeyType = FIRST_VOWEL;
                }
                wytiwygVowelLeftHalf = 0;
            }

            return delCount; // KSR_DELETE_NONE;//KSR_DELETE_PREV_KS_LENGTH;

        // modifying modifier  ?
        } else if ( (vpos = GetKeyPos(key, mModiKeys, 0, NULL, 0, 0)) >= 0) {

            delCount = KSR_DELETE_PREV_KS_LENGTH; // default

            vowelChar = mModiChar[vpos];
            if (kbdType != kbdTWOld) {
                if ( prevKeyType == FIRST_CONSO ) {
                    WStringCopy(s, GetCompoundString(lastConsoChar,vowelChar));
                } else {
                    WStringCopy(s, L"");  // nothing to modify
                    delCount = KSR_DELETE_NONE;
                }
                prevKeyType = FIRST_VOWEL;
            } else {
                // for oldtypewriter, this is a dead key
                //WStringCopy(s, L"");
                // --- put the modifier w dotted-circle as a place-holder
                WStringCopy(s, GetCompoundString('j', vowelChar));
                s[0] = 0x200B; //---zero width space added as a "place-holder" base
                s[1] = s[wcslen(s)-1];
                s[2] = '\0';
                prevKeyType = DEAD_KEY;
                delCount = KSR_DELETE_NONE;
            }

            return delCount;

        // out of matrix key ?
        } else if ( (vpos = GetKeyPos(key, OMKeys, 0, NULL, 0, 0)) >= 0)
        {
            delCount = KSR_DELETE_NONE; //default
            // Could be an au-length-mark (index=0) for AU-Modifier
            if ( wytiwygVowelLeftHalf==L'\x0BC6' && vpos==0 )
            {
                s[0] = L'\x0BCC';
                s[1] = '\0';
                prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                delCount = 1; // delete the half-vowel
            }
            // Could be an au-mark for Vowel AU
            else if ( wytiwygVowelLeftHalf==L'\x0B92' && vpos==0 )
            {
                s[0] = L'\x0B94';
                s[1] = '\0';
                prevKeyType = FIRST_VOWEL; // SECOND_VOWEL is not used in WYTIWYG keyboards
                delCount = 1; // delete the O-vowek
            }
            else
            {
                // key does not translate to an alphabet - but requires translation.
                // typically tamil numerals or remapping of keyboard
                prevKeyType = FRESH_SEQ;
                s[0] = OMChar[vpos];
                s[1] = '\0';
            }
            wytiwygVowelLeftHalf = 0;
            return delCount;
        }
        else
        {
            delCount = KSR_DELETE_NONE;
        }
    }   // end of WYTIWYG (Mylai & TWNew procesing)

    //--------------------------------------------------------------
    // If code gets here, character cannot be converted.
    // must be a white-space, numerical or punct.  Reset flags
    //--------------------------------------------------------------

    lastConsoChar = '\0';
    firstConsoKey = 0;
    prevKeyType =  FRESH_SEQ;
    //delCount=0;
    return delCount;
}

void ResetPrevKeyType()
{
    prevKeyType = FRESH_SEQ;
}

int GetKeyPos(WCHAR key, char *table, WCHAR pKey, char *pTable, WCHAR fKey, char *fTable)
{
    if ( strlen(table) == 0 )
        return -1;

    int vpos=0;
    bool done = false;

    do {    // loop until some condition is reached
        while ( table[vpos] != key ) {
            if ( table[vpos] == 0 ) break;
            vpos++;
        }

        if (table[vpos] == 0)
            // key not in table - so just return error (-1)
            return -1;

        // Key is in table.  Check if prev. key is given.
        if (pTable != NULL) { //(pKey > 0) {
            // Prev. key is given, match it against the
            // previous table so that the correct entry is taken
            if (pTable[vpos] == pKey)
                done = true;
            else {
                // fall through and loop until a match is found
                vpos++;
                continue;
            }
        } else {
            // if no prev. key is given, return the current position
            return vpos;
        }

        // Prev key matched.  Check if first key given
        if (fTable != NULL) {//(fKey > 0) {
            done = false;   // reset done flag
            // first key is given, match it against the
            // first table so that the correct entry is taken
            if (fTable[vpos] == fKey)
                done = true;
            else {
                // fall through and loop until a match is found
                vpos++;
                continue;
            }
        }

        if (done) return vpos;

    } while (true);

}


//---------------------------------------------------------------------------
#define     MAXCHANGE    21

WCHAR GetKeyFromShift(WCHAR key, bool shiftState)
{
    int       vpos;
    WCHAR   changeShift[22]     =  L"\xC0\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30\xBD\xBB\xDB\xDD\xBA\xDE\xBC\xBE\xBF\xDC";
    WCHAR   changeShiftON[22]    =  L"~!@#$%^&*()_+{}:\"<>?|";
    WCHAR   changeShiftOFF[22]  =  L"`1234567890-=[];',./\\";


    if (key == 16) // shift key has been depressed - do nothing, just return
        return 0;
    else if ( isspace((int)key) ) // if it's a white space, just return it's value
        return key;


    // convert if chars shift key needs to be processed
    vpos = 0;
    // check if this is a non-alphabet
    while (changeShift[vpos] != key && vpos != MAXCHANGE+1) {
        vpos++;
    }

    if (shiftState == true) {
        if (vpos < MAXCHANGE + 1) {
            // yes - it's a non-alphabet, get the actual key from array
            key = changeShiftON[vpos];
        }
        else if ( isalpha((int)key) )
        {
            // don't need to worry about alphabets here as they are
            // always in upper case
        }
        else
            return 0;

    } else {
        if (vpos < MAXCHANGE + 1)
            // for non-alphabets, get the actual keycode from array
            key = changeShiftOFF[vpos];
        else if (isalpha((int)key) )
        {
            // it's an alphabet, convert using to-lower
            key = (WORD) tolower( (int) key);
        }
        else
            return 0;
    }

    // return with the value returned
    return key;
}


WCHAR *GetCompoundString(char conso, char vowel)
{
    int    row, col;

    row = (conso == 0) ? 0 : GetIndexInTable(conso, RowSequence);
    col = GetIndexInTable(vowel, ColumnSequence);

    if ( row == -1 ) return L"";
    if ( col == -1 ) return L"";

    WCHAR *r = encTable[row][col];
    int slen = (wcslen(r)*2);
    WCHAR *s = new WCHAR[slen+1];

    if ( slen > 0 )
    {
        wcsncpy_s(s, slen, (WCHAR *)r, slen);
        //MessageBox(NULL, "Copied to buffer", "TextService", MB_OK);
        s[wcslen(r)] = 0;
        //MessageBox(NULL, "Null Terminated", "TextService", MB_OK);
    }
    else s[0]=0;

    return s;
}

BOOL OkToTerminateComposition(WCHAR wch, int kbdType)
{
    //if ( wch>0 && kbdType == kbdAnjal )
    //{
    //    if ( strchr(" `1234567890-=[]\\;',./~!@#$%^&*()_+{}|:\"<>?\n\r\t", (char) wch) != NULL )
    //        return true;
    //}

    //return false;

    if ( wch!=0 && GetKeyState(VK_SHIFT)<0 && kbdType==kbdTamil99 && wcschr(L"KL\xde\xbf", wch) != NULL )
    {
        return true;
    }

    // --- don't terminate composition if this key is mapped
    if ( IsKeyMapped(wch, kbdType) )
        return false;
    // --- terminate otherwise
    return true;
}

BOOL IsKeyMapped(WCHAR wParam, int kbdType)
{
    bool mapped = false;

    //printf("checking if %d is used in keyboard type %d\n", (int)wParam, kbdType);

    // for debugging
    //if ( wParam != 16 )
    //{
    //    char m[100];
    //    int shifted = GetKeyState(VK_SHIFT)<0 ? 1 : 0;
    //    wsprintf(m, "Shift: %d, wParam: %d [%x]", shifted, wParam, wParam);
    //    MessageBox(NULL, m, "IsKeyMapped", MB_OK);
    //}

    if ( GetKeyState(VK_SHIFT)<0 )
    {
        // Only eat the affected keys when shift is pressed
        if ( kbdType == kbdAnjal && wcschr(L"ERUIOASLNM$W", wParam) != NULL )
            mapped = TRUE;
        else if ( kbdType==kbdTamil99 && wcschr(L"QWERTYOPFKLM$\xde\xbf", wParam) != NULL )
            mapped = TRUE;
        else if ( kbdType==kbdTamil97 && wcschr(L"QWERYUIOPFKLZX\xbc\xbe\xdb", wParam) != NULL )
            mapped = TRUE;
        else if ( kbdType==kbdMurasu6 && wcschr(L"YUIOPJKL", wParam) != NULL )
            mapped = TRUE;
        else if ( kbdType==kbdMylai && wcschr(L"12346QWERTYUIOPASDFGHJKLZXCVBNM\xc0\xbd\xdb\xdd\xdc\xba\xde\xbc\xbe\xbf", wParam) != NULL )
            mapped = TRUE;
        else if ( (kbdType==kbdTWOld || kbdType==kbdTWNew) && wcschr(L"47H3SWRLGNXEA3856OPWRTPDFGHJKLZCVBNMYUI\xdc\xbd\xbb\xde\xbe\xba\xc0\xdb\xdd\xba\xbc", wParam) != NULL )
            mapped = TRUE;
    }
    else
    {
        if ( kbdType==kbdAnjal && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"\xbd\xbb\xdc", wParam) != NULL) ) // -, = and backslash
            mapped = TRUE;
        else if ( kbdType==kbdTamil99 && ((wParam >= 'A' && wParam <= 'Z') || wcschr(L"\xdb\xdd\xba\xde\xbf", wParam) != NULL) ) // [];'/
            mapped = TRUE;
        else if ( kbdType==kbdTamil97 && (wcschr(L"QWERTYUIOPASDFGHJKLZXCVBNM\xbf\xdb\xdd\xba\xde", wParam) != NULL) )
            mapped = TRUE;
        else if ( kbdType==kbdMurasu6 && wcschr(L"WERTYUIOPASDFGHJKLZXCVBNM\xdb\xdd\xba\xde\xbf", wParam) != NULL )
            mapped = TRUE;
        else if ( kbdType==kbdMylai && wcschr(L"QWERTYUIOPASDFGHJKLZXCVBNM\xc0\xdb\xdd\xdc\xba\xde", wParam) != NULL )
            mapped = TRUE;
        else if ( (kbdType==kbdTWOld || kbdType==kbdTWNew) && wcschr(L"QWERTYUASDFGJKLZJSHWCVLRYNKOPTMDGZXIBNHEP\xde\xbd\xdb\xdd\xba\xc0\xbf", wParam) != NULL )
            mapped = TRUE;
    }

    return mapped;
}

BOOL IsDependantVowel(WCHAR wch)
{
    return ( wcschr(L"\x0bbe\x0bbf\x0bc0\x0bc1\x0bc2\xbc6\x0bc7\x0bc8\x0bca\x0bcb\x0bcc\x0bcd\x0bd7", (wchar_t)wch) != NULL );
}

BOOL IsBaseChar(WCHAR wch)
{
    return ( wcschr(L"\x0b95\x0b99\x0b9a\x0b9c\x0b9e\x0b9f\x0ba3\x0ba4\x0ba8\x0ba9\x0baa\x0bae\x0baf\x0bb0\x0bb1\x0bb2\x0bb3\x0bb4\x0bb5\x0bb6\x0bb7\x0bb8\x0bb9", (wchar_t)wch) != NULL );
}

int GetIndexInTable(char c, char *table)
{
    int i=0;

    while (table[i] != '\0') {
        if (table[i] == c) break;
        i++;
    }

    return (table[i] == '\0') ? -1 : i;
}

void WStringCopy(WCHAR *dst, const WCHAR *src)
{
    int i=0;

    for (int d=0; d<(int)wcslen(src); d++)
    {
        dst[i++] = src[d];
    }

    dst[i] = '\0';
}

void WStringCat(WCHAR *dst, const WCHAR *src)
{
    int i=wcslen(dst);

    for (int d=0; d<(int)wcslen(src); d++)
    {
        dst[i++] = src[d];
    }

    dst[i] = '\0';
}

void doDebug(char *log)
{
    
    //FILE *f;
    //if ( (f = fopen("\\Users\\muthu\\ime_debug.log", "a")) == NULL )
    //{
    //    MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    //}
    //else
    //{
    //    fprintf(f, "%s", log);
    //    fclose(f);
    //}
    
}

void doDebug1(char *log)
{
    //FILE *f;
    //if ( (f = fopen("\\Users\\muthu\\ime_debug.log", "a")) == NULL )
    //{
    //    MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    //}
    //else
    //{
    //    fprintf(f, "%s", log);
    //    fclose(f);
    //}
}

void doDebugDumpArray(WCHAR *log)
{
    //FILE *f;
    //if ( (f = fopen("c:\\ime_debug.log", "a")) == NULL )
    //{
    //    MessageBox(NULL, "Can't Open File", "TextService", MB_OK);
    //}
    //else
    //{
    //    fprintf(f, "   ");
    //    for ( int i=0; i<(int)wcslen(log); i++)
    //        fprintf(f, "%04X ", log[i]);
    //    fprintf(f, "\n");
    //    fclose(f);
    //}
}

--- End Old Code */
