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

// Ported to iOS for Sellinam : June 2010
// Adapted for Devanagari (IndicNotes) : Sept 2010

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>

#include "IndicNotesIMEngine.h"


// Lookup tables

// Vowel keystrokes
static UniChar DevaUV1Keys[] = { 'a','i','u','e','a','o','a',  'R','L','A','I','U',  'M','H','q','Q','O','E', 0 };  // first keystroke
static UniChar DevaUV2Keys[] = { 'a','i','u','e','i','o','u',  'r','l','*','*','*',  '*','*','q','*','M','*', 0 };  // second keystroke
static UniChar DevaUV3Keys[] = { '*','*','*','e','*','o','*',  '*','*','*','*','*',  '*','*','q','*','*','*', 0 };  // third keystroke

// vowel chars
static UniChar DevaUV1Char[] = { 0x0905,0x0907,0x0909,0x090F,0x0905,0x0913,0x0905, 0x090B,0x090C,0x0906,0x0908,0x090A, 0x0902,0x0903,0x094D,0x0901,0x0912,0x090E };  // first keystroke
static UniChar DevaUV2Char[] = { 0x0906,0x0908,0x090A,0x090D,0x0910,0x0911,0x0914, 0x0960,0x0961,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x093C,0x0B00,0x0950,0x0B00 };  // second keystroke
static UniChar DevaUV3Char[] = { 0x0B00,0x0B00,0x0B00,0x090E,0x0B00,0x0912,0x0B00, 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0901,0x0B00,0x0B00,0x0B00 };  // third keystroke

// vowel sign chars                                                   
static UniChar DevaUVS1Char[]= { 0x0008,0x093F,0x0941,0x0947,0x0008,0x094B,0x0008, 0x0943,0x0962,0x093E,0x0940,0x0942, 0x0902,0x0903,0x094D,0x0901,0x094A,0x0946 };  // first keystroke
static UniChar DevaUVS2Char[]= { 0x093E,0x0940,0x0942,0x0945,0x0948,0x0949,0x094C, 0x0944,0x0963,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x093C,0x0B00,0x0950,0x0B00 };  // second keystroke
static UniChar DevaUVS3Char[]= { 0x0B00,0x0B00,0x0B00,0x0946,0x0B00,0x094A,0x0B00, 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0901,0x0B00,0x0B00,0x0B00 };  // third keystroke

// conso keystrokes
static UniChar DevaUC1Keys[] = { 'k','g','n','c','j','T','D','n','N',  't','d','n','p','b','m','y','r',  'l','z','v','s','S','h',  0 };
static UniChar DevaUC2Keys[] = { 'h','h','g','h','h','h','h','y','*',  'h','h','n','h','h','*','*','r',  'l','h','*','h','*','*',  0 };
static UniChar DevaUC3Keys[] = { '*','*','*','*','*','*','*','*','*',  '*','*','*','*','*','*','*','*',  'l','*','*','*','*','*',  0 };

// conso chars
static UniChar DevaUC1Char[] = { 0x0915,0x0917,0x0928,0x091A,0x091C,0x091F,0x0921,0x0928,0x0923,  0x0924,0x0926,0x0928,0x092A,0x092C,0x092E,0x092F,0x0930,  0x0932,0x0936,0x0935,0x0938,0x0937,0x0939, 0};
static UniChar DevaUC2Char[] = { 0x0916,0x0918,0x0919,0x091B,0x091D,0x0920,0x0922,0x091E,0x0B00,  0x0925,0x0927,0x0929,0x092B,0x092D,0x0B00,0x0B00,0x0931,  0x0933,0x0934,0x0B00,0x0936,0x0B00,0x0B00, 0}; 
static UniChar DevaUC3Char[] = { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,  0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,  0x0934,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0}; 

// numeric keystrokes
static UniChar DevaUNKeys[] = {'0','1','2','3','4','5','6','7','8','9'};
static UniChar DevaUNChar[] = {0x0966,0x0967,0x0968,0x0969,0x096A,0x096B,0x096C,0x096D,0x096E,0x096F};

static UniChar DevaUNuktaBase[] = {0x0915,0x0916,0x0917,0x091C,0x0921,0x0922,0x092B,0x092F}; // base chars whose nukta forms are encoded
static UniChar DevaUNuktaForm[] = {0x0958,0x0959,0x095A,0x095B,0x095C,0x095D,0x095E,0x095F}; // corresponding nukta forms

void  getKeyStringUnicodeDevanagariAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results)
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
		s[0] = DevaUNChar[currKey-'0'];
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;
	}
	else if ( currKey == '|' ) {
		s[0] = results->prevKey == '|' ? 0x0965 : 0x0964; // (double) danda
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = results->prevKey == '|' ? 1 : 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;		
	}
	else if ( currKey == '#' ) {
		s[0] = 0x093D; // avagraha
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;		
	}
	
	switch (results->prevKeyType) {
		case (CHARACTER_END_KEYTYPE) :
			
			// The prev unicode character has been composed. Start a new session
			
			startNewSessionDevanagariAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			// --- qq is nukta. if the currentBaseChar has an encoded nukta form, send that char
			if ( currKey == 'q' && results->prevKey == 'q' ) {
				//// Debug: Nukta entered. Current base char: %C
				vpos = getKeyPos(results->currentBaseChar, DevaUNuktaBase, 0, 0, 0, 0);
				if ( vpos >= 0 ) {
					results->currentBaseChar = DevaUNuktaForm[vpos];
					s[0] = results->currentBaseChar;
					s[1] = '\0';
					results->insertCount = 1;
					results->prevKeyType = SECOND_VOWEL_KEYTYPE;
					results->deleteCount = 2; // the first q would have sent a virama, delete that as well
					break;
				}
			}
			
			if ( (vpos = getKeyPos( currKey, DevaUV2Keys, results->prevKey, DevaUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = DevaUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
                } else {
                    s[0] = DevaUVS2Char[vpos]; s[1] = '\0';
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
			
			startNewSessionDevanagariAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, DevaUV3Keys, results->prevKey, DevaUV2Keys, results->firstVowelKey,DevaUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = DevaUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = DevaUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionDevanagariAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			if ( (vpos = getKeyPos( currKey, DevaUC2Keys, results->prevKey, DevaUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character with a
                // backspace flag
				results->currentBaseChar = DevaUC2Char[vpos];
				s[0] =  results->currentBaseChar;
				s[1] = '\0';
				results->insertCount = 1;
                // delete the prev conso
                results->deleteCount = 1;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, DevaUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = DevaUVS1Char[vpos]; 
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
			startNewSessionDevanagariAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. Check for special sequences first.
			// If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
			if ( (vpos = getKeyPos( currKey, DevaUC3Keys, results->prevKey, DevaUC2Keys, results->firstConsoKey, DevaUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
				results->currentBaseChar = DevaUC3Char[vpos];
				s[0] = results->currentBaseChar; 
				s[1]='\0';
                results->deleteCount = 1;
				results->insertCount = 1;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, DevaUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = DevaUVS1Char[vpos]; 
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
			startNewSessionDevanagariAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, DevaUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = DevaUVS1Char[vpos]; 
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
			startNewSessionDevanagariAnjal(currKey, s, results);
            break;
			
		default :
			startNewSessionDevanagariAnjal(currKey, s, results);
			break;
	}
	
	results->prevKey = currKey;
}


void startNewSessionDevanagariAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c\n", (char) currKey);
	
	int vpos = -1;
	
	
    // check if key is a consonant or a vowel or an out-of-matrix key
	if ( (vpos = getKeyPos(currKey, DevaUC1Keys, 0, NULL, 0, 0)) >= 0) {
		
        int i=0;
		
		// Key is starting a sequence for a conso.
        s[i] = '\0';
		
		results->currentBaseChar = DevaUC1Char[vpos];
		s[i++] = results->currentBaseChar;  // add the conso char to s
		
        s[i] = '\0';
		results->insertCount = i;
		results->prevKeyType = FIRST_CONSO_KEYTYPE;
        results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
        results->firstConsoKey = currKey;
		results->fixPrevious = true; // since this a start of a new composition, fix the previous one
		
        results->deleteCount = 0; // no deleting of previous characters
		
		// --- I'm using a place holder char 0x0B01 for X
		//if ( s[0] == 0x0B01 )
		//{
		//	s[0]=0x0B95; s[1]=0x0BCD; s[2]=0x0BB7; s[3]=0x0BCD; s[4]='\0';
		//	results->insertCount = 4;
		//}
		
		return;
		
	} else if ( (vpos = getKeyPos(currKey, DevaUV1Keys, 0, NULL, 0, 0)) >= 0) {
		
        s[0] = DevaUV1Char[vpos]; s[1] = '\0';
		
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


