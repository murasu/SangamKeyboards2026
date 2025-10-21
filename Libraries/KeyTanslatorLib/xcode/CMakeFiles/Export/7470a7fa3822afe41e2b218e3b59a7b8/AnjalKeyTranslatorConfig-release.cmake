#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AnjalKeyTranslator" for configuration "Release"
set_property(TARGET AnjalKeyTranslator APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(AnjalKeyTranslator PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  )

list(APPEND _cmake_import_check_targets AnjalKeyTranslator )
list(APPEND _cmake_import_check_files_for_AnjalKeyTranslator "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard" )

# Import target "AnjalKeyTranslatorShared" for configuration "Release"
set_property(TARGET AnjalKeyTranslatorShared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(AnjalKeyTranslatorShared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  IMPORTED_SONAME_RELEASE "@rpath/anjalkeyboard.framework/Versions/A/anjalkeyboard"
  )

list(APPEND _cmake_import_check_targets AnjalKeyTranslatorShared )
list(APPEND _cmake_import_check_files_for_AnjalKeyTranslatorShared "${_IMPORT_PREFIX}/Frameworks/anjalkeyboard.framework/Versions/A/anjalkeyboard" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
