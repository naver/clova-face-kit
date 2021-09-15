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

#ifndef ANDROID_ROTATE_IMAGE_H
#define ANDROID_ROTATE_IMAGE_H

// type is the from type, 6 means rotating from 6 to 1
//
//     1        2       3      4         5            6           7          8
//
//   888888  888888      88  88      8888888888  88                  88  8888888888
//   88          88      88  88      88  88      88  88          88  88      88  88
//   8888      8888    8888  8888    88          8888888888  8888888888          88
//   88          88      88  88
//   88          88  888888  888888
//
// ref http://sylvana.net/jpegcrop/exif_orientation.html
// image pixel kanna rotate
void RotateImageC1(const unsigned char* src, int srcw, int srch, unsigned char* dst, int w, int h, int type);
void RotateImageC2(const unsigned char* src, int srcw, int srch, unsigned char* dst, int w, int h, int type);
void RotateImageC3(const unsigned char* src, int srcw, int srch, unsigned char* dst, int w, int h, int type);
void RotateImageC4(const unsigned char* src, int srcw, int srch, unsigned char* dst, int w, int h, int type);

// image pixel kanna rotate with stride(bytes-per-row) parameter
void RotateImageC1(const unsigned char* src, int srcw, int srch, int srcstride, unsigned char* dst, int w, int h, int stride, int type);
void RotateImageC2(const unsigned char* src, int srcw, int srch, int srcstride, unsigned char* dst, int w, int h, int stride, int type);
void RotateImageC3(const unsigned char* src, int srcw, int srch, int srcstride, unsigned char* dst, int w, int h, int stride, int type);
void RotateImageC4(const unsigned char* src, int srcw, int srch, int srcstride, unsigned char* dst, int w, int h, int stride, int type);

// image pixel kanna rotate, convenient wrapper for yuv420sp(nv21/nv12)
void RotateImageYUV420sp(const unsigned char* src, int srcw, int srch, unsigned char* dst, int w, int h, int type);

#endif //ANDROID_ROTATE_IMAGE_H
