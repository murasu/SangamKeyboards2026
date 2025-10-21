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

// Adapted for Telugu : 3 Dec 2010

// Modified and incorporated into Sangam (iOS 8): 29 Nov 2014

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>

#include "IndicNotesIMEngine.h"

#define TELUGU_HALANT   0x0C4D

// Lookup tables

// Vowel keystrokes
static UniChar TelUV1Keys[] = {'a','i','u','H','H','H','H','e','a','o','a','q','M','H','Q', 0 };  // first keystroke
static UniChar TelUV2Keys[] = {'a','i','u','r','R','l','L','e','i','o','u','q','M','H','*', 0 };  // second keystroke
static UniChar TelUV3Keys[] = {'*','*','*','*','*','*','*','*','*','*','*','*','M','H','*', 0 };  // third keystroke

// vowel chars
static UniChar TelUV1Char[] = { 0x0C05,0x0C07,0x0C09,0x0C03,0x0C03,0x0C03,0x0C03,0x0C0E,0x0C10,0x0C12,0x0C14,0x0C4D,0x0C02,0x0C03,0x0C01 };  // first keystroke
static UniChar TelUV2Char[] = { 0x0C06,0x0C08,0x0C0A,0x0C0B,0x0C60,0x0C0C,0x0C61,0x0C0F,0x0C10,0x0C13,0x0C14,0x0C00,0x0C00,0x0C03,0x0C00 };  // second keystroke
static UniChar TelUV3Char[] = { 0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C03,0x0C00 };  // third keystroke

// vowel sign chars                                                   
static UniChar TelUVS1Char[]= { 0x0008,0x0C3F,0x0C41,0x0C03,0x0C03,0x0C03,0x0C03,0x0C46,0x0C48,0x0C4A,0x0C4C,0x0C4D,0x0C02,0x0C03,0x0C50 };  // first keystroke
static UniChar TelUVS2Char[]= { 0x0C3E,0x0C40,0x0C42,0x0C43,0x0C44,0x0C62,0x0C63,0x0C47,0x0C48,0x0C4B,0x0C4C,0x0C00,0x0C00,0x0C03,0x0C50 };  // second keystroke
static UniChar TelUVS3Char[]= { 0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C03,0x0C50 };  // third keystroke

// conso keystrokes
static UniChar TelUC1Keys[] = {'k','g','n','c','j','n',  'T','D','N','t','d',  'n','p','b',  'm','y','r','R','l',  'L','z','v','S','s','h', 0 };
static UniChar TelUC2Keys[] = {'h','h','g','h','h','j',  'h','h','*','h','h',  '*','h','h',  '*','*','*','*','*',  '*','*','*','*','h','*', 0 };
static UniChar TelUC3Keys[] = {'*','*','*','*','*','*',  '*','*','*','*','*',  '*','*','*',  '*','*','*','*','*',  '*','*','*','*','*','*', 0 };

// conso chars
static UniChar TelUC1Char[] = { 0x0C15,0x0C17,0x0C28,0x0C1A,0x0C1C,0x0C1E,  0x0C1F,0x0C21,0x0C23,0x0C24,0x0C26,  0x0C28,0x0C2A,0x0C2C,  0x0C2E,0x0C2F,0x0C30,0x0C31,0x0C32,  0x0C33,0x0C34,0x0C35,0x0C36,0x0C38,0x0C39 };

static UniChar TelUC2Char[] = { 0x0C16,0x0C18,0x0C19,0x0C1B,0x0C1D,0x0C1E,  0x0C20,0x0C22,0x0C00,0x0C25,0x0C27,  0x0C00,0x0C2B,0x0C2D,  0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,  0x0C00,0x0C00,0x0C00,0x0C00,0x0C37,0x0C00 }; 

static UniChar TelUC3Char[] = { 0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,  0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,  0x0C00,0x0C00,0x0C00,  0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,  0x0C00,0x0C00,0x0C00,0x0C00,0x0C00,0x0C00 }; 



void  getKeyStringUnicodeTeluguAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	
	// Function to call when a new session needs to be started
	
	int     vpos;
    //int     aTyped = 0;
	
	// Assume no conversions are going to be done
	results->deleteCount = 0;
	results->insertCount = 0;
	results->fixPrevious = false;
	
	//printf("In GKS: currKey = %d('%c'), prevKey = %d, prevKeyType = %d\n", currKey, (char)currKey, results->prevKey, results->prevKeyType);
	/*
	if ( currKey == '#' ) {
		s[0] = 0x0C3D; // avagraha
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
			
			startNewSessionTeluguAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			if ( (vpos = getKeyPos( currKey, TelUV2Keys, results->prevKey, TelUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = TelUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
					results->deleteCount = 1; // delete the prev vowel
                } else {
                    s[0] = TelUVS2Char[vpos]; s[1] = '\0';
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
			
			startNewSessionTeluguAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, TelUV3Keys, results->prevKey, TelUV2Keys, results->firstVowelKey,TelUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = TelUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = TelUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionTeluguAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			// Handle special occurances first
            /*
			if ( results->prevKey == 't' && currKey == 't' ) 
			{
                s[0]=0x0C31; s[1]=0x0C4D; s[2]=0x0C31; s[3]=TELUGU_HALANT; s[4]='\0';
				results->insertCount = 3;
                // delete the prev conso and halant
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			} */
			
			if ( (vpos = getKeyPos( currKey, TelUC2Keys, results->prevKey, TelUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character with a
                // backspace flag
                s[0] = TelUC2Char[vpos]; s[1] = TELUGU_HALANT; s[2] = '\0';
				results->insertCount = 2;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, TelUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = TelUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0'; // nothing happens with akaram.
					results->insertCount = 0;
                    //aTyped = 1;
				}
				// --- delete the auto-inseted halant
                results->deleteCount = 1;
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;  // must break here as there is a default
            }
			
			// Current key is not a second conso or first vowel, start a new session
			startNewSessionTeluguAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
 			if ( (vpos = getKeyPos( currKey, TelUC3Keys, results->prevKey, TelUC2Keys, results->firstConsoKey, TelUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
                s[0] = TelUC3Char[vpos]; s[1] = TELUGU_HALANT; s[2] = '\0';
                results->deleteCount = 2;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, TelUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = TelUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
                    //aTyped = 1;
				}
				
                // --- delete the auto-inserted halant
                results->deleteCount = 1;
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;
				
            }
			
			// Current key is not third conso or first vowel, start a new session
			startNewSessionTeluguAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, TelUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                // (currKey != 'a') { 
				s[0] = TelUVS1Char[vpos]; 
				s[1] = '\0'; 
				results->insertCount = 1;
				//} else {
				//	s[0] = '\0';  // nothing happens with akaram.
				//	results->insertCount = 0;
				//}
				
                //if ( currKey == 'a' ) aTyped = 1;
                
                // --- delete the auto-inserted halant
                results->deleteCount = 1;
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;   // must break as there is a default
				
            }
			
			// currKey is not a vowel, start a new session
			startNewSessionTeluguAnjal(currKey, s, results);
            break;
			
		default :
			
			startNewSessionTeluguAnjal(currKey, s, results);
			break;
	}
	
    //results->aTyped  = aTyped;
	results->prevKey = currKey;
}


void startNewSessionTeluguAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c\n", (char) currKey);
	
	int vpos = -1;
	
	if ( (vpos = getKeyPos(currKey, TelUC1Keys, 0, NULL, 0, 0)) >= 0) {
		 
        int i=0;
        
        // Key is starting a sequence for a conso.
        s[i] = '\0';
        
        /*
        if ( (results->prevKeyType == FIRST_CONSO_KEYTYPE || results->prevKeyType==SECOND_CONSO_KEYTYPE || results->prevKeyType==THIRD_CONSO_KEYTYPE) && results->aTyped == 0) {
            // --- if the current key is a candidate for conjunct formation, send a virama
            //NSString *sechalfs = @"";
            
            //if (vpos < CONSO_MAX && currKey == results->prevKey)
            //    s[i++] = VIRAMA_CHAR;
            s[i++] = 0x0C4D; // Telugu Virama
        }
        */
        
        // add the conso char to s
        s[i++] = TelUC1Char[vpos];
        s[i++] = TELUGU_HALANT;
        s[i] = '\0';
        results->insertCount = i;
        results->prevKeyType = FIRST_CONSO_KEYTYPE;
        results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
        results->firstConsoKey = currKey;
        results->fixPrevious = true; // since this a start of a new composition, fix the previous one
        
        results->deleteCount = 0; // no deleting of previous characters
        
        //results->aTyped = 0;
        
        return;
		 
	 } else if ( (vpos = getKeyPos(currKey, TelUV1Keys, 0, NULL, 0, 0)) >= 0) {
		 
		 // -----------------------------------------------
		 // ((B)) - Implementation of section B in diagram
		 // -----------------------------------------------
		 
		 //printf("Inserting character in TelUV1Char at index %d\n", vpos);
		 
		 s[0] = TelUV1Char[vpos]; s[1] = '\0';
		 
		 results->insertCount = 1;
		 results->prevKeyType = FIRST_VOWEL_KEYTYPE;
		 results->prevCharType = VOWEL_CHARTYPE;
		 results->firstVowelKey = currKey;
		 results->deleteCount = 0; // no deleting of previous characters
		 results->fixPrevious = true; // independant vowels fix previous composition
		 
         //results->aTyped = 0;
         
		 return;
		 
	 } else {
		 
		 results->firstConsoKey = 0;
		 results->prevKeyType =  CHARACTER_END_KEYTYPE;
		 results->prevCharType = NON_INDIC_CHARTYPE;
		 results->deleteCount=0;
		 results->fixPrevious = true;  // non convertable characters fix previous composition
		 
         //results->aTyped = 0;
         
         if ( currKey == 'W' ) {
             s[0] = 0x0C3D; // avagraha
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



