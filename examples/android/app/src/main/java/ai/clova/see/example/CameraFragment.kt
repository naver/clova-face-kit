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

import ai.clova.see.ClovaSee
import ai.clova.see.Document
import ai.clova.see.Face
import ai.clova.see.MeasureResult
import ai.clova.see.Segment
import ai.clova.see.Settings
import ai.clova.see.SettingsBuilder
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.util.DisplayMetrics
import android.view.LayoutInflater
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.camera.core.CameraX
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageAnalysisConfig
import androidx.camera.core.ImageProxy
import androidx.core.graphics.and
import androidx.fragment.app.Fragment
import androidx.navigation.Navigation
import java.lang.Exception
import java.util.ArrayDeque
import kotlin.collections.ArrayList
import timber.log.Timber

class ClovaSeeRunResult(
    val face: ai.clova.see.face.Result,
    val body: ai.clova.see.body.Result,
    val ocr: ai.clova.see.ocr.Result
)

typealias ClovaSeeRunnerListener = (
    viewfinderFrame: Bitmap,
    result: ClovaSeeRunResult,
    measureResult: MeasureResult
) -> Unit

typealias ClovaSeeComparerPickerCallback = (Bitmap, Face) -> Unit

/**
 * CameraControllable
 */
interface CameraControllable {
    fun setCameraController(controller: CameraController)
}

/**
 * CameraController
 */
interface CameraController {
    fun getCameraFacing(): CameraX.LensFacing
    fun setCameraFacing(lensFacing: CameraX.LensFacing)
}

/**
 * ClovaSeeControllable
 */
interface ClovaSeeControllable {
    fun setClovaSeeController(controller: ClovaSeeController)
}

/**
 * ClovaSeeController
 */
interface ClovaSeeController {
    enum class RunType { FACE, BODY, OCR }

    fun isBypassed(): Boolean
    fun setBypassed(set: Boolean)
    fun getRunType(): RunType
    fun setRunType(set: RunType)
    fun isLogging(): Boolean
    fun setIsLogging(isLogging: Boolean)
}

/**
 * OnImageAnalysisResultListener
 */
interface OnImageAnalysisResultListener {
    fun onImageAnalysisResult(result: CameraFragment.ImageAnalysisResult)
}

class CameraFragment :
    Fragment(),
    CameraController,
    ClovaSeeController
{
    private lateinit var rootView: FrameLayout
    private lateinit var viewfinder: TextureView
    private lateinit var comparerView: ImageView

    private var lensFacing = CameraX.LensFacing.FRONT
    private var imageAnalyzer: ImageAnalysis? = null
    private val imageAnalyzerThread = HandlerThread("ImageAnalyzerThread").apply { start() }

    private lateinit var displayManager: DisplayManager
    private var displayId = -1
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) = view?.let { view ->
            if (displayId == this@CameraFragment.displayId) {
                Timber.d("rotation changed: ${view.display.rotation}")
                imageAnalyzer?.setTargetRotation(view.display.rotation)
            }
        } ?: Unit
    }

    private var imageAnalysisResultListener: OnImageAnalysisResultListener? = null
    private var bypassClovaSee = false
    private var runType = ClovaSeeController.RunType.FACE
    private var isMeasureResultLogging = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        retainInstance = true
        setOnImageAnalysisResultListener(requireActivity() as OnImageAnalysisResultListener)
        (requireActivity() as CameraControllable)
            .setCameraController(this as CameraController)
        (requireActivity() as ClovaSeeControllable)
            .setClovaSeeController(this as ClovaSeeController)
    }

    override fun onResume() {
        super.onResume()
        if (!PermissionsFragment.hasPermissions(requireContext())) {
            navigateToPermissionsFragment()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_camera, container, false)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        displayManager.unregisterDisplayListener(displayListener)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        rootView = view as FrameLayout
        viewfinder = rootView.findViewById(R.id.viewfinder)
        comparerView = rootView.findViewById(R.id.comparerView)

        displayManager = viewfinder.context.getSystemService(Context.DISPLAY_SERVICE)
            as DisplayManager
        displayManager.registerDisplayListener(displayListener, null)

        viewfinder.post {
            displayId = viewfinder.display.displayId
            initializeCamera()
        }
        viewfinder.setOnTouchListener { _, event ->
            ClovaSeeComparerPicker.request(event.x, event.y, { bitmap, face ->
                ClovaSeeResultRenderer.setComparerFace(face)
                comparerView.post { comparerView.setImageBitmap(bitmap) }
            })
            true
        }
    }

    override fun getCameraFacing() = lensFacing

    @SuppressLint("RestrictedApi")
    override fun setCameraFacing(lensFacing: CameraX.LensFacing) {
        if (this.lensFacing == lensFacing)
            return

        try {
            this.lensFacing = lensFacing
            CameraX.getCameraWithLensFacing(lensFacing)
            CameraX.unbindAll()
            initializeCamera()
        } catch (e: Exception) {
            Timber.e(e)
        }
    }

    override fun isBypassed() = bypassClovaSee

    override fun setBypassed(set: Boolean) {
        bypassClovaSee = set
    }

    override fun getRunType() = runType

    override fun setRunType(set: ClovaSeeController.RunType) {
        runType = set
    }

    fun setOnImageAnalysisResultListener(listener: OnImageAnalysisResultListener) {
        imageAnalysisResultListener = listener
    }

    private fun navigateToPermissionsFragment() {
        Navigation.findNavController(requireActivity(), R.id.fragment_holder)
            .navigate(CameraFragmentDirections.actionCameraToPermissions())
    }

    private fun initializeCamera() {
        val displayMetrics = DisplayMetrics().also { viewfinder.display.getRealMetrics(it) }
        Timber.d("display metrics: ${displayMetrics.widthPixels} x ${displayMetrics.heightPixels}")
        ClovaSeeComparerPicker.setDisplayMetrics(displayMetrics)

        val imageAnalysisConfig = ImageAnalysisConfig.Builder().apply {
            setCallbackHandler(Handler(imageAnalyzerThread.looper))
            setImageReaderMode(ImageAnalysis.ImageReaderMode.ACQUIRE_LATEST_IMAGE)
            setLensFacing(lensFacing)
            setTargetRotation(viewfinder.display.rotation)
            // It is recommended to set the frame size to 360p due to cpu performance.
            setTargetAspectRatio(android.util.Rational(9, 16))
            setTargetResolution(android.util.Size(360, 640))
        }.build()

        imageAnalyzer = ImageAnalysis(imageAnalysisConfig).apply {
            ClovaSeeResultRenderer.setBackground(
                BitmapFactory.decodeResource(resources, R.drawable.segment_background))
            analyzer = ClovaSeeRunner(requireContext(), lensFacing) { frame, result, measureResult ->
                ClovaSeeComparerPicker.process(frame, result.face.faces)
                ClovaSeeResultRenderer.render(frame, result)
                drawViewfinderFrame(frame)
                rootView.post {
                    imageAnalysisResultListener?.onImageAnalysisResult(ImageAnalysisResult(
                        measureResult.alignerInMilli,
                        measureResult.detectorInMilli,
                        measureResult.estimatorInMilli,
                        measureResult.landmarkerInMilli,
                        measureResult.maskDetectorInMilli,
                        measureResult.recognizerInMilli,
                        measureResult.smootherDetectorInMilli,
                        measureResult.smootherLandmarkerInMilli,
                        measureResult.spoofingDetectorInMilli,
                        measureResult.trackerInMilli,
                        measureResult.totalFps,
                        (analyzer as ClovaSeeRunner).framesPerSecond
                    ))
                }
            }
        }

        CameraX.unbindAll()
        CameraX.bindToLifecycle(viewLifecycleOwner, imageAnalyzer)
    }

    private fun drawViewfinderFrame(frame: Bitmap) {
        val canvas = viewfinder.lockCanvas()
        if (canvas != null) {
            val scaleRatio = canvas.width.toFloat() / frame.width
            val matrix = Matrix().apply { postScale(scaleRatio, scaleRatio) }
            canvas.drawBitmap(frame, matrix, Paint())
            viewfinder.unlockCanvasAndPost(canvas)
        }
    }

    /**
     * ImageAnalysisResult
     */
    data class ImageAnalysisResult(
        val alignerInMilli: Float = 0.0f,
        val detectorInMilli: Float = 0.0f,
        val estimatorInMilli: Float = 0.0f,
        val landmarkerInMilli: Float = 0.0f,
        val maskDetectorInMilli: Float = 0.0f,
        val recognizerInMilli: Float = 0.0f,
        val smootherDetectorInMilli: Float = 0.0f,
        val smootherLandmarkerInMilli: Float = 0.0f,
        val spoofingDetectorInMilli: Float = 0.0f,
        val trackerInMilli: Float = 0.0f,
        val nativeTotalFps: Float = 0.0f,
        val totalFps: Float = 0.0f
    )

    /**
     * ClovaSeeRunner
     */
    private inner class ClovaSeeRunner(
        context: Context,
        lensFacing: CameraX.LensFacing,
        listener: ClovaSeeRunnerListener? = null
    ) : ImageAnalysis.Analyzer {
        private val listeners =
            ArrayList<ClovaSeeRunnerListener>().apply { listener?.let { add(it) } }
        private val imageProcessor = ImageProcessor(lensFacing)
        private val clovaSee: ClovaSee

        private val frameRateWindow = 8
        private val frameTimestamps = ArrayDeque<Long>(5)
        var framesPerSecond: Float = -1.0f
            private set

        init {
            val settings = SettingsBuilder()
                .setIntermittentInformationRatio(1)
                .setNumberOfThreads(4)  // Set the maximum number of threads to be used by ClovaSee.
                .setPerformanceMode(Settings.PerformanceMode.ACCURATE_106)
                .build()
            clovaSee = ClovaSee(context, settings)
            // clovaSee = ClovaSee(context, settings, "file:///android_asset/clovasee.bundle")
            // clovaSee = ClovaSee(context, settings, "/data/local/tmp/clovasee.bundle")
        }

        override fun analyze(imageProxy: ImageProxy?, rotationDegrees: Int) {
            if (listeners.isEmpty())
                return

            // convertYUV420ToARGB8888 is very naive implementation.!!
            // It is recommended to use the optimized implementation within the service.!!
            val bitmap = imageProcessor.toBitmap(imageProxy!!.image, rotationDegrees)

            // val testInput = BitmapFactory.decodeResource(resources, R.drawable.test_input_body)
            // val testInput = BitmapFactory.decodeResource(resources, R.drawable.test_input_face)
            // val testInput = BitmapFactory.decodeResource(resources, R.drawable.test_input_ocr)
            // val bitmap = Bitmap.createBitmap(testInput.width, testInput.height, testInput.config)
            // val canvas = Canvas(bitmap)
            // canvas.drawBitmap(testInput, 0.0f, 0.0f, Paint())

            if (bitmap == null || bitmap.width == 0 || bitmap.height == 0)
                return

            val (result, measureResult) = if (bypassClovaSee) {
                Pair(
                    ClovaSeeRunResult(
                        ai.clova.see.face.Result(emptyArray()),
                        ai.clova.see.body.Result(Segment(0)),
                        ai.clova.see.ocr.Result(Document())
                    ),
                    MeasureResult()
                )
            } else {
                when (runType) {
                    ClovaSeeController.RunType.BODY -> {
                        Pair(
                            ClovaSeeRunResult(
                                ai.clova.see.face.Result(emptyArray()),
                                clovaSee.run(bitmap, ai.clova.see.body.OptionsBuilder().build()),
                                ai.clova.see.ocr.Result(Document())
                            ),
                            clovaSee.getMeasureResult()
                        )
                    }
                    ClovaSeeController.RunType.OCR -> {
                        Pair(
                            ClovaSeeRunResult(
                                ai.clova.see.face.Result(emptyArray()),
                                ai.clova.see.body.Result(Segment(0)),
                                clovaSee.run(bitmap, ai.clova.see.ocr.OptionsBuilder().build())
                            ),
                            clovaSee.getMeasureResult()
                        )
                    }
                    else -> {
                        val faceOptions = ai.clova.see.face.OptionsBuilder()
                            .setBoundingBoxThreshold(0.7f)
                            .setInformationToObtain(ai.clova.see.face.Options.CONTOURS or
                                                    ai.clova.see.face.Options.MASKS or
                                                    ai.clova.see.face.Options.EULER_ANGLES or
                                                    ai.clova.see.face.Options.TRACKING_IDS)
                            .setResizeThreshold(320)
                            .setMinimumBoundingBoxSize(0.1f)
                            .build()
                        Pair(
                            ClovaSeeRunResult(
                                clovaSee.run(bitmap, faceOptions),
                                ai.clova.see.body.Result(Segment(0)),
                                ai.clova.see.ocr.Result(Document())
                            ),
                            clovaSee.getMeasureResult()
                        )
                    }
                }
            }
            listeners.forEach { it(bitmap, result, measureResult) }

            calculateFramesPerSecond()
        }

        private fun calculateFramesPerSecond() {
            // Keep track of frames analyzed.
            frameTimestamps.push(System.currentTimeMillis())

            // Compute the FPS using a moving average.
            while (frameTimestamps.size >= frameRateWindow)
                frameTimestamps.removeLast()
            framesPerSecond = 1.0f / ((frameTimestamps.peekFirst()!! -
                    frameTimestamps.peekLast()!!) / frameTimestamps.size.toFloat()) * 1000.0f
        }
    }

    /**
     * ClovaSeeComparerPicker
     */
    private object ClovaSeeComparerPicker {
        private var displayMetrics: DisplayMetrics? = null
        private var displayX = 0
        private var displayY = 0
        private var callback: ClovaSeeComparerPickerCallback? = null

        fun setDisplayMetrics(displayMetrics: DisplayMetrics) {
            this.displayMetrics = displayMetrics
        }

        fun request(x: Float, y: Float, callback: ClovaSeeComparerPickerCallback?) {
            displayX = x.toInt()
            displayY = y.toInt()
            this.callback = callback
        }

        fun process(frame: Bitmap, faces: Array<Face>) {
            val scaleRatio = getScaleRatio(frame)
            val x = (displayX / scaleRatio).toInt()
            val y = (displayY / scaleRatio).toInt()

            for (face in faces) {
                if (face.boundingBox.contains(x, y)) {
                    val cropRect = face.boundingBox and Rect(0, 0, frame.width, frame.height)
                    callback?.invoke(cropBitmap(frame, cropRect), face)
                    break
                }
            }
            clearRequest()
        }

        private fun getScaleRatio(frame: Bitmap): Float {
            val displayMetrics = displayMetrics ?: return 1.0f
            return displayMetrics.widthPixels.toFloat() / frame.width
        }

        private fun cropBitmap(source: Bitmap, rect: Rect) =
            Bitmap.createBitmap(source, rect.left, rect.top, rect.width(), rect.height())

        private fun clearRequest() {
            displayX = 0
            displayY = 0
            callback = null
        }
    }

    /**
     * ClovaSeeResultRenderer
     */
    private object ClovaSeeResultRenderer {
        private val positivePaint = Paint().apply {
            color = Color.GREEN
            strokeWidth = 1.5f
            style = Paint.Style.STROKE
        }

        private val negativePaint = Paint().apply {
            color = Color.RED
            strokeWidth = 1.5f
            style = Paint.Style.STROKE
        }

        private var comparerFace: Face? = null
        private var background: Bitmap? = null

        fun setComparerFace(face: Face) {
            comparerFace = face
        }

        fun setBackground(bitmap: Bitmap) {
            background = bitmap;
        }

        fun render(frame: Bitmap, result: ClovaSeeRunResult) {
            val canvas = Canvas(frame)
            result.face.faces.forEach { face ->
                val paint = determinePaint(face, comparerFace)
                renderBoundingBox(canvas, paint, face)
                renderContour(canvas, paint, face)
                renderSpoof(canvas, paint, face)
                renderMask(canvas, paint, face)
                renderTrackingID(canvas, paint, face)
                renderSimilarity(canvas, paint, face)
            }
            renderSegment(canvas, result.body)
            renderDocument(canvas, result.ocr)
        }

        private fun determinePaint(face1: Face?, face2: Face?): Paint {
            if (face1 == null || face2 == null)
                return positivePaint
            if (Face.isSame(face1, face2))
                return positivePaint
            return negativePaint
        }

        private fun renderBoundingBox(canvas: Canvas, paint: Paint, face: Face) =
            canvas.drawRect(face.boundingBox, paint)

        private fun renderContour(canvas: Canvas, paint: Paint, face: Face) =
            face.contour.points.forEach { canvas.drawPoint(it.x.toFloat(), it.y.toFloat(), paint) }

        private fun renderSpoof(canvas: Canvas, paint: Paint, face: Face) {
            if (face.spoof) {
                val left = face.boundingBox.left.toFloat()
                val top = face.boundingBox.top.toFloat()
                val right = face.boundingBox.right.toFloat()
                val bottom = face.boundingBox.bottom.toFloat()
                canvas.drawLine(left, top, right, bottom, paint)
                canvas.drawLine(right, top, left, bottom, paint)
            }
        }

        private fun renderMask(canvas: Canvas, paint: Paint, face: Face) {
            canvas.drawRect(face.boundingBox,
                            Paint(paint).apply {
                                if (face.mask) {
                                    color = color and 0x6fffffff
                                    style = Paint.Style.FILL
                                }
                            })
        }

        private fun renderTrackingID(canvas: Canvas, paint: Paint, face: Face) {
            canvas.drawText("id=${face.trackingID}",
                            face.boundingBox.left.toFloat(),
                            face.boundingBox.top.toFloat(),
                            Paint(paint).apply {
                                style = Paint.Style.FILL
                                textSize = 18.0f
                            })
        }

        private fun renderSimilarity(canvas: Canvas, paint: Paint, face: Face) {
            if (comparerFace == null)
                return

            canvas.drawText("${Face.getCosineSimilarity(face, comparerFace!!)}",
                            face.boundingBox.left.toFloat(),
                            face.boundingBox.bottom.toFloat(),
                            Paint(paint).apply {
                                style = Paint.Style.FILL
                                textSize = 18.0f
                            })
        }

        private fun renderSegment(
            canvas: Canvas,
            body: ai.clova.see.body.Result
        ) {
            if (body.segment.isEmpty())
                return

            val offBitmap = Bitmap.createBitmap(canvas.width, canvas.height, background!!.config)
            val offCanvas = Canvas(offBitmap)
            offCanvas.drawBitmap(background!!, 0.0f, 0.0f, Paint())

            val alphaMask = Bitmap.createBitmap(canvas.width, canvas.height, Bitmap.Config.ALPHA_8)
            val alphaPixels = body.segment.map { pixel -> (pixel.toInt()).shl(24) or 0x00ffffff }
            alphaMask.setPixels(alphaPixels.toIntArray(), 0, canvas.width, 0, 0, canvas.width, canvas.height)
            offCanvas.drawBitmap(alphaMask, 0.0f, 0.0f, Paint().apply {
                xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_OUT)
            })

            canvas.drawBitmap(offBitmap, 0.0f, 0.0f, Paint())
        }

        private fun renderDocument(canvas: Canvas, ocr: ai.clova.see.ocr.Result) {
            canvas.drawPath(Path().apply {
                moveTo(ocr.document.leftTop.x.toFloat(), ocr.document.leftTop.y.toFloat())
                lineTo(ocr.document.rightTop.x.toFloat(), ocr.document.rightTop.y.toFloat())
                lineTo(ocr.document.rightBottom.x.toFloat(), ocr.document.rightBottom.y.toFloat())
                lineTo(ocr.document.leftBottom.x.toFloat(), ocr.document.leftBottom.y.toFloat())
                lineTo(ocr.document.leftTop.x.toFloat(), ocr.document.leftTop.y.toFloat())
            }, positivePaint)
        }
    }

    override fun isLogging() = isMeasureResultLogging

    override fun setIsLogging(isLogging: Boolean) {
        isMeasureResultLogging = isLogging
    }

}
