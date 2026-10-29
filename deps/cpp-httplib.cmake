# cpp-httplib: pinned by gr-core's FetchContent_Declare, which fetches it only under Emscripten and
# otherwise expects find_package(httplib CONFIG) or pkg-config to supply it. Built here so that the
# non-Emscripten path has something to find.
#
# Left header-only (HTTPLIB_COMPILE OFF, the upstream default): that is the form gr-core and
# gr-library consume through the httplib::httplib interface target.
if(ENABLE_HTTPLIB)
  ExternalProject_Add(
    cpp-httplib
    GIT_REPOSITORY https://github.com/yhirose/cpp-httplib.git
    GIT_TAG v0.18.1
    GIT_SHALLOW TRUE
    INSTALL_DIR "${GR_DEPS_INSTALL_PREFIX}"
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS ${GR_DEPS_INSTALL_ARGS} ${GR_DEPS_MSVC_RUNTIME_ARGS} 
               -DHTTPLIB_INSTALL=ON
               -DHTTPLIB_TEST=OFF
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
    USES_TERMINAL_INSTALL TRUE)
endif()
