cmake_minimum_required(VERSION 3.16)
project(AnjalKeyTranslator VERSION 1.0.0 LANGUAGES C CXX)

# Set standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Source files
set(TAMIL_SOURCES
    src/tamil/AnjalKeyMap.c
    src/tamil/KeyTranslatorTamil.c
)

set(INDIC_SOURCES
    src/indic/IndicNotesIMEngine.c
    src/indic/IndicDevanagariKeymap.c
    src/indic/IndicMalayalamKeymap.c
    src/indic/IndicKannadaKeymap.c
    src/indic/IndicTeluguKeymap.c
    src/indic/IndicGurmukhiKeymap.c
    src/indic/IndicTamilAnjalKeymap.c
)

set(MAIN_SOURCES
    src/KeyTranslatorMultilingual.c
    ${TAMIL_SOURCES}
    ${INDIC_SOURCES}
)

set(HEADERS
    include/AnjalKeyMap.h
    include/EncodingTamil.h
    include/AnjalKeyMapLookup.h
    include/IndicNotesIMEngine.h
    include/IndicIMEConstants.h
    include/KeyTranslatorMultilingual.h
)

# Create static library
add_library(AnjalKeyTranslator STATIC ${MAIN_SOURCES} ${HEADERS})

# Create shared library for better Swift interop
add_library(AnjalKeyTranslatorShared SHARED ${MAIN_SOURCES} ${HEADERS})

# Set library properties
set_target_properties(AnjalKeyTranslator PROPERTIES
    OUTPUT_NAME "anjalkeyboard"
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
)

set_target_properties(AnjalKeyTranslatorShared PROPERTIES
    OUTPUT_NAME "anjalkeyboard"
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
)

# Platform-specific settings
if(APPLE)
    set_target_properties(AnjalKeyTranslator PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.murasu.anjalkeyboard
        PUBLIC_HEADER "${HEADERS}"
    )
    set_target_properties(AnjalKeyTranslatorShared PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.murasu.anjalkeyboard.shared
        PUBLIC_HEADER "${HEADERS}"
    )
endif()

# Compiler-specific settings
target_compile_definitions(AnjalKeyTranslator PRIVATE
    $<$<PLATFORM_ID:Darwin>:TARGET_OS_MAC>
    $<$<PLATFORM_ID:Linux>:TARGET_OS_LINUX>
    $<$<PLATFORM_ID:Windows>:TARGET_OS_WINDOWS>
)

target_compile_definitions(AnjalKeyTranslatorShared PRIVATE
    $<$<PLATFORM_ID:Darwin>:TARGET_OS_MAC>
    $<$<PLATFORM_ID:Linux>:TARGET_OS_LINUX>
    $<$<PLATFORM_ID:Windows>:TARGET_OS_WINDOWS>
)

# Include directories for installation
target_include_directories(AnjalKeyTranslator PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_include_directories(AnjalKeyTranslatorShared PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Installation
install(TARGETS AnjalKeyTranslator AnjalKeyTranslatorShared
    EXPORT AnjalKeyTranslatorTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    FRAMEWORK DESTINATION Frameworks
    PUBLIC_HEADER DESTINATION include/AnjalKeyTranslator
)

install(EXPORT AnjalKeyTranslatorTargets
    FILE AnjalKeyTranslatorConfig.cmake
    DESTINATION lib/cmake/AnjalKeyTranslator
)

# Examples (optional)
option(BUILD_EXAMPLES "Build example programs" OFF)
if(BUILD_EXAMPLES)
    add_executable(c_example examples/c_example.c)
    target_link_libraries(c_example AnjalKeyTranslator)
    
    add_executable(cpp_example examples/cpp_example.cpp)
    target_link_libraries(cpp_example AnjalKeyTranslator)
endif()

# Tests (optional)
option(BUILD_TESTS "Build test programs" OFF)
if(BUILD_TESTS)
    enable_testing()
    add_executable(keymap_tests tests/keymap_tests.c)
    target_link_libraries(keymap_tests AnjalKeyTranslator)
    add_test(NAME keymap_tests COMMAND keymap_tests)
endif()
