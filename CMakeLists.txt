cmake_minimum_required(VERSION 3.25)

project(field_device_lab LANGUAGES CXX)

include(cmake/ProjectOptions.cmake)
include(CTest)

find_package(nlohmann_json 3.12.0 CONFIG REQUIRED)

if(BUILD_TESTING)
    find_package(GTest 1.17.0 CONFIG REQUIRED)
endif()

add_library(field_device_core
    src/measurement.cpp
)

add_library(field_device::core ALIAS field_device_core)

target_compile_features(field_device_core
    PUBLIC
        cxx_std_20
)

target_include_directories(field_device_core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

field_device_apply_warnings(field_device_core)
