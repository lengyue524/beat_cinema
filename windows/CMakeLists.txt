# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(beat_cinema LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "beat_cinema")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Full LGPL libmpv override (enables audio filters: pan, lavfi, etc.) ===
# The default media_kit build strips audio filters for size. We replace it with
# zhongfly/mpv-winbuild's LGPL build that includes them.
set(CUSTOM_LIBMPV_7Z "mpv-dev-lgpl-x86_64-20260320-git-7b1ee86.7z")
set(CUSTOM_LIBMPV_URL "https://github.com/zhongfly/mpv-winbuild/releases/download/2026-03-20-7b1ee86/${CUSTOM_LIBMPV_7Z}")
set(CUSTOM_LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${CUSTOM_LIBMPV_7Z}")
set(CUSTOM_LIBMPV_DIR "${CMAKE_BINARY_DIR}/libmpv-full")

if(NOT EXISTS "${CUSTOM_LIBMPV_ARCHIVE}")
  message(STATUS "Downloading full LGPL libmpv from zhongfly/mpv-winbuild...")
  file(DOWNLOAD
    "${CUSTOM_LIBMPV_URL}" "${CUSTOM_LIBMPV_ARCHIVE}"
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=305643e2b4630530c944a12cb9e535bab7156621b749f09b2aea4482dfaa4bd9
  )
endif()

if(NOT EXISTS "${CUSTOM_LIBMPV_DIR}/libmpv-2.dll")
  make_directory("${CUSTOM_LIBMPV_DIR}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xf "${CUSTOM_LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${CUSTOM_LIBMPV_DIR}"
  )
endif()

# Overwrite the stripped DLL in the plugin's extraction directory at configure time
# so the normal PLUGIN_BUNDLED_LIBRARIES install picks up the full version.
if(EXISTS "${CMAKE_BINARY_DIR}/libmpv/libmpv-2.dll")
  file(COPY_FILE
    "${CUSTOM_LIBMPV_DIR}/libmpv-2.dll"
    "${CMAKE_BINARY_DIR}/libmpv/libmpv-2.dll"
  )
endif()

# Also override at build time (handles first build where plugin extracts after configure).
add_custom_target(override_libmpv ALL
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
    "${CUSTOM_LIBMPV_DIR}/libmpv-2.dll"
    "${CMAKE_BINARY_DIR}/libmpv/libmpv-2.dll"
)

# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

# Remove read-only attribute from previously installed binaries to allow overwrite.
install(CODE "
  foreach(_cfg Debug Profile Release)
    set(_dir \"${CMAKE_BINARY_DIR}/runner/\${_cfg}\")
    if(EXISTS \"\${_dir}\")
      file(GLOB _files \"\${_dir}/*.dll\" \"\${_dir}/*.exe\")
      foreach(_f \${_files})
        execute_process(COMMAND cmd /c attrib -R \"\${_f}\" OUTPUT_QUIET ERROR_QUIET)
      endforeach()
    endif()
  endforeach()
" COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

