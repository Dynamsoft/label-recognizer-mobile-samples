package com.dynamsoft.readtextlineswithcameraenhancer;

import android.app.AlertDialog;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.DSRect;
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType;
import com.dynamsoft.cvr.CaptureVisionRouter;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.CapturedResultReceiver;
import com.dynamsoft.cvr.EnumPresetTemplate;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.utils.PermissionUtil;
import com.dynamsoft.dlr.RecognizedTextLinesResult;
import com.dynamsoft.dlr.TextLineResultItem;
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.Locale;

public class MainActivity extends AppCompatActivity {
    private TextView tvRes;
    private CameraEnhancer mCamera;
    private CaptureVisionRouter mRouter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        PermissionUtil.requestCameraPermission(this);

        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=samples&package=android
        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, (isSuccess, error) -> {
            if (!isSuccess) {
                error.printStackTrace();
                runOnUiThread(()-> ((TextView) findViewById(R.id.tv_license_error)).setText("License initialization failed: "+error.getMessage()));
            }
        });

        tvRes = findViewById(R.id.tv_res);

        // Add camera view for previewing video.
        CameraView cameraView = findViewById(R.id.dce_camera_view);
        cameraView.setScanRegionMaskVisible(true);
        cameraView.setScanLaserVisible(true);

        // Create an instance of Dynamsoft Camera Enhancer for video streaming.
        mCamera = new CameraEnhancer(cameraView, this);

        MultiFrameResultCrossFilter filter = new MultiFrameResultCrossFilter();
        filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE, true);

        // Create an instance of Dynamsoft Capture Vision Router (CVR).  The CVR instance will responsible for retrieving images and dispatch results.
        mRouter = new CaptureVisionRouter(this);
        mRouter.addResultFilter(filter);
        try {
            // Set camera enhance as the video input.
            mRouter.setInput(mCamera);
        } catch (CaptureVisionRouterException e) {
            throw new RuntimeException(e);
        }
        // Set a scan region for the text line recognition.
        DSRect region = new DSRect(0.1f, 0.4f, 0.9f, 0.6f, true);
        try {
            mCamera.setScanRegion(region);
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        // The CapturedResultReceiver interface provides methods for monitoring the output of captured results.
        // The CapturedResultReceiver can add a receiver for any type of captured result or for a specific type of captured result, based on the method that is implemented.
        mRouter.addResultReceiver(new CapturedResultReceiver() {
            @Override
            // Implement this method to receive RecognizedTextLinesResult.
            public void onRecognizedTextLinesReceived(RecognizedTextLinesResult result) {
                showResults(result.getItems());
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        try {
            // Open the camera.
            mCamera.open();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        // Start capturing by specifying the preset template, PT_RECOGNIZE_TEXT_LINES.
        mRouter.startCapturing(EnumPresetTemplate.PT_RECOGNIZE_TEXT_LINES, new CompletionListener() {
            @Override
            // Callback when the capture start succeed.
            public void onSuccess() {
            }

            @Override
            // Callback when the capture start failed.
            public void onFailure(int errorCode, String errorString) {
                runOnUiThread(() -> new AlertDialog.Builder(MainActivity.this).setTitle("Error:")
                        .setMessage(String.format(Locale.getDefault(), "ErrorCode: %d %nErrorMessage: %s", errorCode, errorString))
                        .setCancelable(true)
                        .setPositiveButton("OK", null)
                        .show());
            }
        });
    }

    public void onPause() {
        try {
            // Close the camera.
            mCamera.close();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        // Stop capturing.
        mRouter.stopCapturing();
        super.onPause();
    }

    // Show the recognized text line results.
    private void showResults(TextLineResultItem[] results) {
        StringBuilder resultBuilder = new StringBuilder();
        if (results != null) {
            for (TextLineResultItem result : results) {
                resultBuilder.append(result.getText()).append("\n\n");
            }
        }
        runOnUiThread(() -> tvRes.setText(resultBuilder.toString()));
    }
}