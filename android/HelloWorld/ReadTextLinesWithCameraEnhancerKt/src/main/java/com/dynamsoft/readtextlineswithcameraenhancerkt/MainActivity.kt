package com.dynamsoft.readtextlineswithcameraenhancerkt

import android.app.AlertDialog
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.dynamsoft.core.basic_structures.CompletionListener
import com.dynamsoft.core.basic_structures.DSRect
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType
import com.dynamsoft.cvr.CaptureVisionRouter
import com.dynamsoft.cvr.CaptureVisionRouterException
import com.dynamsoft.cvr.CapturedResultReceiver
import com.dynamsoft.cvr.EnumPresetTemplate
import com.dynamsoft.dce.CameraEnhancer
import com.dynamsoft.dce.CameraEnhancerException
import com.dynamsoft.dce.CameraView
import com.dynamsoft.dce.utils.PermissionUtil
import com.dynamsoft.dlr.RecognizedTextLinesResult
import com.dynamsoft.dlr.TextLineResultItem
import com.dynamsoft.license.LicenseManager
import com.dynamsoft.utility.MultiFrameResultCrossFilter
import java.util.Locale


class MainActivity : AppCompatActivity() {
    private lateinit var tvRes: TextView
    private lateinit var mCamera: CameraEnhancer
    private lateinit var mRouter: CaptureVisionRouter
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        PermissionUtil.requestCameraPermission(this)

        // Initialize license for Dynamsoft Label Recognizer SDK.
        // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
        // You can also request a 30-day trial license via the Request a Trial License link: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=android
        LicenseManager.initLicense(
            "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9",
            this
        ) { isSuccess, error ->
            if (!isSuccess) {
                error?.printStackTrace()
            }
        }

        tvRes = findViewById(R.id.tv_res)

        // Add camera view for previewing video.
        val cameraView: CameraView = findViewById<CameraView>(R.id.dce_camera_view)
        cameraView.isScanLaserVisible = true
        cameraView.isScanRegionMaskVisible = true

        // Create an instance of Dynamsoft Camera Enhancer for video streaming.
        mCamera = CameraEnhancer(cameraView, this)

        val filter = MultiFrameResultCrossFilter()
        filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE, true);
        mRouter = CaptureVisionRouter(this)
        mRouter.addResultFilter(filter)

        try {
            // Set camera enhance as the video input.
            mRouter.input = mCamera
        } catch (e: CaptureVisionRouterException) {
            throw RuntimeException(e)
        }
        // Set a scan region for the text line recognition.
        val region = DSRect(0.1f, 0.4f, 0.9f, 0.6f, true)
        try {
            mCamera.scanRegion = region
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        // The CapturedResultReceiver interface provides methods for monitoring the output of captured results. 
        // The CapturedResultReceiver can add a receiver for any type of captured result or for a specific type of captured result, based on the method that is implemented.
        mRouter.addResultReceiver(object : CapturedResultReceiver {
            // Implement this method to receive RecognizedTextLinesResult.
            override fun onRecognizedTextLinesReceived(result: RecognizedTextLinesResult) {
                showResults(result.items)
            }
        })
    }

    override fun onResume() {
        super.onResume()
        try {
            // Open the camera.
            mCamera.open()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        // Start capturing by specifying the preset template, PT_RECOGNIZE_TEXT_LINES.
        // onSuccess: Callback when the capture start succeed.
        // onFailure: Callback when the capture start failed.
        mRouter.startCapturing(
            EnumPresetTemplate.PT_RECOGNIZE_TEXT_LINES,
            object : CompletionListener {
                override fun onSuccess() = Unit
                override fun onFailure(errorCode: Int, errorString: String) {
                    runOnUiThread {
                        AlertDialog.Builder(this@MainActivity)
                            .setTitle("Error:")
                            .setMessage("ErrorCode: $errorCode \nErrorMessage: $errorString")
                            .setCancelable(true)
                            .setPositiveButton("OK", null)
                            .show()
                    }
                }
            })
    }

    public override fun onPause() {
        try {
            // Close the camera.
            mCamera.close()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        // Stop capturing.
        mRouter.stopCapturing()
        super.onPause()
    }

    // Show the recognized text line results.
    private fun showResults(results: Array<TextLineResultItem>?) {
        val resultBuilder = StringBuilder()
        if (results != null) {
            for (result in results) {
                resultBuilder.append(result.text).append("\n\n")
            }
        }
        runOnUiThread { tvRes.text = resultBuilder.toString() }
    }
}