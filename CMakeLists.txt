# ------------------------------------------------------------
# Minimum CMake version required
# ------------------------------------------------------------
cmake_minimum_required(VERSION 3.20)

# ------------------------------------------------------------
# TOOLCHAIN CONFIGURATION
# ------------------------------------------------------------

# Define the root path to your build_tools submodule
set(TOOLS_DIR "${CMAKE_SOURCE_DIR}/build_tools")

# Force CMake to use the compilers inside your submodule
set(CMAKE_C_COMPILER   "${TOOLS_DIR}/MinGW/bin/gcc.exe")
set(CMAKE_CXX_COMPILER "${TOOLS_DIR}/MinGW/bin/g++.exe")
set(CMAKE_MAKE_PROGRAM "${TOOLS_DIR}/ninja-win/ninja.exe") 

# Locate objcopy for HEX/BIN generation
set(CMAKE_OBJCOPY      "${TOOLS_DIR}/MinGW/bin/objcopy.exe")

# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------
# If no project is selected via the command line (e.g. -DSELECTED_PROJECT=MyProj)
if(NOT DEFINED SELECTED_PROJECT OR "${SELECTED_PROJECT}" STREQUAL "")
    message(FATAL_ERROR "No project selected! You must run CMake with -DSELECTED_PROJECT=<ProjectFolderName>")
endif()

# Initialize the project
project(${SELECTED_PROJECT} C CXX)

# -----------------------------------------------------------------------------
# SOURCE CONFIGURATION (CRITICAL FIX)
# -----------------------------------------------------------------------------
# Point specifically to the selected project's folder
set(PROJ_SOURCE_DIR "${CMAKE_SOURCE_DIR}/src/${SELECTED_PROJECT}")

if(NOT EXISTS ${PROJ_SOURCE_DIR})
    message(FATAL_ERROR "Project directory not found: ${PROJ_SOURCE_DIR}")
endif()

# ------------------------------------------------------------
# Define Build Type
# ------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "CMAKE_BUILD_TYPE is not set. Defaulting to Debug.")
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")

# ------------------------------------------------------------
# Output Directories
# ------------------------------------------------------------
# Output path: build/bin/Debug/MyApp.exe
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ------------------------------------------------------------
# Compiler Flags
# ------------------------------------------------------------
add_compile_options(
    -Wall
    -Wextra
    -g
    -O0
)

# ------------------------------------------------------------
# Source Files (CRITICAL FIX)
# ------------------------------------------------------------
# Only find files inside the SPECIFIC project folder
file(GLOB_RECURSE PROJECT_SOURCES
    "${PROJ_SOURCE_DIR}/*.cpp"
    "${PROJ_SOURCE_DIR}/*.c"
)

# Only find headers inside the SPECIFIC project folder
file(GLOB_RECURSE PROJECT_HEADERS
    "${PROJ_SOURCE_DIR}/*.hpp"
    "${PROJ_SOURCE_DIR}/*.h"
)

# ------------------------------------------------------------
# Add Executable
# ------------------------------------------------------------
add_executable(${PROJECT_NAME}
    ${PROJECT_SOURCES}
    ${PROJECT_HEADERS}
)

# --------------------------------------------------------------------
# Link Statically to avoid "Missing DLL" errors
# This embeds libgcc and libstdc++ into the .exe so it is standalone.
# --------------------------------------------------------------------
if(MINGW OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    target_link_options(${PROJECT_NAME} PRIVATE 
        -static
    )
endif()

# ------------------------------------------------------------
# Include Directories
# ------------------------------------------------------------
# Add the specific project folder AND the root src folder to include paths
target_include_directories(${PROJECT_NAME} PRIVATE 
    ${PROJ_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

# ------------------------------------------------------------
# Post-Build Steps: Generate HEX and BIN files
# ------------------------------------------------------------
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    # 1. Generate Intel HEX file
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}> ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.hex
    
    # 2. Generate Raw Binary file
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}> ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.bin
    
    # 3. Print size information
    COMMAND echo "------------------------------------------------"
    COMMAND echo "Build artifact location: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
    COMMAND echo "Generated: ${PROJECT_NAME}.exe, .hex, .bin"
    COMMAND echo "------------------------------------------------"
    
    COMMENT "Post-build: Generating HEX and BIN files..."
)