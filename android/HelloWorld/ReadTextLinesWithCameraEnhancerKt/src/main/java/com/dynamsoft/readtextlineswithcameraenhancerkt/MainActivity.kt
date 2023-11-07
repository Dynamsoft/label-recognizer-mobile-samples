package com.dynamsoft.readtextlineswithcameraenhancerkt

import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.dynamsoft.core.LicenseManager
import com.dynamsoft.core.RegionDefinition
import com.dynamsoft.dce.CameraEnhancer
import com.dynamsoft.dce.CameraEnhancerException
import com.dynamsoft.dce.DCECameraView
import com.dynamsoft.dlr.DLRResult
import com.dynamsoft.dlr.LabelRecognizer
import com.dynamsoft.dlr.LabelRecognizerException


class MainActivity : AppCompatActivity() {
    private lateinit var tvRes: TextView
    private lateinit var mCameraView: DCECameraView
    private lateinit var mCamera: CameraEnhancer
    private lateinit var mRecognizer: LabelRecognizer
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize license for Dynamsoft Label Recognizer SDK.
        // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
        // You can also request an extension for your trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=installer&package=android
        LicenseManager.initLicense(
            "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this
        ) { isSuccess, error ->
            if (!isSuccess) {
                error.printStackTrace()
                runOnUiThread {
                    val ts = Toast.makeText(
                        baseContext,
                        "error:" + error.errorCode + " " + error.message,
                        Toast.LENGTH_LONG
                    )
                    ts.show()
                }
            }
        }
        tvRes = findViewById(R.id.tv_res)

        // Add camera view for previewing video.
        mCameraView = findViewById(R.id.dce_camera_view)

        // Create an instance of Dynamsoft Camera Enhancer for video streaming.
        mCamera = CameraEnhancer(this)
        mCamera.cameraView = mCameraView

        // Define a scan region for recognition
        val region = RegionDefinition(10, 40, 90, 60, 1)
        try {
            mCamera.scanRegion = region
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        try {
            // Create an instance of Dynamsoft Label Recognizer.
            mRecognizer = LabelRecognizer()
        } catch (e: LabelRecognizerException) {
            e.printStackTrace()
        }

        // Bind the Camera Enhancer instance to the Label Recognizer instance.
        mRecognizer.setImageSource(mCamera)

        // Register the label result listener to get the recognized results from images.
        mRecognizer.setLabelResultListener { _, _, dlrResults ->
            if (dlrResults != null && dlrResults.isNotEmpty()) {
                showResults(dlrResults)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            mCamera.open()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        mRecognizer.startScanning()
    }

    override fun onPause() {
        super.onPause()
        try {
            mCamera.close()
        } catch (e: CameraEnhancerException) {
            e.printStackTrace()
        }
        mRecognizer.stopScanning()
    }

    private fun showResults(results: Array<DLRResult>?) {
        val resultBuilder = StringBuilder()
        if (results != null) {
            for (result in results) {
                for (lineResult in result.lineResults) {
                    resultBuilder.append(lineResult.text).append("\n\n")
                }
            }
        }
        runOnUiThread { tvRes.text = resultBuilder.toString() }
    }
}