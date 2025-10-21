/* keyboard driver for M5 	*/
/* Written by M. N. Muthu 	*/
/* (C) 1992, M. N. Muthu  	*/
/* Date : 27 October 1992 	*/
/* Modified for Windows  3.1	*/
/* 	on : 24 Jan 1993	*/
// Modified for M6 : Feb 1995
// Ported to 32bit (Anjal 2.0) : 31 Dec 1997
// Modified to process keystrokes independant of charset
//   and to support Unicode (doublebyte characters)
//   for Anjal2000 - 23 Sept 1999
// Modified for Anjal Indic Keyboard
//   to support Unicode only Indic scripts - 1 Feb 2001

// Ported to MacOS 13 Jan 2003
// Adapted for Malayalam Sept 6, 2006

// Ported to iOS for Sellinam : 18 June 2010
// Adapted for Devanagari (IndicNotes) : 10 Sept 2010

// Modified for Gurmukhi : 26 Sept 2010


#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>

#include "IndicNotesIMEngine.h"


// Lookup tables

// Vowel keystrokes
static UniChar GrmkUV1Keys[] = { 'a','i','u','e','a','o','a',  'x','M','H','q','Q','o','a', 0 };  // first keystroke
static UniChar GrmkUV2Keys[] = { 'a','i','u','*','i','*','u',  '*','m','*','q','q','n','d', 0 };  // second keystroke
static UniChar GrmkUV3Keys[] = { '*','*','*','*','*','*','*',  '*','*','*','q','*','k','*', 0 };  // third keystroke

// vowel chars
static UniChar GrmkUV1Char[] = { 0x0A05,0x0A07,0x0A09,0x0A0F,0x0A05,0x0A13,0x0A05, 0x0A71,0x0A02,0x0A03,0x0A4D,0x0A01,0x0A13,0x0A05 };  // first keystroke
static UniChar GrmkUV2Char[] = { 0x0A06,0x0A08,0x0A0A,0x0B00,0x0A10,0x0B00,0x0A14, 0x0B00,0x0A70,0x0B00,0x0A3C,0x0A51,0x0A74,0x262C };  // second keystroke
static UniChar GrmkUV3Char[] = { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0B00,0x0A51,0x0B00,0x0A74,0x262C };  // third keystroke

// vowel sign chars                                                   
static UniChar GrmkUVS1Char[]= { 0x0008,0x0A3F,0x0A41,0x0A47,0x0008,0x0A4B,0x0008, 0x0A71,0x0A02,0x0A03,0x0A4D,0x0A01,0x0A4B,0x0008 };  // first keystroke
static UniChar GrmkUVS2Char[]= { 0x0A3E,0x0A40,0x0A42,0x0B00,0x0A48,0x0B00,0x0A4C, 0x0B00,0x0A70,0x0B00,0x0A3C,0x0A51,0x0A74,0x262C };  // second keystroke
static UniChar GrmkUVS3Char[]= { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0B00,0x0A51,0x0B00,0x0A74,0x262C };  // third keystroke

// conso keystrokes
static UniChar GrmkUC1Keys[] = { 'k','g','n','c','j','T','D','n','N',  't','d','n','p','b','m','y','r',  'l','L','v','s','h',  'K','G','z','R','f','Y', 0 };
static UniChar GrmkUC2Keys[] = { 'h','h','g','h','h','h','h','y','*',  'h','h','*','h','h','*','*','*',  '*','*','*','h','*',  '*','*','*','*','*','*', 0 };
static UniChar GrmkUC3Keys[] = { '*','*','*','*','*','*','*','*','*',  '*','*','*','*','*','*','*','*',  '*','*','*','*','*',  '*','*','*','*','*','*', 0 };

// conso chars
static UniChar GrmkUC1Char[] = { 0x0A15,0x0A17,0x0A28,0x0A1A,0x0A1C,0x0A1F,0x0A21,0x0A28,0x0A23,  0x0A24,0x0A26,0x0A28,0x0A2A,0x0A2C,0x0A2E,0x0A2F,0x0A30,  0x0A32,0x0A33,0x0A35,0x0A38,0x0A39,  0x0A59,0x0A5A,0x0A5B,0x0A5C,0x0A5E,0x0A75, 0};
static UniChar GrmkUC2Char[] = { 0x0A16,0x0A18,0x0A19,0x0A1B,0x0A1D,0x0A20,0x0A22,0x0A1E,0x0B00,  0x0A25,0x0A27,0x0B00,0x0A2B,0x0A2D,0x0B00,0x0B00,0x0B00,  0x0B00,0x0B00,0x0B00,0x0A36,0x0B00,  0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0}; 
static UniChar GrmkUC3Char[] = { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,  0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,  0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,  0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0}; 

// numeric keystrokes
static UniChar GrmkUNKeys[] = {'0','1','2','3','4','5','6','7','8','9'};
static UniChar GrmkUNChar[] = {0x0A66,0x0A67,0x0A68,0x0A69,0x0A6A,0x0A6B,0x0A6C,0x0A6D,0x0A6E,0x0A6F};

static UniChar GrmkUNuktaBase[] = {0x0915,0x0916,0x0917,0x091C,0x0921,0x0922,0x092B,0x092F}; // base chars whose nukta forms are encoded
static UniChar GrmkUNuktaForm[] = {0x0958,0x0959,0x095A,0x095B,0x095C,0x095D,0x095E,0x095F}; // corresponding nukta forms

void  getKeyStringUnicodeGurmukhiAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results)
{
	// Function to call when a new session needs to be started
	
	int     vpos;
	
	// Assume no conversions are going to be done
	results->deleteCount = 0;
	results->insertCount = 0;
	results->fixPrevious = false;
	
	//printf("In GKS: currKey = %d('%c'), prevKey = %d, prevKeyType = %d\n", currKey, (char)currKey, results->prevKey, results->prevKeyType);
	//// Debug: In GKS: currKey = %d('%c'), prevKey = %d('%c'), prevKeyType = %d, firstConsoKey = %c\n
	
	if ( isdigit((int)currKey) ) {
		s[0] = GrmkUNChar[currKey-'0'];
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;
	}
	else if ( currKey == '|' ) {
		s[0] = results->prevKey == '|' ? 0x0A65 : 0x0A64; // (double) danda
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = results->prevKey == '|' ? 1 : 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;		
	}

	
	switch (results->prevKeyType) {
		case (CHARACTER_END_KEYTYPE) :
			
			// The prev unicode character has been composed. Start a new session
			
			startNewSessionGurmukhiAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			// --- qq is nukta. if the currentBaseChar has an encoded nukta form, send that char
			if ( currKey == 'q' && results->prevKey == 'q' ) {
				//// Debug: Nukta entered. Current base char: %C
				vpos = getKeyPos(results->currentBaseChar, GrmkUNuktaBase, 0, 0, 0, 0);
				if ( vpos >= 0 ) {
					results->currentBaseChar = GrmkUNuktaForm[vpos];
					s[0] = results->currentBaseChar;
					s[1] = '\0';
					results->insertCount = 1;
					results->prevKeyType = SECOND_VOWEL_KEYTYPE;
					results->deleteCount = 2; // the first q would have sent a virama, delete that as well
					break;
				}
			}
			
			if ( (vpos = getKeyPos( currKey, GrmkUV2Keys, results->prevKey, GrmkUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = GrmkUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
                } else {
                    s[0] = GrmkUVS2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWELSIGN_KEYTYPE;
                }
                results->deleteCount = 1; // delete the prev vowel
                //------- 'a' does not have a vowelsign
                if ( currKey == 'a' && results->prevKeyType == SECOND_VOWELSIGN_KEYTYPE)
                    results->deleteCount = 0;
				else if ( results->prevKey == 'a' && (currKey=='i' || currKey=='u') && results->prevKeyType == SECOND_VOWELSIGN_KEYTYPE)
					results->deleteCount = 0;
                //---------------
				
				break;
            } 
		    
			// This key is not a second vowel, start a new session
			
			startNewSessionGurmukhiAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, GrmkUV3Keys, results->prevKey, GrmkUV2Keys, results->firstVowelKey,GrmkUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = GrmkUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = GrmkUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionGurmukhiAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			if ( (vpos = getKeyPos( currKey, GrmkUC2Keys, results->prevKey, GrmkUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character with a
                // backspace flag
				results->currentBaseChar = GrmkUC2Char[vpos];
				s[0] =  results->currentBaseChar;
				s[1] = '\0';
				results->insertCount = 1;
                // delete the prev conso
                results->deleteCount = 1;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, GrmkUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = GrmkUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
					//results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0'; // nothing happens with akaram.
					results->insertCount = 0;
					//results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;  // must break here as there is a default
            }
			
			// Current key is not a second conso or first vowel, start a new session
			startNewSessionGurmukhiAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. Check for special sequences first.
			// If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
			if ( (vpos = getKeyPos( currKey, GrmkUC3Keys, results->prevKey, GrmkUC2Keys, results->firstConsoKey, GrmkUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
				results->currentBaseChar = GrmkUC3Char[vpos];
				s[0] = results->currentBaseChar; 
				s[1]='\0';
                results->deleteCount = 1;
				results->insertCount = 1;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, GrmkUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = GrmkUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
					//results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
					//results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;
				
            }
			
			// Current key is not third conso or first vowel, start a new session
			startNewSessionGurmukhiAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, GrmkUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = GrmkUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				    //results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
					//results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;   // must break as there is a default
				
            }
			
			// currKey is not a vowel, start a new session
			startNewSessionGurmukhiAnjal(currKey, s, results);
            break;
			
		default :
			startNewSessionGurmukhiAnjal(currKey, s, results);
			break;
	}
	
	results->prevKey = currKey;
}


void startNewSessionGurmukhiAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c\n", (char) currKey);
	
	int vpos = -1;
	
	
    // check if key is a consonant or a vowel or an out-of-matrix key
	if ( (vpos = getKeyPos(currKey, GrmkUC1Keys, 0, NULL, 0, 0)) >= 0) {
		
        int i=0;
		
		// Key is starting a sequence for a conso.
        s[i] = '\0';
		
		results->currentBaseChar = GrmkUC1Char[vpos];
		s[i++] = results->currentBaseChar;  // add the conso char to s
		
        s[i] = '\0';
		results->insertCount = i;
		results->prevKeyType = FIRST_CONSO_KEYTYPE;
        results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
        results->firstConsoKey = currKey;
		results->fixPrevious = true; // since this a start of a new composition, fix the previous one
		
        results->deleteCount = 0; // no deleting of previous characters
		
		return;
		
	} else if ( (vpos = getKeyPos(currKey, GrmkUV1Keys, 0, NULL, 0, 0)) >= 0) {
		
        s[0] = GrmkUV1Char[vpos]; s[1] = '\0';
		
		results->insertCount = 1;
        results->prevKeyType = FIRST_VOWEL_KEYTYPE;
        results->prevCharType = VOWEL_CHARTYPE;
        results->firstVowelKey = currKey;
        results->deleteCount = 0; // no deleting of previous characters
		results->fixPrevious = true; // independant vowels fix previous composition
		results->currentBaseChar = '\0'; // since we are starting a vowel 
		return;
		
	} else {
		
		clearResults(results);
		
		results->firstConsoKey = 0;
		results->prevKeyType =  CHARACTER_END_KEYTYPE;
		results->prevCharType = NON_INDIC_CHARTYPE;
		results->deleteCount=0;
		results->fixPrevious = true;  // non convertable characters fix previous composition
		results->prevKey = currKey;
		
		if ( isalpha(currKey) )
		{
			// Don't send Roman alphabets while in Indic mode
			results->insertCount = 0;
		} else {
			s[0] = currKey;
			s[1] = 0;
			results->insertCount = 1;
			if ( isspace(currKey) )
				results->prevKeyType = WHITE_SPACE_KEYTYPE;
		}
		return;
	}
}


