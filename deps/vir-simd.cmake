# vir-simd: header-only SIMD wrapper, pinned by gr-core's FetchContent_Declare.
# Installs its own CMake package (vir-simd-config), so a consumer finds it with find_package(vir-simd).
if(ENABLE_VIR_SIMD)
  ExternalProject_Add(
    vir-simd
    GIT_REPOSITORY https://github.com/mattkretz/vir-simd.git
    GIT_TAG v0.4.4
    GIT_SHALLOW TRUE
    INSTALL_DIR "${GR_DEPS_INSTALL_PREFIX}"
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS ${GR_DEPS_INSTALL_ARGS} ${GR_DEPS_MSVC_RUNTIME_ARGS}
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
    USES_TERMINAL_INSTALL TRUE)
endif()
