//
//  IndicRomanIMEngine.m
//  IndRo
//
//  Created by Muthu Nedumaran on 28-08-2010.
//  Copyright 2010 Murasu Systems Sdn Bhd. All rights reserved.
//

#include "IndicNotesIMEngine.h"
#include <ctype.h>

#include "IndicNotesIMEngine.h"


void  getKeyStringUnicode(UniChar currKey, UniChar *s,  getKeyStringResults *results)
{
	// --- Call the appropriate getKeyStringUnicode based on inputMode
	if ( results->imeType == kImeTypeDevanagari )
		getKeyStringUnicodeDevanagariAnjal(currKey, s, results);
	else if ( results->imeType == kImeTypeTamil )
        // TODO: This was used in the IndicNotes key translator. Check if it can be removed.
		getKeyStringUnicodeTamilAnjal(currKey, s, results);
	//else if ( results->imeType == kImeTypeDiacritic )
	//	getKeyStringUnicodeDiacritic(currKey, s, results);
	else if ( results->imeType == kImeTypeMalayalam )
		getKeyStringUnicodeMalayalamAnjal(currKey, s, results);
	else if ( results->imeType == kImeTypeGurmukhi )
		getKeyStringUnicodeGurmukhiAnjal(currKey, s, results);
	else if ( results->imeType == kImeTypeTelugu )
		getKeyStringUnicodeTeluguAnjal(currKey, s, results);
	else if ( results->imeType == kImeTypeKannada )
		getKeyStringUnicodeKannadaAnjal(currKey, s, results);
}

int getKeyPos(UniChar key, UniChar table[], UniChar pKey, UniChar pTable[], UniChar fKey,
              UniChar fTable[])
{
	
	// don't lookup '*'
	if ( key == '*' )  return -1;
	
	int vpos=0;
    bool done = false;
	
	do {	// loop until some condition is reached
		
		while ( table[vpos] != key ) {
			if ( table[vpos] == 0 ) break;
			vpos++;
		}
		
		if (table[vpos] == 0)
			// key not in table - so just return error (-1)
			return -1;
		
		// Key is in table.  Check if prev. key is given.
		if (pKey) {
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
		if (fKey) {
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

void clearResults(getKeyStringResults *results)
{
	results->prevKey            = 0;
	results->prevKeyType        = 0;
	results->prevCharType       = 0;
	results->firstVowelKey      = 0;
	results->firstConsoKey      = 0;
	results->insertCount        = 0;
	results->deleteCount        = 0;
	results->fixPrevious        = false;
	results->currentBaseChar    = 0;
    results->contextBefore      = 0;
    //results->aTyped             = 0;
}
