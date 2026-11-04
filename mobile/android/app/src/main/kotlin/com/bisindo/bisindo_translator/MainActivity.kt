package com.bisindo.bisindo_translator

import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity(), HandLandmarkerHelper.LandmarkerListener {

    companion object {
        private const val CHANNEL = "com.bisindo.mediapipe/hand_landmark"
        private const val TAG = "MainActivity"
    }

    private var methodChannel: MethodChannel? = null
    private var handLandmarkerHelper: HandLandmarkerHelper? = null
    private val backgroundExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        handLandmarkerHelper = HandLandmarkerHelper(this, this)

        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "processJpegFrame" -> handleJpegFrame(call, result)
                "processYuvFrame" -> handleYuvFrame(call, result)
                "close" -> {
                    handLandmarkerHelper?.close()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleJpegFrame(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val rotation = call.argument<Int>("rotation") ?: 0
        if (bytes == null) {
            result.error("INVALID_ARG", "Frame bytes null", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bitmap != null) {
                    handLandmarkerHelper?.detectLiveStream(bitmap, rotation)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error decode JPEG: ${e.message}", e)
            }
        }
        result.success(true)
    }

    private fun handleYuvFrame(call: MethodCall, result: MethodChannel.Result) {
        val y = call.argument<ByteArray>("y")
        val u = call.argument<ByteArray>("u")
        val v = call.argument<ByteArray>("v")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val yRowStride = call.argument<Int>("yRowStride") ?: width
        val uvRowStride = call.argument<Int>("uvRowStride") ?: width
        val uvPixelStride = call.argument<Int>("uvPixelStride") ?: 1
        val rotation = call.argument<Int>("rotation") ?: 0

        if (y == null || u == null || v == null || width <= 0 || height <= 0) {
            result.error("INVALID_ARG", "YUV data invalid", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val bitmap = YuvUtils.yuv420ToBitmap(y, u, v, width, height, yRowStride, uvRowStride, uvPixelStride)
                if (bitmap != null) {
                    handLandmarkerHelper?.detectLiveStream(bitmap, rotation)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error convert YUV: ${e.message}", e)
            }
        }
        result.success(true)
    }

    override fun onResults(result: HandLandmarkerResult) {
        val allHands = mutableListOf<Map<String, Any>>()
        val landmarksList = result.landmarks()
        val handednessList = try { result.handedness() } catch (_: Exception) { null }

        for (i in landmarksList.indices) {
            val points = landmarksList[i].map { pt ->
                mapOf("x" to pt.x(), "y" to pt.y(), "z" to pt.z())
            }

            var label = "Unknown"
            var score = 0.0f
            if (handednessList != null && i < handednessList.size && handednessList[i].isNotEmpty()) {
                label = handednessList[i][0].categoryName()
                score = handednessList[i][0].score()
            }

            allHands.add(mapOf("landmarks" to points, "label" to label, "score" to score))
        }

        mainHandler.post {
            methodChannel?.invokeMethod("onHandLandmarks", allHands)
        }
    }

    override fun onError(error: String) {
        mainHandler.post {
            methodChannel?.invokeMethod("onLandmarkError", error)
        }
    }

    override fun onDestroy() {
        handLandmarkerHelper?.close()
        backgroundExecutor.shutdown()
        super.onDestroy()
    }
}
