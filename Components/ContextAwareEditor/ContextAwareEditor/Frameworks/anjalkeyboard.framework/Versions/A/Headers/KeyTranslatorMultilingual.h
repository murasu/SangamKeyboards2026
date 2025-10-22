#ifndef KEYTRANSLATOR_MULTILINGUAL_H
#define KEYTRANSLATOR_MULTILINGUAL_H

#include <wchar.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// code to indicate that delete should be sent. the next char to this code indicates the number of deletes
#define DELCODE         0x2421

// Supported languages
typedef enum {
    LANG_TAMIL = 0,
    LANG_DEVANAGARI = 1,    // Hindi, Sanskrit, Marathi, Nepali
    LANG_MALAYALAM = 2,
    LANG_KANNADA = 3,
    LANG_TELUGU = 4,
    LANG_GURMUKHI = 5,      // Punjabi
    LANG_DIACRITICS = 6     // Linguistic transcription
} SupportedLanguage;

// Keyboard layouts (Tamil-specific)
typedef enum {
    KBD_ANJAL = 0,
    KBD_TAMIL99 = 1,
    KBD_TAMIL97 = 2,
    KBD_MYLAI = 3,
    KBD_TYPEWRITER_NEW = 4,
    KBD_TYPEWRITER_OLD = 5,
    KBD_ANJAL_INDIC = 6,
    KBD_MURASU6 = 7,
    KBD_BAMINI = 8,
    KBD_TN_TYPEWRITER = 9
} KeyboardLayout;

// Opaque handle for multilingual translator
typedef struct MultilingualTranslatorHandle* MultilingualTranslatorRef;

// Create translator for specific language and keyboard layout
MultilingualTranslatorRef multilingual_translator_create(SupportedLanguage language, 
                                                        KeyboardLayout layout);

// Destroy translator
void multilingual_translator_destroy(MultilingualTranslatorRef translator);

// Translate key for current language
int multilingual_translator_translate_key(MultilingualTranslatorRef translator,
                                         int32_t key_code,
                                         bool shifted,
                                         wchar_t* output_buffer,
                                         int buffer_size);

// Switch language while keeping same translator instance
bool multilingual_translator_set_language(MultilingualTranslatorRef translator, 
                                         SupportedLanguage language);

// Set keyboard layout (primarily for Tamil)
bool multilingual_translator_set_layout(MultilingualTranslatorRef translator, 
                                       KeyboardLayout layout);

// Get current language
SupportedLanguage multilingual_translator_get_language(MultilingualTranslatorRef translator);

// Get supported keyboard layouts for current language
int multilingual_translator_get_supported_layouts(MultilingualTranslatorRef translator,
                                                 KeyboardLayout* layouts_buffer,
                                                 int buffer_size);

// Terminate composition
void multilingual_translator_terminate_composition(MultilingualTranslatorRef translator);

// Language-specific helper functions
const char* multilingual_get_language_name(SupportedLanguage language);
const char* multilingual_get_layout_name(KeyboardLayout layout);
bool multilingual_is_layout_supported_for_language(SupportedLanguage language, 
                                                   KeyboardLayout layout);

#ifdef __cplusplus
}
#endif

#endif // KEYTRANSLATOR_MULTILINGUAL_H
