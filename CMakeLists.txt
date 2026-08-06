cmake_minimum_required(VERSION 3.25)

project(field_device_lab LANGUAGES CXX)

include(cmake/ProjectOptions.cmake)
include(CTest)

find_package(nlohmann_json 3.12.0 CONFIG REQUIRED)

if(BUILD_TESTING)
    find_package(GTest 1.17.0 CONFIG REQUIRED)
endif()
