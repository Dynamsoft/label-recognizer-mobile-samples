package com.dynamsoft.dlrsample.mrzscanner.ui.main;

import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;

import android.content.Context;
import android.graphics.Point;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.dynamsoft.core.ImageData;
import com.dynamsoft.core.Quadrilateral;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.DCECameraView;
import com.dynamsoft.dlr.DLRRuntimeSettings;
import com.dynamsoft.dlr.EnumMRZDocumentType;
import com.dynamsoft.dlr.LabelRecognizerException;
import com.dynamsoft.dlr.MRZRecognizer;
import com.dynamsoft.dlr.MRZResult;
import com.dynamsoft.dlr.MRZResultListener;
import com.dynamsoft.dlrsample.mrzscanner.MainActivity;
import com.dynamsoft.dlrsample.mrzscanner.R;
import java.io.FileOutputStream;

public class ScanFragment extends Fragment {
    private static final String TAG = "ScanFragment";
    private DCECameraView mCameraView;
    private CameraEnhancer mCamera;
    private MRZRecognizer mMRZRecognizer;
    private MainViewModel mViewModel;
    private boolean isShowing;
    private final ResultFragment mResultFragment = ResultFragment.newInstance();

    private final Point[] rotationPoints = new Point[]{new Point(0, 100), new Point(0, 0), new Point(100, 0), new Point(100, 100)};

    public static ScanFragment newInstance() {
        return new ScanFragment();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        initViewModel();
        return inflater.inflate(R.layout.scan_fragment, container, false);
    }


    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        mCameraView = view.findViewById(R.id.dce_camera_view);
        mCamera = new CameraEnhancer(requireActivity());
        mCamera.setCameraView(mCameraView);

        try {
            mMRZRecognizer = new MRZRecognizer(EnumMRZDocumentType.MDT_PASSPORT);
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }

        try {
            FileOutputStream outStream = null;
            outStream = getActivity().openFileOutput("settingMRZ0.json", Context.MODE_PRIVATE);
            outStream.write(mMRZRecognizer.outputRuntimeSettingsToString("").getBytes());
            outStream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            Quadrilateral quad = new Quadrilateral();
            Integer rotationValue = mViewModel.deviceRotation.getValue();
            for (int i = 0; i < 4; i++) {
                quad.points[i] = rotationPoints[(i+rotationValue) % 4];
            }
            DLRRuntimeSettings settings = mMRZRecognizer.getRuntimeSettings();
            settings.textArea = quad;
            mMRZRecognizer.updateRuntimeSettings(settings);
            FileOutputStream outStream = getActivity().openFileOutput("settingMRZ.json", Context.MODE_PRIVATE);
            outStream.write(mMRZRecognizer.outputRuntimeSettingsToString("").getBytes());
            outStream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        mMRZRecognizer.setImageSource(mCamera);
        mMRZRecognizer.setMRZResultListener(new MRZResultListener() {
            @Override
            public void mrzResultCallback(int i, ImageData imageData, MRZResult mrzResult) {
                if (mrzResult != null && !isShowing && mrzResult.isParsed) {
                    isShowing = true;
                    mViewModel.mrzResult = mrzResult;
                    requireActivity().getSupportFragmentManager()
                            .beginTransaction()
                            .add(R.id.container, mResultFragment, null)
                            .setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE)
                            .addToBackStack(null)
                            .hide(ScanFragment.this)
                            .commit();
                }
            }
        });
    }

    @Override
    public void onHiddenChanged(boolean hidden) {
        super.onHiddenChanged(hidden);
        if (hidden) {
            try {
                mCamera.close();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
            mMRZRecognizer.stopScanning();
        } else {
            mViewModel.currentFragment.setValue(MainViewModel.SCAN_FRAGMENT);
            isShowing = false;
            try {
                mCamera.open();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
            mMRZRecognizer.startScanning();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        ((MainActivity) requireActivity()).getSupportActionBar().setTitle("MRZScanner");
        ((MainActivity) requireActivity()).getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        if (!isShowing) {
            mMRZRecognizer.startScanning();
            try {
                mCamera.open();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        mMRZRecognizer.stopScanning();
        try {
            mCamera.close();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
    }

    private void initViewModel() {
        mViewModel = new ViewModelProvider(requireActivity()).get(MainViewModel.class);
        mViewModel.currentFragment.setValue(MainViewModel.SCAN_FRAGMENT);
        mViewModel.deviceRotation.observe(getViewLifecycleOwner(), new Observer<Integer>() {
            @Override
            public void onChanged(Integer rotationValue) {
                Quadrilateral quad = new Quadrilateral();
                for (int i = 0; i < 4; i++) {
                    quad.points[i] = rotationPoints[(i+rotationValue) % 4];
                }
                if(mMRZRecognizer != null) {
                    try {
                        DLRRuntimeSettings settings = mMRZRecognizer.getRuntimeSettings();
                        settings.textArea = quad;
                        mMRZRecognizer.updateRuntimeSettings(settings);
                    } catch (LabelRecognizerException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

}