# %%
import cv2

from clovasee import ClovaSee
from clovasee import Frame
from clovasee import Settings
from clovasee import SettingsBuilder
from clovasee import FaceOptions
from clovasee import FaceOptionsBuilder

# %%
def draw_bounding_box(canvas, face):
  cv2.rectangle(canvas,
               (face.bounding_box().origin().x,
                face.bounding_box().origin().y),
               (face.bounding_box().right_bottom().x,
               face.bounding_box().right_bottom().y),
               (0, 0, 255), 2)

def draw_mask(canvas, face, mask):
  box = face.bounding_box()

  y = 0 if box.origin().y < 0 else box.origin().y
  x = 0 if box.origin().x < 0 else box.origin().x

  resized_mask = cv2.resize(mask, (box.width, box.height), interpolation=cv2.INTER_AREA)
  alpha = resized_mask[:, :, 3] / 255.0
  alpha_inv = 1.0 - alpha
  resized_mask[:, :, 0] = resized_mask[:, :, 0] * alpha
  resized_mask[:, :, 1] = resized_mask[:, :, 1] * alpha
  resized_mask[:, :, 2] = resized_mask[:, :, 2] * alpha

  crop = canvas[y:y+box.height, x:x+box.width]
  crop[:, :, 0] = crop[:, :, 0] * alpha_inv
  crop[:, :, 1] = crop[:, :, 1] * alpha_inv
  crop[:, :, 2] = crop[:, :, 2] * alpha_inv

  canvas[y:y+box.height, x:x+box.width] = resized_mask[:, :, :3] + crop

def draw_contour(canvas, face):
  for point in face.contour().points:
    cv2.circle(canvas, (point.x, point.y), 1, (0, 255, 0))

def draw_euler_angle(canvas, face):
  cv2.putText(canvas, 
             (f"x={face.euler_angle().x:.2f} "
              f"y={face.euler_angle().y:.2f} "
              f"z={face.euler_angle().z:.2f}"),
             (face.bounding_box().x, face.bounding_box().right_bottom().y+18),
             cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255))

def draw_mask(canvas, face, mask):
  box = face.bounding_box()

  y = 0 if box.origin().y < 0 else box.origin().y
  x = 0 if box.origin().x < 0 else box.origin().x

  resized_mask = cv2.resize(mask, (box.width, box.height), interpolation=cv2.INTER_AREA)
  alpha = resized_mask[:, :, 3] / 255.0
  alpha_inv = 1.0 - alpha
  resized_mask[:, :, 0] = resized_mask[:, :, 0] * alpha
  resized_mask[:, :, 1] = resized_mask[:, :, 1] * alpha
  resized_mask[:, :, 2] = resized_mask[:, :, 2] * alpha

  crop = canvas[y:y+box.height, x:x+box.width]
  crop[:, :, 0] = crop[:, :, 0] * alpha_inv
  crop[:, :, 1] = crop[:, :, 1] * alpha_inv
  crop[:, :, 2] = crop[:, :, 2] * alpha_inv

  canvas[y:y+box.height, x:x+box.width] = resized_mask[:, :, :3] + crop

# %%
def main():
  capture = cv2.VideoCapture(1)
  capture.set(cv2.CAP_PROP_FORMAT, cv2.CV_8UC3)

  settings = SettingsBuilder() \
      .set_number_of_threads(4) \
      .set_performance_mode(Settings.PerformanceMode.kAccurate106) \
      .build()
  clova_see = ClovaSee(settings)

  options = FaceOptionsBuilder() \
            .set_bounding_box_threshold(0.7) \
            .set_information_to_obtain(
              FaceOptions.kBoundingBoxes
              | FaceOptions.kContours \
              | FaceOptions.kEulerAngles \
            ) \
            .set_minimum_bounding_box_size(0.1) \
            .set_resize_threshold(320) \
            .build()

  mask = cv2.imread('mask.png', cv2.IMREAD_UNCHANGED)

  while True:
    ret, snapshot = capture.read()
    if not ret:
      continue

    snapshot = cv2.flip(snapshot, 1)

    (height, width, _) = snapshot.shape
    frame = Frame(snapshot,
                  width,
                  height,
                  Frame.Format.kBGR_888)
    faces = clova_see.run(frame, options).faces()

    for face in faces:
      draw_bounding_box(snapshot, face)
      draw_mask(snapshot, face, mask)
      draw_contour(snapshot, face)
      draw_euler_angle(snapshot, face)

    cv2.imshow("deview 2021", snapshot)

    key = cv2.waitKey(1)
    if key == ord('q'):
      break

  capture.release()
  cv2.destroyAllWindows()

if __name__ == '__main__':
  main()
