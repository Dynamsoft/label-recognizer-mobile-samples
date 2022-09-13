package com.dynamsoft.dlrsample.helloworld;

import androidx.appcompat.app.AppCompatActivity;

import android.graphics.Color;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.fonts.FontFamily;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import com.dynamsoft.core.CoreException;
import com.dynamsoft.core.ImageData;
import com.dynamsoft.core.LicenseManager;
import com.dynamsoft.core.LicenseVerificationListener;
import com.dynamsoft.core.Quadrilateral;
import com.dynamsoft.core.RegionDefinition;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.DCECameraView;
import com.dynamsoft.dce.DCEDrawingLayer;
import com.dynamsoft.dce.DrawingItem;
import com.dynamsoft.dce.DrawingStyle;
import com.dynamsoft.dce.DrawingStyleManager;
import com.dynamsoft.dce.TextDrawingItem;
import com.dynamsoft.dlr.DLRLineResult;
import com.dynamsoft.dlr.DLRResult;
import com.dynamsoft.dlr.DLRRuntimeSettings;
import com.dynamsoft.dlr.LabelRecognizer;
import com.dynamsoft.dlr.LabelRecognizerException;
import com.dynamsoft.dlr.LabelResultListener;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {
    private TextView tvRes;
    private CameraEnhancer mCamera;
    private LabelRecognizer mRecognizer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, new LicenseVerificationListener() {
            @Override
            public void licenseVerificationCallback(boolean b, CoreException e) {
                //Do something you want.
            }
        });
        tvRes = findViewById(R.id.tv_res);
        DCECameraView mCameraView = findViewById(R.id.dce_camera_view);
        mCamera = new CameraEnhancer(this);
        mCamera.setCameraView(mCameraView);

        RegionDefinition region = new RegionDefinition(10, 40, 90, 60, 1);
        try {
            mCamera.setScanRegion(region);
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }

        try {
            mRecognizer = new LabelRecognizer();
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }
        mRecognizer.setImageSource(mCamera);

        try {
            DLRRuntimeSettings settings = mRecognizer.getRuntimeSettings();
            Quadrilateral quad = new Quadrilateral();
            quad.points[0] = new Point(0,100);
            quad.points[1] = new Point(0,0);
            quad.points[2] = new Point(100,0);
            quad.points[3] = new Point(100,100);
            settings.textArea = quad;
            mRecognizer.updateRuntimeSettings(settings);
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }


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