/*
 * Copyright 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.dynamsoft.passportmrzreading;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.MeteringRectangle;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.support.annotation.NonNull;
import android.support.constraint.ConstraintLayout;
import android.support.v4.app.ActivityCompat;
import android.support.v4.app.DialogFragment;
import android.support.v4.app.Fragment;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.util.Size;
import android.util.SparseIntArray;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.dynamsoft.dlr.*;
import com.dynamsoft.core.*;
import com.dynamsoft.passportmrzreading.util.AutoFocusHelper;
import com.dynamsoft.passportmrzreading.util.CameraConstants;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;


public class Camera2BasicFragment extends Fragment
        implements ActivityCompat.OnRequestPermissionsResultCallback {

    /**
     * Conversion from screen rotation to JPEG orientation.
     */
    private static final SparseIntArray ORIENTATIONS = new SparseIntArray();
    private static final int REQUEST_CAMERA_PERMISSION = 1;
    private static final String FRAGMENT_DIALOG = "dialog";

    private CaptureActivity mCaptureActivity;

    private String path = Environment.getExternalStorageDirectory() + "/dlr-preview-img";

    static {
        ORIENTATIONS.append(Surface.ROTATION_0, 90);
        ORIENTATIONS.append(Surface.ROTATION_90, 0);
        ORIENTATIONS.append(Surface.ROTATION_180, 270);
        ORIENTATIONS.append(Surface.ROTATION_270, 180);
    }

    /**
     * Tag for the {@link Log}.
     */
    private static final String TAG = "Camera2BasicFragment";

    /**
     * Camera state: Showing camera preview.
     */
    private static final int STATE_PREVIEW = 0;

    /**
     * Max preview width that is guaranteed by Camera2 API
     */
    private static final int MAX_PREVIEW_WIDTH = 1920;

    /**
     * Max preview height that is guaranteed by Camera2 API
     */
    private static final int MAX_PREVIEW_HEIGHT = 1080;

    /**
     * {@link TextureView.SurfaceTextureListener} handles several lifecycle events on a
     * {@link TextureView}.
     */
    private final TextureView.SurfaceTextureListener mSurfaceTextureListener
            = new TextureView.SurfaceTextureListener() {

        @Override
        public void onSurfaceTextureAvailable(SurfaceTexture texture, int width, int height) {
            openCamera(width, height);
        }

        @Override
        public void onSurfaceTextureSizeChanged(SurfaceTexture texture, int width, int height) {
            configureTransform(width, height);
        }

        @Override
        public boolean onSurfaceTextureDestroyed(SurfaceTexture texture) {
            return true;
        }

        @Override
        public void onSurfaceTextureUpdated(SurfaceTexture texture) {
        }

    };

    /**
     * ID of the current {@link CameraDevice}.
     */
    private String mCameraId;

    /**
     * An {@link AutoFitTextureView} for camera preview.
     */
    private AutoFitTextureView mTextureView;

    /**
     * A {@link CameraCaptureSession } for camera preview.
     */
    private CameraCaptureSession mCaptureSession;

    /**
     * A reference to the opened {@link CameraDevice}.
     */
    private CameraDevice mCameraDevice;

    /**
     * The {@link Size} of camera preview.
     */
    private Size mPreviewSize;

    /**
     * {@link CameraDevice.StateCallback} is called when {@link CameraDevice} changes its state.
     */
    private final CameraDevice.StateCallback mStateCallback = new CameraDevice.StateCallback() {

        @Override
        public void onOpened(@NonNull CameraDevice cameraDevice) {
            // This method is called when the camera is opened.  We start camera preview here.
            mCameraOpenCloseLock.release();
            mCameraDevice = cameraDevice;
            createCameraPreviewSession();
        }

        @Override
        public void onDisconnected(@NonNull CameraDevice cameraDevice) {
            mCameraOpenCloseLock.release();
            cameraDevice.close();
            mCameraDevice = null;
        }

        @Override
        public void onError(@NonNull CameraDevice cameraDevice, int error) {
            mCameraOpenCloseLock.release();
            cameraDevice.close();
            mCameraDevice = null;
            Activity activity = getActivity();
            if (null != activity) {
                activity.finish();
            }
        }

    };

    /**
     * An additional thread for running tasks that shouldn't block the UI.
     */
    private HandlerThread mBackgroundThread;
    private HandlerThread mBackgroundThread2;

    /**
     * A {@link Handler} for running tasks in the background.
     */
    private Handler mBackgroundHandler;
    private Handler mBackgroundHandler2;

    /**
     * An {@link ImageReader} that handles still image capture.
     */
    private ImageReader mImageReader;

    Button btnCapture;
    ProgressBar pb;
    TextView tvTip;
    RelativeLayout viewRegion;
    private Size outputPreviewSize;
    static boolean bDecoding = false;
    private final ImageReader.OnImageAvailableListener mOnImageAvailableListener
            = new ImageReader.OnImageAvailableListener() {

        @Override
        public void onImageAvailable(ImageReader reader) {
            if (reader != null) {
                Image mImage = reader.acquireLatestImage();

                if (mImage != null) {
                    if(isSingle){
                        ByteBuffer buffer = mImage.getPlanes()[0].getBuffer();
                        int nRowStride = mImage.getPlanes()[0].getRowStride();
                        int nPixelStride = mImage.getPlanes()[0].getPixelStride();
                        if(mBackgroundHandler2!=null &&!bDecoding) {
                            bDecoding = true;
                            byte[] bytes =  new byte[buffer.remaining()];
                            buffer.get(bytes);
                            ImageData imageData= new ImageData();
                            imageData.bytes = bytes;
                            imageData.width = reader.getWidth();
                            imageData.height = reader.getHeight();
                            imageData.format = EnumImagePixelFormat.IPF_NV21;
                            imageData.stride = nRowStride *nPixelStride;
                            Message message = new Message();
                            message.what = 0x101 ;
                            message.obj = imageData;
                            mBackgroundHandler2.sendMessage(message);
                        }
                    }
                    mImage.close();
                }
            }
        }


    };


    /**
     * {@link CaptureRequest.Builder} for the camera preview
     */
    private CaptureRequest.Builder mPreviewRequestBuilder;

    /**
     * {@link CaptureRequest} generated by {@link #mPreviewRequestBuilder}
     */
    private CaptureRequest mPreviewRequest;


    /**
     * A {@link Semaphore} to prevent the app from exiting before closing the camera.
     */
    private Semaphore mCameraOpenCloseLock = new Semaphore(1);

    /**
     * Whether the current camera device supports Flash or not.
     */
    private boolean mFlashSupported;
    /**
     * Whether the current camera device supports auto focus or not.
     */
    private boolean mAutoFocusSupported = true;

    /**
     * Orientation of the camera sensor
     */
    private int mSensorOrientation;

    private int mDisplayOrientation;
    /**
     * A {@link CameraCaptureSession.CaptureCallback} that handles events related to JPEG capture.
     */
    private CameraCaptureSession.CaptureCallback mCaptureCallback
            = null;
    private CameraCharacteristics mCameraCharacteristics;

    /**
     * Shows a {@link Toast} on the UI thread.
     *
     * @param text The message to show
     */
    private void showToast(final String text) {
        final Activity activity = getActivity();
        if (activity != null) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(activity, text, Toast.LENGTH_SHORT).show();
                }
            });
        }
    }

    /**
     * Given {@code choices} of {@code Size}s supported by a camera, choose the smallest one that
     * is at least as large as the respective texture view size, and that is at most as large as the
     * respective max size, and whose aspect ratio matches with the specified value. If such size
     * doesn't exist, choose the largest one that is at most as large as the respective max size,
     * and whose aspect ratio matches with the specified value.
     *
     * @param choices           The list of sizes that the camera supports for the intended output
     *                          class
     * @param textureViewWidth  The width of the texture view relative to sensor coordinate
     * @param textureViewHeight The height of the texture view relative to sensor coordinate
     * @param maxWidth          The maximum width that can be chosen
     * @param maxHeight         The maximum height that can be chosen
     * @param aspectRatio       The aspect ratio
     * @return The optimal {@code Size}, or an arbitrary one if none were big enough
     */
    private static Size chooseOptimalSize(Size[] choices, int textureViewWidth,
                                          int textureViewHeight, int maxWidth, int maxHeight, Size aspectRatio) {

        // Collect the supported resolutions that are at least as big as the preview Surface
        List<Size> bigEnough = new ArrayList<>();
        // Collect the supported resolutions that are smaller than the preview Surface
        List<Size> notBigEnough = new ArrayList<>();
        int w = aspectRatio.getWidth();
        int h = aspectRatio.getHeight();
        for (Size option : choices) {
            if (option.getWidth() <= maxWidth && option.getHeight() <= maxHeight &&
                    option.getHeight() == option.getWidth() * h / w) {
                if (option.getWidth() >= textureViewWidth &&
                        option.getHeight() >= textureViewHeight) {
                    bigEnough.add(option);
                } else {
                    notBigEnough.add(option);
                }
            }
        }

        // Pick the smallest of those big enough. If there is no one big enough, pick the
        // largest of those not big enough.
        if (bigEnough.size() > 0) {
            return Collections.min(bigEnough, new CompareSizesByArea());
        } else if (notBigEnough.size() > 0) {
            return Collections.max(notBigEnough, new CompareSizesByArea());
        } else {
            Log.e(TAG, "Couldn't find any suitable preview size");
            return choices[0];
        }
    }

    public static Camera2BasicFragment newInstance() {
        return new Camera2BasicFragment();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        mCaptureActivity = ((CaptureActivity) getActivity());

        return inflater.inflate(R.layout.fragment_camera2_basic, container, false);

    }

    @Override
    public void onViewCreated(final View view, Bundle savedInstanceState) {
        mTextureView = view.findViewById(R.id.texture);
        btnCapture = mCaptureActivity.findViewById(R.id.btn_capture);
        viewRegion = mCaptureActivity.findViewById(R.id.view_passport_region);
        pb = mCaptureActivity.findViewById(R.id.pb_progress_capture);
        tvTip = mCaptureActivity.findViewById(R.id.tv_string_tip);
        tvTip.setVisibility(View.VISIBLE);
        AlphaAnimation alp = new AlphaAnimation(1.0f,0.0f);
        alp.setDuration(3000);
        alp.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                tvTip.setVisibility(View.GONE);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });
        tvTip.setAnimation(alp);
        mTextureView.setGestureListener(new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onSingleTapUp(MotionEvent e) {

                setManualFocusAt((int) e.getX(), (int) e.getY());
                return true;
            }
        });
        int rotation = getActivity().getWindowManager().getDefaultDisplay().getRotation();
        if(rotation==Surface.ROTATION_90 || rotation == Surface.ROTATION_270){
            ConstraintLayout.LayoutParams btnCaptureParams = (ConstraintLayout.LayoutParams)btnCapture.getLayoutParams();
            btnCaptureParams.horizontalBias = 0.96f;
            btnCaptureParams.verticalBias = 0.5f;
            btnCapture.setLayoutParams(btnCaptureParams);
            ConstraintLayout.LayoutParams p = (ConstraintLayout.LayoutParams)viewRegion.getLayoutParams();
            p.rightMargin = btnCapture.getLayoutParams().width*2;
            p.leftMargin = btnCapture.getLayoutParams().width;
            p.height = (int)(p.width/1.8);
            viewRegion.setLayoutParams(p);
        }



        btnCapture.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                takePicture();
            }
        });
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
    }

    @Override
    public void onResume() {
        super.onResume();
        startBackgroundThread();
        pb.setVisibility(View.GONE);
        // When the screen is turned off and turned back on, the SurfaceTexture is already
        // available, and "onSurfaceTextureAvailable" will not be called. In that case, we can open
        // a camera and start preview from here (otherwise, we wait until the surface is ready in
        // the SurfaceTextureListener).
        if (mTextureView.isAvailable()) {

            openCamera(mTextureView.getWidth(), mTextureView.getHeight());
        } else {
            mTextureView.setSurfaceTextureListener(mSurfaceTextureListener);
        }
    }

    @Override
    public void onPause() {
        closeCamera();
        stopBackgroundThread();
        super.onPause();
    }

    private void requestCameraPermission() {
        if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) {
            new ConfirmationDialog().show(getChildFragmentManager(), FRAGMENT_DIALOG);
        } else {
            requestPermissions(new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.length != 1 || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                ErrorDialog.newInstance(getString(R.string.request_permission))
                        .show(getChildFragmentManager(), FRAGMENT_DIALOG);
            }
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        }
    }

    /**
     * Sets up member variables related to camera.
     *
     * @param width  The width of available size for camera preview
     * @param height The height of available size for camera preview
     */
    @SuppressWarnings("SuspiciousNameCombination")
    int w = 0;
    int h = 0;

    private void setUpCameraOutputs(int width, int height) {
        Activity activity = getActivity();
        CameraManager manager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
        try {
            for (String cameraId : manager.getCameraIdList()) {
                mCameraCharacteristics
                        = manager.getCameraCharacteristics(cameraId);

                // We don't use a front facing camera in this sample.
                Integer facing = mCameraCharacteristics.get(CameraCharacteristics.LENS_FACING);
                if (facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    continue;
                }

                StreamConfigurationMap map = mCameraCharacteristics.get(
                        CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
                if (map == null) {
                    continue;
                }

                // For video image captures, we use the suitable available size.
                Size[] sizeList = map.getOutputSizes(ImageFormat.YUV_420_888);
                for (Size size : sizeList
                ) {
                    if (size.getWidth() * size.getHeight() > 1000000)
                        continue;
                    else {
                        outputPreviewSize = size;
                        break;
                    }

                }
                mImageReader = ImageReader.newInstance(outputPreviewSize.getWidth(), outputPreviewSize.getHeight(),
                        ImageFormat.YUV_420_888, /*maxImages*/3);

                mImageReader.setOnImageAvailableListener(
                        mOnImageAvailableListener, null);// mBackgroundHandler2);

                // Find out if we need to swap dimension to get the preview size relative to sensor
                // coordinate.
                int displayRotation = activity.getWindowManager().getDefaultDisplay().getRotation();
                mDisplayOrientation = displayRotation;
                //noinspection ConstantConditions
                mSensorOrientation = mCameraCharacteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
                Log.e(TAG, "setUpCameraOutputs: "+displayRotation+" "+mSensorOrientation );
                boolean swappedDimensions = false;
                switch (displayRotation) {
                    case Surface.ROTATION_0:
                    case Surface.ROTATION_180:
                        if (mSensorOrientation == 90 || mSensorOrientation == 270) {
                            swappedDimensions = true;
                        }
                        break;
                    case Surface.ROTATION_90:
                    case Surface.ROTATION_270:
                        if (mSensorOrientation == 0 || mSensorOrientation == 180) {
                            swappedDimensions = true;
                        }
                        break;
                    default:
                        Log.e(TAG, "Display rotation is invalid: " + displayRotation);
                }

                Point displaySize = new Point();
                activity.getWindowManager().getDefaultDisplay().getSize(displaySize);
                int rotatedPreviewWidth = width;
                int rotatedPreviewHeight = height;
                int maxPreviewWidth = displaySize.x;
                int maxPreviewHeight = displaySize.y;

                if (swappedDimensions) {
                    rotatedPreviewWidth = height;
                    rotatedPreviewHeight = width;
                    maxPreviewWidth = displaySize.y;
                    maxPreviewHeight = displaySize.x;
                }

                if (maxPreviewWidth > MAX_PREVIEW_WIDTH) {
                    maxPreviewWidth = MAX_PREVIEW_WIDTH;
                }

                if (maxPreviewHeight > MAX_PREVIEW_HEIGHT) {
                    maxPreviewHeight = MAX_PREVIEW_HEIGHT;
                }

                // Danger, W.R.! Attempting to use too large a preview size could  exceed the camera
                // bus' bandwidth limitation, resulting in gorgeous previews but the storage of
                // garbage capture data.
                mPreviewSize = chooseOptimalSize(map.getOutputSizes(SurfaceTexture.class),
                        rotatedPreviewWidth, rotatedPreviewHeight, maxPreviewWidth,
                        maxPreviewHeight, outputPreviewSize);

                // We fit the aspect ratio of TextureView to the size of preview we picked.
//                int orientation = getResources().getConfiguration().orientation;
//                if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
//                    mTextureView.setAspectRatio(
//                            mPreviewSize.getWidth(), mPreviewSize.getHeight());
//                } else {
//                    mTextureView.setAspectRatio(
//                            mPreviewSize.getHeight(), mPreviewSize.getWidth());
//                }


                // Check if the flash is supported.
                Boolean available = mCameraCharacteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
                mFlashSupported = available == null ? false : available;

                mCameraId = cameraId;

                checkAutoFocusSupported();
                checkFlashSupported();

                mCropRegion = AutoFocusHelper.cropRegionForZoom(mCameraCharacteristics,
                        CameraConstants.ZOOM_REGION_DEFAULT);
                if (w == 0 || h == 0) {
                    w = mTextureView.getWidth();
                    h = mTextureView.getHeight();
                }
                //show the crop view
//                int nQrViewW = (int) (w * 0.8), nQrViewH = (int) (h * 0.2);
//
//                int boxLeft = (w - nQrViewW) / 2;
//                int boxTop = (h - nQrViewH) / 2;
//                if (boxLeft >= 0 && boxTop >= 0) {
//                    mQrCropRect = new Rect(boxLeft, boxTop, boxLeft + nQrViewW, boxTop + nQrViewH);
//                    mQrView.reSetboxview(mQrCropRect.left, mQrCropRect.top, mQrCropRect.width(), mQrCropRect.height());
//                }
//                float previewScaleX = (float) mTextureView.getWidth() / (float) outputPreviewSize.getHeight();
//                float previewScaleY = (float) mTextureView.getHeight() / (float) outputPreviewSize.getWidth();
//                boolean dependOnWid;
//                if (previewScaleX > previewScaleY) {
//                    dependOnWid = true;
//                } else {
//                    dependOnWid = false;
//                }

//                if (mCaptureActivity.getMainLabelRecognition() != null) {
//                    DLRRuntimeSettings settings = mCaptureActivity.getMainLabelRecognition().getRuntimeSettings();
//                    settings.textArea = handleRegion(mQrCropRect.left, mQrCropRect.top, mQrCropRect.width(), previewScaleX, previewScaleY, outputPreviewSize.getHeight(), outputPreviewSize.getWidth(), dependOnWid);
//                    mCaptureActivity.getMainLabelRecognition().updateRuntimeSettings(settings);
//                }

                return;
            }
        } catch (CameraAccessException e) {
            e.printStackTrace();
        } catch (NullPointerException e) {
            // Currently an NPE is thrown when the Camera2API is used but not supported on the
            // device this code runs.
            ErrorDialog.newInstance(getString(R.string.camera_error))
                    .show(getChildFragmentManager(), FRAGMENT_DIALOG);
        } /*catch (LabelRecognitionException e) {
            e.printStackTrace();
        }*/
    }

    private Bitmap rotateBitmap(Bitmap origin,float degree) {
        if (origin == null) {
            return null;
        }
        int width = origin.getWidth();
        int height = origin.getHeight();
        Matrix matrix = new Matrix();
        matrix.setRotate(degree);
        Bitmap newBM = Bitmap.createBitmap(origin, 0, 0, width, height, matrix, false);
        origin.recycle();
        return newBM;
    }

    private boolean isSingle = false;
    private void takePicture() {
        pb.setVisibility(View.VISIBLE);
        isSingle = true;
        if (mCameraDevice == null) {
            return;
        }
        final ImageReader captureImageReader = ImageReader.newInstance(outputPreviewSize.getWidth(), outputPreviewSize.getHeight(), ImageFormat.JPEG, 1);
        try {
            mCameraDevice.createCaptureSession(Arrays.asList(surface, captureImageReader.getSurface()), new CameraCaptureSession.StateCallback() {
                @Override
                public void onConfigured(@NonNull CameraCaptureSession session) {
                    try {
                        final CaptureRequest.Builder captureRequestBuilder;
                        captureRequestBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
                        captureRequestBuilder.addTarget(captureImageReader.getSurface());

                        captureRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
                        CaptureRequest mCaptureRequest = captureRequestBuilder.build();
                        session.capture(mCaptureRequest, null, null);
                    } catch (CameraAccessException e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession session) {

                }
            }, null);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
        captureImageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader reader) {
                if (reader != null) {
                    Image image = reader.acquireLatestImage();
                    if (image != null) {
                        ByteBuffer buffer = image.getPlanes()[0].getBuffer();
                        int nRowStride = image.getPlanes()[0].getRowStride();
                        int nPixelStride = image.getPlanes()[0].getPixelStride();
                        byte[] bytes = null;
//                        if (mBackgroundHandler2 != null) {
                            bDecoding = true;
                            bytes = new byte[buffer.remaining()];
                            buffer.get(bytes);
//                        }
                        image.close();
                        Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                        if(mDisplayOrientation == 0){
                            bitmap = rotateBitmap(bitmap,90f);
                        }
                        if(mDisplayOrientation == 3){
                            bitmap = rotateBitmap(bitmap,180f);
                        }
                        String photoName = System.currentTimeMillis() + "";
                        File saveFile = new File(path, photoName + ".jpg");
                        try {
                            if (!saveFile.getParentFile().exists()) {
                                saveFile.getParentFile().mkdirs();
                            }
                            saveFile.createNewFile();
                            FileOutputStream fileOutputStream = new FileOutputStream(saveFile);
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fileOutputStream);
                            fileOutputStream.flush();
                            fileOutputStream.close();
                            long modifyDate = new File(path, photoName + ".jpg").lastModified();
                            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                            String timeStamp = "";
                            try {
                                Date date = new Date(modifyDate);
                                timeStamp = formatter.format(date);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            Intent intent = new Intent(mCaptureActivity, resultActivity.class);
                            intent.putExtra("fileName", path + "/" + photoName + ".jpg");
                            intent.putExtra("imageType", 0);
                            startActivity(intent);
//                            Message message = new Message();
//                            message.what = 0x101;
//                            message.obj = path + "/" + photoName + ".jpg";
//                            mBackgroundHandler2.sendMessage(message);
                        } catch (Exception e) {
                            e.printStackTrace();
                        } finally {
                            reader.close();
                        }
                    }
                }
            }
        }, null);

    }


    private Quadrilateral handleRegion(int left, int top, int width, float previewScaleX, float previewScaleY, int srcBitmapHeight, int srcBitmapWidth, boolean dependOnWid) {
        Quadrilateral newRegion = new Quadrilateral();
        newRegion.points = new com.dynamsoft.core.Point[4];
        for (int i = 0; i < 4; i++) {
            newRegion.points[i] = new com.dynamsoft.core.Point();
        }
        int iBottom;
        int iLeft;
        int iTop;
        int iRight;
        if (dependOnWid) {
            iBottom = (int) (srcBitmapHeight - left / previewScaleX);
            iLeft = (int) ((top + Math.abs(previewScaleX - previewScaleY) * srcBitmapWidth / 2) / previewScaleX);
            iTop = (int) (iBottom - width / previewScaleX);
            iRight = (int) (iLeft + width / previewScaleX);
        } else {
            iBottom = (int) (srcBitmapHeight - left / previewScaleY);
            iLeft = (int) (top / previewScaleY);
            iTop = (int) (iBottom - width / previewScaleY);
            iRight = (int) (iLeft + width / previewScaleY);
        }
        newRegion.points[1].x = iLeft * 100 / srcBitmapWidth;
        newRegion.points[1].y = iTop * 100 / srcBitmapHeight;
        newRegion.points[2].x = iRight * 100 / srcBitmapWidth;
        newRegion.points[2].y = iTop * 100 / srcBitmapHeight;
        newRegion.points[3].x = iRight * 100 / srcBitmapWidth;
        newRegion.points[3].y = iBottom * 100 / srcBitmapHeight;
        newRegion.points[0].x = iLeft * 100 / srcBitmapWidth;
        newRegion.points[0].y = iBottom * 100 / srcBitmapHeight;
        return newRegion;
    }

    /**
     * Opens the camera specified by {@link Camera2BasicFragment#mCameraId}.
     */
    private void openCamera(int width, int height) {
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            requestCameraPermission();
            return;
        }
        setUpCameraOutputs(width, height);
        configureTransform(width, height);
        Activity activity = getActivity();
        CameraManager manager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
        try {
            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw new RuntimeException("Time out waiting to lock camera opening.");
            }
            manager.openCamera(mCameraId, mStateCallback, mBackgroundHandler);

        } catch (CameraAccessException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera opening.", e);
        }


    }

    /**
     * Closes the current {@link CameraDevice}.
     */
    private void closeCamera() {
        try {
            mCameraOpenCloseLock.acquire();
            if (null != mCaptureSession) {
                mCaptureSession.close();
                mCaptureSession = null;
            }
            if (null != mCameraDevice) {
                mCameraDevice.close();
                mCameraDevice = null;
            }
            if (null != mImageReader) {
                mImageReader.close();
                mImageReader = null;
            }
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera closing.", e);
        } finally {
            mCameraOpenCloseLock.release();
        }
    }

    /**
     * Starts a background thread and its {@link Handler}.
     */

    private void startBackgroundThread() {
        mBackgroundThread = new HandlerThread("CameraBackground");
        mBackgroundThread.start();
        mBackgroundHandler = new Handler(mBackgroundThread.getLooper());

//        mBackgroundThread2 = new HandlerThread("CameraBK2");
//        mBackgroundThread2.start();
//        mBackgroundHandler2 = new Handler(mBackgroundThread2.getLooper()) {
//            @Override
//            public void handleMessage(Message msg) {
//                if (msg == null || msg.obj == null)
//                    return;
//                isSingle = false;
////                String imagePath = (String) msg.obj;
//                DLRImageData imageData = (DLRImageData)msg.obj;
//                DLRResult[] results = null;
//                try {
//                    results = MainActivity.getMainLabelRecognition().recognizeByBuffer(imageData, "locr");
//                } catch (LabelRecognitionException e) {
//                    e.printStackTrace();
//                }
//                Log.e( "handleMessage: ",imageData.format+" "+imageData.stride+" "+imageData.height+" "+imageData.width+" "+imageData.bytes.length );
//                if(results ==null||results.length==0){
//                    Log.e( "handleMessage: ","NO Result" );
//                } else {
//                    Log.e( "handleMessage: ",paraseResult(results) );
//                }
//
//                super.handleMessage(msg);
//            }
//        };

    }

    int wid = 0;
    int hgt = 0;
    int stride = 0;

    public byte[] convertImage(String path) {
        Bitmap bitmap = BitmapFactory.decodeFile(path);
        if (bitmap == null) {
            return null;
        }
        int bytes = bitmap.getByteCount();
        wid = bitmap.getWidth();
        hgt = bitmap.getHeight();
        stride = bitmap.getWidth() * 4;
        ByteBuffer buf = ByteBuffer.allocate(bytes);
        bitmap.copyPixelsToBuffer(buf);
        return buf.array();
    }

    /**
     * Stops the background thread and its {@link Handler}.
     */
    private void stopBackgroundThread() {
        mBackgroundThread.quitSafely();
        try {
            mBackgroundThread.join();
            mBackgroundThread = null;
            mBackgroundHandler = null;
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        if(mBackgroundHandler2!=null) {
            mBackgroundThread2.quitSafely();
            try {
                mBackgroundThread2.join();
                mBackgroundThread2 = null;
                mBackgroundHandler2 = null;
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Creates a new {@link CameraCaptureSession} for camera preview.
     */
    Surface surface;

    private void createCameraPreviewSession() {
        try {
            SurfaceTexture texture = mTextureView.getSurfaceTexture();
            assert texture != null;

            // We configure the size of default buffer to be the size of camera preview we want.
            texture.setDefaultBufferSize(mPreviewSize.getWidth(), mPreviewSize.getHeight());

            // This is the output Surface we need to start preview.
            surface = new Surface(texture);

            // We set up a CaptureRequest.Builder with the output Surface.
            mPreviewRequestBuilder
                    = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            mPreviewRequestBuilder.addTarget(surface);
            mPreviewRequestBuilder.addTarget(mImageReader.getSurface());
            //todo:set the auto focus region and auto exposure region
            int width = (int) (mPreviewSize.getWidth() * 3 / 4);
            int height = (int) (mPreviewSize.getHeight() * 3 / 4);
            int boxWidth = (width < height) ? width : height;
            mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_REGIONS, new MeteringRectangle[]{new MeteringRectangle(new Point((mPreviewSize.getWidth() - boxWidth) / 2
                    , (mPreviewSize.getHeight() - boxWidth) / 2), new Size(boxWidth, boxWidth), 1000)});
            mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_REGIONS, new MeteringRectangle[]{new MeteringRectangle(new Point((mPreviewSize.getWidth() - boxWidth) / 2
                    , (mPreviewSize.getHeight() - boxWidth) / 2), new Size(boxWidth, boxWidth), 1000)});

            // Here, we create a CameraCaptureSession for camera preview.
            mCameraDevice.createCaptureSession(Arrays.asList(surface, mImageReader.getSurface()),
                    new CameraCaptureSession.StateCallback() {

                        @Override
                        public void onConfigured(@NonNull CameraCaptureSession cameraCaptureSession) {
                            // The camera is already closed
                            if (null == mCameraDevice) {
                                return;
                            }

                            // When the session is ready, we start displaying the preview.
                            mCaptureSession = cameraCaptureSession;
                            try {
                                // Auto focus should be continuous for camera preview.
                                updateAutoFocus();
                                // Flash is automatically enabled when necessary.
                                setAutoFlash(mPreviewRequestBuilder);

                                // Finally, we start displaying the camera preview.
                                mPreviewRequest = mPreviewRequestBuilder.build();
                                mCaptureSession.setRepeatingRequest(mPreviewRequest,
                                        mCaptureCallback, mBackgroundHandler);
                            } catch (CameraAccessException e) {
                                e.printStackTrace();
                            }
                        }

                        @Override
                        public void onConfigureFailed(
                                @NonNull CameraCaptureSession cameraCaptureSession) {
                            showToast("Failed");
                        }
                    }, null
            );
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    /**
     * Configures the necessary {@link Matrix} transformation to `mTextureView`.
     * This method should be called after the camera preview size is determined in
     * setUpCameraOutputs and also the size of `mTextureView` is fixed.
     *
     * @param viewWidth  The width of `mTextureView`
     * @param viewHeight The height of `mTextureView`
     */
    private void configureTransform(int viewWidth, int viewHeight) {
        Activity activity = getActivity();
        if (null == mTextureView || null == mPreviewSize || null == activity) {
            return;
        }
        int rotation = activity.getWindowManager().getDefaultDisplay().getRotation();
        Matrix matrix = new Matrix();
        RectF viewRect = new RectF(0, 0, viewWidth, viewHeight);
        RectF bufferRect = new RectF(0, 0, mPreviewSize.getHeight(), mPreviewSize.getWidth());
        float centerX = viewRect.centerX();
        float centerY = viewRect.centerY();
        if (Surface.ROTATION_90 == rotation || Surface.ROTATION_270 == rotation) {
            bufferRect.offset(centerX - bufferRect.centerX(), centerY - bufferRect.centerY());
            matrix.setRectToRect(viewRect, bufferRect, Matrix.ScaleToFit.FILL);
            float scale = Math.max(
                    (float) viewHeight / mPreviewSize.getHeight(),
                    (float) viewWidth / mPreviewSize.getWidth());
            matrix.postScale(scale, scale, centerX, centerY);
            matrix.postRotate(90 * (rotation - 2), centerX, centerY);
        } else if (Surface.ROTATION_180 == rotation) {
            matrix.postRotate(180, centerX, centerY);
        }
        mTextureView.setTransform(matrix);
    }

    private void setAutoFlash(CaptureRequest.Builder requestBuilder) {
        if (mFlashSupported) {
            requestBuilder.set(CaptureRequest.CONTROL_AE_MODE,
                    CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
        }
    }


    /**
     * Compares two {@code Size}s based on their areas.
     */
    static class CompareSizesByArea implements Comparator<Size> {

        @Override
        public int compare(Size lhs, Size rhs) {
            // We cast here to ensure the multiplications won't overflow
            return Long.signum((long) lhs.getWidth() * lhs.getHeight() -
                    (long) rhs.getWidth() * rhs.getHeight());
        }

    }

    /**
     * Shows an error message dialog.
     */
    public static class ErrorDialog extends DialogFragment {

        private static final String ARG_MESSAGE = "message";

        public static ErrorDialog newInstance(String message) {
            ErrorDialog dialog = new ErrorDialog();
            Bundle args = new Bundle();
            args.putString(ARG_MESSAGE, message);
            dialog.setArguments(args);
            return dialog;
        }

        @NonNull
        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            final Activity activity = getActivity();
            return new AlertDialog.Builder(activity)
                    .setMessage(getArguments().getString(ARG_MESSAGE))
                    .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialogInterface, int i) {
                            activity.finish();
                        }
                    })
                    .create();
        }

    }

    /**
     * Shows OK/Cancel confirmation dialog about camera permission.
     */
    public static class ConfirmationDialog extends DialogFragment {

        @NonNull
        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            final Fragment parent = getParentFragment();
            return new AlertDialog.Builder(getActivity())
                    .setMessage(R.string.request_permission)
                    .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            parent.requestPermissions(new String[]{Manifest.permission.CAMERA},
                                    REQUEST_CAMERA_PERMISSION);
                        }
                    })
                    .setNegativeButton(android.R.string.cancel,
                            new DialogInterface.OnClickListener() {
                                @Override
                                public void onClick(DialogInterface dialog, int which) {
                                    Activity activity = parent.getActivity();
                                    if (activity != null) {
                                        activity.finish();
                                    }
                                }
                            })
                    .create();
        }
    }

    /**
     * Whether the camera is manual focusing now
     */
    private boolean mIsManualFocusing;
    /**
     * The current camera auto focus mode
     */
    private boolean mAutoFocus = true;

    private Rect mCropRegion;
    private MeteringRectangle[] mAFRegions = AutoFocusHelper.getZeroWeightRegion();

    private MeteringRectangle[] mAERegions = AutoFocusHelper.getZeroWeightRegion();

    /**
     * Check if the auto focus is supported.
     */
    private void checkAutoFocusSupported() {
        int[] modes = mCameraCharacteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES);
        mAutoFocusSupported = !(modes == null || modes.length == 0 ||
                (modes.length == 1 && modes[0] == CameraCharacteristics.CONTROL_AF_MODE_OFF));
    }

    /**
     * Check if the flash is supported.
     */
    private void checkFlashSupported() {
        Boolean available = mCameraCharacteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
        mFlashSupported = available == null ? false : available;
    }


    /**
     * Updates the internal state of manual focus.
     */
    void updateManualFocus(float x, float y) {
        @SuppressWarnings("ConstantConditions")
        int sensorOrientation = mCameraCharacteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
        mAFRegions = AutoFocusHelper.afRegionsForNormalizedCoord(x, y, mCropRegion, sensorOrientation);
        mAERegions = AutoFocusHelper.aeRegionsForNormalizedCoord(x, y, mCropRegion, sensorOrientation);
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_REGIONS, mAFRegions);
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_REGIONS, mAERegions);
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_AUTO);
    }

    void setManualFocusAt(int x, int y) {
        int mDisplayOrientation = getActivity().getWindowManager().getDefaultDisplay().getRotation();
        float points[] = new float[2];
        points[0] = (float) x / mTextureView.getWidth();
        points[1] = (float) y / mTextureView.getHeight();
        Matrix rotationMatrix = new Matrix();
        rotationMatrix.setRotate(mDisplayOrientation, 0.5f, 0.5f);
        rotationMatrix.mapPoints(points);
        if (mPreviewRequestBuilder != null) {
            mIsManualFocusing = true;
            updateManualFocus(points[0], points[1]);

            if (mCaptureSession != null) {
                try {
                    mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_TRIGGER,
                            CaptureRequest.CONTROL_AF_TRIGGER_START);
                    mCaptureSession.capture(mPreviewRequestBuilder.build(), null, mBackgroundHandler);
                    mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_TRIGGER,
                            CaptureRequest.CONTROL_AF_TRIGGER_IDLE);
                    mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(),
                            null, mBackgroundHandler);
                } catch (CameraAccessException | IllegalStateException e) {
                    Log.e(TAG, "Failed to set manual focus.", e);
                }
            }
            resumeAutoFocusAfterManualFocus();
        }
    }

    private final Runnable mAutoFocusRunnable = new Runnable() {
        @Override
        public void run() {
            if (mPreviewRequestBuilder != null) {
                mIsManualFocusing = false;
                updateAutoFocus();
                if (mCaptureSession != null) {
                    try {
                        mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(),
                                mCaptureCallback, mBackgroundHandler);
                    } catch (CameraAccessException e) {
                        Log.e(TAG, "Failed to set manual focus.", e);
                    }
                }
            }
        }
    };

    private void resumeAutoFocusAfterManualFocus() {
        mBackgroundHandler.removeCallbacks(mAutoFocusRunnable);
        mBackgroundHandler.postDelayed(mAutoFocusRunnable, CameraConstants.FOCUS_HOLD_MILLIS);
    }

    void updateAutoFocus() {
        if (mAutoFocus) {
            if (!mAutoFocusSupported) {
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                        CaptureRequest.CONTROL_AF_MODE_OFF);
            } else {
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                        CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);

            }
        } else {
            mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                    CaptureRequest.CONTROL_AF_MODE_OFF);
        }
        mAFRegions = AutoFocusHelper.getZeroWeightRegion();
        mAERegions = AutoFocusHelper.getZeroWeightRegion();
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_REGIONS, mAFRegions);
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_REGIONS, mAERegions);
    }

    public void setAutoFocus(boolean autoFocus) {
        if (mAutoFocus == autoFocus) {
            return;
        }
        mAutoFocus = autoFocus;
        if (mPreviewRequestBuilder != null) {
            updateAutoFocus();
            if (mCaptureSession != null) {
                try {
                    mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(),
                            mCaptureCallback, mBackgroundHandler);
                } catch (CameraAccessException e) {
                    mAutoFocus = !mAutoFocus; // Revert
                }
            }
        }
    }

    public boolean getAutoFocus() {
        return mAutoFocus;
    }


    String paraseResult(DLRResult[] result) {
        String strResult = "";
        if (result == null || result.length == 0) {
            return strResult;
        }

        for (int i = 0; i < result.length; i++) {
            String strCurResult = "[" + i + "] :\n";
            for (int j = 0; j < result[i].lineResults.length; j++) {
                strCurResult += result[i].lineResults[j].text + "\n";
            }
            if (i == 0)
                strResult = strCurResult;
            else
                strResult += "\n\n" + strCurResult;

        }
        return strResult;
    }
}
