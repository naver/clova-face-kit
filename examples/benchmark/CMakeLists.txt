# CLOVA Face Kit
# Copyright (c) 2021-present NAVER Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.11 FATAL_ERROR)

set(ENABLE_TEST_FACILITY ON CACHE BOOL "" FORCE)

set(INCLUDE_DIRECTORIES ${CMAKE_SOURCE_DIR}/third_parties/range_v3/include)
if(USE_INFERENCE_BACKEND_NCNN)
    set(INCLUDE_DIRECTORIES ${INCLUDE_DIRECTORIES}
                            ${CMAKE_BINARY_DIR}/third_parties/ncnn/src)
endif()

add_executable(benchmark main.cc)
include_directories(${INCLUDE_DIRECTORIES})
target_link_libraries(benchmark clovasee test_facility)
