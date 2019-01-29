# CMake project file for mt_stream
cmake_minimum_required ( VERSION 2.6 )
project (fruit)
enable_language ( Fortran )

# Set library name
set (LIBRARY_NAME fruit)

# Set the CMAKE_MODULE_PATH
LIST (APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
LIST (APPEND CMAKE_MODULE_PATH $ENV{CMAKE_MACROS})
LIST (APPEND CMAKE_MODULE_PATH "$ENV{CMAKE_MACROS}/external")

# Set flag for Shippable CD/CI
if (SHIPPABLE)
  set (SHIPPABLE ON CACHE INTERNAL "Flag for Shippable CD/CI")
  set (SHIPPABLE_SUFFIX "_Shippable" CACHE INTERNAL "Suffix for file versions tailored at working with Shippable CI/CD")
endif (SHIPPABLE)

include(ExternalProject)
include(libFindGeneral)
include(parseDependencies)
include(addNestedDependencies)

# Probelms with RPATH
if ( NOT RPATH_CONFIG )
  include ( General_rpath_config ) 
endif ( NOT RPATH_CONFIG )

# Default flags
if ( USE_MPI )
  include( MPI_Fortran_Flags )
endif ( USE_MPI )

# Check that when using GNU Fortran the free form flag is passed
if ( NOT Fortran_FLAGS_ARE_SET )
  if ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU )
    include( GNU_Fortran_Flags )
  elseif ( CMAKE_Fortran_COMPILER_ID STREQUAL Intel )
    include( Intel_Fortran_Flags )
  endif ( CMAKE_Fortran_COMPILER_ID STREQUAL GNU )
endif ( NOT Fortran_FLAGS_ARE_SET )

# *******************************************
# ************* PRE-PROCESSING **************
# *******************************************

# Find all *fpp files
FILE(GLOB fppFiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/*.fpp")

# Pre-process
FOREACH(infileName ${fppFiles})

    #MESSAGE(STATUS "Process file: ${infileName}")

    # Generate output file name
    STRING(REGEX REPLACE ".fpp\$" ".f90" outfileName "${infileName}")

    SET(outfile "${CMAKE_CURRENT_BINARY_DIR}/${outfileName}")
    #MESSAGE(STATUS "Output file: ${outfile}")

    # Generate input file name
    SET(infile "${CMAKE_CURRENT_SOURCE_DIR}/${infileName}")
    #MESSAGE(STATUS "Input file: ${infile}")

    # Custom command to do the processing
    ADD_CUSTOM_COMMAND(
        OUTPUT "${outfile}"
        COMMAND fypp "${infile}" "${outfile}" -l 100 -f smart
        MAIN_DEPENDENCY "${infile}"
        VERBATIM
        )

    # Finally remember the output file for dependencies
    SET(outFiles ${outFiles} "${outfile}")

ENDFOREACH(infileName)

# *******************************************
# ************  LIBRARY *******************
# *******************************************

# Whether you build a static or shared library
set(LIBRARY_TYPE SHARED)
if (CMAKE_LIBRARY_TYPE)
  set(LIBRARY_TYPE ${CMAKE_LIBRARY_TYPE})
endif (CMAKE_LIBRARY_TYPE)

if (${LIBRARY_TYPE} STREQUAL "STATIC")
  set (CMAKE_LIBRARY_PREFIX ${CMAKE_STATIC_LIBRARY_PREFIX} CACHE INTERNAL "Prefix for CMake libraries")
  set (CMAKE_LIBRARY_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX} CACHE INTERNAL "Suffix for CMake libraries")
elseif (${LIBRARY_TYPE} STREQUAL "SHARED")
  set (CMAKE_LIBRARY_PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX} CACHE INTERNAL "Prefix for CMake libraries")
  set (CMAKE_LIBRARY_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX} CACHE INTERNAL "Suffix for CMake libraries")
endif (${LIBRARY_TYPE} STREQUAL "STATIC")

# Library installation directory
set (CMAKE_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib)

# Header files installation directory
set (CMAKE_INCLUDEDIR ${CMAKE_INSTALL_PREFIX}/include/${LIBRARY_NAME})

# Binary files installation directory
set (CMAKE_BINDIR ${CMAKE_INSTALL_PREFIX}/bin)

# Where do we put the *mod files created during compilation?
set ( CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod_files )

# Find all *f90 files
FILE(GLOB f90Files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
  src/fruit.f90)

# Source files used to build the library
set ( SRC_FILES
  ${outFiles}
  ${f90Files}
  )

# Command to build the library
add_library(
  ${LIBRARY_NAME}
  ${LIBRARY_TYPE} 
  ${SRC_FILES}
)

# Note that library dependencies are transitive by default,
# see https://cmake.org/cmake/help/v3.0/command/target_link_libraries.html, and
# so sub-dependencies are correctly propagated
target_link_libraries ( 
  ${LIBRARY_NAME} 
  ${target_link_libraries_list}
)

# Using the "PUBLIC" attribute allows to correclty propagate the include
# directories dependencies, see https://stackoverflow.com/a/40244458/3294009
# https://cmake.org/cmake/help/v3.6/command/target_include_directories.html
# https://crascit.com/2016/01/31/enhanced-source-file-handling-with-target_sources/
# and especially https://schneide.wordpress.com/2016/04/08/modern-cmake-with-target_link_libraries/
#foreach (include_dir ${include_directories_list})
#include_directories(${include_directories_list})
  target_include_directories(
  ${LIBRARY_NAME} 
  SYSTEM
  PUBLIC
  ${include_directories_list}
  )
  #endforeach (include_dir)

# install library
install(
  TARGETS ${LIBRARY_NAME} 
  ARCHIVE DESTINATION ${CMAKE_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_LIBDIR}
)

# install header (*mod) files
install(
  DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/ 
  DESTINATION ${CMAKE_INCLUDEDIR}
)

# install the configuration file
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/cmake/${LIBRARY_NAME}_meta_info.json
  DESTINATION ${CMAKE_LIBDIR}/pkgconfig
  COMPONENT config
  )

# Set variables which can be used by CMakeLists.txt calling this CMakeLists.txt through a 'add_subdirectory()' command
set ( FRUIT_INCLUDE_DIR ${CMAKE_INCLUDEDIR} CACHE INTERNAL "FRUIT include directory" )
set ( FRUIT_LIBRARIES "${CMAKE_LIBDIR}/${CMAKE_LIBRARY_PREFIX}${LIBRARY_NAME}${CMAKE_LIBRARY_SUFFIX}" CACHE INTERNAL "FRUIT library" )

# *******************************************
# ************* UNINSTALL THE LIBRARY *******
# *******************************************
configure_file(
    "$ENV{CMAKE_MACROS}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake)


# **************************************************
# ************* EXTRACT THE PACKAGE VERSION FROM THE GIT TAG
# **************************************************
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${LIBRARY_NAME}_meta_info.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/cmake/${LIBRARY_NAME}_meta_info.cmake"
)

add_custom_command(TARGET ${LIBRARY_NAME} PRE_BUILD COMMAND cmake -P ${CMAKE_CURRENT_BINARY_DIR}/cmake/${LIBRARY_NAME}_meta_info.cmake)

# *******************************************
# ************* UNIT TESTING **************
# *******************************************
# Find all *test_* files
FILE(GLOB testFiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/tests/*test*")

# Pre-process test files
FOREACH(infileName ${testFiles})

    # Check if the *test_* files needs to be pre-processed
    get_filename_component( EXTENSION ${infileName} EXT )

    if ( "${EXTENSION}" STREQUAL ".fpp" )

      # Generate output file name
      STRING(REGEX REPLACE ".fpp\$" ".f90" outfileName "${infileName}")
      SET(outfile "${CMAKE_CURRENT_BINARY_DIR}/${outfileName}")

      #MESSAGE(STATUS "Output file: ${outfile}")

      # Generate input file name
      SET(infile "${CMAKE_CURRENT_SOURCE_DIR}/${infileName}")

      # Custom command to do the processing
      ADD_CUSTOM_COMMAND(
          OUTPUT "${outfile}"
          COMMAND fypp "${infile}" "${outfile}" -p -l 100 -f smart
          MAIN_DEPENDENCY "${infile}"
          VERBATIM
          )

      # Finally remember the output file for dependencies
      SET(outtestFiles ${outtestFiles} "${outfile}")

    else( )

      SET(infile "${CMAKE_CURRENT_SOURCE_DIR}/${infileName}")
      FILE(COPY ${infile} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/src/tests")

    endif( )

ENDFOREACH(infileName)

# At this point all *test*fpp files and *test*f90 files have been pre-processed (if *fpp) or copied (if *f90) 
# to the CMAKE_CURRENT_BINARY_DIR folder

# Now get all *test_driver* files, which contain the actual unit test programs
FILE(GLOB testFiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/tests/*test_driver.f90" "${CMAKE_CURRENT_SOURCE_DIR}/src/tests/*test_driver.fpp" )

enable_testing( )

FOREACH(infileName ${testFiles})

    # Generate output file name
    #MESSAGE(STATUS "")
    STRING(REGEX REPLACE "_test_driver.+" "" outfileName "${infileName}")
    #MESSAGE(STATUS "outfileName: ${outfileName}")

    SET(modulefile "${outfileName}_test.f90")
    SET(inputfile "${outfileName}_test_driver.f90")

    get_filename_component( execFile ${outfileName} NAME )
    SET(execFile "test_${execFile}")

    #MESSAGE(STATUS "execFile: ${execFile}")
    #MESSAGE(STATUS "moduleFile: ${modulefile}")
    #MESSAGE(STATUS "infileName: ${infileName}")

    if (COMPILE_TESTS)
      add_executable( ${execFile} ${modulefile} ${inputfile} )
      target_link_libraries( ${execFile} ${LIBRARY_NAME} )
      add_test( ${execFile} ${execFile} )
    endif (COMPILE_TESTS)

ENDFOREACH(infileName)

