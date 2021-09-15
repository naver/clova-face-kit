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

#include <android/bitmap.h>
#include <jni.h>
#include <string>

#include "converter/rotate_image.h"
#include "converter/yuv2rgb.h"
#include "utils/bitmap_utils.h"

extern "C" {

JNIEXPORT jobject JNICALL
Java_ai_clova_see_example_ImageConverter_nv21ToARGB(
        JNIEnv *env,
        jobject self,
        jbyteArray nv21ObjectArray,
        jint srcWidth,
        jint srcHeight) {

    // 비트맵 정보의 width 또는 Height가 0인경우 null을 리턴한다.
    if (srcWidth == 0 || srcHeight == 0) {
        return nullptr;
    }
    // 파라메터로 전달받은 이미지의 width, height를 가지고 비트맵을 생성한다.
    jobject bmpResult = createBitmapARGB8888(env, srcWidth, srcHeight);
    void *pixels = nullptr;
    // 파라메터로 넘어온 비트맵의 첫번째 픽셀 정보를 가져온다.
    AndroidBitmap_lockPixels(env, bmpResult, &pixels);
    // jbyteArray에 lock을 걸어 메모리 포인터를 가져온다. 이때 nv21ByteArray는 gc 메모리 해제 대상에서 제외된다.
    auto *nv21ByteArray = (unsigned char *) env->GetPrimitiveArrayCritical(nv21ObjectArray, 0);
    // nv21를 Array를 변환하여 생성된 비트맵 포인터에 저장한다.
    ConvertNV21ToARGB8888(srcWidth, srcHeight, nv21ByteArray, (unsigned char*) pixels, true, 4);
    // nv21ObjectArray에 lock을 해제 한다. 이때 nv21ByteArray는 gc 해제 대상으로 다시 설정된다.
    env->ReleasePrimitiveArrayCritical(nv21ObjectArray, (jbyte*)nv21ByteArray, 0);
    // 메모리를 해제한다.
    AndroidBitmap_unlockPixels(env, bmpResult);
    return bmpResult;
}

JNIEXPORT jobject JNICALL
Java_ai_clova_see_example_ImageConverter_rotateImage(
        JNIEnv *env,
        jobject self,
        jbyteArray bitmapData,
        jint srcWidth,
        jint srcHeight,
        jint rotationType) {

    // 비트맵 정보의 width 또는 Height가 0인경우 null을 리턴한다.
    if (srcWidth == 0 || srcHeight == 0) {
        return nullptr;
    }

    // rotation type에 따라 출력 이미지의 width, height를 결정합니다.
    const int dstWidth = rotationType > 4 ? srcHeight : srcWidth;
    const int dstHeight = rotationType > 4 ? srcWidth : srcHeight;
    // 출력을 위한 비트맵을 생성 합니다.
    jobject bmpResult = createBitmapARGB8888(env, dstWidth, dstHeight);
    void* pixels = nullptr;
    AndroidBitmap_lockPixels(env, bmpResult, &pixels);
    auto* imageByteArray =
            static_cast<unsigned char*>(env->GetPrimitiveArrayCritical(bitmapData, 0));
    // 회전을 수행한 후에 출력 비트맵에 저장합니다.
    RotateImageC4(imageByteArray, srcWidth, srcHeight,
            static_cast<unsigned char*>(pixels), dstWidth, dstHeight,
            rotationType);
    env->ReleasePrimitiveArrayCritical(bitmapData, (jbyte*)imageByteArray, 0);
    AndroidBitmap_unlockPixels(env, bmpResult);
    return bmpResult;
}

} // extern c
