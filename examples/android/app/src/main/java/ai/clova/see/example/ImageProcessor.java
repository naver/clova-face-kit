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
import android.graphics.Matrix;
import android.media.Image;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.camera.core.CameraX;

import java.nio.ByteBuffer;

public class ImageProcessor {
    @NonNull
    private CameraX.LensFacing lensFacing;
    private ImageConverter converter = new ImageConverter();

    public ImageProcessor(@NonNull CameraX.LensFacing lensFacing) {
        this.lensFacing = lensFacing;
    }

    @Nullable
    public Bitmap toBitmap(@Nullable Image image, int rotationDegrees) {
        if (image == null || image.getWidth() == 0 || image.getHeight() == 0)
            return null;

        final int imageWidth = image.getWidth();
        final int imageHeight = image.getHeight();

        // YUV420_888 포맷을 NV21 포맷의 데이터 형태로 변환합니다.
        byte[] data = yuv420ToNV21(image);
        // NV21포맷의 ByteArray를  ARGB8888 포맷으로 변환합니다.
        Bitmap rgbBitmap = converter.nv21ToARGB(data, imageWidth, imageHeight);
        // ARGB8888로 변환 된 비트맵을 Rotation 및 Flip을 수행합니다.
        final float sx = lensFacing == CameraX.LensFacing.FRONT ? -1.0f : 1.0f;
        Bitmap rotateBitmap = toRotateBitmap(rgbBitmap, rotationDegrees, sx, 1.0f);

        return rotateBitmap;
    }

    private Bitmap toRotateBitmap(Bitmap bitmap,
                                  final int rotationDegrees,
                                  final float sx,
                                  final float sy) {
        int rotationType = toRotationType(rotationDegrees, sx);
        // rotationType이 1인 경우는 bitmap을 그대로 반환 해 줍니다.
        if (rotationType == 1)
            return bitmap;

        // 90, 180, 270 또는 scale이 1.0이 아닐 경우에는 기존의 로직을 그대로 수행합니다.
        if (rotationDegrees % 90 != 0 || Math.abs(sx) != 1.0f || Math.abs(sy) != 1.0f || rotationType == -1) {
            Matrix matrix = new Matrix();
            matrix.postRotate(rotationDegrees);
            matrix.postScale(sx, sy);

            return Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, false);
        }

        byte[] rgbData = toByteArray(bitmap);
        // 90, 180, 270 회전 및 좌우 flip의 경우에는 최적화 구현된 함수를 호출합니다.
        return converter.rotateImage(rgbData, bitmap.getWidth(), bitmap.getHeight(), rotationType);
    }

    private static byte[] yuv420ToNV21(Image image) {
        ByteBuffer yBuffer = image.getPlanes()[0].getBuffer();
        ByteBuffer vuBuffer = image.getPlanes()[2].getBuffer();

        final int ySize = yBuffer.remaining();
        final int vuSize = vuBuffer.remaining();

        byte[] nv21 = new byte[ySize + vuSize];

        yBuffer.get(nv21, 0, ySize);
        vuBuffer.get(nv21, ySize, vuSize);

        return nv21;
    }

    private static byte[] toByteArray(Bitmap bitmap) {
        int size = bitmap.getRowBytes() * bitmap.getHeight();
        ByteBuffer buffer = ByteBuffer.allocate(size);

        bitmap.copyPixelsToBuffer(buffer);

        return buffer.array();
    }

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
    private static int toRotationType(int rotationDegrees, float sx) {
        if (rotationDegrees == 90 && sx == 1.0f)
            return 6;
        else if (rotationDegrees == 90 && sx == -1.0f)
            return 5;
        else if (rotationDegrees == 180 && sx == 1.0f)
            return 3;
        else if (rotationDegrees == 180 && sx == -1.0f)
            return 4;
        else if (rotationDegrees == 270 && sx == 1.0f)
            return 8;
        else if (rotationDegrees == 270 && sx == -1.0f)
            return 7;
        else if (rotationDegrees == 0 && sx == 1.0f)
            return 1;
        else if (rotationDegrees == 0 && sx == -1.0f)
            return 2;

        return -1;
    }

}
