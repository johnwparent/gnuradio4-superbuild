# SoapySDR: gr-blocks reaches it through find_package(SoapySDR CONFIG) and links the SoapySDR
# target. Nothing in gr-blocks pins a version, so this tracks the newest release tag.
#
# Only the library is wanted: the apps, tests and docs are not consumed, and the SWIG bindings
# build only when SWIG and Python are found, which this superbuild does not provide.
if(ENABLE_SOAPY_SDR)
  ExternalProject_Add(
    soapysdr
    GIT_REPOSITORY https://github.com/pothosware/SoapySDR.git
    GIT_TAG soapy-sdr-0.9.0
    GIT_SHALLOW TRUE
    INSTALL_DIR "${GR_DEPS_INSTALL_PREFIX}"
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS ${GR_DEPS_INSTALL_ARGS} ${GR_DEPS_MSVC_RUNTIME_ARGS} 
               -DENABLE_LIBRARY=ON
               -DENABLE_APPS=OFF
               -DENABLE_TESTS=OFF
               -DENABLE_DOCS=OFF
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
    USES_TERMINAL_INSTALL TRUE)
endif()
