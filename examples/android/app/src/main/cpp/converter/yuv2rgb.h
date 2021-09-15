// CLOVA Face Kit
// Copyright (c) 2021-present NAVER Corp.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ANDROID_YUV2RGB_H
#define ANDROID_YUV2RGB_H

template <int rgb_width, bool rgb_swizzle, bool interleaved, bool first_u, bool full_range>
void YUV2RGB(
        int width,
        int height,
        const void* y,
        const void* u,
        const void* v,
        int stride_y,
        int stride_u,
        int stride_v,
        void* rgb,
        int stride_rgb);

/**
 * NV21 포맷으로부터 ARGB8888 포맷으로 변환 합니다.
 * @param width       : 입력 이미지의 width
 * @param height      : 입력 이미지의 height
 * @param yuv         : NV21 타입의 이미지 원본 포인터
 * @param rgb         : ARGB 타입으로 변환된 이미지를 결과로 받을 포인터
 * @param full_range   : BT.709 Video Range or Full Range
 * @param rgb_width    : RGB 픽셀의 stride (ex) RGB=3, RGBA=4)
 * @param rgb_swizzle  : RGB 픽셀의 순서 RGB or BGR
 * @param stride_rgb   : BytesPerRow
 * @param align_width  : width를 몇바이트로 align 할 것인지 설정
 * @param align_height : height를 몇바이트로 align 할 것인지 설정
 * @param align_size   : size를 몇바이트로 align 할 것인지 설정
 */
void ConvertNV21ToARGB8888(
        int width,
        int height,
        const void* yuv,
        void* rgb,
        bool full_range = true,
        int rgb_width = 3,
        bool rgb_swizzle = false,
        int stride_rgb = 0,
        int align_width = 16,
        int align_height = 1,
        int align_size = 1);


#endif //ANDROID_YUV2RGB_H
