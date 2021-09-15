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

//==============================================================================
// reference from https://github.com/metarutaiga/xxYUV
//==============================================================================

#if defined(__ARM_NEON__) || defined(__ARM_NEON) || defined(_M_ARM) || defined(_M_ARM64) || defined(_M_HYBRID_X86_ARM64)
#include <arm_neon.h>
#define NEON_FAST 1
#endif

#include "yuv2rgb.h"

#define align(v, a) ((v) + ((a) - 1) & ~((a) - 1))

// BT.709 - Video Range
//     Y         U         V
// R = 1.164384  0.000000  1.792741
// G = 1.164384 -0.213249 -0.532909
// B = 1.164384  2.112402  0.000000
//
// BT.709 - Full Range
//     Y         U         V
// R = 1.000000  0.000000  1.581000
// G = 1.000000 -0.188062 -0.469967
// B = 1.000000  1.862906  0.000000
#define vY   1.164384
#define vUG -0.213249
#define vUB  2.112402
#define vVR  1.792741
#define vVG -0.532909
#define fY   1.000000
#define fUG -0.188062
#define fUB  1.862906
#define fVR  1.581000
#define fVG -0.469967

template<int rgb_width, bool rgb_swizzle, bool interleaved, bool first_u, bool full_range>
void YUV2RGB(
    int width, int height,
    const void *y, const void *u, const void *v,
    int stride_y, int stride_u, int stride_v,
    void *rgb, int stride_rgb) {
  if (stride_rgb < 0) {
    rgb = static_cast<char *>(rgb) - (stride_rgb * (height - 1));
  }

  int half_width = width >> 1;
  int half_height = height >> 1;

  int iR = rgb_swizzle ? 2 : 0;
  int iG = 1;
  int iB = rgb_swizzle ? 0 : 2;
  int iA = 3;

  int Y, UG, UB, VR, VG;
  if (full_range) {
    Y = static_cast<int>(fY * 256);
    UG = static_cast<int>(fUG * 255);
    UB = static_cast<int>(fUB * 255);
    VR = static_cast<int>(fVR * 255);
    VG = static_cast<int>(fVG * 255);
  } else {
    Y = static_cast<int>(vY * 256);
    UG = static_cast<int>(vUG * 255);
    UB = static_cast<int>(vUB * 255);
    VR = static_cast<int>(vVR * 255);
    VG = static_cast<int>(vVG * 255);
  }

  for (int h = 0; h < half_height; ++h) {
    const unsigned char *y0 = static_cast<const unsigned char *>(y);
    const unsigned char *y1 = y0 + stride_y;
    y = y1 + stride_y;
    const unsigned char *u0 = static_cast<const unsigned char *>(u);
    u = u0 + stride_u;
    const unsigned char *v0 = static_cast<const unsigned char *>(v);
    v = v0 + stride_v;
    unsigned char *rgb0 = static_cast<unsigned char *>(rgb);
    unsigned char *rgb1 = rgb0 + stride_rgb;
    rgb = rgb1 + stride_rgb;

#if defined(__ARM_NEON__) || defined(__ARM_NEON) || defined(_M_ARM) || defined(_M_ARM64) || defined(_M_HYBRID_X86_ARM64)
    int half_width8 = (rgb_width == 4) ? half_width / 8 : 0;
    for (int w = 0; w < half_width8; ++w) {
      uint8x16_t y00lh = vld1q_u8(y0); y0 += 16;
      uint8x16_t y10lh = vld1q_u8(y1); y1 += 16;
      uint8x8_t y00;
      uint8x8_t y01;
      uint8x8_t y10;
      uint8x8_t y11;
      if (full_range) {
        y00 = vget_low_u8(y00lh);
        y01 = vget_high_u8(y00lh);
        y10 = vget_low_u8(y10lh);
        y11 = vget_high_u8(y10lh);
      } else {
        y00lh = vqsubq_u8(y00lh, vdupq_n_u8(16));
        y10lh = vqsubq_u8(y10lh, vdupq_n_u8(16));
        y00 = vshrn_n_u16(vmull_u8(vget_low_u8(y00lh), vdup_n_u8(Y >> 1)), 7);
        y01 = vshrn_n_u16(vmull_u8(vget_high_u8(y00lh), vdup_n_u8(Y >> 1)), 7);
        y10 = vshrn_n_u16(vmull_u8(vget_low_u8(y10lh), vdup_n_u8(Y >> 1)), 7);
        y11 = vshrn_n_u16(vmull_u8(vget_high_u8(y10lh), vdup_n_u8(Y >> 1)), 7);
      }

      int8x8_t u000;
      int8x8_t v000;
      if (interleaved) {
        if (first_u) {
          int8x16_t uv00 = vld1q_u8(u0); u0 += 16;
          int8x8x2_t uv00lh = vuzp_s8(vget_low_s8(uv00), vget_high_s8(uv00));
          int8x16_t uv000 =
                  vaddq_s8(vcombine_s8(uv00lh.val[0], uv00lh.val[1]), vdupq_n_s8(-128));
          u000 = vget_low_s8(uv000);
          v000 = vget_high_s8(uv000);
        } else {
          int8x16_t uv00 = vld1q_u8(v0); v0 += 16;
          int8x8x2_t uv00lh = vuzp_s8(vget_low_s8(uv00), vget_high_s8(uv00));
          int8x16_t uv000 =
                  vaddq_s8(vcombine_s8(uv00lh.val[1], uv00lh.val[0]), vdupq_n_s8(-128));
          u000 = vget_low_s8(uv000);
          v000 = vget_high_s8(uv000);
        }
      } else {
        int8x16_t uv000 =
            vaddq_s8(vcombine_s8(vld1_u8(u0), vld1_u8(v0)), vdupq_n_s8(-128));
        u0 += 8; v0 += 8;
        u000 = vget_low_s8(uv000);
        v000 = vget_high_s8(uv000);
      }

#if NEON_FAST
      int16x8_t dR = vshrq_n_s16(vmull_s8(v000, vdup_n_s8(VR >> 2)), 6);
      int16x8_t dG =
          vshrq_n_s16(vmlal_s8(vmull_s8(u000, vdup_n_s8(UG >> 1)),
                                        v000,
                                        vdup_n_s8(VG >> 1)),
                               7);
      int16x8_t dB = vshrq_n_s16(vmull_s8(u000, vdup_n_s8(UB >> 3)), 5);
#else
      int16x8_t u00 = vshll_n_s8(u000, 7);
      int16x8_t v00 = vshll_n_s8(v000, 7);

      int16x8_t dR = vqdmulhq_s16(v00, vdupq_n_s16(VR));
      int16x8_t dG = vaddq_s16(vqdmulhq_s16(u00, vdupq_n_s16(UG)),
                               vqdmulhq_s16(v00, vdupq_n_s16(VG)));
      int16x8_t dB = vqdmulhq_s16(u00, vdupq_n_s16(UB));
#endif // NEON_FAST

      uint16x8x2_t xR = vzipq_u16(vreinterpretq_u16_s16(dR),
                                  vreinterpretq_u16_s16(dR));
      uint16x8x2_t xG = vzipq_u16(vreinterpretq_u16_s16(dG),
                                  vreinterpretq_u16_s16(dG));
      uint16x8x2_t xB = vzipq_u16(vreinterpretq_u16_s16(dB),
                                  vreinterpretq_u16_s16(dB));

      uint8x16x4_t t;
      uint8x16x4_t b;

      t.val[iR] = vcombine_u8(vqmovun_s16(vaddw_u8(xR.val[0], y00)),
                              vqmovun_s16(vaddw_u8(xR.val[1], y01)));
      t.val[iG] = vcombine_u8(vqmovun_s16(vaddw_u8(xG.val[0], y00)),
                              vqmovun_s16(vaddw_u8(xG.val[1], y01)));
      t.val[iB] = vcombine_u8(vqmovun_s16(vaddw_u8(xB.val[0], y00)),
                              vqmovun_s16(vaddw_u8(xB.val[1], y01)));
      t.val[iA] = vdupq_n_u8(255);
      b.val[iR] = vcombine_u8(vqmovun_s16(vaddw_u8(xR.val[0], y10)),
                              vqmovun_s16(vaddw_u8(xR.val[1], y11)));
      b.val[iG] = vcombine_u8(vqmovun_s16(vaddw_u8(xG.val[0], y10)),
                              vqmovun_s16(vaddw_u8(xG.val[1], y11)));
      b.val[iB] = vcombine_u8(vqmovun_s16(vaddw_u8(xB.val[0], y10)),
                              vqmovun_s16(vaddw_u8(xB.val[1], y11)));
      b.val[iA] = vdupq_n_u8(255);

      vst4q_u8(rgb0, t);
      rgb0 += 16 * 4;
      vst4q_u8(rgb1, b);
      rgb1 += 16 * 4;
    }
    if (rgb_width == 4)
      continue;

#endif  // defined(__ARM_NEON__)
    for (int w = 0; w < half_width; ++w) {
      int y00 = (*y0++);
      int y01 = (*y0++);
      int y10 = (*y1++);
      int y11 = (*y1++);
      if (full_range) {
      } else {
        y00 = ((y00 - 16) * Y) >> 8;
        y01 = ((y01 - 16) * Y) >> 8;
        y10 = ((y10 - 16) * Y) >> 8;
        y11 = ((y11 - 16) * Y) >> 8;
      }

      int u00 = (*u0++) - 128;
      int v00 = (*v0++) - 128;
      if (interleaved) {
        u0++;
        v0++;
      }

      int dR = (v00 * VR) >> 8;
      int dG = (u00 * UG + v00 * VG) >> 8;
      int dB = (u00 * UB) >> 8;

      auto clamp = [](int value) -> unsigned char {
        return (unsigned char) (value < 255 ? value < 0 ? 0 : value : 255);
      };

      if (rgb_width >= 1) rgb0[iR] = clamp(y00 + dR);
      if (rgb_width >= 2) rgb0[iG] = clamp(y00 + dG);
      if (rgb_width >= 3) rgb0[iB] = clamp(y00 + dB);
      if (rgb_width >= 4) rgb0[iA] = 255;
      rgb0 += rgb_width;

      if (rgb_width >= 1) rgb0[iR] = clamp(y01 + dR);
      if (rgb_width >= 2) rgb0[iG] = clamp(y01 + dG);
      if (rgb_width >= 3) rgb0[iB] = clamp(y01 + dB);
      if (rgb_width >= 4) rgb0[iA] = 255;
      rgb0 += rgb_width;

      if (rgb_width >= 1) rgb1[iR] = clamp(y10 + dR);
      if (rgb_width >= 2) rgb1[iG] = clamp(y10 + dG);
      if (rgb_width >= 3) rgb1[iB] = clamp(y10 + dB);
      if (rgb_width >= 4) rgb1[iA] = 255;
      rgb1 += rgb_width;

      if (rgb_width >= 1) rgb1[iR] = clamp(y11 + dR);
      if (rgb_width >= 2) rgb1[iG] = clamp(y11 + dG);
      if (rgb_width >= 3) rgb1[iB] = clamp(y11 + dB);
      if (rgb_width >= 4) rgb1[iA] = 255;
      rgb1 += rgb_width;
    }
  }
}

void ConvertNV21ToARGB8888(
    int width, int height,
    const void *yuv, void *rgb,
    bool full_range, int rgb_width, bool rgb_swizzle, int stride_rgb,
    int align_width, int align_height, int align_size) {
  int stride_yuv = align(width, align_width);
  int size_y = align(stride_yuv * align(height, align_height), align_size);
  int size_uv = align(stride_yuv * align(height, align_height) / 2, align_size);

  if (stride_rgb == 0)
    stride_rgb = rgb_width * width;

  auto converter = YUV2RGB<3, false, false, false, false>;

  if (rgb_width == 3) {
    if (rgb_swizzle) {
      if (full_range)
        converter = YUV2RGB<3, true, true, false, true>;
      else
        converter = YUV2RGB<3, true, true, false, false>;
    } else {
      if (full_range)
        converter = YUV2RGB<3, false, true, false, true>;
      else
        converter = YUV2RGB<3, false, true, false, false>;
    }
  } else if (rgb_width == 4) {
    if (rgb_swizzle) {
      if (full_range)
        converter = YUV2RGB<4, true, true, false, true>;
      else
        converter = YUV2RGB<4, true, true, false, false>;
    } else {
      if (full_range)
        converter = YUV2RGB<4, false, true, false, true>;
      else
        converter = YUV2RGB<4, false, true, false, false>;
    }
  }

  converter(width, height,
            yuv, (char *) yuv + size_y + 1, (char *) yuv + size_y,
            stride_yuv, stride_yuv, stride_yuv,
            rgb, stride_rgb);
}
