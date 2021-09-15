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

package ai.clova.see.example

import android.os.Bundle
import android.view.View
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.annotation.MainThread
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraX
import com.google.android.material.bottomsheet.BottomSheetBehavior
import kotlinx.android.synthetic.main.bottom_sheet.*
import timber.log.Timber

private const val FLAGS_FULLSCREEN =
    View.SYSTEM_UI_FLAG_FULLSCREEN or
    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
    View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
    View.SYSTEM_UI_FLAG_LOW_PROFILE

class MainActivity :
    AppCompatActivity(),
    CameraControllable,
    ClovaSeeControllable,
    OnImageAnalysisResultListener
{
    private lateinit var fragmentHolder: FrameLayout
    private lateinit var cameraController: CameraController
    private lateinit var clovaSeeController: ClovaSeeController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initializeUi()
    }

    override fun onResume() {
        super.onResume()
        fragmentHolder.postDelayed({ fragmentHolder.systemUiVisibility = FLAGS_FULLSCREEN }, 500L)
    }

    @MainThread
    override fun onImageAnalysisResult(result: CameraFragment.ImageAnalysisResult) {
        if (clovaSeeController.isLogging()) {
            Timber.v("$result")
        }
        performance.setText(String.format("%.2ffps", result.totalFps))
        native_total.setText(String.format("%.2ffps", result.nativeTotalFps))
        aligner.setText(String.format("%.2fms", result.alignerInMilli))
        detector.setText(String.format("%.2fms", result.detectorInMilli))
        estimator.setText(String.format("%.2fms", result.estimatorInMilli))
        landmarker.setText(String.format("%.2fms", result.landmarkerInMilli))
        recognizer.setText(String.format("%.2fms", result.recognizerInMilli))
        tracker.setText(String.format("%.2fms", result.trackerInMilli))
        mask_detector.setText(String.format("%.2fms", result.maskDetectorInMilli))
        spoofing_detector.setText(String.format("%.2fms", result.spoofingDetectorInMilli))
    }

    override fun setCameraController(controller: CameraController) {
        cameraController = controller
    }

    override fun setClovaSeeController(controller: ClovaSeeController) {
        clovaSeeController = controller
    }

    private fun initializeUi() {
        fragmentHolder = findViewById(R.id.fragment_holder)

        val bottomSheetBehavior = BottomSheetBehavior.from(bottom_sheet)
        bottomSheetBehavior.isHideable = false
        bottomSheetBehavior.setBottomSheetCallback(
            object: BottomSheetBehavior.BottomSheetCallback() {
                override fun onSlide(bottomSheet: View, slideOffset: Float) {}

                override fun onStateChanged(bottomSheet: View, newState: Int) {
                    when (newState) {
                        BottomSheetBehavior.STATE_COLLAPSED,
                        BottomSheetBehavior.STATE_SETTLING ->
                            bottom_sheet_chevron.setImageResource(R.drawable.icon_chevron_up)
                        BottomSheetBehavior.STATE_EXPANDED ->
                            bottom_sheet_chevron.setImageResource(R.drawable.icon_chevron_down)
                        else -> Unit
                    }
                }
            })

        bottom_sheet_peekable.viewTreeObserver.addOnGlobalLayoutListener(
                object: ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                bottom_sheet_peekable.viewTreeObserver.removeOnGlobalLayoutListener(this)
                bottomSheetBehavior.peekHeight = bottom_sheet_peekable.measuredHeight
            }
        })

        toggle_clova_see.setOnClickListener {
            val (nextState, nextIcon) = if (clovaSeeController.isBypassed()) {
                Pair(false, R.drawable.icon_clova_see_off)
            } else {
                Pair(true, R.drawable.icon_clova_see_on)
            }
            clovaSeeController.setBypassed(nextState)
            toggle_clova_see.setImageResource(nextIcon)
        }

        toggle_camera.setOnClickListener {
            val currentState = cameraController.getCameraFacing()
            val (nextState, nextIcon) = if (currentState == CameraX.LensFacing.FRONT) {
                Pair(CameraX.LensFacing.BACK, R.drawable.icon_camera_front)
            } else {
                Pair(CameraX.LensFacing.FRONT, R.drawable.icon_camera_rear)
            }
            cameraController.setCameraFacing(nextState)
            toggle_camera.setImageResource(nextIcon)
        }

        toggle_logging.setOnClickListener {
            val (nextState, nextIcon) = if (clovaSeeController.isLogging()) {
                Pair(false, R.drawable.icon_log_off)
            } else {
                Pair(true, R.drawable.icon_log_on)
            }
            clovaSeeController.setIsLogging(nextState)
            toggle_logging.setImageResource(nextIcon)
        }

        run_for_body.setOnClickListener {
            clovaSeeController.setRunType(ClovaSeeController.RunType.BODY)
        }

        run_for_face.setOnClickListener {
            clovaSeeController.setRunType(ClovaSeeController.RunType.FACE)
        }

        run_for_ocr.setOnClickListener {
            clovaSeeController.setRunType(ClovaSeeController.RunType.OCR)
        }
    }
}
