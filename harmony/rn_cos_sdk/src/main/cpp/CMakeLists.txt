cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(rnoh_cos_sdk_generated_dir "${CMAKE_CURRENT_SOURCE_DIR}/generated")
file(GLOB_RECURSE rnoh_cos_sdk_generated_SRC "${rnoh_cos_sdk_generated_dir}/**/*.cpp")
file(GLOB rnoh_cos_sdk_SRC CONFIGURE_DEPENDS *.cpp)
add_library(rnoh_cos_sdk SHARED ${rnoh_cos_sdk_generated_SRC} ${rnoh_cos_sdk_SRC})
target_include_directories(rnoh_cos_sdk PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${rnoh_cos_sdk_generated_dir})
target_link_libraries(rnoh_cos_sdk PUBLIC rnoh)
