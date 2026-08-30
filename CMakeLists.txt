cmake_minimum_required(VERSION 3.15)
project(pkmn_encounters LANGUAGES CXX VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
  add_compile_options(/W4 /permissive-)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# --- Librería del núcleo (reutilizable en cualquier motor) ---
add_library(enc_encounters STATIC src/encounter_system.cpp)
target_include_directories(enc_encounters PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# --- Demo de consola ---
add_executable(enc_demo examples/demo.cpp)
target_link_libraries(enc_demo PRIVATE enc_encounters)
target_include_directories(enc_demo PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/examples)

# --- Tests ---
option(ENC_BUILD_TESTS "Compilar los tests" ON)
if(ENC_BUILD_TESTS)
  enable_testing()
  add_executable(enc_tests tests/test_encounter_system.cpp)
  target_link_libraries(enc_tests PRIVATE enc_encounters)
  add_test(NAME enc_tests COMMAND enc_tests)
endif()
