iree_setup_c_src_root(
  PACKAGE_ROOT_PREFIX iree::compiler::bindings::c
  DEFAULT_EXPORT_SET Compiler
  DEFAULT_INSTALL_COMPONENT IREEDevLibraries-Compiler
)

### BAZEL_TO_CMAKE_PRESERVES_ALL_CONTENT_ABOVE_THIS_LINE ###
################################################################################
# Autogenerated by build_tools/bazel_to_cmake/bazel_to_cmake.py from           #
# compiler/bindings/c/BUILD.bazel                                              #
#                                                                              #
# Use iree_cmake_extra_content from iree/build_defs.oss.bzl to add arbitrary   #
# CMake-only content.                                                          #
#                                                                              #
# To disable autogeneration for this file entirely, delete this header.        #
################################################################################

iree_add_all_subdirs()

iree_cc_library(
  NAME
    headers
  HDRS
    "iree/compiler/api_support.h"
    "iree/compiler/dialects/iree_codegen.h"
    "iree/compiler/dialects/iree_gpu.h"
    "iree/compiler/embedding_api.h"
    "iree/compiler/loader.h"
    "iree/compiler/mlir_interop.h"
    "iree/compiler/tool_entry_points_api.h"
  DEPS
    IREELLVMIncludeSetup
  INCLUDES
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/.>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/.>"
  PUBLIC
)

iree_cc_library(
  NAME
    loader
  SRCS
    "iree/compiler/loader/handle_symbols.inc"
    "iree/compiler/loader/loader.cpp"
  DEPS
    ${CMAKE_DL_LIBS}
    ::headers
  PUBLIC
)

### BAZEL_TO_CMAKE_PRESERVES_ALL_CONTENT_BELOW_THIS_LINE ###

# TODO: Make this test work with Bazel once that is more solid.

if(IREE_HAVE_DYNAMIC_LIBRARY_LOADING)
  # Dynamic library loading enabled.
  if(IREE_BUILD_COMPILER AND IREE_BUILD_TESTS)
      iree_cc_test(
      NAME
          loader_test
      SRCS
          "iree/compiler/loader/loader_test.c"
      ARGS
          "$<TARGET_FILE:iree::compiler::API::SharedImpl>"
      DEPS
          ::loader
      )

      # Must be a build dependency but not a library dep (we depend on it at
      # runtime).
      # TODO: Find a better way to do this.
      add_dependencies(
          iree_compiler_bindings_c_loader_test
          iree::compiler::API::SharedImpl
      )
  endif()
else()
  # Dynamic library loading not available. Exclude loader from all.
  message(STATUS "Disabling compiler loader (platform does not support library loading)")
  iree_cc_library_exclude_from_all(loader TRUE)
endif()

# Install public mlir-c headers (since we export them from our library).
# Scan the MLIR_INCLUDE_DIRS and install any that contains mlir-c. This
# will work for both bundled and installed LLVM.
# We could filter this, but it is just some C headers and easier to include
# them all.
foreach(_d ${MLIR_INCLUDE_DIRS})
  if(EXISTS "${_d}/mlir-c")
    install(
      DIRECTORY "${_d}/mlir-c"
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
      COMPONENT IREEDevLibraries-Compiler
      EXCLUDE_FROM_ALL
    )
  endif()
endforeach()
