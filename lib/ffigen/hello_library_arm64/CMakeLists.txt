set(CMAKE_OSX_ARCHITECTURES "arm64")
cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(hello_library_arm64 VERSION 1.0.0 LANGUAGES C)
add_library(hello_library_arm64 SHARED hello.c hello.def)
add_executable(hello_test hello.c)

set_target_properties(hello_library_arm64 PROPERTIES
    PUBLIC_HEADER hello.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "hello"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)