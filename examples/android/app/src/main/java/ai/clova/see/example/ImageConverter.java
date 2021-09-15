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

package ai.clova.see.example;

import android.graphics.Bitmap;

public class ImageConverter {
    static {
        System.loadLibrary("image_converter");
    }

    public native Bitmap nv21ToARGB(byte[] rawData, int width, int height);

    public native Bitmap rotateImage(byte[] rawData, int width, int height, int rotationType);

}
