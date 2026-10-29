# Boost.UT: header-only test framework, pinned to the revision all three GR repos fetch.
#
# BOOST_UT_DISABLE_MODULE matches what gr-core, gr-library and gr-blocks force in their own caches.
# The remaining toggles default to PROJECT_IS_TOP_LEVEL, which is true here but false when the GR
# repos fetch it as a subproject, so examples, tests and install are set explicitly.
if(ENABLE_BOOST_UT)
  ExternalProject_Add(
    boost.ut
    GIT_REPOSITORY https://github.com/boost-ext/ut.git
    GIT_TAG 53e17f25119598c6458d30351b260193096ba67e
    INSTALL_DIR "${GR_DEPS_INSTALL_PREFIX}"
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS ${GR_DEPS_INSTALL_ARGS} ${GR_DEPS_MSVC_RUNTIME_ARGS} 
               -DBOOST_UT_DISABLE_MODULE=ON
               -DBOOST_UT_BUILD_EXAMPLES=OFF
               -DBOOST_UT_BUILD_TESTS=OFF
               -DBOOST_UT_BUILD_BENCHMARKS=OFF
               -DBOOST_UT_ENABLE_INSTALL=ON
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
    USES_TERMINAL_INSTALL TRUE)
endif()
