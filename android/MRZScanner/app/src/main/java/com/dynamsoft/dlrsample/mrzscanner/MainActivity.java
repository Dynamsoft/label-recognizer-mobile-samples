package com.dynamsoft.dlrsample.mrzscanner;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;

import android.content.Context;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.OrientationEventListener;
import android.view.WindowManager;

import com.dynamsoft.core.CoreException;
import com.dynamsoft.core.LicenseManager;
import com.dynamsoft.core.LicenseVerificationListener;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.ScanFragment;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.MainViewModel;

public class MainActivity extends AppCompatActivity {
    private MainViewModel mViewModel;
    private OrientationEventListener mOrientationListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_activity);
        mViewModel = new ViewModelProvider(this).get(MainViewModel.class);

        //Change toolbar title on different fragments
        mViewModel.currentFragmentFlag.observe(this, flag -> {
            if (flag == MainViewModel.SCAN_FRAGMENT) {
                getSupportActionBar().setTitle("MRZ Scanner");
                getSupportActionBar().setDisplayHomeAsUpEnabled(false);
            } else if (flag == MainViewModel.RESULT_FRAGMENT) {
                getSupportActionBar().setTitle("MRZ Result");
                getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            }
        });

        //Set default device rotation.
        mViewModel.deviceRotation.setValue(((WindowManager) getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation());


        if (savedInstanceState == null) {
            LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, new LicenseVerificationListener() {
                @Override
                public void licenseVerificationCallback(boolean b, CoreException e) {
                    //Write your codes.
                }
            });

            getSupportFragmentManager().beginTransaction()
                    .add(R.id.container, ScanFragment.newInstance())
                    .commit();
        }

        //Detecting device orientation and rotation in real time.
        mOrientationListener = new OrientationEventListener(this) {
            @Override
            public void onOrientationChanged(int rotation) {
                int deviceRotation = ((WindowManager) getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation();
                if (mViewModel != null && mViewModel.deviceRotation != null) {
                    Integer value = mViewModel.deviceRotation.getValue();
                    if (value != null && value != deviceRotation) {
                        mViewModel.deviceRotation.setValue(deviceRotation);
                    }
                }
            }
        };
    }

    @Override
    protected void onResume() {
        super.onResume();
        mOrientationListener.enable();
    }

    @Override
    protected void onPause() {
        super.onPause();
        mOrientationListener.disable();
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
        }
        return super.onOptionsItemSelected(item);
    }

}