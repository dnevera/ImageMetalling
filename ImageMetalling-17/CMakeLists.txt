cmake_minimum_required(VERSION 3.17)
project(ImageMetalling_17)

#
# CXX 1x
#
set (CMAKE_CXX_STANDARD 17)
set (BUILD_SHARED_LIBS OFF)
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wc++17-extensions")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdeclspec -fms-extensions")
# disable developer warnings
set(CMAKE_POLICY_DEFAULT_CMP0054 NEW)

#
# CMAKE Options
#
option(QT_INSTALLER_PREFIX /usr/local/QtInstaller/bin)
option(QT_INSTALLER_ON OFF)
option(INSTALL_ON OFF)
option(DEHANCER_RESIGN_RESOURCES OFF)
option(MACDEPLOY OFF)
option(BUILD_PRO_ONLY OFF)
option(BUILD_TESTING OFF)
option(PRINT_DEBUG ON)
#
# External projects
#
include(ExternalProject)

#find_package (PkgConfig REQUIRED)
find_package (EXPAT REQUIRED)
find_package (ZLIB REQUIRED)
find_package (Iconv REQUIRED)
find_package (CURL REQUIRED)
find_package (Qt5Core REQUIRED)
find_package (Qt5Gui REQUIRED)
find_package (Qt5Widgets REQUIRED)
find_package (SQLite3 REQUIRED)
find_package (BLAS REQUIRED)
find_package (LAPACK REQUIRED)
find_package (YAML-CPP REQUIRED)

add_definitions(-DCURL_STATICLIB )


if(NOT PKG_CONFIG_FOUND)
    message(FATAL_ERROR "pkg-config not found!" )
    message(FATAL_ERROR "sudo apt-get install pkg-config, or brew install pkg-config")
endif()

set(COMMON_DEPENDECIES ImageMetallingKernel)
set(COMMON_LIBRARIES  ${EXPAT_LIBRARIES}; ${ZLIB_LIBRARIES}; ${Iconv_LIBRARIES}; ${CURL_LIBRARIES}; SQLite3; libyaml-cpp.a)
string(TIMESTAMP TODAY "%Y-%m-%d")

message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})
message(STATUS "METAL_FLAGS: " ${METAL_FLAGS})

set (CMAKE_OSX_DEPLOYMENT_TARGET $ENV{MACOSX_DEPLOYMENT_TARGET})
set (CMAKE_INSTALL_PREFIX "/Library/OFX/Plugins")
set (EXTERNAL_INSTALL_LOCATION ${CMAKE_BINARY_DIR}/external)

set (CURRENT_METAL_TARGET_NAME ImageMetallingKernel)
set (CURRENT_METAL_TARGET_LIB ${CURRENT_METAL_TARGET_NAME}.metallib)

#
# OFX
#
ExternalProject_Add(ofx_lib
        GIT_REPOSITORY https://github.com/dehancer/dehancer-external
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DBUILD_TESTING=OFF
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};ofx_lib)
set(COMMON_LIBRARIES ${COMMON_LIBRARIES};OpenFXS)

#
# Capy threads pool dispatcher
#
ExternalProject_Add(capy_dispatchq_lib
        GIT_REPOSITORY https://github.com/dehancer/capy-dispatchq
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DBUILD_TESTING=OFF
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};capy_dispatchq_lib)
set(COMMON_LIBRARIES ${COMMON_LIBRARIES};capy_dispatchq)

#
# Ed25519
#
ExternalProject_Add(ed25519cpplib
        GIT_REPOSITORY https://github.com/dnevera/ed25519cpp
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};ed25519cpplib)
set(COMMON_LIBRARIES  ${COMMON_LIBRARIES};ed25519cpp)

#
# Base64
#
ExternalProject_Add(base64cpplib
        GIT_REPOSITORY https://github.com/dnevera/base64cpp
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};base64cpplib)
set(COMMON_LIBRARIES  ${COMMON_LIBRARIES};base64cpp)

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
# Math SDKs
#

ExternalProject_Add(armadillo-lib
        GIT_REPOSITORY https://github.com/dehancer/armadillo-code
        GIT_TAG 9.700.x
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DBUILD_TESTING=OFF
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        )

set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};armadillo-lib)
set(COMMON_LIBRARIES ${COMMON_LIBRARIES};armadillo)


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

ExternalProject_Add(rxcpp
        GIT_REPOSITORY https://github.com/ReactiveX/RxCpp
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION} -Wno-error=dev -Wno-dev
        BUILD_ALWAYS NO
        BUILD_COMMAND echo "skip..."
        INSTALL_COMMAND make install
        )
set(COMMON_DEPENDECIES ${COMMON_DEPENDECIES};rxcpp)

link_directories(
        ${CMAKE_BINARY_DIR}/external/lib
)

include_directories(
        ${CMAKE_SOURCE_DIR}/ofx
        ${CMAKE_SOURCE_DIR}/ofx/kernels
        ${CMAKE_CURRENT_BINARY_DIR}/generated
        ${CURL_INCLUDE_DIR}
        ${SQLITE3_INCLUDE_DIRS}
        ./
)

set(COMMON_LIBRARIES
        ${COMMON_LIBRARIES};
        ${BLAS_LIBRARIES};${LAPACK_LIBRARIES})


add_subdirectory(ofx)