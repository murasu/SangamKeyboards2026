#ifndef PREDICTOR_C_API_H
#define PREDICTOR_C_API_H

#include <stddef.h>  // for size_t
#include <stdbool.h>
#include "ScriptConverterStructs.h"

#ifdef _WIN32
    #ifdef PREDICTOR_STATIC
        #define PREDICTOR_API
    #else
        #ifdef PREDICTOR_EXPORTS
            #define PREDICTOR_API __declspec(dllexport)
        #else
            #define PREDICTOR_API __declspec(dllimport)
        #endif
    #endif
#else
    #define PREDICTOR_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Status codes
typedef enum PredictorStatus {
    PREDICTOR_SUCCESS = 0,
    PREDICTOR_ERROR_INVALID_ARGUMENT = -1,
    PREDICTOR_ERROR_OUT_OF_MEMORY = -2,
    PREDICTOR_ERROR_INITIALIZATION = -3,
    PREDICTOR_ERROR_INTERNAL = -4
} PredictorStatus;

// Opaque type for predictor handle
typedef struct PredictorHandle* PredictorRef;

// Configuration options
typedef struct {
    int allow_variations;
    int enable_user_dictionary;
    float score_threshold;
} PredictorOptions;

// Result structure
typedef struct {
    const wchar_t* word;    // Points to internal buffer, don't free
    const wchar_t* annotation; // Points to annotation text, don't free
    double frequency;
    int word_id;
    float final_score;
    bool user_word;         // Is word from user dictionary flag
    bool is_emoji;
} PredictorResult;

// Creation/Destruction
PREDICTOR_API PredictorRef Predictor_Create(int debug_mode, PredictorStatus* status);
PREDICTOR_API void Predictor_Destroy(PredictorRef predictor);

// Configuration
PREDICTOR_API PredictorStatus Predictor_Initialize(
    PredictorRef predictor,
    const char* trie_path);

PREDICTOR_API PredictorStatus Predictor_SetUserDictionary(
    PredictorRef predictor,
    const char* db_path);

PREDICTOR_API PredictorStatus Predictor_Configure(
    PredictorRef predictor,
    const PredictorOptions* options);

// Core prediction functionality
PREDICTOR_API PredictorStatus Predictor_GetWordPredictions(
    PredictorRef predictor,
    const wchar_t* prefix,
    enum TargetScript target_script,
    enum AnnotationDataType annotation_type,
    size_t max_results,
    PredictorResult** out_results,
    size_t* out_count);

PREDICTOR_API PredictorStatus Predictor_GetNgramPredictions(
    PredictorRef predictor,
    const wchar_t* base_word,
    const wchar_t* second_word,
    const wchar_t* next_word_prefix,
    enum TargetScript target_script,
    enum AnnotationDataType annotation_type,
    size_t max_results,
    PredictorResult** out_results,
    size_t* out_count);

// Dictionary management
PREDICTOR_API PredictorStatus Predictor_AddWord(
    PredictorRef predictor,
    const wchar_t* word);

PREDICTOR_API PredictorStatus Predictor_AddBigram(
    PredictorRef predictor,
    const wchar_t* word1,
    const wchar_t* word2);

PREDICTOR_API PredictorStatus Predictor_AddTrigram(
    PredictorRef predictor,
    const wchar_t* word1,
    const wchar_t* word2,
    const wchar_t* word3);

PREDICTOR_API PredictorStatus Predictor_GetAnnotationsCount(
    PredictorRef predictor,
    size_t* out_count);

PREDICTOR_API PredictorStatus Predictor_ImportAnnotationsFromTextFile(
    PredictorRef predictor,
    const char* fileName,
    size_t* out_count);

PREDICTOR_API PredictorStatus Predictor_ImportShortcutsFromTextFile(
    PredictorRef predictor,
    const char* fileName,
    size_t* out_count);

PREDICTOR_API PredictorStatus Predictor_ImportBlacklistFromTextFile(
    PredictorRef predictor,
    const char* fileName,
    size_t* out_count);

PREDICTOR_API PredictorStatus Predictor_RemoveWord(
    PredictorRef predictor,
    const wchar_t* word,
    size_t* out_result);
                                  
PREDICTOR_API PredictorStatus Predictor_ConvertToBrahmi(
    const wchar_t* word,
    wchar_t** out_result);

// Memory management
PREDICTOR_API void Predictor_FreeResults(PredictorResult* results);

// Debug support
PREDICTOR_API void Predictor_SetDebugMode(
    PredictorRef predictor,
    int enable);

#ifdef __cplusplus
}
#endif

#endif // PREDICTOR_C_API_H
