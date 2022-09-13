package com.dynamsoft.dlrsample.mrzscanner.ui.main;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.dynamsoft.dlr.MRZResult;

public class MainViewModel extends ViewModel {
    public final static int SCAN_FRAGMENT = 0;
    public final static int RESULT_FRAGMENT = 1;

    public MutableLiveData<Integer> currentFragment = new MutableLiveData<>(SCAN_FRAGMENT);
    public MRZResult mrzResult = null;
    public MutableLiveData<Integer> deviceRotation = new MutableLiveData<Integer>(0);
}