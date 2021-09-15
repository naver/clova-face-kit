# Quick Developer Guide to CLOVA Face Kit for Android

## 예제 프로젝트

CLOVA Face Kit 적용법과 사용법은 [examples/android](../../examples/android)를 참고해주세요.

## 간단 사용법

1. `Context`를 가지고 `ClovaSee` 객체를 생성합니다. `ClovaSee` 객체를 생성할 때는 `Options`를 통해서 몇 가지 세부 옵션을 설정할 수 있는데 이 부분은 다음 절에서 설명합니다.

   ```Kotlin
   import ai.clova.see.ClovaSee

   val clovaSee = ClovaSee(context)
   ```

2. `ClovaSee`로 분석할 이미지를 `Bitmap`으로 만들어 준비합니다.

   ```Kotlin
   val bitmap = getBitmapFromSomewhere(...)
   ```

3. `Bitmap`에 있는 얼굴에서 어떠한 정보들을 분석할 것인지, 조건을 설정할 것인지 `face.OptionsBuilder()` 를 이용하여 `clova::face::Options`을 설정합니다. `face.Options`에서 설정할 수 있는 옵션들은 마지막 절에서 설명합니다.

   ```Kotlin
   val faceOptions = ai.clova.see.face.OptionsBuilder()
                               .setBoundingBoxThreshold(0.7f)
                               .setInformationToObtain(ai.clova.see.face.Options.CONTOURS or
                                                       ai.clova.see.face.Options.MASKS or
                                                       ai.clova.see.face.Options.EULER_ANGLES or
                                                       ai.clova.see.face.Options.TRACKING_IDS)
                               .setResizeThreshold(320)
                               .setMinimumBoundingBoxSize(0.1f)
                               .build()
   
   ```

4. 2에서 준비한 `Bitmap`과 3에서 준비한 `face.Options`을 가지고 `ClovaSee.run()`을 호출합니다. `ClovaSee.run()`은 주어진 `Bitmap`에 있는 얼굴 정보를 분석해서 결과를 `face.Result`에 담아 반환합니다. `Face`에 반환되는 정보는 마지막 절에서 설명합니다.

   ```Kotlin
   import ai.clova.see.Face

   val faces = clovaSee.run(bitmap, faceOptions.build())
   ```

5. 3에서 반환된 `Array<Face>`를 가지고 원하는 작업을 합니다.

   ```Kotlin
   import ai.clova.see.Contour
   import android.graphics.Canvas
   import android.graphics.Paint

   faces.forEach { face ->
       val canvas = getCanvasFromSomewhere(...)
       val paint = Paint()

       // Draw the face bounding box.
       canvas.drawRect(face.boundingBox, paint)
       // Draw the face contour points.
       face.contour.points.forEach { canvas.drawPoint(it.x.toFloat(), it.y.toFloat(), paint) }

       ...
   }
   ```

## 세부 옵션 설정 방법

`ClovaSee` 객체를 생성할 때 두 번째 매개변수에 `Settings` 객체를 전달하면 `ClovaSee`의 동작 방식과 관련된 몇 가지 세부 옵션을 제어할 수 있습니다. `Settings` 객체는 보통 `SettingsBuilder`를 통해서 만드는데, 사용 예와 주요 옵션의 의미는 아래와 같습니다.

```Kotlin
import ai.clova.see.ClovaSee
import ai.clova.see.Settings
import ai.clova.see.SettingsBuilder

val settings = SettingsBuilder()
    .setNumberOfThreads(4)
    .setPerformanceMode(Options.PerformanceMode.ACCURATE_98)
    .setIntermittentInformationRatio(1)
    .build()
val clovaSee = ClovaSee(context, settings)
```

1. `SettingsBuilder.setNumberOfThreads()`: `ClovaSee` 내부의 스레드 풀 크기를 설정합니다. 보통 실행 환경에 장착된 코어의 수(Big-Little 구조의 경우에는 Big의 수)로 설정하며, 기본 값은 4입니다.

2. `SettingsBuilder.setPerformanceMode()`: `ClovaSee`의 수행 속도와 반환되는 정보의 정확성 둘 중에 어떤 것이 더 중요한지를 설정합니다. 아래의 값들 중 하나를 설정하면 되며, 기본 값은 `Settings.PerformanceMode.ACCURATE_98`입니다. 현재 이 옵션으로 영향을 받는 반환 값은 `Face.contours` 뿐이지만 추후 확대될 수 있습니다.

   `Settings.PerformanceMode.ACCURATE_106`: `Face.contours`에 106개의 점으로 구성된 윤곽선 정보를 반환합니다.

   `Settings.PerformanceMode.ACCURATE_98`: `Face.contours`에 98개의 점으로 구성된 윤곽선 정보를 반환합니다.

   `Settings.PerformanceMode.FAST`: `Face.contours`에 5개의 점으로 구성된 윤곽선 정보를 반환합니다.

3. `SettingsBuilder.setIntermittentInformationRatio()`: 얼굴 분석을 수행할 주기를 프레임 수 단위로 지정합니다. 기본 값은 1입니다. 예를 들어, 5를 지정하면 `OptionsBuilder.setInformationToObtain()`으로 설정한 정보가 5프레임마다 한 번씩만 분석되어 반환됩니다. 단, `Options.BOUNDING_BOXES`는 이 주기와 상관 없이 항상 반환됩니다. 이처럼 사용자가 설정한 주기에 따라서만 분석되어 반환되는 정보를 Intermittent Information이라고 하며, `Options.BOUNDING_BOXES`를 제외한 나머지 모든 정보가 여기에 해당합니다.


## `face.Options`

1. `OptionsBuilder.setInformationToObtain()`: `ClovaSee`를 통해 알고자 하는 정보의 종류를 설정합니다. 아래의 값들 중 원하는 정보의 종류를 `or`로 묶어서 설정하면 됩니다. 필요한 정보의 종류만 간략하게 설정하면 `ClovaSee.run()`의 실행 시간을 줄이는데 도움이 됩니다. 기본 값은 `Options.ALL` 입니다.

   `Options.BOUNDING_BOXES`: 얼굴이 있는 영역의 좌표 정보를 반환합니다.

   `Options.CONTOURS`: 얼굴의 윤곽선 정보를 반환합니다.

   `Options.MASKS`: 마스크 착용 여부를 반환합니다.

   `Options.TRACKING_IDS`: 얼굴마다 ID를 할당해 반환합니다.

   `Options.MOJOS`: `Mojo`라고 하는 얼굴 정보 값을 반환합니다. 일부 서비스에서만 사용하는 정보입니다.
   
   `Options.SPOOFS`: 얼굴이 진짜인지 가짜(디바이스, 프린트, 마스크)인지 여부를 반환합니다.

   `Options.FEATURES`: 얼굴의 특징 값을 반환합니다.

   `Options.EULER_ANGLES`: 얼굴이 향하고 있는 방향 정보를 X, Y, Z 값으로 반환합니다.

   `Options.ALL`: 위 여섯 가지 정보를 모두 반환합니다.


## `Face`에 반환되는 정보

`ClovaSee.run()`은 전달된 `Bitmap`에 있는 얼굴을 분석한 뒤 그 결과를 `Array<Face>`에 담아 반환합니다. `Face`에 반환되는 정보는 아래와 같습니다.

1. `Face.boundingBox`: 얼굴이 있는 영역의 좌표 정보가 `Rect` 형식으로 반환됩니다. 아래의 그림 1에서 초록색 사각 영역에 해당하는 정보입니다.

2. `Face.contour`: 얼굴의 윤곽선 정보가 `Contour` 형식으로 반환됩니다. 아래의 그림 1에서 얼굴의 윤곽선을 따라 그려진 점들에 해당하는 정보입니다.

   `Options.PerformanceMode.ACCURATE_106`: 106개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치와 색인 정보는 그림 2와 같습니다.

   `Options.PerformanceMode.ACCURATE_98`: 98개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치와 색인 정보는 그림 3와 같습니다.

   `Options.PerformanceMode.FAST`: 5개의 점으로 구성된 윤곽선 정보가 반환됩니다. 점의 위치는 그림 4에서 빨간 점에 해당합니다.

3. `Face.mojo`: 일부 서비스에서만 사용하는 정보입니다.

4. `Face.feature`: 얼굴의 특징 값이 `Feature` 형식으로 반환됩니다.

5. `Face.eulerAngle`: 얼굴이 향하고 있는 방향 정보가 `EulerAngle` 형식으로 반환됩니다.

   `EulerAngle.x()`, `EulerAngle.pitch()`: 정면을 응시한 상태에서 머리를 위아래로 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 아래로 움직일 때 음수가 반환됩니다.

   `EulerAngle.y()`, `EulerAngle.yaw()`: 정면을 응시한 상태에서 머리를 좌우로 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 왼쪽으로 움직일 때 음수가 반환됩니다.

   `EulerAngle.z()`, `EulerAngle.roll()`: 정면을 응시한 상태에서 머리를 좌우 어깨쪽으로 갸웃거리며 움직일 때의 각입니다. 값의 범위는 -90도에서 90도이며, 왼쪽 어깨쪽으로 움직일 때 음수가 반환됩니다.

6. `Face.trackingID`: 얼굴마다 할당된 고유의 ID가 `TrackingID` 형식으로 반환됩니다. 이 ID는 0부터 시작하며 항상 양수입니다.

7. `Face.mask`: 마스크 착용 여부가 `Mask` 형식으로 반환됩니다. 이 형식은 `Boolean`과 동일합니다. `true`는 마스크 착용을, `false`는 마스크 미착용을 의미합니다.

<img src="../figure_1.png" width=50%/><br/>
*그림 1*

<img src="../figure_2.png" width=50%/><br/>
*그림 2*

<img src="../figure_3.png" width=50%/><br/>
*그림 3*

<img src="../figure_4.png" width=50%/><br/>
*그림 4*
