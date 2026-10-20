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

## GitHub Action

The GR projects no longer build these dependencies inside their own CMake graph, so their CI has to
build them first. This repository is a composite action that does that and caches the result:

```yaml
steps:
  - uses: actions/checkout@v4

  - id: deps
    uses: johnwparent/gnuradio4-superbuild@main
    with:
      target-gr-blocks: ON

  # CMAKE_PREFIX_PATH now includes the prefix, so this finds the dependencies without extra flags
  - run: cmake -S . -B build && cmake --build build
```

On a cache miss the action configures and builds the superbuild, then saves the install prefix. On
a hit it restores the prefix and builds nothing. Either way, later steps in the job see the same
prefix.

### Inputs

Each toggle takes `ON` or `OFF` (or `true`/`false`, `yes`/`no`, `1`/`0`) and mirrors the CMake
option of the same name. An empty dependency toggle follows its group, as the CMake default does.

| Input | Default | CMake option |
| --- | --- | --- |
| `target-gr-core` | `ON` | `TARGET_GR_CORE` |
| `target-gr-blocks` | `OFF` | `TARGET_GR_BLOCKS` |
| `enable-vir-simd` | follows `target-gr-core` | `ENABLE_VIR_SIMD` |
| `enable-httplib` | follows `target-gr-core` | `ENABLE_HTTPLIB` |
| `enable-boost-ut` | follows `target-gr-core` | `ENABLE_BOOST_UT` |
| `enable-soapy-sdr` | follows `target-gr-blocks` | `ENABLE_SOAPY_SDR` |
| `enable-tbb` | `OFF` | `ENABLE_TBB` |
| `enable-python3` | follows `target-gr-core` | `ENABLE_PYTHON3` |
| `build-type` | `Release` | `GR_DEPS_BUILD_TYPE` |
| `msvc-runtime-static` | `OFF` | `GR_DEPS_MSVC_RUNTIME_STATIC` |
| `msvc-runtime-debug` | `DEFAULT` | `GR_DEPS_MSVC_RUNTIME_DEBUG` |

The toolchain and the build itself:

| Input | Default | Effect |
| --- | --- | --- |
| `generator` | CMake's default | passed as `-G` |
| `c-compiler` | the default | exported as `CC` to the dependency builds |
| `cxx-compiler` | the default | exported as `CXX` to the dependency builds |
| `cmake-args` | none | extra superbuild configure arguments, one per line |
| `install-prefix` | `<runner.temp>/gr-deps` | where the dependencies install, and what is cached |
| `build-dir` | `<runner.temp>/gr-deps-build` | superbuild binary directory, not cached |
| `cache` | `true` | `false` always builds and neither restores nor saves |
| `cache-key-prefix` | `gr-deps-v1` | first part of the key; change it to throw every entry away |
| `export-env` | `true` | see below |

Compilers are set through `CC` and `CXX`, not `-DCMAKE_CXX_COMPILER`, because the superbuild is
`LANGUAGES NONE`. The subprojects take their compiler from the environment, not from the
superbuild's cache. For the same reason, `cmake-args` only sets superbuild cache variables.

### Outputs and environment

| Output | Value |
| --- | --- |
| `install-prefix` | absolute path of the prefix |
| `cache-hit` | `true` when the prefix was restored and nothing was built |
| `cache-key` | the key that was restored or saved |
| `toolchain` | the C and C++ compiler IDs and versions that were found |

With `export-env` on, later steps also get:

- `GR_DEPS_PREFIX` set to the prefix
- the prefix prepended to `CMAKE_PREFIX_PATH`
- `<prefix>/bin` added to `PATH`, so a test executable finds `SoapySDR.dll` on Windows

### The cache key

A key looks like

```
gr-deps-v1-ubuntu24-X64-GNU-13.3.0-Release-vir1-http1-ut1-soapy1-tbb0-py1-3f9c0a17d2b84e61
```

The readable part names the runner image, architecture, C++ compiler, build type and selected
dependencies. The trailing hash covers everything that can change the installed files:

- **Selection.** The resolved toggles, not the group inputs. `target-gr-core: ON` and three explicit
  `enable-*: ON` inputs build the same thing, so they share one entry.
- **Toolchain.** The C and C++ compiler IDs and versions and the target processor. The superbuild
  enables no languages itself, so the action finds these by configuring a throwaway project with
  the same generator, `CC` and `CXX`. A runner image that upgrades its compiler gets a new entry.
- **Platform.** `runner.os`, `runner.arch`, and the image (`ImageOS`, e.g. `ubuntu22` vs `ubuntu24`).
- **Build settings.** Generator, build type, MSVC runtime settings, `cmake-args`, and the
  install prefix.
- **Recipes.** A hash of `CMakeLists.txt`, `deps/*.cmake` and `action.yml`, so moving a pin or
  changing a build flag rebuilds.

Restores need an exact match: there are no `restore-keys`. A partial match would restore a prefix
built for a different selection, and the stale extra dependencies would then be saved under the
new key.

### Platform notes

- **Windows with Ninja** needs the MSVC environment set up first, for example with
  `ilammy/msvc-dev-cmd`. The default Visual Studio generator does not. If no working compiler is
  found, the action stops with an error before building anything.
- **Multi-config generators** are built with `--config <build-type>`. Without it, ExternalProject
  builds and installs each dependency in the superbuild's own default configuration (`Debug` for
  Visual Studio), whatever `GR_DEPS_BUILD_TYPE` says.
- **TBB and Python** are only located, never installed. Install TBB first if you enable it (it is
  `REQUIRED`). For the Python pieces, set up Python 3.12 and NumPy first. On a cache hit the
  configure is skipped, so neither is looked for.
- **A custom `install-prefix` should be empty.** The action clears its own default prefix and build
  directory before building, but leaves any path you give it alone. Anything already there would
  be cached along with the build.

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
