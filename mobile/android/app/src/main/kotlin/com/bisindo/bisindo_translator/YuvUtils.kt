package com.bisindo.bisindo_translator

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import kotlin.math.min

object YuvUtils {

    fun yuv420ToBitmap(
        yPlane: ByteArray,
        uPlane: ByteArray,
        vPlane: ByteArray,
        width: Int,
        height: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int
    ): Bitmap? {
        val nv21 = ByteArray(width * height * 3 / 2)
        var yPos = 0
        for (row in 0 until height) {
            val srcOffset = row * yRowStride
            if (srcOffset < yPlane.size) {
                val length = min(width, yPlane.size - srcOffset)
                System.arraycopy(yPlane, srcOffset, nv21, yPos, length)
            }
            yPos += width
        }

        var uvPos = width * height
        val uvHeight = height / 2
        val uvWidth = width / 2
        for (row in 0 until uvHeight) {
            val uRowStart = row * uvRowStride
            val vRowStart = row * uvRowStride
            for (col in 0 until uvWidth) {
                val vIndex = vRowStart + col * uvPixelStride
                val uIndex = uRowStart + col * uvPixelStride
                if (vIndex < vPlane.size && uIndex < uPlane.size && uvPos + 1 < nv21.size) {
                    nv21[uvPos++] = vPlane[vIndex]
                    nv21[uvPos++] = uPlane[uIndex]
                }
            }
        }

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 70, out)
        val jpegBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
    }
}

