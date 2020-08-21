cmake_minimum_required(VERSION 3.15)
project(ImageMetalling_17)

set (PLUGIN_ID "com.imetalling.false_color")
set (PLUGIN_BUNDLE_NAME "IMFalseColor")
set (PLUGIN_BUNDLE_INSTALATION_PATH "/Library/OFX/Plugins/${PLUGIN_BUNDLE_NAME}.ofx.bundle")

#
# CXX 1x
#
set (CMAKE_CXX_STANDARD 17)
set (BUILD_SHARED_LIBS OFF)
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wc++17-extensions")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdeclspec -fms-extensions")
# disable developer warnings
set (CMAKE_POLICY_DEFAULT_CMP0054 NEW)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ObjC++ -fvisibility=hidden -Wno-unused-command-line-argument -F/Library/Frameworks ")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework Metal")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework MetalKit")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework MetalPerformanceShaders")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework Foundation ")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework Cocoa")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -framework Security")

#
# CMAKE Options
#
option(QT_INSTALLER_PREFIX /usr/local/QtInstaller/bin)
option(QT_INSTALLER_ON OFF)
option(DEHANCER_RESIGN_RESOURCES OFF)
option(MACDEPLOY OFF)
option(BUILD_PRO_ONLY OFF)
option(BUILD_TESTING OFF)
option(PRINT_DEBUG ON)


if(PRINT_DEBUG)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DPRINT_DEBUG=1")
endif()

#
# External projects
#
include(ExternalProject)

find_package (PkgConfig REQUIRED)
find_package (Qt5Core REQUIRED)
find_package (Qt5Gui REQUIRED)
find_package (Qt5Widgets REQUIRED)
find_package (BLAS REQUIRED)
find_package (LAPACK REQUIRED)

add_definitions(-DCURL_STATICLIB )


if(NOT PKG_CONFIG_FOUND)
    message(FATAL_ERROR "pkg-config not found!" )
    message(FATAL_ERROR "sudo apt-get install pkg-config, or brew install pkg-config")
endif()

set (CURRENT_METAL_TARGET_NAME ImageMetallingKernel)
set (CURRENT_METAL_TARGET_LIB ${CURRENT_METAL_TARGET_NAME}.metallib)
set (COMMON_DEPENDECIES ${CURRENT_METAL_TARGET_NAME})
set (COMMON_LIBRARIES)

string(TIMESTAMP TODAY "%Y-%m-%d")

message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})
message(STATUS "METAL_FLAGS: " ${METAL_FLAGS})

set (CMAKE_OSX_DEPLOYMENT_TARGET $ENV{MACOSX_DEPLOYMENT_TARGET})
set (CMAKE_INSTALL_PREFIX "/Library/OFX/Plugins")
set (EXTERNAL_INSTALL_LOCATION ${CMAKE_BINARY_DIR}/external)


#
# OFX
#
ExternalProject_Add(ofx_lib
        GIT_REPOSITORY https://github.com/dehancer/dehancer-external
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DBUILD_TESTING=OFF
        -DPRINT_DEBUG=${PRINT_DEBUG}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};ofx_lib)
set(COMMON_LIBRARIES ${COMMON_LIBRARIES};OpenFXS)

#
# Common
#
ExternalProject_Add(dehancer_common_cpplib
        GIT_REPOSITORY https://github.com/dehancer/dehancer-common-cpp
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${DCMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};dehancer_common_cpplib)
set(COMMON_LIBRARIES  ${COMMON_LIBRARIES};dehancer_common_cpp)

#
# Maths
#
ExternalProject_Add(dehancer_maths_cpplib
        GIT_REPOSITORY https://github.com/dehancer/dehancer-maths-cpp
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${DCMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};dehancer_maths_cpplib)
set(COMMON_LIBRARIES  ${COMMON_LIBRARIES};dehancer_maths_cpp)

link_directories(
        ${CMAKE_BINARY_DIR}/external/lib
)

include_directories(
        ${CMAKE_SOURCE_DIR}/ofx/lib
        ${CMAKE_SOURCE_DIR}/ofx/lib/kernels
        ${CMAKE_CURRENT_BINARY_DIR}/generated
        ${CMAKE_BINARY_DIR}/external/include
        ${CMAKE_BINARY_DIR}/external/include/openfx
        ./
)

set(COMMON_LIBRARIES
        ${COMMON_LIBRARIES};
        ${BLAS_LIBRARIES};${LAPACK_LIBRARIES})

add_subdirectory(ofx)