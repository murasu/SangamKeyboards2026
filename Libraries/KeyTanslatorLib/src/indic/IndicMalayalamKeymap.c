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

// Modified and incorporated into IndicNotes (iOS4): Sept 2010

// Modified and incorporated into Sangam (iOS 8): 29 Nov 2014

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>

#include "IndicNotesIMEngine.h"

#define MAL_CHANDRA 0x0D4D

// Lookup tables

// Vowel keystrokes
static UniChar MalUV1Keys[] = {'a','i','u','H','H','H','H','e','a','o','a','q','M','H', 0};  // first keystroke
static UniChar MalUV2Keys[] = {'a','i','u','r','R','l','L','e','i','o','u','q','M','H', 0 };  // second keystroke
static UniChar MalUV3Keys[] = {'*','*','*','*','*','*','*','*','*','*','*','*','M','H', 0 };  // third keystroke

// vowel chars
static UniChar MalUV1Char[] = { 0x0D05,0x0D07,0x0D09,0x0D03,0x0D03,0x0D03,0x0D03,0x0D0E,0x0D10,0x0D12,0x0D14,0x0D4D,0x0D02,0x0D03,0x0D50 };  // first keystroke
static UniChar MalUV2Char[] = { 0x0D06,0x0D08,0x0D0A,0x0D0B,0x0D60,0x0D0C,0x0D61,0x0D0F,0x0D10,0x0D13,0x0D14,0x0D00,0x0D00,0x0D03,0x0D50 };  // second keystroke
static UniChar MalUV3Char[] = { 0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D03,0x0D50 };  // third keystroke

// vowel sign chars                                                   
static UniChar MalUVS1Char[]= { 0x0008,0x0D3F,0x0D41,0x0D03,0x0D03,0x0D03,0x0D03,0x0D46,0x0D48,0x0D4A,0x0D4C,0x0D4D,0x0D02,0x0D03,0x0D50 };  // first keystroke
static UniChar MalUVS2Char[]= { 0x0D3E,0x0D40,0x0D42,0x0D43,0x0D44,0x0D62,0x0D63,0x0D47,0x0D48,0x0D4B,0x0D4C,0x0D00,0x0D00,0x0D03,0x0D50 };  // second keystroke
static UniChar MalUVS3Char[]= { 0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D03,0x0D50 };  // third keystroke

// conso keystrokes
static UniChar MalUC1Keys[] = {'k','g','n','c','j','n',  'T','D','N','t','d',  'n','p','b',  'm','y','r','R','l',  'L','z','v','S','s','h',  'N','n','R','r','l','L','k', 0 };
static UniChar MalUC2Keys[] = {'h','h','g','h','h','j',  'h','h','*','h','h',  '*','h','h',  '*','*','*','*','*',  '*','*','*','*','h','*',  'w','w','w','w','w','w','w', 0 };
static UniChar MalUC3Keys[] = {'*','*','*','*','*','*',  '*','*','*','*','*',  '*','*','*',  '*','*','*','*','*',  '*','*','*','*','*','*',  '*','*','*','*','*','*','*', 0 };

// conso chars
static UniChar MalUC1Char[] = { 0x0D15,0x0D17,0x0D28,0x0D1A,0x0D1C,0x0D1E,  0x0D1F,0x0D21,0x0D23,0x0D24,0x0D26,  0x0D28,0x0D2A,0x0D2C,  0x0D2E,0x0D2F,0x0D30,0x0D31,0x0D32,  0x0D33,0x0D34,0x0D35,0x0D36,0x0D38,0x0D39,  0x0D7A,0x0D7B,0x0D7C,0x0D7C,0x0D7D,0x0D7E,0x0D7F};

static UniChar MalUC2Char[] = { 0x0D16,0x0D18,0x0D19,0x0D1B,0x0D1D,0x0D1E,  0x0D20,0x0D22,0x0D00,0x0D25,0x0D27,  0x0D00,0x0D2B,0x0D2D,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D37,0x0D00,  0x0D7A,0x0D7B,0x0D7C,0x0D7C,0x0D7D,0x0D7E,0x0D7F};

static UniChar MalUC3Char[] = { 0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,  0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00,0x0D00}; 



void  getKeyStringUnicodeMalayalamAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	
	// Function to call when a new session needs to be started
	
	int     vpos;
    //int     aTyped = 0; // assume no Vowel 'A'  was typed
	
	// Assume no conversions are going to be done
	results->deleteCount = 0;
	results->insertCount = 0;
	results->fixPrevious = false;

	//printf("In GKS: currKey = %d('%c'), prevKey = %d, prevKeyType = %d\n", currKey, (char)currKey, results->prevKey, results->prevKeyType);
	/*
	if ( currKey == '#' ) {
		s[0] = 0x0D3D; // avagraha
		s[1] = '\0';
		results->insertCount = 1;
		results->deleteCount = 0;
		results->prevKeyType = NON_INDIC_CHARTYPE;
		results->prevKey = currKey;
		results->currentBaseChar = 0;
		return;
	} */

	switch (results->prevKeyType) {
		case (CHARACTER_END_KEYTYPE) :
			
			// The prev unicode character has been composed. Start a new session
			
			startNewSessionMalayalamAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			if ( (vpos = getKeyPos( currKey, MalUV2Keys, results->prevKey, MalUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = MalUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
					results->deleteCount = 1; // delete the prev vowel
                } else {
                    s[0] = MalUVS2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWELSIGN_KEYTYPE;
					results->deleteCount = (results->prevKey=='a') ? 0 : 1; // delete the prev vowel sign, but not for aa
                }
                //---------------
                //if ( currKey == 'a' && results->prevKeyType == SECOND_VOWELSIGN_KEYTYPE)
                //    results->deleteCount = 0;
				
                //---------------
				
				break;
            } 
		    
			// This key is not a second vowel, start a new session
			
			startNewSessionMalayalamAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, MalUV3Keys, results->prevKey, MalUV2Keys, results->firstVowelKey,MalUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = MalUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = MalUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionMalayalamAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			// Handle special occurances first
   
			if ( results->prevKey == 'r' && currKey == 'r' )
			{
                s[0]=0x0D31; s[1]=0x0D4D; s[2]=0x0D31; s[3]=MAL_CHANDRA; s[4]='\0';
				results->insertCount = 4;
                // delete the prev conso
                results->deleteCount = 2; // the prev consonant+chandrakala
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			}
			
			if ( (vpos = getKeyPos( currKey, MalUC2Keys, results->prevKey, MalUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character
                if ( currKey == 'w' ) {
                    // this is a chillu, do not append chandrakala
                    s[0] = MalUC2Char[vpos]; s[1] = '\0';
                    results->insertCount = 1;
                }
                else {
                    s[0] = MalUC2Char[vpos]; s[1] = MAL_CHANDRA; s[2] = '\0';
                    results->insertCount = 2;
                }
                // delete the prev conso+chandrakala
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, MalUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = MalUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0'; // nothing happens with akaram.
					results->insertCount = 0;
                    //aTyped = 1;
				}
				
                // delete the chandrakala that was automatically sent
                results->deleteCount = 1;
                
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;  // must break here as there is a default
            }
			
			// Current key is not a second conso or first vowel, start a new session
			startNewSessionMalayalamAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
 			if ( (vpos = getKeyPos( currKey, MalUC3Keys, results->prevKey, MalUC2Keys, results->firstConsoKey, MalUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
                s[0] = MalUC3Char[vpos]; s[1] = MAL_CHANDRA; s[2] = '\0';
                results->insertCount = 2;
                // delete the prev conso+chandrakala
                results->deleteCount = 2;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, MalUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = MalUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
                    //aTyped = 1;
				}
				
                // delete the chandrakala that was automatically sent
                results->deleteCount = 1;
                
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;
				
            }
			
			// Current key is not third conso or first vowel, start a new session
			startNewSessionMalayalamAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, MalUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                // (currKey != 'a') { 
				s[0] = MalUVS1Char[vpos]; 
				s[1] = '\0'; 
				results->insertCount = 1;
				//} else {
				//	s[0] = '\0';  // nothing happens with akaram.
				//	results->insertCount = 0;
				//}
                //if (currKey == 'a') aTyped = 1;
                
                // delete the chandrakala that was automatically sent
                results->deleteCount = 1;
                
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;   // must break as there is a default
				
            }
			
			// currKey is not a vowel, start a new session
			startNewSessionMalayalamAnjal(currKey, s, results);
            break;
			
		default :
			
			startNewSessionMalayalamAnjal(currKey, s, results);
			break;
	}
	
    //results->aTyped     = aTyped;
	results->prevKey    = currKey;
}


void startNewSessionMalayalamAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c. Current base char %C\n", (char) currKey, results->currentBaseChar);
	
	int vpos = -1;
	
	// Q is used to convert base characters into Chillu form (Malayalam only)
	//  -- only 5 are relevant. TODO: Don't process this for irrelevant base chars
	/*if ( currKey == 'Q' && getKeyPos(results->prevKey, ChilluBaseKeys, 0, NULL, 0, 0) >= 0 )
    {
        s[0] = 0x0D4D;  // Chandra
        s[1] = 0x200D;  // } ZWJ
		s[2] = 0;
		
        results->insertCount = 2;
		results->firstConsoKey = 0;
	    results->prevKeyType =  CHARACTER_END_KEYTYPE;
        results->prevCharType = NON_INDIC_CHARTYPE;
		results->fixPrevious = true;
		results->deleteCount = 0;
	    return;
    }
	
    // check if key is a consonant or a vowel or an out-of-matrix key
	else*/ if ( (vpos = getKeyPos(currKey, MalUC1Keys, 0, NULL, 0, 0)) >= 0) {
		
        int i=0;
		
		// Key is starting a sequence for a conso.
        s[i] = '\0';
		
        
        
        
        // if prevKeyType is also a conso, send a halant (=virama) first
/*
        if ( (results->prevKeyType == FIRST_CONSO_KEYTYPE || results->prevKeyType==SECOND_CONSO_KEYTYPE || results->prevKeyType==THIRD_CONSO_KEYTYPE) && results->aTyped == 0) {
            // --- if the current key is a candidate for conjunct formation, send a virama
            //NSString *sechalfs = @"";
            
            //if (vpos < CONSO_MAX && currKey == results->prevKey)
            //    s[i++] = VIRAMA_CHAR;
            s[i++] = 0x0D4D; // Malayalam Virama
        }
*/
        
        
        
		
		//printf("Inserting character in MalUC1Char at index %d\n", vpos);
		
        // add the conso char to s
        s[i++] = MalUC1Char[vpos];
        s[i++] = MAL_CHANDRA;
        s[i] = '\0';
		results->insertCount = i;
		results->prevKeyType = FIRST_CONSO_KEYTYPE;
        results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
        results->firstConsoKey = currKey;
		results->fixPrevious = true; // since this a start of a new composition, fix the previous one
		
        results->deleteCount = 0; // no deleting of previous characters
        //results->aTyped      = 0;
        
		return;
		
	} else if ( (vpos = getKeyPos(currKey, MalUV1Keys, 0, NULL, 0, 0)) >= 0) {
		
        // -----------------------------------------------
        // ((B)) - Implementation of section B in diagram
        // -----------------------------------------------
		
		//printf("Inserting character in MalUV1Char at index %d\n", vpos);
		
        s[0] = MalUV1Char[vpos]; s[1] = '\0';
		
		results->insertCount = 1;
        results->prevKeyType = FIRST_VOWEL_KEYTYPE;
        results->prevCharType = VOWEL_CHARTYPE;
        results->firstVowelKey = currKey;
        results->deleteCount = 0; // no deleting of previous characters
		results->fixPrevious = true; // independant vowels fix previous composition
        //results->aTyped      = 0;

		return;
		
	} else {
		
		results->firstConsoKey = 0;
		results->prevKeyType =  CHARACTER_END_KEYTYPE;
		results->prevCharType = NON_INDIC_CHARTYPE;
		results->deleteCount=0;
		results->fixPrevious = true;  // non convertable characters fix previous composition
        //results->aTyped      = 0;

        if ( currKey == 'W' ) {
            s[0] = 0x0D3D; // avagraha
            s[1] = 0;
            results->insertCount = 1;
        }
		else if ( isalpha(currKey) )
		{
			// Don't send Roman alphabets while in Indic mode
			results->insertCount = 0;
		} else {
			s[0] = currKey;
			s[1] = 0;
			results->insertCount = 1;
		}
		return;
	}
}



