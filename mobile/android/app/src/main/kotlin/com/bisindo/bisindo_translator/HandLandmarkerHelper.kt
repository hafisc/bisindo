package com.bisindo.bisindo_translator

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class HandLandmarkerHelper(
    private val context: Context,
    private val listener: LandmarkerListener
) {
    private var handLandmarker: HandLandmarker? = null
    private var lastTimestampMs: Long = 0

    companion object {
        private const val TAG = "HandLandmarkerHelper"
        const val MODEL_NAME = "hand_landmarker.task"
    }

    init {
        setupHandLandmarker()
    }

    @Synchronized
    fun setupHandLandmarker() {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(MODEL_NAME)
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinHandDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setNumHands(2)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener { result: HandLandmarkerResult, _: MPImage ->
                listener.onResults(result)
            }
            .setErrorListener { error: RuntimeException ->
                Log.e(TAG, "MediaPipe error: ${error.message}", error)
                listener.onError(error.message ?: "Unknown MediaPipe error")
            }
            .build()

        try {
            handLandmarker = HandLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal inisialisasi MediaPipe: ${e.message}", e)
            listener.onError("Gagal inisialisasi MediaPipe: ${e.message}")
        }
    }

    @Synchronized
    fun detectLiveStream(bitmap: Bitmap, rotationDegrees: Int = 0) {
        if (handLandmarker == null) {
            setupHandLandmarker()
            if (handLandmarker == null) return
        }

        try {
            val processedBitmap = if (rotationDegrees != 0) {
                val matrix = Matrix().apply { postRotate(rotationDegrees.toFloat()) }
                Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            } else {
                bitmap
            }

            val mpImage = BitmapImageBuilder(processedBitmap).build()

            // Pastikan timestamp selalu strictly monotonically increasing
            var frameTime = SystemClock.uptimeMillis()
            if (frameTime <= lastTimestampMs) {
                frameTime = lastTimestampMs + 1
            }
            lastTimestampMs = frameTime

            handLandmarker?.detectAsync(mpImage, frameTime)
        } catch (e: Exception) {
            Log.e(TAG, "Error detectAsync: ${e.message}", e)
            listener.onError("Error detectAsync: ${e.message}")
        }
    }

    @Synchronized
    fun close() {
        try {
            handLandmarker?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error close: ${e.message}", e)
        } finally {
            handLandmarker = null
            lastTimestampMs = 0
        }
    }

    interface LandmarkerListener {
        fun onResults(result: HandLandmarkerResult)
        fun onError(error: String)
    }
}
