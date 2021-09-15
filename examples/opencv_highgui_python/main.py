#!/usr/bin/env python

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

import cv2 as cv
import numpy as np
import os
import platform
import time
import sys

from enum import Enum

current_directory = os.path.dirname(os.path.abspath(__file__))

OS_NAME = platform.system()
BUILD_DIRECTORY = ""
if OS_NAME == "Linux":
    BUILD_DIRECTORY = "linux"
elif OS_NAME == "Darwin":
    BUILD_DIRECTORY = "macos"
elif OS_NAME == "Windows":
    BUILD_DIRECTORY = "windows"


from clovasee import ClovaSee
from clovasee import Face
from clovasee import Frame
from clovasee import Settings
from clovasee import SettingsBuilder
from clovasee import FaceOptions
from clovasee import FaceOptionsBuilder
from clovasee import BodyOptions
from clovasee import BodyOptionsBuilder

class RunType(Enum):
  Body = 0
  Face = 1

def create_video_capture(filename):
  capturer = cv.VideoCapture(filename if filename else 0)
  capturer.set(cv.CAP_PROP_FORMAT, cv.CV_8UC3)
  return capturer

def capture(video_capture, is_selfie_facing = False):
  ret, snapshot = video_capture.read()
  if (is_selfie_facing):
    snapshot = cv.flip(snapshot, 1)
  return ret, snapshot

def to_frame(snapshot):
  (height, width, _) = snapshot.shape
  return Frame(snapshot,
               width,
               height,
               Frame.Format.kBGR_888)

def to_cv_point(point):
  return (point.x, point.y)

def calculate_cosine_similarity(faces):
  if len(faces) != 2:
    return 0.0
  return Face.get_cosine_similarity(faces[0], faces[1])

def draw_text(canvas, text, line_number):
  cv.putText(canvas, text, (10, 18 * (line_number + 1)),
             cv.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0))

def draw_similarity(canvas, faces):
  similarity = calculate_cosine_similarity(faces)
  draw_text(canvas, "cosine similarity: {}".format(similarity), 1)

def draw_bounding_box(canvas, face):
  cv.rectangle(canvas,
               to_cv_point(face.bounding_box().origin()),
               to_cv_point(face.bounding_box().right_bottom()),
               (0, 0, 255), 2)

def draw_contour(canvas, face):
  for point in face.contour().points:
    cv.circle(canvas, to_cv_point(point), 1, (0, 255, 0))

def draw_euler_angle(canvas, face):
  x = face.euler_angle().x
  y = face.euler_angle().y
  z = face.euler_angle().z
  message = "euler angle: x={:.2f} y={:.2f} z={:.2f}".format(x, y, z)
  draw_text(canvas, message, 2)

def draw_mask(canvas, face):
  box_origin = to_cv_point(face.bounding_box().origin())
  cv.putText(canvas, "mask={}".format("yes" if face.mask() else "no"),
             (box_origin[0], box_origin[1] - 25),
             cv.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255))

def draw_tracking_id(canvas, face):
  box_origin = to_cv_point(face.bounding_box().origin())
  cv.putText(canvas, "id={}".format(face.tracking_id()),
             (box_origin[0], box_origin[1] - 5),
             cv.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255))

def draw_fps(canvas, fps):
  cv.putText(canvas, "fps={:.2f}".format(fps),
             (10, canvas.shape[0] - 10),
             cv.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255))

def render_segment(canvas, result):
  segment = result.segment()  # CHW
  height, width, channels = canvas.shape  # HWC
  alpha_np = segment.astype(np.float32)
  alpha_np /= 255.0
  alpha_np = alpha_np.reshape(height, width)
  output = np.multiply(alpha_np[..., np.newaxis], canvas).astype(np.uint8)
  return output

def run_for_body(clova_see, snapshot):
  options = BodyOptionsBuilder().build()
  result = clova_see.run(to_frame(snapshot), options)
  return render_segment(snapshot, result)

def run_for_face(clova_see, snapshot):
    options = FaceOptionsBuilder() \
        .set_bounding_box_threshold(0.7) \
        .set_information_to_obtain(FaceOptions.kContours |
                                   FaceOptions.kMasks |
                                   FaceOptions.kTrackingIDs |
                                   FaceOptions.kEulerAngles) \
        .set_minimum_bounding_box_size(0.1) \
        .set_resize_threshold(320) \
        .build()
    faces = clova_see.run(to_frame(snapshot), options).faces()
    draw_similarity(snapshot, faces)
    for face in faces:
      draw_bounding_box(snapshot, face)
      draw_contour(snapshot, face)
      draw_euler_angle(snapshot, face)
      draw_tracking_id(snapshot, face)
      draw_mask(snapshot, face)

def main():
  settings = SettingsBuilder() \
      .set_intermittent_information_ratio(1) \
      .set_number_of_threads(4) \
      .set_performance_mode(Settings.PerformanceMode.kAccurate106) \
      .build()
  clova_see = ClovaSee(settings)

  has_option = len(sys.argv) > 1
  is_selfie_facing = not has_option
  run_type = RunType.Body

  video_capture = create_video_capture(sys.argv[1] if has_option else "")

  while True:
    ret, snapshot = capture(video_capture, is_selfie_facing)
    if not ret:
      continue

    start_time = time.time()
    if run_type == RunType.Body:
        snapshot = run_for_body(clova_see, snapshot)
    elif run_type == RunType.Face:
        run_for_face(clova_see, snapshot)

    elapsed_time = (time.time() - start_time) * 1000.0
    fps = 1000.0 / elapsed_time
    draw_fps(snapshot, fps)

    cv.imshow("OpenCV HighGui Example for Python", snapshot)

    key = cv.waitKey(20)
    if key == ord('b'):
      run_type = RunType.Body
    elif key == ord('f'):
      run_type = RunType.Face
    elif key == 27:
      break

  video_capture.release()
  cv.destroyAllWindows()

if __name__ == '__main__':
  sys.exit(main())
