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

#ifndef ANDROID_BITMAP_UTILS_H
#define ANDROID_BITMAP_UTILS_H

#include <android/bitmap.h>

/**
 * Bitmap을 생성한다.
 * @param env Jni 환경변수
 * @param width 생성될 bitmap의 width
 * @param height 생성될 bitmap의 height
 * @param bitmapConfig {@see android/graphics/BitmapConfig} BitmapConfig
 * @return Android 비트맵 인스턴스
 */
jobject createBitmap(
        JNIEnv *env,
        const int width,
        const int height,
        const _jobject *bitmapConfig);

/**
 * ARGB8888의 Bitmap을 생성한다.
 * @param env Jni 환경변수
 * @param width 생성될 bitmap의 width
 * @param height 생성될 bitmap의 height
 * @return Android 비트맵 인스턴스
 */
jobject createBitmapARGB8888(
        JNIEnv *env,
        const int width,
        const int height);

/**
 * ARGB 포멧으로 BitmapConfig를 생성한다.
  * @param env Jni 환경변수
 * @return {@link android/graphics/BitmapConfig} BitmapConfig 정보
 */
jobject createBitmapConfigARGB8888(JNIEnv *env);

#endif //ANDROID_BITMAP_UTILS_H
