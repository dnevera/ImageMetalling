
set(CURRENT_TARGET_NAME ${CURRENT_METAL_TARGET_NAME})
set(CURRENT_TARGET_LIB ${CURRENT_METAL_TARGET_LIB})
set(CMAKE_INSTALL_PREFIX "/Library/OFX/Plugins")

message(STATUS "CMAKE_INCLUDE_PATH  " .)

file(GLOB __DEPENDS_PLUGIN_SOURCES ${__DEPENDS_PLUGIN_SOURCES}
        ${CMAKE_SOURCE_DIR}/ofx/lib/shaders/*.h
        )

# -ffast-math ?
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/ImageMetalling.air
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/ImageMetalling.metal ${__DEPENDS_PLUGIN_SOURCES}
        COMMAND xcrun -sdk macosx metal
        ${METAL_FLAGS}
        -I .
        -c ${CMAKE_CURRENT_SOURCE_DIR}/ImageMetalling.metal
        -o ${CMAKE_CURRENT_BINARY_DIR}/ImageMetalling.air
        VERBATIM
        )

add_custom_target(
        ${CURRENT_TARGET_NAME}
        DEPENDS
        ${CMAKE_CURRENT_BINARY_DIR}/ImageMetalling.air
        COMMAND xcrun -sdk macosx metallib ${CMAKE_CURRENT_BINARY_DIR}/*.air -o ${CURRENT_TARGET_LIB}
)

set_target_properties(${CURRENT_TARGET_NAME} PROPERTIES BUNDLE TRUE)
set_target_properties(${CURRENT_TARGET_NAME} PROPERTIES PREFIX "")
set_target_properties(${CURRENT_TARGET_NAME} PROPERTIES SUFFIX ".metallib")

