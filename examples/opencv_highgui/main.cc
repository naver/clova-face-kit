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

#define CHRONO_ALWAYS_ON

#include <algorithm>
#include <cassert>
#include <cstdarg>
#include <cstdlib>
#include <string>
#include <vector>

#include <cmrc/cmrc.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>

#include "base/buffer.h"
#include "base/chrono.h"
#include "base/face.h"
#include "base/frame.h"
#include "base/settings.h"
#include "body/options.h"
#include "face/options.h"
#include "ocr/options.h"
#include "sdk/clova_see.h"
#include "third_parties/range_v3/include/range/v3/view/transform.hpp"

CMRC_DECLARE(resources);

namespace {

const cv::Scalar kColorBlue(255, 0, 0, 0);
const cv::Scalar kColorGreen(0, 255, 0, 0);
const cv::Scalar kColorRed(0, 0, 255, 0);

enum class RunType {
  kBody,
  kFace,
  kOcr,
};

std::string Format(const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  const int buffer_length = std::vsnprintf(nullptr, 0, format, arguments);
  va_end(arguments);

  std::vector<char> buffer(buffer_length + 1);
  va_start(arguments, format);
  std::vsnprintf(&buffer[0], buffer_length + 1, format, arguments);
  va_end(arguments);
  return std::string(&buffer[0]);
}

clova::Frame::Format ToFrameFormat(const cv::Mat& mat) {
  switch (mat.type()) {
    case CV_8UC3:
      return clova::Frame::Format::kBGR_888;
    default:
      return clova::Frame::Format::kUnknown;
  }
}

clova::Frame ToFrame(const cv::Mat& mat) {
  return clova::Frame(mat.data, mat.cols, mat.rows, ToFrameFormat(mat));
}

cv::Point ToCvPoint(const clova::Point& point) {
  return cv::Point(point.x(), point.y());
}

std::vector<cv::Point> ToCvPoints(const clova::Points& points) {
  return points | ranges::views::transform(ToCvPoint)
                | ranges::to<std::vector<cv::Point>>();
}

cv::Rect ToCvRect(const clova::Rect& rect) {
  return cv::Rect(rect.x(), rect.y(), rect.width(), rect.height());
}

bool InitializeVideoCapture(cv::VideoCapture& capturer,
                            const std::string& filename) {
  filename.empty() ? capturer.open(0) : capturer.open(filename);
  if (!capturer.isOpened())
    return false;

  return true;
}

cv::Mat Capture(cv::VideoCapture& capturer, bool is_selfie_facing = false) {
  cv::Mat snapshot;
  capturer >> snapshot;
  if (is_selfie_facing)
    cv::flip(snapshot, snapshot, 1);
  return snapshot;
}

float CalculateCosineSimilarity(const std::vector<clova::Face>& faces) {
  if (faces.size() != 2)
    return 0.0f;

  return clova::Face::GetCosineSimilarity(faces.at(0), faces.at(1));
}

cv::Mat LoadEmbeddedImage(const std::string& filename, const cv::Size& size) {
  const auto& file = cmrc::resources::get_filesystem().open(filename);
  const clova::Buffer file_content(file.cbegin(), file.cend());
  auto image = cv::imdecode(file_content, cv::IMREAD_COLOR);
  if (image.size() != size) {
    cv::Mat resized_image;
    cv::resize(image, resized_image, size, 0, 0);
    image = std::move(resized_image);
  }
  return image;
}

void DrawText(cv::Mat& canvas, const std::string& text, int line_number) {
  cv::putText(canvas, text, cv::Point(10, 18 * (line_number + 1)),
              cv::FONT_HERSHEY_SIMPLEX, 0.6, kColorRed);
}

void DrawSegment(cv::Mat& canvas, const clova::body::Result& result) {
  const auto& segment = result.segment();
  if (segment.empty())
    return;

  assert(canvas.total() == segment.size());
  const int channel_count = canvas.channels();
  const int pixel_count = canvas.cols * canvas.rows * channel_count;
  auto* canvas_pixels = canvas.ptr<uint8_t>();

  static const cv::Mat background =
      LoadEmbeddedImage("background.png", canvas.size());
  assert(canvas.size() == background.size());
  auto* background_pixels = background.ptr<uint8_t>();

  for (int pixel_index = 0, alpha_index = 0;
       pixel_index < pixel_count;
       pixel_index += channel_count, alpha_index += 1) {
    const float alpha = segment[alpha_index] / 255.0f;
    for (int channel_index = 0;
         channel_index < channel_count;
         channel_index++) {
        float value =
            canvas_pixels[pixel_index + channel_index] * alpha +
            background_pixels[pixel_index + channel_index] * (1 - alpha);
        value = std::max(std::min(value, 255.f), 0.f);
        canvas_pixels[pixel_index + channel_index] = value;
    }
  }
}

void DrawSimilarity(cv::Mat& canvas, const std::vector<clova::Face>& faces) {
  const auto similarity = CalculateCosineSimilarity(faces);
  const auto message = Format("cosine similarity: %.2f", similarity);
  DrawText(canvas, message, 1);
}

void DrawBoundingBox(cv::Mat& canvas, const clova::Face& face) {
  cv::rectangle(canvas, ToCvRect(face.bounding_box()), kColorRed, 2);
}

void DrawContour(cv::Mat& canvas, const clova::Face& face) {
  for (const auto point : face.contour().points)
    cv::circle(canvas, ToCvPoint(point), 1, kColorGreen);
}

void DrawEulerAngle(cv::Mat& canvas, const clova::Face& face) {
  const auto x = face.euler_angle().x();
  const auto y = face.euler_angle().y();
  const auto z = face.euler_angle().z();
  const auto message = Format("euler angle: x=%+.2f y=%+.2f z=%+.2f", x, y, z);
  DrawText(canvas, message, 2);
}

void DrawTrackingID(cv::Mat& canvas, const clova::Face& face) {
  cv::putText(canvas, Format("id=%u", face.tracking_id()),
              ToCvPoint(face.bounding_box().origin()),
              cv::FONT_HERSHEY_SIMPLEX, 0.6, kColorRed);
}

void DrawMask(cv::Mat& canvas, const clova::Face& face) {
  cv::putText(canvas, Format("mask=%s", face.mask() ? "yes" : "no"),
              ToCvPoint(face.bounding_box().origin() - clova::Vector2d(0, 18)),
              cv::FONT_HERSHEY_SIMPLEX, 0.6, kColorRed);
}

void DrawSpoof(cv::Mat& canvas, const clova::Face& face) {
  if (face.spoof())
    cv::rectangle(canvas, ToCvRect(face.bounding_box()), kColorBlue, 3);
  cv::putText(canvas, Format("spoof=%s", face.spoof() ? "yes" : "no"),
              ToCvPoint(face.bounding_box().origin() - clova::Vector2d(0, 36)),
              cv::FONT_HERSHEY_SIMPLEX, 0.6, kColorRed);
}

void DrawDocument(cv::Mat& canvas, const clova::ocr::Result& result) {
  cv::polylines(canvas, ToCvPoints(result.document().clockwise_points()), true,
                kColorRed, 2);
}

void DrawFps(cv::Mat& canvas, float fps) {
  cv::putText(canvas, Format("fps=%.2f", fps), cv::Point(10, canvas.rows - 10),
              cv::FONT_HERSHEY_SIMPLEX, 0.6, kColorRed);
}

void DoRunForBody(clova::ClovaSee& clova_see, cv::Mat& snapshot) {
  const auto& options = clova::body::OptionsBuilder().Build();
  const auto& result = clova_see.Run(ToFrame(snapshot), options);
  DrawSegment(snapshot, result);
}

void DoRunForFace(clova::ClovaSee& clova_see, cv::Mat& snapshot) {
  const auto& options = clova::face::OptionsBuilder()
      .SetBoundingBoxThreshold(0.7f)
      .SetInformationToObtain(clova::face::Options::kContours |
                              clova::face::Options::kEulerAngles |
                              clova::face::Options::kMasks |
                              clova::face::Options::kTrackingIDs |
                              clova::face::Options::kSpoofs)
      .SetMinimumBoundingBoxSize(0.1f)
      .SetResizeThreshold(320)
      .SetSmoothingContour(true)
      .SetSmoothingRect(false)
      .Build();
  const auto& faces = clova_see.Run(ToFrame(snapshot), options).faces();
  DrawSimilarity(snapshot, faces);
  for (const auto& face : faces) {
    DrawBoundingBox(snapshot, face);
    DrawContour(snapshot, face);
    DrawEulerAngle(snapshot, face);
    DrawTrackingID(snapshot, face);
    DrawMask(snapshot, face);
    DrawSpoof(snapshot, face);
  }
}

void DoRunForOcr(clova::ClovaSee& clova_see, cv::Mat& snapshot) {
  const auto& options = clova::ocr::OptionsBuilder().Build();
  const auto& result = clova_see.Run(ToFrame(snapshot), options);
  DrawDocument(snapshot, result);
}

}  // namespace

int main(int argc, char* argv[]) {
  const auto& settings = clova::SettingsBuilder()
      .SetIntermittentInformationRatio(1)
      .SetNumberOfThreads(4)
      .SetPerformanceMode(clova::Settings::PerformanceMode::kAccurate106)
      .Build();
  clova::ClovaSee clova_see(settings);

  const bool has_option = argc > 1;
  const bool is_selfie_facing = !has_option;
  bool quit_requested = false;
  RunType run_type = RunType::kFace;

  cv::VideoCapture video_capture;
  if (!InitializeVideoCapture(video_capture, has_option ? argv[1] : ""))
    return EXIT_FAILURE;

  while (!quit_requested) {
    auto snapshot = Capture(video_capture, is_selfie_facing);
    if (snapshot.empty())
      break;

    static float fps = 0.0f;
    measure_in_fps(fps) {
      if (run_type == RunType::kBody) {
        DoRunForBody(clova_see, snapshot);
      } else if (run_type == RunType::kFace) {
        DoRunForFace(clova_see, snapshot);
      } else if (run_type == RunType::kOcr) {
        DoRunForOcr(clova_see, snapshot);
      }
    }
    DrawFps(snapshot, fps);

    cv::imshow("OpenCV HighGui Example", snapshot);
    switch (cv::waitKey(20)) {
      case 'b':
        run_type = RunType::kBody;
        continue;
      case 'f':
        run_type = RunType::kFace;
        continue;
      case 'o':
        run_type = RunType::kOcr;
        continue;
      case 27:  // ESC
        quit_requested = true;
        break;
    }
  }

  return EXIT_SUCCESS;
}
