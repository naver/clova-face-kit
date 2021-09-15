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

#include "bitmap_utils.h"

jobject createBitmap(
        JNIEnv *env,
        const int width,
        const int height,
        const _jobject *bitmapConfig) {
  jclass bitmapClass = env->FindClass("android/graphics/Bitmap");
  jmethodID createBitmapMethodID = env->GetStaticMethodID(
          bitmapClass,
          "createBitmap",
          "(IILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;"
  );
  return env->CallStaticObjectMethod(
          bitmapClass,
          createBitmapMethodID,
          width,
          height,
          bitmapConfig);
}

jobject createBitmapARGB8888(JNIEnv *env, const int width, const int height) {
    return createBitmap(env, width, height, createBitmapConfigARGB8888(env));
}

jobject createBitmapConfigARGB8888(JNIEnv *env) {
    jclass bitmapConfig = env->FindClass("android/graphics/Bitmap$Config");
    jfieldID rgba8888FieldID =
            env->GetStaticFieldID(bitmapConfig,
                                  "ARGB_8888",
                                  "Landroid/graphics/Bitmap$Config;");
    jobject rgba8888Obj = env->GetStaticObjectField(bitmapConfig, rgba8888FieldID);
    return rgba8888Obj;
}
