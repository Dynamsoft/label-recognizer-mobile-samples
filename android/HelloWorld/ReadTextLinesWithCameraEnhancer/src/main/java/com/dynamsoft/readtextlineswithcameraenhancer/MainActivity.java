package com.dynamsoft.readtextlineswithcameraenhancer;

import android.content.res.Configuration;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

import com.dynamsoft.core.basic_structures.CapturedResultReceiver;
import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.DSRect;
import com.dynamsoft.cvr.CaptureVisionRouter;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.EnumPresetTemplate;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.utils.PermissionUtil;
import com.dynamsoft.dlr.RecognizedTextLinesResult;
import com.dynamsoft.dlr.TextLineResultItem;
import com.dynamsoft.license.LicenseManager;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.MutableLiveData;

public class MainActivity extends AppCompatActivity {
	private TextView tvRes;
	private CameraEnhancer mCamera;
	private CaptureVisionRouter mRouter;

	private final MutableLiveData<Integer> deviceOrientation = new MutableLiveData<>(Configuration.ORIENTATION_PORTRAIT);

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		PermissionUtil.requestCameraPermission(this);

		// Initialize license for Dynamsoft Label Recognizer SDK.
		// The license string here is a time-limited trial license. Note that network connection is required for this license to work.
		// You can also request an extension for your trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=installer&package=android

		LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, (isSuccess, error) -> {
			if (!isSuccess) {
				error.printStackTrace();
				runOnUiThread(new Runnable() {
					@Override
					public void run() {
						Toast ts = Toast.makeText(getBaseContext(), "error: " + error.getMessage(), Toast.LENGTH_LONG);
						ts.show();
					}
				});
			}
		});

		deviceOrientation.observe(this, orientationValue -> {
			if (orientationValue == Configuration.ORIENTATION_PORTRAIT) {
				DSRect region = new DSRect(0.1f, 0.4f, 0.9f, 0.6f, true);
				try {
					mCamera.setScanRegion(region);
				} catch (CameraEnhancerException e) {
					e.printStackTrace();
				}
			} else if (orientationValue == Configuration.ORIENTATION_LANDSCAPE) {
				DSRect region = new DSRect(20, 40, 80, 60, false);
				try {
					mCamera.setScanRegion(region);
				} catch (CameraEnhancerException e) {
					e.printStackTrace();
				}
			}
		});

		tvRes = findViewById(R.id.tv_res);

		// Add camera view for previewing video.
		CameraView cameraView = findViewById(R.id.dce_camera_view);
		cameraView.setScanRegionMaskVisible(true);

		// Create an instance of Dynamsoft Camera Enhancer for video streaming.
		mCamera = new CameraEnhancer(cameraView, this);
		mRouter = new CaptureVisionRouter(this);
		try {
			mRouter.setInput(mCamera);
		} catch (CaptureVisionRouterException e) {
			throw new RuntimeException(e);
		}

		mRouter.addResultReceiver(new CapturedResultReceiver() {
			@Override
			public void onRecognizedTextLinesReceived(RecognizedTextLinesResult result) {
				showResults(result.getItems());
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
		mRouter.startCapturing(EnumPresetTemplate.PT_RECOGNIZE_TEXT_LINES, new CompletionListener() {
			@Override
			public void onSuccess() {
			}

			@Override
			public void onFailure(int errorCode, String errorString) {
				runOnUiThread(() -> Toast.makeText(MainActivity.this, errorString, Toast.LENGTH_SHORT).show());
			}
		});
	}

	public void onPause() {
		try {
			mCamera.close();
		} catch (CameraEnhancerException e) {
			e.printStackTrace();
		}
		mRouter.stopCapturing();
		super.onPause();
	}

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