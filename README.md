# gr-deps

A CMake superbuild for the third-party dependencies of GNU Radio 4.

`gr-super` builds the GNU Radio projects themselves. This builds what they depend on, into one
install prefix, with one toolchain and one MSVC runtime, so that a GR project configured against
that prefix gets a consistent set.

Each dependency is declared in its own module under `deps/`, and each module is self-contained:
there is deliberately no shared helper yet.

## Quick start

```sh
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/path/to/prefix
cmake --build build
```

Then point the GR projects at it:

```sh
cmake -S ../gr-core -B ../gr-core/build -DCMAKE_PREFIX_PATH=/path/to/prefix
```

Dependencies are built on demand, so `cmake --build build --target boost.ut` builds just that one.

## What is built, and what is only located

Built from source, each pinned to the revision the GR repositories themselves fetch:

| Target | Source | Pin | Used by |
| --- | --- | --- | --- |
| `vir-simd` | mattkretz/vir-simd | `v0.4.4` | gr-core |
| `boost.ut` | boost-ext/ut | `53e17f25` | gr-core, gr-library, gr-blocks |
| `cpp-httplib` | yhirose/cpp-httplib | `v0.18.1` | gr-core, gr-library |
| `soapysdr` | pothosware/SoapySDR | `soapy-sdr-0.9.0` | gr-blocks |

Located with `find_package`, never built, because they are toolchain or distribution provided:

| Module | Call |
| --- | --- |
| `deps/tbb.cmake` | `find_package(TBB REQUIRED)` |
| `deps/python3.cmake` | `find_package(Python3 3.12 COMPONENTS Interpreter Development NumPy)` |

Python3 is intentionally not `REQUIRED`, matching gr-core, which enables its Python-facing pieces
only when the interpreter, the development files and NumPy are all present.

## Options

Groups, which set the defaults for the individual toggles:

| Option | Default | Effect |
| --- | --- | --- |
| `TARGET_GR_CORE` | `ON` | the dependencies gr-core needs |
| `TARGET_GR_BLOCKS` | `OFF` | the dependencies gr-blocks needs |

Individual dependencies, each overridable on its own:

| Option | Default |
| --- | --- |
| `ENABLE_VIR_SIMD` | `${TARGET_GR_CORE}` |
| `ENABLE_HTTPLIB` | `${TARGET_GR_CORE}` |
| `ENABLE_BOOST_UT` | `${TARGET_GR_CORE}` |
| `ENABLE_SOAPY_SDR` | `${TARGET_GR_BLOCKS}` |
| `ENABLE_TBB` | `OFF` |
| `ENABLE_PYTHON3` | `${TARGET_GR_CORE}` |

Build-wide:

| Option | Default | Effect |
| --- | --- | --- |
| `GR_DEPS_INSTALL_PREFIX` | `${CMAKE_INSTALL_PREFIX}` | where every dependency installs |
| `GR_DEPS_BUILD_TYPE` | `${CMAKE_BUILD_TYPE}`, else `Release` | build type for every dependency |

## The install prefix

Every subproject is configured with both

- `-DCMAKE_INSTALL_PREFIX=${GR_DEPS_INSTALL_PREFIX}`, so everything lands in one tree, and
- `-DCMAKE_PREFIX_PATH=${GR_DEPS_INSTALL_PREFIX}`, so a dependency that needs an earlier one finds
  the copy this superbuild just installed rather than a system copy.

After a build the prefix looks like a normal install root, and the CMake packages the GR projects
look for are in it:

```
<prefix>/include/boost/ut.hpp
<prefix>/include/vir/
<prefix>/lib/cmake/ut/utConfig.cmake
<prefix>/lib/cmake/vir-simd/vir-simd-config.cmake
```

## MSVC runtime

Mixing C runtimes across a program is a real failure, not a warning: memory allocated by one CRT
and freed by another, two sets of CRT globals, two `errno`. Every subproject is therefore forced
onto one runtime rather than left to its own default.

| Option | Default | Effect |
| --- | --- | --- |
| `GR_DEPS_MSVC_RUNTIME_STATIC` | `OFF` | `ON` selects the static runtime (`/MT`), `OFF` the DLL runtime (`/MD`) |
| `GR_DEPS_MSVC_RUNTIME_DEBUG` | `DEFAULT` | `DEFAULT` follows `GR_DEPS_BUILD_TYPE`; `ON` or `OFF` decides it independently |

Which resolves to:

| Build type | Static | Runtime | Flag |
| --- | --- | --- | --- |
| Release | `OFF` | `MultiThreadedDLL` | `/MD` |
| Debug | `OFF` | `MultiThreadedDebugDLL` | `/MDd` |
| Release | `ON` | `MultiThreaded` | `/MT` |
| Debug | `ON` | `MultiThreadedDebug` | `/MTd` |

The resolved value is printed at the end of configure, and the override exists because a debug
build against a release runtime is occasionally what you want when matching a prebuilt library.

**Why the policy is forced.** `CMAKE_MSVC_RUNTIME_LIBRARY` is only honoured under `CMP0091` set to
`NEW`, and a project inherits that policy from its own `cmake_minimum_required`. SoapySDR declares
`3.3...3.10`, vir-simd `3.5` and cpp-httplib `3.14` — all below the 3.15 that introduced the
policy. Without `-DCMAKE_POLICY_DEFAULT_CMP0091=NEW` the runtime setting would be accepted and then
silently ignored by the one dependency here that compiles anything. Both arguments are passed
together, from `GR_DEPS_MSVC_RUNTIME_ARGS`.

The setting is harmless on non-MSVC toolchains, which ignore it.

## Notes

- **The SoapySDR pin is a choice, not a requirement.** Nothing in gr-blocks states a version; it
  only does `find_package(SoapySDR CONFIG QUIET)` and links the `SoapySDR` target. This tracks the
  newest release tag. Change `GIT_TAG` in `deps/soapysdr.cmake` if you need a specific one.
- **cpp-httplib is built even though gr-core only fetches it under Emscripten.** Elsewhere gr-core
  expects `find_package(httplib CONFIG)` or pkg-config to supply it, so building it here is what
  gives that path something to find. It stays header-only (`HTTPLIB_COMPILE=OFF`), which is the
  form gr-core and gr-library consume through `httplib::httplib`.
- **Boost.UT's toggles are set explicitly.** `BOOST_UT_BUILD_TESTS`, `BOOST_UT_BUILD_EXAMPLES` and
  `BOOST_UT_ENABLE_INSTALL` all default to `PROJECT_IS_TOP_LEVEL`, which is false when the GR repos
  fetch it as a subproject but true here, so leaving them unset would build its test suite.
- **SoapySDR's SWIG bindings** build only when SWIG and Python are found. This superbuild provides
  neither, so only the library and its CMake package are installed.
