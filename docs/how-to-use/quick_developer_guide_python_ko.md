# Quick Developer Guide to CLOVA SEE for Python

## 예제 프로젝트

CLOVA SEE의 적용법과 사용법은 [examples/opencv_highgui_python](../../examples/opencv_highgui_python)를 참고해주세요.

## 간단 사용법

1. `ClovaSee` 객체를 생성합니다. `ClovaSee` 객체를 생성할 때는 `Options`를 통해서 몇 가지 세부 옵션을 설정할 수 있는데 이 부분은 다음 절에서 설명합니다.

   ```python
   from clovasee import ClovaSee
   from clovasee import Settings
   from clovasee import SettingsBuilder
   
   def main():
     settings = SettingsBuilder() \
         .set_intermittent_information_ratio(1) \
         .set_number_of_threads(4) \
         .set_performance_mode(Settings.PerformanceMode.kAccurate106) \
         .build()
     clova_see = ClovaSee(settings)
   
     ...
   ```

2. `ClovaSee`로 분석할 이미지를 `Frame`으로 만들어 준비합니다. 아래는 OpenCV에서 얻은 이미지를 `Frame`으로 만드는 예입니다.

   ```python
   import cv2 as cv
  
   from clovasee import Frame
   
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
   
   def main():
     ...
   
     video_capture = create_video_capture(sys.argv[1] if has_option else "")
     
     ret, snapshot = capture(video_capture)
   
     frame = to_frame(snapshot)
   
      ...
   ```

3. `Frame`에 있는 얼굴에서 어떠한 정보들을 분석할 것인지, 조건을 설정할 것인지 `clova::face::OptionsBuilder()` 를 이용하여 `clova::face::Options`을 설정합니다. `clova::face::Options`에서 설정할 수 있는 옵션들은 마지막 절에서 설명합니다.

   ```python
   from clovasee import FaceOptions
   from clovasee import FaceOptionsBuilder
   
   def main():
      ...
      options = FaceOptionsBuilder() \
              .set_bounding_box_threshold(0.7) \
              .set_information_to_obtain(FaceOptions.kContours |
                                         FaceOptions.kMasks |
                                         FaceOptions.kTrackingIDs |
                                         FaceOptions.kEulerAngles) \
              .set_minimum_bounding_box_size(0.1) \
              .set_resize_threshold(320) \
              .build()
   
      ...   
   ```

4. 2에서 준비한 `Frame`과 3에서 준비한 `FaceOptions`을 가지고 `ClovaSee::run()`을 호출합니다. `ClovaSee::run()`은 주어진 `Frame`에 있는 얼굴 정보를 분석해서 결과를 `Faces`에 담아 반환합니다. `Face`에 반환되는 정보는 마지막 절에서 설명합니다.

   ```python
   from clovasee import Face

   def main():
     ...
     
     faces = clova_see.run(frame, options).faces()   
     
     ...
   ```

4. 3에서 반환된 `Faces`를 가지고 원하는 작업을 합니다. 아래는 OpenCV HighGui를 써서 화면에 얼굴 정보를 그리는 예입니다.

   ```python
   import cv2 as cv
   
   def to_cv_point(point):
     return (point.x, point.y)
   
   def draw_bounding_box(canvas, face):
     cv.rectangle(canvas,
                  to_cv_point(face.bounding_box().origin()),
                  to_cv_point(face.bounding_box().right_bottom()),
                  (0, 0, 255), 2)
   
   def draw_contour(canvas, face):
     for point in face.contour().points:
       cv.circle(canvas, to_cv_point(point), 1, (0, 255, 0))
   
   def main():   
     ...
   
     for face in faces:
       draw_bounding_box(snapshot, face)
       draw_contour(snapshot, face)
       
     cv.imshow("OpenCV HighGui Example for Python", snapshot);

     ...
   ```

## 세부 옵션 설정 방법

`ClovaSee` 객체를 생성할 때 첫 번째 매개변수에 `Settings` 객체를 전달하면 `ClovaSee`의 동작 방식과 관련된 몇 가지 세부 옵션을 제어할 수 있습니다. `Settings` 객체는 보통 `SettingsBuilder`를 통해서 만드는데, 사용 예와 주요 옵션의 의미는 아래와 같습니다.

```python
settings = SettingsBuilder() \
      .set_intermittent_information_ratio(1) \
      .set_number_of_threads(4) \
      .set_performance_mode(Settings.PerformanceMode.kAccurate106) \
      .build()

clova_see = ClovaSee(settings)
```

1. `set_number_of_threads()`: `ClovaSee` 내부의 스레드 풀 크기를 설정합니다. 보통 실행 환경에 장착된 코어의 수(Big-Little 구조의 경우에는 Big의 수)로 설정하며, 기본 값은 4입니다.

2. `set_performance_mode()`: `ClovaSee`의 수행 속도와 반환되는 정보의 정확성 둘 중에 어떤 것이 더 중요한지를 설정합니다. 아래의 값들 중 하나를 설정하면 되며, 기본 값은 `Settings.PerformanceMode.kAccurate98`입니다. 현재 이 옵션으로 영향을 받는 반환 값은 `Face.contours` 뿐이지만 추후 확대될 수 있습니다.

   `Settings.PerformanceMode.kAccurate106`: `Face.contours`에 106개의 점으로 구성된 윤곽선 정보를 반환합니다.

   `Settings.PerformanceMode.kAccurate98`: `Face.contours`에 98개의 점으로 구성된 윤곽선 정보를 반환합니다.

   `Settings.PerformanceMode.kFast`: `Face.contours`에 5개의 점으로 구성된 윤곽선 정보를 반환합니다.

4. `set_intermittent_information_ratio()`: 얼굴 분석을 수행할 주기를 프레임 수 단위로 지정합니다. 기본 값은 1입니다. 예를 들어, 5를 지정하면 `set_information_to_obtain()`으로 설정한 정보가 5프레임마다 한 번씩만 분석되어 반환됩니다. 단, `FaceOptions.kBoundingBoxes`는 이 주기와 상관 없이 항상 반환됩니다. 이처럼 사용자가 설정한 주기에 따라서만 분석되어 반환되는 정보를 Intermittent Information이라고 하며, `FaceOptions.kBoundingBoxes`를 제외한 나머지 모든 정보가 여기에 해당합니다.

## `FaceOptions`

1. `set_bounding_box_threshold()` : Face Detection에서 특정 confidence 값 이상인 경우에만 반환하도록 threshold를 설정합니다.

2. `set_information_to_obtain()`: `ClovaSee`를 통해 알고자 하는 정보의 종류를 설정합니다. 아래의 값들 중 원하는 정보의 종류를 `|`로 묶어서 설정하면 됩니다. 필요한 정보의 종류만 간략하게 설정하면 `ClovaSee.run()`의 실행 시간을 줄이는데 도움이 됩니다. 기본 값은 `FaceOptions.kAll` 입니다.

   `FaceOptions.kBoundingBoxes`: 얼굴이 있는 영역의 좌표 정보를 반환합니다.

   `FaceOptions.kContours`: 얼굴의 윤곽선 정보를 반환합니다.

   `FaceOptions.kMasks`: 마스크 착용 여부를 반환합니다.

   `FaceOptions.kTrackingIDs`: 얼굴마다 ID를 할당해 반환합니다.

   `FaceOptions.kMojos`: `Mojo`라고 하는 얼굴 정보 값을 반환합니다. 일부 서비스에서만 사용하는 정보입니다.
   
   `FaceOptions.kSpoofs`: 얼굴이 진짜인지 가짜(디바이스, 프린트, 마스크)인지 여부를 반환합니다.

   `FaceOptions.kFeatures`: 얼굴의 특징 값을 반환합니다.

   `FaceOptions.kEulerAngles`: 얼굴이 향하고 있는 방향 정보를 X, Y, Z 값으로 반환합니다.

   `FaceOptions.kAll`: 위 여섯 가지 정보를 모두 반환합니다.

3. `set_minimum_bounding_box_size()` : 이미지를 기준으로 Face Detection의 결과를 반환할 얼굴의 최소 크기를 설정합니다.

4. `set_resize_threshold()` : Face Detection의 입력으로 들어갈 이미지의 장축 사이즈를 설정합니다. 기본값은 320 입니다. 


## `Face`에 반환되는 정보

`ClovaSee.run()`은 전달된 `Frame`에 있는 얼굴을 분석한 뒤 그 결과를 `Faces`에 담아 반환합니다. `Face`에 반환되는 정보는 아래와 같습니다.

1. `Face.bounding_box()`: 얼굴이 있는 영역의 좌표 정보가 `Rect` 형식으로 반환됩니다. 아래의 그림 1에서 초록색 사각 영역에 해당하는 정보입니다.

2. `Face.contour()`: 얼굴의 윤곽선 정보가 `Contour` 형식으로 반환됩니다. 아래의 그림 1에서 얼굴의 윤곽선을 따라 그려진 점들에 해당하는 정보입니다.

   `Settings.PerformanceMode.kAccurate106`: 106개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치와 색인 정보는 그림 2와 같습니다.

   `Settings.PerformanceMode.kAccurate98`: 98개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치와 색인 정보는 그림 3와 같습니다.

   `Settings.PerformanceMode.kFast`: 5개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치는 그림 4에서 빨간 점에 해당합니다.

3. `Face.mojo()`: 일부 서비스에서만 사용하는 정보입니다.

4. `Face.feature()`: 얼굴의 특징 값이 `Feature` 형식으로 반환됩니다.

5. `Face.euler_angle()`: 얼굴이 향하고 있는 방향 정보가 `EulerAngle` 형식으로 반환됩니다.

   `EulerAngle::x()`, `EulerAngle::pitch()`: 정면을 응시한 상태에서 머리를 위아래로 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 아래로 움직일 때 음수가 반환됩니다.

   `EulerAngle::y()`, `EulerAngle::yaw()`: 정면을 응시한 상태에서 머리를 좌우로 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 왼쪽으로 움직일 때 음수가 반환됩니다.

   `EulerAngle::z()`, `EulerAngle::roll()`: 정면을 응시한 상태에서 머리를 좌우 어깨쪽으로 갸웃거리며 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 왼쪽 어깨쪽으로 움직일 때 음수가 반환됩니다.

6. `Face.tracking_id()`: 얼굴마다 할당된 고유의 ID가 `TrackingID` 형식으로 반환됩니다. 이 ID는 0부터 시작하며 항상 양수입니다.

7. `Face.mask()`: 마스크 착용 여부가 `Mask` 형식으로 반환됩니다. 이 형식은 `bool`과 동일합니다. `true`는 마스크 착용을, `false`는 마스크 미착용을 의미합니다.

8. `Face.spoof()`: 얼굴이 진짜인지 가짜인지 여부가 `Spoof` 형식으로 반환됩니다. 이 형식은 `bool`과 동일합니다. `true`는 가짜 얼굴을, `false`는 진짜 얼굴을 의미합니다.

<img src="../figure_1.png" width=50%/><br/>
*그림 1*

<img src="../figure_2.png" width=50%/><br/>
*그림 2*

<img src="../figure_3.png" width=50%/><br/>
*그림 3*

<img src="../figure_4.png" width=50%/><br/>
*그림 4*
