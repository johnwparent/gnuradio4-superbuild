# TBB: gr-core links TBB::tbb when its own ENABLE_TBB is on, to give libstdc++ a parallel backend
# for std::execution::par. Toolchain or distribution provided, so this locates it rather than
# building it.
if(ENABLE_TBB)
  find_package(TBB REQUIRED)
endif()
