
#-------------------------------------------------------------------------------
# The XrdSecgsiVOMS library
#-------------------------------------------------------------------------------

include_directories( ${VOMS_INCLUDE_DIR} )
include_directories( ${XROOTD_INCLUDE_DIR} ${XRDCRYPTO_INCLUDE_DIR})
add_definitions(${XROOTD_CFLAGS})
include( vomsxrdCommon )

#-------------------------------------------------------------------------------
# Shared library version
#-------------------------------------------------------------------------------
if (XROOTD_VERSIONNED)

  set( LIB_XRD_SEC_GSI_VOMS     XrdSecgsiVOMS-${XROOTD_PLUGIN_VERSION} )

  add_library(
     ${LIB_XRD_SEC_GSI_VOMS}
     MODULE
     ${CMAKE_SOURCE_DIR}/src/XrdSecgsiVOMSFun.cc )

  target_link_libraries(
     ${LIB_XRD_SEC_GSI_VOMS}
     ${XROOTD_LIBRARIES}
     ${VOMS_LIBRARIES} )

  set_target_properties(
     ${LIB_XRD_SEC_GSI_VOMS}
     PROPERTIES
     INTERFACE_LINK_LIBRARIES ""
     LINK_INTERFACE_LIBRARIES "" )

else()

  set( LIB_XRD_SEC_GSI_VOMS     XrdSecgsiVOMS )
  set( XRD_SEC_GSI_VOMS_VERSION    1.0.0 )
  set( XRD_SEC_GSI_VOMS_SOVERSION  0 )

  add_library(
     ${LIB_XRD_SEC_GSI_VOMS}
     SHARED
     ${CMAKE_SOURCE_DIR}/src/XrdSecgsiVOMSFun.cc )

  target_link_libraries(
     ${LIB_XRD_SEC_GSI_VOMS}
     ${XROOTD_LIBRARIES}
     ${VOMS_LIBRARIES} )

  set_target_properties(
     ${LIB_XRD_SEC_GSI_VOMS}
     PROPERTIES
     VERSION   ${XRD_SEC_GSI_VOMS_VERSION}
     SOVERSION ${XRD_SEC_GSI_VOMS_SOVERSION}
     LINK_INTERFACE_LIBRARIES "" )

endif()

#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
install(
   TARGETS ${LIB_XRD_SEC_GSI_VOMS}
   RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
   LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} )

install(
   FILES
   ${CMAKE_BINARY_DIR}/src/XrdSecgsiVOMSVers.hh
   ${CMAKE_SOURCE_DIR}/src/XrdSecgsiVOMS.hh
   DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/vomsxrd )

install(
  FILES
  ${PROJECT_SOURCE_DIR}/docs/man/libXrdSecgsiVOMS.1
  DESTINATION ${CMAKE_INSTALL_MANDIR}/man1 )

