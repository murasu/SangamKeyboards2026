#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AnjalKeyTranslator" for configuration "Debug"
set_property(TARGET AnjalKeyTranslator APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(AnjalKeyTranslator PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "C"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  )

list(APPEND _cmake_import_check_targets AnjalKeyTranslator )
list(APPEND _cmake_import_check_files_for_AnjalKeyTranslator "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard" )

# Import target "AnjalKeyTranslatorShared" for configuration "Debug"
set_property(TARGET AnjalKeyTranslatorShared APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(AnjalKeyTranslatorShared PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  IMPORTED_SONAME_DEBUG "@rpath/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  )

list(APPEND _cmake_import_check_targets AnjalKeyTranslatorShared )
list(APPEND _cmake_import_check_files_for_AnjalKeyTranslatorShared "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
