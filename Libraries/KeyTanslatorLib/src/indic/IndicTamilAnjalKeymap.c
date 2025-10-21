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

// Modified and incorporated into Sangam (iOS 8): 29 Nov 2014

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include <stdio.h>
#include <string.h>
//#pragma hdrstop

#include "IndicNotesIMEngine.h"
#include "EncodingTamil.h"


// Lookup tables

// Vowel keystrokes
static UniChar AnjalUV1Keys[] = {'a','i','u','e','a','o','a','q','A','I','U','E','O', 0 };  // first keystroke
static UniChar AnjalUV2Keys[] = {'a','i','u','e','i','o','u','q','*','*','*','*','M', 0 };  // second keystroke
static UniChar AnjalUV3Keys[] = {'*','*','*','*','*','*','*','*','*','*','*','*','*', 0 };  // third keystroke

// vowel chars
static UniChar AnjalUV1Char[] = { 0x0B85,0x0B87,0x0B89,0x0B8E,0x0B90,0x0B92,0x0B94,0x0B83,0x0B86,0x0B88,0x0B8A,0x0B8F,0x0B93 };  // first keystroke
static UniChar AnjalUV2Char[] = { 0x0B86,0x0B88,0x0B8A,0x0B8F,0x0B90,0x0B93,0x0B94,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0BD0 };  // second keystroke
static UniChar AnjalUV3Char[] = { 0x0B00,0x0B00,0x0B00,0x0B0B,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00 };  // third keystroke

// vowel sign chars                                                   
static UniChar AnjalUVS1Char[]= { 0x0008,0x0BBF,0x0BC1,0x0BC6,0x0BC8,0x0BCA,0x0BCC,0x0BCD,0x0BBE,0x0BC0,0x0BC2,0x0BC7,0x0BCB };  // first keystroke
static UniChar AnjalUVS2Char[]= { 0x0BBE,0x0BC0,0x0BC2,0x0BC7,0x0BC8,0x0BCB,0x0BCC,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00 };  // second keystroke
static UniChar AnjalUVS3Char[]= { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00 };  // third keystroke

// conso keys
static UniChar AnjalUC1Keys[] = { 'k','g','c','d','t','p','b','R',  'y','r','l','v','z','L',  'n','n','N','w','m','n',  'j','s','S','h','x','s',  'n', 'W', 0 };
static UniChar AnjalUC2Keys[] = { '*','*','h','*','h','*','*','*',  '*','*','*','*','*','*',  'g','j','*','-','*','-',  '*','h','*','*','*','r',  '=', '*', 0 };
static UniChar AnjalUC3Keys[] = { '*','*','*','*','*','*','*','*',  '*','*','*','*','*','*',  '*','*','*','*','*','*',  '*','*','*','*','*','i',  '*', '*', 0 };

// conso chars
static UniChar AnjalUC1Char[] = { 0x0B95,0x0B95,0x0B9A,0x0B9F,0x0BA4,0x0BAA,0x0BAA,0x0BB1, 0x0BAF,0x0BB0,0x0BB2,0x0BB5,0x0BB4,0x0BB3, 
	                       0x0BA9,0x0BA9,0x0BA3,0x0BA8,0x0BAE,0x0BA9,               0x0B9C,0x0B9A,0x0BB8,0x0BB9,0x0B01,0x0B9A,  0x0BA9, 0x0BA9, 0};

static UniChar AnjalUC2Char[] = { 0x0B00,0x0B00,0x0B9A,0x0B00,0x0BA4,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 
	                       0x0B99,0x0B9E,0x0B00,0x0BA9,0x0B00,0x0BA8,               0x0B00,0x0BB7,0x0B00,0x0B00,0x0B00,0x0B02,  0x0BA9, 0x0BA9, 0};

static UniChar AnjalUC3Char[] = { 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00, 
	                       0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,               0x0B00,0x0B00,0x0B00,0x0B00,0x0B00,0x0B02,  0x0B00, 0x0BA9, 0}; 


void  getKeyStringUnicodeTamilAnjal(UniChar currKey, UniChar *s, getKeyStringResults *results)
{
	// Function to call when a new session needs to be started
	
	int     vpos;
    bool    nReplacedWithW = false;
	
	// Assume no conversions are going to be done
	results->deleteCount = 0;
	results->insertCount = 0;
	results->fixPrevious = false;
	
	//printf("In GKS: currKey = %d('%c'), prevKey = %d, prevKeyType = %d\n", currKey, (char)currKey, results->prevKey, results->prevKeyType);
	//// Debug: In GKS: currKey = %d('%c'), prevKey = %d('%c'), prevKeyType = %d, firstConsoKey = %c, context before = %C\n
	
    // 2016-09-17 : fix for n typed after delete resulting in ந
    if ( currKey == 'n' && (results->contextBefore >= tgv_q && results->contextBefore <= tgm_pulli) ) {
        //// Debug: n replaced by W
        currKey = 'W'; // force a ன
        nReplacedWithW = true;
    }
    
	switch (results->prevKeyType) {
		case (CHARACTER_END_KEYTYPE) :
			
			// The prev unicode character has been composed. Start a new session
			
			startNewSessionTamilAnjal(currKey, s, results);
			break;
			
		case (FIRST_VOWEL_KEYTYPE) :
        case (FIRST_VOWELSIGN_KEYTYPE) :
			
            // First key was a vowel key. Check if the current key is a second vowel key
			
			if ( (vpos = getKeyPos( currKey, AnjalUV2Keys, results->prevKey, AnjalUV1Keys, 0,0)) >=0) {
			    // current key is a second vowel key
                // send the new vowel with a backspace.
                if (results->prevKeyType == FIRST_VOWEL_KEYTYPE) {
                    s[0] = AnjalUV2Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = SECOND_VOWEL_KEYTYPE;
                } else {
                    s[0] = AnjalUVS2Char[vpos]; s[1] = '\0';
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
			
			startNewSessionTamilAnjal(currKey, s, results);
			break;
			
		case (SECOND_VOWEL_KEYTYPE) :
        case (SECOND_VOWELSIGN_KEYTYPE) :
			
            // Second key was a vowel key. Check if the current key is a third vowel key
			
			if ( (vpos=getKeyPos(currKey, AnjalUV3Keys, results->prevKey, AnjalUV2Keys, results->firstVowelKey,AnjalUV1Keys)) >=0) {
			    
				// current key is a third vowel key - send the new vowel with a backspace.
				
                if (results->prevKeyType == SECOND_VOWEL_KEYTYPE) {
                    s[0] = AnjalUV3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWEL_KEYTYPE;
                } else {
                    s[0] = AnjalUVS3Char[vpos]; s[1] = '\0';
					results->insertCount = 1;
                    results->prevKeyType = THIRD_VOWELSIGN_KEYTYPE;
                }
				
                results->deleteCount = 1; // delete the prev vowel
                results->prevCharType = VOWEL_CHARTYPE;
				
				break;
				
            }
			
			// Current key is not a third vowel, start a new session
			
			startNewSessionTamilAnjal(currKey, s, results);
			break;
			
		case (FIRST_CONSO_KEYTYPE) :
			
			// Prev key was a first conso key. Check if curr key is 2nd conso,
			// Handle special occurances first
			if ( results->prevKey == 't' && currKey == 'r' ) 
			{
				s[0]=0x0BB1; s[1]=0x0BCD; s[2]=0x0BB1; s[3]=0x0BCD; s[4] = '\0';
				results->insertCount = 4;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			}
			if ( results->prevKey == 'n' && currKey == 't' ) 
			{
				s[0]=0x0BA8; s[1]=0x0BCD; s[2]=0x0BA4; s[3]=0x0BCD; s[4] = '\0';
				results->insertCount = 4;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			}
			if ( results->prevKey == 'n' && currKey == 'd' ) 
			{
				s[0]=0x0BA3; s[1]=0x0BCD; s[2]=0x0B9F; s[3]=0x0BCD; s[4] = '\0';
				results->insertCount = 4;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			}
			if ( results->prevKey == 'L' && currKey == 'l' )  // added for sellinam
			{
				s[0]=0x0BB3; s[1]=0x0BCD; s[2] = '\0';
				results->insertCount = 2;
                // don't delete anything -- this is to make the second l following an L into an L.
                results->deleteCount = 0;
                results->prevKeyType = FIRST_CONSO_KEYTYPE;	
				break;
			}
			if ( results->prevKey == 'k' && currKey == 's' )  // nothing special, just insert CA. remembering k, s just in case the next one is h so I can insert ZWNJ
			{
				s[0]=0x0B9A; s[1]=0x0BCD; s[2] = '\0';
				results->insertCount = 2;
                results->deleteCount = 0;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;	
				break;
			}
			else if ( (vpos = getKeyPos( currKey, AnjalUC2Keys, results->prevKey, AnjalUC1Keys, 0, 0)) >= 0) {
				
				// It's a second conso. key. Send the new character with a
                // backspace flag
				s[0] = AnjalUC2Char[vpos]; s[1] = 0x0BCD; s[2] = '\0';
				results->insertCount = 2;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = SECOND_CONSO_KEYTYPE;
				
				// --- I'm using a place holder char 0x0B02 for SRI
				if ( s[0] == 0x0B02 )
				{
					s[0]=0x0BB6; s[1]=0x0BCD; s[2]=0x0BB0; s[3]=0x0BC0; s[4]='\0';
					results->insertCount = 4;
				}
                break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, AnjalUV1Keys, 0, 0, 0, 0)) >= 0) {
				
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = AnjalUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
					results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0'; // nothing happens with akaram.
					results->insertCount = 0;
					results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;  // must break here as there is a default
            }
			
			// Current key is not a second conso or first vowel, start a new session
			startNewSessionTamilAnjal(currKey, s, results);
            break;
			
		case (SECOND_CONSO_KEYTYPE) :
			
			// Prev. Key was a 2nd conso. Check for special sequences first.
			// If curr Key is NOT a 3rd conso, the
            // character is composed - start a new character.
			
			if ( (results->firstConsoKey=='n' || results->firstConsoKey=='W' )&& results->prevKey=='d' && currKey=='r' )
			{
				s[0]=0x0BA9; s[1]=0x0BCD; s[2]=0x0BB1; s[3]=0x0BCD; s[4] = '\0';
				results->insertCount = 4;
                // delete the prev conso
                results->deleteCount = 4;
                results->prevKeyType = THIRD_CONSO_KEYTYPE;	
				break;	
			}
			if ( (results->firstConsoKey=='n' || results->firstConsoKey=='W') && results->prevKey=='j' && currKey=='j' )
			{
				s[0]=0x0B9A; s[1]=0x0BCD; s[2] = '\0';
				results->insertCount = 2;
                // delete the prev conso
                results->deleteCount = 0;
                results->prevKeyType = THIRD_CONSO_KEYTYPE;	
				break;	
			}
			if ( results->firstConsoKey=='k' && results->prevKey=='s' && currKey=='h' )
			{
				s[0]=ZWNJ; s[1]=0x0BB7; s[2]=0x0BCD; s[3] = '\0';
				results->insertCount = 3;
                // delete the prev conso
                results->deleteCount = 2;
                results->prevKeyType = THIRD_CONSO_KEYTYPE;	
				break;	
			}
 			else if ( (vpos = getKeyPos( currKey, AnjalUC3Keys, results->prevKey, AnjalUC2Keys, results->firstConsoKey, AnjalUC1Keys)) >= 0) {
				
				// key is a third conso. Send the new character with a b/s flag
				s[0] = AnjalUC3Char[vpos]; s[1]=0x0BCD; s[2] = '\0';
                results->deleteCount = 2;
				results->insertCount = 2;
				results->prevKeyType = THIRD_CONSO_KEYTYPE;
				
				// --- I'm using a place holder char 0x0B02 for SRI
				if ( s[0] == 0x0B02 )
				{
					s[0]=0x0BB6; s[1]=0x0BCD; s[2]=0x0BB0; s[3]=0x0BC0; s[4]='\0';
					results->insertCount = 4;
					results->deleteCount = 4;
				}
				
				break;  // must break here as there is a default
				
			} else if ((vpos = getKeyPos(currKey, AnjalUV1Keys, 0, 0, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = AnjalUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
					results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
					results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;
				
            }
			
			// Current key is not third conso or first vowel, start a new session
			startNewSessionTamilAnjal(currKey, s, results);
            break;
			
		case (THIRD_CONSO_KEYTYPE) :
			
			// Prev key is a 3rd conso key - if curr key is a vowel key
            // send vowel sign apply modifier
			
			if ((vpos = getKeyPos(currKey, AnjalUV1Keys, 0, NULL, 0, 0)) >= 0) {
                // If key is a vowel, send vowel sign if it's not 'a'
                // Can't be a second vowel since the prevKey is a conso
                if (currKey != 'a') { 
					s[0] = AnjalUVS1Char[vpos]; 
					s[1] = '\0'; 
					results->insertCount = 1;
				    results->deleteCount = 1; // delete the pulli
				} else {
					s[0] = '\0';  // nothing happens with akaram.
					results->insertCount = 0;
					results->deleteCount = 1; // delete the pulli
				}
				
                results->prevKeyType = FIRST_VOWELSIGN_KEYTYPE;
				
                break;   // must break as there is a default
				
            }
			
			// currKey is not a vowel, start a new session
			startNewSessionTamilAnjal(currKey, s, results);
            break;
			
		default :
			startNewSessionTamilAnjal(currKey, s, results);
			break;
	}
	
    // 2016-09-17 Restore 'n' if it was replaced with 'W'
    if ( nReplacedWithW )
        results->prevKey = 'n';
    else
        results->prevKey = currKey;
}


void startNewSessionTamilAnjal(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	//printf("Starting a new session...with %c\n", (char) currKey);
	
	int vpos = -1;
	
	
    // check if key is a consonant or a vowel or an out-of-matrix key
	if ( (vpos = getKeyPos(currKey, AnjalUC1Keys, 0, NULL, 0, 0)) >= 0) {
		
        int i=0;
		
		// Key is starting a sequence for a conso.
        s[i] = '\0';
		
		// --- replace 'na' with dental-na if it's starting a word
		//// Debug: Prev Key: %d
		if ( (results->prevKeyType == 0 || results->prevKeyType == WHITE_SPACE_KEYTYPE) && currKey == 'n' && (results->prevKey != BACKSPACEKEY) )
            s[i++] = tgc_na;// 0x0BA8;
		else 
			s[i++] = AnjalUC1Char[vpos];  // add the conso char to s
		
		s[i++] = 0x0BCD; // pulli
        s[i] = '\0';
		results->insertCount = i;
		results->prevKeyType = FIRST_CONSO_KEYTYPE;
        results->prevCharType = CONSO_CHARTYPE; //(vpos < MAL_CONSO_MAX) ? CONSO_CHARTYPE : VOWEL_CHARTYPE;
        results->firstConsoKey = currKey;
		results->fixPrevious = true; // since this a start of a new composition, fix the previous one
		
        results->deleteCount = 0; // no deleting of previous characters
		
		// --- I'm using a place holder char 0x0B01 for X
		if ( s[0] == 0x0B01 )
		{
			s[0]=0x0B95; s[1]=0x0BCD; s[2]=0x0BB7; s[3]=0x0BCD; s[4]='\0';
			results->insertCount = 4;
		}
		
		return;
		
	} else if ( (vpos = getKeyPos(currKey, AnjalUV1Keys, 0, NULL, 0, 0)) >= 0) {
		
        s[0] = AnjalUV1Char[vpos]; s[1] = '\0';
		
		results->insertCount = 1;
        results->prevKeyType = FIRST_VOWEL_KEYTYPE;
        results->prevCharType = VOWEL_CHARTYPE;
        results->firstVowelKey = currKey;
        results->deleteCount = 0; // no deleting of previous characters
		results->fixPrevious = true; // independant vowels fix previous composition
		
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


