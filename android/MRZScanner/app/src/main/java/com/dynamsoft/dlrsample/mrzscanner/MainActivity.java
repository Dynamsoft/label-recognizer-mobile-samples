package com.dynamsoft.dlrsample.mrzscanner;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;

import android.content.Context;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.OrientationEventListener;
import android.view.WindowManager;

import com.dynamsoft.core.LicenseManager;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.ScanFragment;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.MainViewModel;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    private MainViewModel mViewModel;
    private OrientationEventListener mOrientationListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_activity);
        mViewModel = new ViewModelProvider(this).get(MainViewModel.class);
        mViewModel.currentFragment.observe(this, new Observer<Integer>() {
            @Override
            public void onChanged(Integer integer) {
                if(integer == MainViewModel.SCAN_FRAGMENT) {
                    getSupportActionBar().setTitle("MRZ Scanner");
                    getSupportActionBar().setDisplayHomeAsUpEnabled(false);
                } else if(integer == MainViewModel.RESULT_FRAGMENT) {
                    getSupportActionBar().setTitle("MRZ Result");
                    getSupportActionBar().setDisplayHomeAsUpEnabled(true);
                }
            }
        });

        mViewModel.deviceRotation.setValue(((WindowManager) getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation());
        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, null);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE)
                    .replace(R.id.container, ScanFragment.newInstance())
                    .commit();
        }

        mOrientationListener = new OrientationEventListener(this) {
            @Override
            public void onOrientationChanged(int rotation) {
                int deviceRotation = ((WindowManager) getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation();
                if(mViewModel.deviceRotation.getValue() != deviceRotation) {
                    mViewModel.deviceRotation.setValue(deviceRotation);
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
        if(item.getItemId() == android.R.id.home) {
            onBackPressed();
        }
        return super.onOptionsItemSelected(item);
    }

}