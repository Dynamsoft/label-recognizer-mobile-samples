package com.dynamsoft.readtextlineswithcameraenhancerkt

import android.content.res.Configuration
import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.MutableLiveData
import com.dynamsoft.core.basic_structures.CapturedResultReceiver
import com.dynamsoft.core.basic_structures.CompletionListener
import com.dynamsoft.core.basic_structures.DSRect
import com.dynamsoft.cvr.CaptureVisionRouter
import com.dynamsoft.cvr.CaptureVisionRouterException
import com.dynamsoft.cvr.EnumPresetTemplate
import com.dynamsoft.dce.CameraEnhancer
import com.dynamsoft.dce.CameraEnhancerException
import com.dynamsoft.dce.CameraView
import com.dynamsoft.dce.utils.PermissionUtil
import com.dynamsoft.dlr.RecognizedTextLinesResult
import com.dynamsoft.dlr.TextLineResultItem
import com.dynamsoft.license.LicenseManager


class MainActivity : AppCompatActivity() {
    private lateinit var tvRes: TextView
    private lateinit var mCamera: CameraEnhancer
    private lateinit var mRouter: CaptureVisionRouter
    private val deviceOrientation = MutableLiveData(Configuration.ORIENTATION_PORTRAIT)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        PermissionUtil.requestCameraPermission(this)

        // Initialize license for Dynamsoft Label Recognizer SDK.
        // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
        // You can also request an extension for your trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=installer&package=android
        LicenseManager.initLicense(
            "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9",
            this
        ) { isSuccess: Boolean, error: Exception ->
            if (!isSuccess) {
                error.printStackTrace()
                runOnUiThread {
                    val ts = Toast.makeText(
                        baseContext,
                        "error: " + error.message,
                        Toast.LENGTH_LONG
                    )
                    ts.show()
                }
            }
        }
        deviceOrientation.observe(
            this
        ) { orientationValue: Int ->
            if (orientationValue == Configuration.ORIENTATION_PORTRAIT) {
                val region = DSRect(0.1f, 0.4f, 0.9f, 0.6f, true)
                try {
                    mCamera.scanRegion = region
                } catch (e: CameraEnhancerException) {
                    e.printStackTrace()
                }
            } else if (orientationValue == Configuration.ORIENTATION_LANDSCAPE) {
                val region = DSRect(20f, 40f, 80f, 60f, false)
                try {
                    mCamera.scanRegion = region
                } catch (e: CameraEnhancerException) {
                    e.printStackTrace()
                }
            }
        }
        tvRes = findViewById(R.id.tv_res)

        // Add camera view for previewing video.
        val cameraView: CameraView = findViewById<CameraView>(R.id.dce_camera_view)
        cameraView.isScanRegionMaskVisible = true

        // Create an instance of Dynamsoft Camera Enhancer for video streaming.
        mCamera = CameraEnhancer(cameraView, this)
        mRouter = CaptureVisionRouter(this)
        try {
            mRouter.input = mCamera
        } catch (e: CaptureVisionRouterException) {
            throw RuntimeException(e)
        }
        mRouter.addResultReceiver(object : CapturedResultReceiver {
            override fun onRecognizedTextLinesReceived(result: RecognizedTextLinesResult) {
                showResults(result.items)
            }
        })
    }

    override fun onResume() {
        super.onResume()
        try {
            mCamera.open()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        mRouter.startCapturing(
            EnumPresetTemplate.PT_RECOGNIZE_TEXT_LINES,
            object : CompletionListener {
                override fun onSuccess() {}
                override fun onFailure(errorCode: Int, errorString: String) {
                    runOnUiThread {
                        Toast.makeText(
                            this@MainActivity,
                            errorString,
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
            })
    }

    public override fun onPause() {
        try {
            mCamera.close()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        mRouter.stopCapturing()
        super.onPause()
    }

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