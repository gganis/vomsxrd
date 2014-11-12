include( FindPackageHandleStandardArgs )

if( XROOTD_INCLUDE_DIRS AND XROOTD_LIBRARIES )

  set( XROOTD_FOUND TRUE )

else()

   set( XROOTD_VERSIONNED FALSE )

   foreach(i XrdOuc/XrdOucHash.hh XrdOuc/XrdOucString.hh XrdSec/XrdSecEntity.hh XrdSys/XrdSysLogger.hh)
   find_path(XROOTD_INCLUDE_DIR_${i}
      NAMES ${i} 
      HINTS
      ${XROOTD_ROOT_DIR}
      PATH_SUFFIXES
      include/xrootd )
      if (NOT XROOTD_INCLUDE_DIR_${i})
         SET(XROOTD_INCLUDE_DIR FALSE)
         message(ERROR "   Required include file not found: ${i}")
         break()
      else()
         SET(XROOTD_INCLUDE_DIR ${XROOTD_INCLUDE_DIR_${i}})
      endif()
   endforeach()

   if (XROOTD_INCLUDE_DIR)
      # Check for XrdCrypto headers
      foreach(i XrdCrypto/XrdCryptoX509.hh XrdCrypto/XrdCryptoX509Chain.hh XrdSut/XrdSutBucket.hh)
         find_path(XRDCRYPTO_INCLUDE_DIR_${i}
            NAMES ${i} 
            PATHS 
            ${CMAKE_SOURCE_DIR}/src
            ${XROOTD_CRYPTO_INCLUDE_DIR}
            ${XROOTD_INCLUDE_DIR}
            ${XROOTD_INCLUDE_DIR}/private )
         if (NOT XRDCRYPTO_INCLUDE_DIR_${i})
            SET(XRDCRYPTO_INCLUDE_DIR FALSE)
            break()
         else()
            SET(XRDCRYPTO_INCLUDE_DIR ${XRDCRYPTO_INCLUDE_DIR_${i}})
         endif()
       endforeach()

   endif()
    
  set( XROOTD_INCLUDE_DIRS ${XROOTD_INCLUDE_DIR})

  if (NOT XROOTD_COMPAT)
    find_program(
      XROOTD_CONFIG_EXE
      NAMES xrootd-config
      PATHS
      ${XROOTD_ROOT_DIR}/bin
      )
    if (XROOTD_CONFIG_EXE)
      message(STATUS "xrootd-config: ${XROOTD_CONFIG_EXE}")
      exec_program(${XROOTD_CONFIG_EXE} ARGS "--plugin-version 2>&1" OUTPUT_VARIABLE _xrd_plugin_version)
      if (NOT _xrd_plugin_version MATCHES "")
         set(XROOTD_PLUGIN_VERSION ${_xrd_plugin_version})
      else()
         set(XROOTD_PLUGIN_VERSION "4")
      endif()
      set(_xrd_crypto_ssl XrdCryptossl-${XROOTD_PLUGIN_VERSION})
      message(STATUS "Plugin-version set to: ${XROOTD_PLUGIN_VERSION}")
      set( XROOTD_VERSIONNED TRUE )
    else()
      set(_xrd_crypto_ssl XrdCryptossl)
      message(STATUS "No plugin-version information: assume < 4")
    endif()
  else()
    set(_xrd_crypto_ssl XrdCryptossl)
    message(STATUS "Compat build: plugin-version check")    
  endif()

  find_library(
    XROOTD_LIBRARY
    NAMES ${_xrd_crypto_ssl}
    HINTS
    ${XROOTD_ROOT_DIR}
    PATH_SUFFIXES lib64
    ${LIBRARY_PATH_PREFIX}
    ${LIB_SEARCH_OPTIONS})
  set( XROOTD_LIBRARIES ${XROOTD_LIBRARY} )

   find_package_handle_standard_args(
     XROOTD
     DEFAULT_MSG
     XROOTD_LIBRARY XROOTD_INCLUDE_DIR )
    if (XROOTD_INCLUDE_DIR)
       message(STATUS "Found include dir: ${XROOTD_INCLUDE_DIR}")
      if (XRDCRYPTO_INCLUDE_DIR)
         message(STATUS "Found XrdCrypto includes: ${XRDCRYPTO_INCLUDE_DIR}")
         SET(XROOTD_CFLAGS "-DHAVE_XRDCRYPTO")
      endif()
    endif()
   

   mark_as_advanced( XROOTD_INCLUDE_DIR XRDCRYPTO_INCLUDE_DIR XROOTD_LIBRARY )
endif()
