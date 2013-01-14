# CMake project file for VOMS-XRootD

cmake_minimum_required (VERSION 2.6)
project (vomsxrd)

# make sure that the default is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
      "Choose the type of build, options are: None Debug Release."
      FORCE)
endif (NOT CMAKE_BUILD_TYPE)

# Add uninstall target
CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
  IMMEDIATE @ONLY)
ADD_CUSTOM_TARGET(uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake")

set( CMAKE_MODULE_PATH
 ${PROJECT_SOURCE_DIR}/src
 ${PROJECT_SOURCE_DIR}/cmake )

include_directories(${PROJECT_SOURCE_DIR}/src)

include( vomsxrdOSDefs )

#-------------------------------------------------------------------------------
# VOMS libs required
#-------------------------------------------------------------------------------
find_package( VOMS REQUIRED)
find_package( XRootD REQUIRED)

#-------------------------------------------------------------------------------
# Build in subdirectories
#-------------------------------------------------------------------------------
add_subdirectory( src )
 
#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
message( STATUS "----------------------------------------" )
message( STATUS "Installation path: " ${CMAKE_INSTALL_PREFIX} )
message( STATUS "Build type:        " ${CMAKE_BUILD_TYPE} )
message( STATUS "----------------------------------------" )

