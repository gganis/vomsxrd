include( FindPackageHandleStandardArgs )

if( XROOTD_INCLUDE_DIRS AND XROOTD_LIBRARIES )

  set( XROOTD_FOUND TRUE )

else()

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
      foreach(i XrdCrypto/XrdCryptosslAux.hh XrdCrypto/XrdCryptosslgsiAux.hh XrdCrypto/XrdCryptoX509.hh
                XrdCrypto/XrdCryptoX509Chain.hh XrdSut/XrdSutBucket.hh)
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

  find_library(
    XROOTD_LIBRARY
    NAMES XrdCryptossl
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
