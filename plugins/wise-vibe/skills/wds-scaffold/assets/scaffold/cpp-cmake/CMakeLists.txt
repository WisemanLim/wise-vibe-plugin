cmake_minimum_required(VERSION 3.21)
project({{PROJECT_NAME}} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(app_core src/health.cpp)
target_include_directories(app_core PUBLIC src)

add_executable(server src/main.cpp)
target_link_libraries(server PRIVATE app_core)

enable_testing()
add_executable(unit_tests test/unit/health_test.cpp)
target_link_libraries(unit_tests PRIVATE app_core)
add_test(NAME unit_tests COMMAND unit_tests)
