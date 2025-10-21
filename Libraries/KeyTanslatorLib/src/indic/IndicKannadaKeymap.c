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

// Adapted for Kannada : 3 Dec 2010

// Modified and incorporated into Sangam (iOS 8): 29 Nov 2014

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>

#include "IndicNotesIMEngine.h"

#define KANNADA_HALANT  0x0CCD

// Lookup tables

// Vowel keystrokes
static UniChar KanUV1Keys[] = {'a','i','u','H','H','H','H','e','a','o','a','q','M','H', 0 };  // first keystroke
static UniChar KanUV2Keys[] = {'a','i','u','r','R','l','L','e','i','o','u','q','M','H', 0 };  // second keystroke
static UniChar KanUV3Keys[] = {'*','*','*','*','*','*','*','*','*','*','*','*','M','H', 0 };  // third keystroke

// vowel chars
static UniChar KanUV1Char[] = { 0x0C85,0x0C87,0x0C89,0x0C83,0x0C83,0x0C83,0x0C83,0x0C8E,0x0C90,0x0C92,0x0C94,0x0CCD,0x0C82,0x0C83 };  // first keystroke
static UniChar KanUV2Char[] = { 0x0C86,0x0C88,0x0C8A,0x0C8B,0x0CE0,0x0C8C,0x0CE1,0x0C8F,0x0C90,0x0C93,0x0C94,0x0C80,0x0C80,0x0C83 };  // second keystroke
static UniChar KanUV3Char[] = { 0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C83 };  // third keystroke

// vowel sign chars                                                   
static UniChar KanUVS1Char[]= { 0x0008,0x0CBF,0x0CC1,0x0C83,0x0C83,0x0C83,0x0C83,0x0CC6,0x0CC8,0x0CCA,0x0CCC,0x0CCD,0x0C82,0x0C83,0x0CD0 };  // first keystroke
static UniChar KanUVS2Char[]= { 0x0CBE,0x0CC0,0x0CC2,0x0CC3,0x0CC4,0x0CE2,0x0CE3,0x0CC7,0x0CC8,0x0CCB,0x0CCC,0x0C80,0x0C80,0x0C83,0x0CD0 };  // second keystroke
static UniChar KanUVS3Char[]= { 0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C83,0x0CD0 };  // third keystroke

// conso keystrokes
static UniChar KanUC1Keys[] = {'k','g','n','c','j','n',  'T','D','N','t','d',  'n','p','b',  'm','y','r','R','l',  'L','v','S','s','h','f', 0 };
static UniChar KanUC2Keys[] = {'h','h','g','h','h','j',  'h','h','*','h','h',  '*','h','h',  '*','*','*','*','*',  '*','*','*','h','*','*', 0 };
static UniChar KanUC3Keys[] = {'*','*','*','*','*','*',  '*','*','*','*','*',  '*','*','*',  '*','*','*','*','*',  '*','*','*','*','*','*', 0 };

// conso chars
static UniChar KanUC1Char[] = { 0x0C95,0x0C97,0x0CA8,0x0C9A,0x0C9C,0x0C9E,  0x0C9F,0x0CA1,0x0CA3,0x0CA4,0x0CA6,  0x0CA8,0x0CAA,0x0CAC,  0x0CAE,0x0CAF,0x0CB0,0x0CB1,0x0CB2,  0x0CB3,0x0CB5,0x0CB6,0x0CB8,0x0CB9,0x0CDE };

static UniChar KanUC2Char[] = { 0x0C96,0x0C98,0x0C99,0x0C9B,0x0C9D,0x0C9E,  0x0CA0,0x0CA2,0x0C80,0x0CA5,0x0CA7,  0x0C80,0x0CAB,0x0CAD,  0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,  0x0C80,0x0C80,0x0C80,0x0CB7,0x0C80,0x0C80 }; 

static UniChar KanUC3Char[] = { 0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,  0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,  0x0C80,0x0C80,0x0C80,  0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,  0x0C80,0x0C80,0x0C80,0x0C80,0x0C80,0x0C80}; 



void  getKeyStringUnicodeKannadaAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
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
		s[0] = 0x0CBD; // avagraha
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
			
			startNewSessionKannadaAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			if ( (vpos = getKeyPos( currKey, KanUV2Keys, results->prevKey, KanUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = KanUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
					results->deleteCount = 1; // delete the prev vowel
                } else {
                    s[0] = KanUVS2Char[vpos]; s[1] = '\0';
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
			
			startNewSessionKannadaAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, KanUV3Keys, results->prevKey, KanUV2Keys, results->firstVowelKey,KanUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = KanUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = KanUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionKannadaAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			// Handle special occurances first
            /*
			if ( results->prevKey == 't' && currKey == 't' ) 
			{
                s[0]=0x0CB1; s[1]=0x0CCD; s[2]=0x0CB1; s[3]=KANNADA_HALANT; s[4]='\0';
                results->insertCount = 4;//3;
                // delete the prev conso + halant
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			} */
			
			if ( (vpos = getKeyPos( currKey, KanUC2Keys, results->prevKey, KanUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character with a
                // backspace flag
                s[0] = KanUC2Char[vpos]; s[1] = KANNADA_HALANT; s[2] = '\0';
				results->insertCount = 1;
                // delete the prev conso + halant
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, KanUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = KanUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0';
					results->insertCount = 0;
                    //aTyped      = 1;
				}
				// Delete the halant that was automatically sent
                results->deleteCount = 1;
                
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;  // must break here as there is a default
            }
			
			// Current key is not a second conso or first vowel, start a new session
			startNewSessionKannadaAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
 			if ( (vpos = getKeyPos( currKey, KanUC3Keys, results->prevKey, KanUC2Keys, results->firstConsoKey, KanUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
                s[0] = KanUC3Char[vpos]; s[1] = KANNADA_HALANT; s[2] = '\0';
                results->deleteCount = 1;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, KanUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = KanUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
                    //aTyped      = 1;
				}
				
                // Delete the halant that was automatically sent
                results->deleteCount = 1;

                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;
				
            }
			
			// Current key is not third conso or first vowel, start a new session
			startNewSessionKannadaAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, KanUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                // (currKey != 'a') { 
				s[0] = KanUVS1Char[vpos]; 
				s[1] = '\0'; 
				results->insertCount = 1;
				//} else {
				//	s[0] = '\0';  // nothing happens with akaram.
				//	results->insertCount = 0;
				//}
                
                //if ( currKey=='a' ) aTyped = 1;
				
                // Delete the halant that was automatically sent
                results->deleteCount = 1;

                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;   // must break as there is a default
				
            }
			
			// currKey is not a vowel, start a new session
			startNewSessionKannadaAnjal(currKey, s, results);
            break;
			
		default :
			
			startNewSessionKannadaAnjal(currKey, s, results);
			break;
	}
	
    //results->aTyped  = aTyped;
	results->prevKey = currKey;
}


void startNewSessionKannadaAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c\n", (char) currKey);
	
	int vpos = -1;
	
	if ( (vpos = getKeyPos(currKey, KanUC1Keys, 0, NULL, 0, 0)) >= 0) {
		
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
            s[i++] = 0x0CCD; // Kannada Virama
        }
        */
        
		// add the conso char to s
		s[i++] = KanUC1Char[vpos];
        s[i++] = KANNADA_HALANT;
		s[i] = '\0';
		results->insertCount = i;
		results->prevKeyType = FIRST_CONSO_KEYTYPE;
		results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
		results->firstConsoKey = currKey;
		results->fixPrevious = true; // since this a start of a new composition, fix the previous one
		
		results->deleteCount = 0; // no deleting of previous characters
        //results->aTyped      = 0;

		return;
		
	} else if ( (vpos = getKeyPos(currKey, KanUV1Keys, 0, NULL, 0, 0)) >= 0) {
		
		// -----------------------------------------------
		// ((B)) - Implementation of section B in diagram
		// -----------------------------------------------
		
		//printf("Inserting character in KanUV1Char at index %d\n", vpos);
		
		s[0] = KanUV1Char[vpos]; s[1] = '\0';
		
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

        if ( currKey == 'V' )
        {
            s[0] = 0x0CBD; // avagraha
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



