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

find_package(OpenCV REQUIRED COMPONENTS highgui imgproc videoio)

include(../../third_parties/cmrc/CMakeRC.cmake)
cmrc_add_resource_library(resources background.png)

include_directories(${CMAKE_BINARY_DIR}
                    ${CMAKE_SOURCE_DIR}
                    ${CMAKE_SOURCE_DIR}/third_parties/range_v3/include
                    ${CMAKE_SOURCE_DIR}/sources
                    ${OpenCV_INCLUDE_DIR})

if(USE_INFERENCE_BACKEND_NCNN)
    include_directories(${CMAKE_BINARY_DIR}
                        ${CMAKE_BINARY_DIR}/third_parties/ncnn/src)
endif()

add_executable(example_opencv_highgui main.cc)
target_link_libraries(example_opencv_highgui
                      PRIVATE
                      clovasee
                      resources
                      ${OpenCV_LIBRARIES})
