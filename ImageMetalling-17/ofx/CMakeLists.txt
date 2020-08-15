set(CURRENT_TARGET_NAME image_metalling_gpulib)

message(STATUS "LIBS: ${COMMON_LIBRARIES}")
message(STATUS "INSTALL to ${CMAKE_INSTALL_PREFIX}")

file (GLOB SOURCES ${SOURCES}
        ${CMAKE_SOURCE_DIR}/ofx/*.cpp
        ${CMAKE_SOURCE_DIR}/ofx/*.mm
        ${CMAKE_SOURCE_DIR}/ofx/kernels/*.mm
        ${CMAKE_SOURCE_DIR}/ofx/kernels/*.cpp
        )

add_library(${CURRENT_TARGET_NAME} STATIC ${SOURCES})
set_target_properties(${CURRENT_TARGET_NAME} PROPERTIES SUFFIX ".a")

add_dependencies(${CURRENT_TARGET_NAME}
        ${CURRENT_METAL_TARGET_NAME}
        ${COMMON_DEPENDECIES}
        )

add_dependencies(${CURRENT_TARGET_NAME}
        ImageMetallingKernel
        ${COMMON_DEPENDECIES}
        )

add_subdirectory(shaders)
