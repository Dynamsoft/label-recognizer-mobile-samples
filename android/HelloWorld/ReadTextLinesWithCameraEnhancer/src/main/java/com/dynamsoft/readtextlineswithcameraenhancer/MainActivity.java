package com.dynamsoft.readtextlineswithcameraenhancer;

import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

import com.dynamsoft.core.CoreException;
import com.dynamsoft.core.ImageData;
import com.dynamsoft.core.LicenseManager;
import com.dynamsoft.core.LicenseVerificationListener;
import com.dynamsoft.core.RegionDefinition;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.DCECameraView;
import com.dynamsoft.dlr.DLRLineResult;
import com.dynamsoft.dlr.DLRResult;
import com.dynamsoft.dlr.LabelRecognizer;
import com.dynamsoft.dlr.LabelRecognizerException;
import com.dynamsoft.dlr.LabelResultListener;

import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private TextView tvRes;
    private DCECameraView mCameraView;
    private CameraEnhancer mCamera;
    private LabelRecognizer mRecognizer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Initialize license for Dynamsoft Label Recognizer SDK.
        // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
        // You can also request an extension for your trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=installer&package=android
        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, new LicenseVerificationListener() {
            @Override
            public void licenseVerificationCallback(boolean isSuccess, CoreException error) {
                if (!isSuccess) {
                    error.printStackTrace();
                    MainActivity.this.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            Toast ts = Toast.makeText(getBaseContext(), "error:" + error.getErrorCode() + " " + error.getMessage(), Toast.LENGTH_LONG);
                            ts.show();
                        }
                    });
                }
            }
        });

        tvRes = findViewById(R.id.tv_res);

        // Add camera view for previewing video.
        mCameraView = findViewById(R.id.dce_camera_view);

        // Create an instance of Dynamsoft Camera Enhancer for video streaming.
        mCamera = new CameraEnhancer(this);
        mCamera.setCameraView(mCameraView);

        // Define a scan region for recognition
        RegionDefinition region = new RegionDefinition(10, 40, 90, 60, 1);
        try {
            mCamera.setScanRegion(region);
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }

        try {
            // Create an instance of Dynamsoft Label Recognizer.
            mRecognizer = new LabelRecognizer();
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }

        // Bind the Camera Enhancer instance to the Label Recognizer instance.
        mRecognizer.setImageSource(mCamera);

        // Register the label result listener to get the recognized results from images.
        mRecognizer.setLabelResultListener(new LabelResultListener() {
            @Override
            public void labelResultCallback(int i, ImageData imageData, DLRResult[] dlrResults) {
                if (dlrResults != null && dlrResults.length > 0) {
                    showResults(dlrResults);
                }
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        try {
            mCamera.open();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        mRecognizer.startScanning();
    }

    @Override
    protected void onPause() {
        super.onPause();
        try {
            mCamera.close();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        mRecognizer.stopScanning();
    }

    private void showResults(DLRResult[] results) {
        StringBuilder resultBuilder = new StringBuilder();
        if (results != null) {
            for (DLRResult result : results) {
                for (DLRLineResult lineResult : result.lineResults) {
                    resultBuilder.append(lineResult.text).append("\n\n");
                }
            }
        }
        runOnUiThread(() -> tvRes.setText(resultBuilder.toString()));
    }
}