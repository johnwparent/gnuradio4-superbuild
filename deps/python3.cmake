# CPython and NumPy: gr-core looks for the same version and components and treats the result as
# optional, enabling its Python-facing pieces only when all three are present. Located, not built,
# and deliberately not REQUIRED so that a machine without NumPy still configures.
if(ENABLE_PYTHON3)
  find_package(Python3 3.12 COMPONENTS Interpreter Development NumPy)
  if(NOT Python3_FOUND)
    message(STATUS "Python3 3.12 with Development and NumPy not found: the Python-facing parts of gr-core stay off")
  endif()
endif()
