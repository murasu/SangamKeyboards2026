#include "KeyTranslatorMultilingual.h"
#include "AnjalKeyMap.h"
#include "EncodingTamil.h"
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

// Tamil-specific translator handle
typedef struct TamilTranslatorHandle {
    int32_t keyboard_layout;
    int32_t prev_key_code;
    wchar_t prev_translation[10];
    bool prev_key_was_backspace;
    bool wysiwyg_delete_reverse;
} TamilTranslatorHandle;

// Tamil-specific functions
TamilTranslatorHandle* tamil_translator_create(int32_t keyboard_layout) {
    TamilTranslatorHandle* translator = malloc(sizeof(TamilTranslatorHandle));
    if (!translator) return NULL;
    
    translator->keyboard_layout = keyboard_layout;
    translator->prev_key_code = 0;
    translator->prev_translation[0] = 0;
    translator->prev_key_was_backspace = false;
    translator->wysiwyg_delete_reverse = false;
    
    // Initialize the C keyboard system
    SetKeyboardLayout(keyboard_layout);
    ResetKeyStringGlobals();
    
    return translator;
}

void tamil_translator_destroy(TamilTranslatorHandle* translator) {
    if (translator) {
        free(translator);
    }
}

int tamil_translator_translate_key(TamilTranslatorHandle* translator,
                                 int32_t key_code,
                                 int32_t prev_key_code,
                                 bool shifted,
                                 bool prev_key_was_backspace,
                                 wchar_t* output_buffer,
                                 int buffer_size) {
    if (!translator || !output_buffer || buffer_size < 10) {
        return 0;
    }
    
    wchar_t translated_string[10] = {0};
    
    // Call the existing C function from AnjalKeyMap.c
    int result = GetCharStringForKey((WCHAR)key_code, 
                                   (WCHAR)prev_key_code, 
                                   translated_string, 
                                   prev_key_was_backspace);
    
    // Handle deletion count if needed
    if (result > 0) {
        // result > 0 means delete 'result' number of characters
        // We need to encode this information somehow
        // For now, we'll use a special character to indicate deletion
        output_buffer[0] = DELCODE;  // Deletion indicator
        output_buffer[1] = (wchar_t)('0' + result); // Number to delete
        
        int len = 2;
        // Copy the translated characters after the delete instruction
        int i = 0;
        while (len < buffer_size - 1 && translated_string[i] != 0) {
            output_buffer[len] = translated_string[i];
            len++;
            i++;
        }
        output_buffer[len] = 0;
        
        // Update state
        translator->prev_key_code = key_code;
        wcsncpy(translator->prev_translation, translated_string, 10);
        translator->prev_key_was_backspace = prev_key_was_backspace;
        
        return len;
    } else if (result == KSR_DELETE_PREV_KS_LENGTH) {
        // Delete previous key string length
        int delete_count = (int)wcslen(translator->prev_translation);
        
        output_buffer[0] = DELCODE;
        output_buffer[1] = (wchar_t)('0' + delete_count);
        
        int len = 2;
        int i = 0;
        while (len < buffer_size - 1 && translated_string[i] != 0) {
            output_buffer[len] = translated_string[i];
            len++;
            i++;
        }
        output_buffer[len] = 0;
        
        // Update state
        translator->prev_key_code = key_code;
        wcsncpy(translator->prev_translation, translated_string, 10);
        translator->prev_key_was_backspace = prev_key_was_backspace;
        
        return len;
    } else {
        // Normal translation, no deletion needed
        int len = 0;
        while (len < buffer_size - 1 && translated_string[len] != 0) {
            output_buffer[len] = translated_string[len];
            len++;
        }
        output_buffer[len] = 0;
        
        // Update state
        translator->prev_key_code = key_code;
        wcsncpy(translator->prev_translation, translated_string, 10);
        translator->prev_key_was_backspace = prev_key_was_backspace;
        
        return len;
    }
}

void tamil_translator_terminate_composition(TamilTranslatorHandle* translator) {
    if (translator) {
        translator->prev_key_code = 0;
        translator->prev_translation[0] = 0;
        ResetKeyStringGlobals();
    }
}

void tamil_translator_set_layout(TamilTranslatorHandle* translator, int32_t layout) {
    if (translator) {
        translator->keyboard_layout = layout;
        SetKeyboardLayout(layout);
    }
}

int32_t tamil_translator_get_layout(TamilTranslatorHandle* translator) {
    return translator ? translator->keyboard_layout : 0;
}

void tamil_translator_update_after_delete(TamilTranslatorHandle* translator, wchar_t last_char) {
    if (translator) {
        UpdatePrevKeyTypesForLastChar(last_char);
    }
}

void tamil_translator_set_wysiwyg_delete_reverse(TamilTranslatorHandle* translator, bool reverse_order) {
    if (translator) {
        translator->wysiwyg_delete_reverse = reverse_order;
        SetWytiwygDeleteInReverseTypingOrder(reverse_order);
    }
}

// Helper functions for WYSIWYG keyboards
int tamil_translator_delete_last_char(TamilTranslatorHandle* translator,
                                     const wchar_t* input_string,
                                     wchar_t* output_buffer,
                                     int buffer_size) {
    if (!translator || !input_string || !output_buffer) {
        return 0;
    }
    
    // This would need to be implemented based on the WYSIWYG delete logic
    // from your KeyTranslatorAnjalWindows.m file
    // For now, just copy the input to output
    int len = 0;
    while (len < buffer_size - 1 && input_string[len] != 0) {
        output_buffer[len] = input_string[len];
        len++;
    }
    if (len > 0) len--; // Remove last character
    output_buffer[len] = 0;
    
    return len;
}

int tamil_translator_cleanup_stray_vowel(TamilTranslatorHandle* translator,
                                        const wchar_t* input_string,
                                        wchar_t* output_buffer,
                                        int buffer_size) {
    if (!translator || !input_string || !output_buffer) {
        return 0;
    }
    
    // This would implement the stray vowel cleanup logic
    // from your KeyTranslatorAnjalWindows.m file
    // For now, just copy input to output
    int len = 0;
    while (len < buffer_size - 1 && input_string[len] != 0) {
        output_buffer[len] = input_string[len];
        len++;
    }
    output_buffer[len] = 0;
    
    return len;
}
