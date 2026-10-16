cmake_minimum_required(VERSION 3.21..4.5)

project(GR_DEPS LANGUAGES NONE)

include(ExternalProject)

# target groups
option(TARGET_GR_CORE "Build dependencies needed for core GR development" ON)
option(TARGET_GR_BLOCKS "Build dependencies needed for GR Blocks development" OFF)

# individual dependencies, batch enabled by group
# core requirements, each individually togglable, enabled by group
option(ENABLE_VIR_SIMD "Build vir-simd subproject" ${TARGET_GR_CORE})
option(ENABLE_HTTPLIB "Build cpp-httplib subproject" ${TARGET_GR_CORE})
option(ENABLE_BOOST_UT "Build boost.ut subproject" ${TARGET_GR_CORE})

option(ENABLE_SOAPY_SDR "Build soapysdr" ${TARGET_GR_BLOCKS})

# located rather than built: both are toolchain or system provided
option(ENABLE_TBB "Locate TBB, for std::execution::par under libstdc++" OFF)
option(ENABLE_PYTHON3 "Locate CPython and NumPy" ${TARGET_GR_CORE})

# every subproject installs here, and every subproject searches here, so that a dependency that
# needs another one finds the copy this superbuild just installed
set(GR_DEPS_INSTALL_PREFIX
    "${CMAKE_INSTALL_PREFIX}"
    CACHE PATH "Shared install prefix for every dependency built here")

set(GR_DEPS_BUILD_TYPE
    "${CMAKE_BUILD_TYPE}"
    CACHE STRING "Build type used for every dependency built here")
if(NOT GR_DEPS_BUILD_TYPE)
  set(GR_DEPS_BUILD_TYPE Release)
endif()

# MSVC runtime. A dependency that links a different C runtime than the GR project consuming it ends
# up with a second heap and a second set of CRT globals, so the choice is forced on every subproject
# rather than left to each one's own default.
option(GR_DEPS_MSVC_RUNTIME_STATIC "Link the static MSVC runtime (/MT) rather than the DLL runtime (/MD)" OFF)
set(GR_DEPS_MSVC_RUNTIME_DEBUG
    "DEFAULT"
    CACHE STRING "Debug MSVC runtime (/MDd, /MTd): ON, OFF, or DEFAULT to follow GR_DEPS_BUILD_TYPE")
set_property(
  CACHE GR_DEPS_MSVC_RUNTIME_DEBUG
  PROPERTY STRINGS
           DEFAULT
           ON
           OFF)

if(GR_DEPS_MSVC_RUNTIME_DEBUG STREQUAL "DEFAULT")
  if(GR_DEPS_BUILD_TYPE STREQUAL "Debug")
    set(gr_deps_runtime_debug ON)
  else()
    set(gr_deps_runtime_debug OFF)
  endif()
else()
  set(gr_deps_runtime_debug ${GR_DEPS_MSVC_RUNTIME_DEBUG})
endif()

set(GR_DEPS_MSVC_RUNTIME_LIBRARY "MultiThreaded")
if(gr_deps_runtime_debug)
  string(APPEND GR_DEPS_MSVC_RUNTIME_LIBRARY "Debug")
endif()
if(NOT GR_DEPS_MSVC_RUNTIME_STATIC)
  string(APPEND GR_DEPS_MSVC_RUNTIME_LIBRARY "DLL")
endif()

# CMAKE_MSVC_RUNTIME_LIBRARY is honoured only under CMP0091 NEW, and a project gets that policy
# from its own cmake_minimum_required. SoapySDR declares 3.3...3.10, vir-simd 3.5 and cpp-httplib
# 3.14, all below the 3.15 that introduced it, so without this the setting is silently ignored by
# the one dependency here that compiles anything.
set(GR_DEPS_MSVC_RUNTIME_ARGS -DCMAKE_MSVC_RUNTIME_LIBRARY=${GR_DEPS_MSVC_RUNTIME_LIBRARY}
                              -DCMAKE_POLICY_DEFAULT_CMP0091=NEW)

# set CMake module path so includes look slightly nicer
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/deps)

include(deps)

message(STATUS "")
message(STATUS "gr-deps install prefix : ${GR_DEPS_INSTALL_PREFIX}")
message(STATUS "  vir-simd             : ${ENABLE_VIR_SIMD}")
message(STATUS "  cpp-httplib          : ${ENABLE_HTTPLIB}")
message(STATUS "  boost.ut             : ${ENABLE_BOOST_UT}")
message(STATUS "  SoapySDR             : ${ENABLE_SOAPY_SDR}")
message(STATUS "  TBB (located)        : ${ENABLE_TBB}")
message(STATUS "  Python3 (located)    : ${ENABLE_PYTHON3}")
message(STATUS "gr-deps build type     : ${GR_DEPS_BUILD_TYPE}")
message(STATUS "gr-deps MSVC runtime   : ${GR_DEPS_MSVC_RUNTIME_LIBRARY}")
message(STATUS "")
