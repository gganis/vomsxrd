include( FindPackageHandleStandardArgs )

if( XROOTD_INCLUDE_DIRS AND XROOTD_LIBRARIES )

  set( XROOTD_FOUND TRUE )

else()

  find_path(
    XROOTD_INCLUDE_DIR
    NAMES xrootd/XrdVersion.hh
    HINTS
    ${XROOTD_ROOT_DIR}
    PATH_SUFFIXES
    include )
  set( XROOTD_INCLUDE_DIRS ${XROOTD_INCLUDE_DIR})

  find_library(
    XROOTD_LIBRARY
    NAMES XrdCryptossl XrdCrypto XrdUtils
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

   mark_as_advanced( XROOTD_INCLUDE_DIR XROOTD_LIBRARY )
endif()
