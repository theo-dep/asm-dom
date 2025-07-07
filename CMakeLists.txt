cmake_minimum_required (VERSION 3.26)
project(simple-video-cms LANGUAGES CXX VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_program(NPX_EXECUTABLE npx)
if(NOT NPX_EXECUTABLE)
    message(FATAL npx not found)
endif()

find_program(NPM_EXECUTABLE npm)
if(NOT NPM_EXECUTABLE)
    message(FATAL npm not found)
endif()

set(LIB_TARGET_NAME asm-dom-lib)
add_library(${LIB_TARGET_NAME}
    src/cpp/asm-dom.cpp
    src/cpp/asm-dom-server.cpp
    src/cpp/asm-dom.hpp
    src/cpp/asm-dom-server.hpp
)
target_include_directories(${LIB_TARGET_NAME} PUBLIC src/cpp)
target_link_options(${LIB_TARGET_NAME} PUBLIC -lembind -sEXPORTED_RUNTIME_METHODS=['UTF8ToString'])

set(TARGET_NAME asm-dom)
add_executable(${TARGET_NAME}
    src/cpp/asm-dom.cpp
    src/cpp/asm-dom-server.cpp
    src/cpp/asm-dom.hpp
    src/cpp/asm-dom-server.hpp
    src/js/index.cpp
)
target_compile_definitions(${TARGET_NAME} PRIVATE ASMDOM_JS_SIDE)
target_link_options(${TARGET_NAME} PRIVATE -lembind)

set(ASM_DOM_JS ${CMAKE_CURRENT_BINARY_DIR}/dist/js/asm-dom.js)
add_custom_command(
    OUTPUT ${ASM_DOM_JS}
    COMMAND ${NPM_EXECUTABLE} install --ignore-scripts
    COMMAND ${NPX_EXECUTABLE} cross-env
        BABEL_ENV=commonjs
        webpack --env prod --env WASM_PATH=${CMAKE_CURRENT_BINARY_DIR}
        src/js/index.js
        ${ASM_DOM_JS}
    DEPENDS ${TARGET_NAME}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_custom_target(asm-dom-js DEPENDS ${ASM_DOM_JS})

set(ASM_DOM_JS ${ASM_DOM_JS} PARENT_SCOPE)
