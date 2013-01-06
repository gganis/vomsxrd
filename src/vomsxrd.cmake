
#-------------------------------------------------------------------------------
# The XrdSecgsiVOMS library
#-------------------------------------------------------------------------------

include_directories( ${VOMS_INCLUDE_DIR} )
include( vomsxrdCommon )

#-------------------------------------------------------------------------------
# Shared library version
#-------------------------------------------------------------------------------
set( XRD_SEC_GSI_VOMS_VERSION    1.0.0 )
set( XRD_SEC_GSI_VOMS_SOVERSION  0 )

add_library(
   XrdSecgsiVOMS
   SHARED
   src/XrdSecgsiVOMSFun.cc )

target_link_libraries(
   XrdSecgsiVOMS
   ${XROOTD_LIBRARIES}
   ${VOMS_LIBRARIES} )

set_target_properties(
   XrdSecgsiVOMS
   PROPERTIES
   VERSION   ${XRD_SEC_GSI_VOMS_VERSION}
   SOVERSION ${XRD_SEC_GSI_VOMS_SOVERSION}
   LINK_INTERFACE_LIBRARIES "" )

#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
install(
   TARGETS XrdSecgsiVOMS
   RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
   LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} )

install_headers(
   ${CMAKE_INSTALL_INCLUDEDIR}/xrootd
   src/XrdSecgsiVOMS.hh )
