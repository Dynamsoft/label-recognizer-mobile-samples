package com.dynamsoft.passportmrzreading;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.util.TypedValue;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.dynamsoft.dlr.*;
import com.dynamsoft.core.*;
import com.dynamsoft.passportmrzreading.util.FileUtil;

import java.io.File;
import java.io.InputStream;

import cn.bingoogolapple.photopicker.util.BGAPhotoHelper;


public class MainActivity extends AppCompatActivity {
    private static LabelRecognizer mRecognizer;
    Button btnCaptrue;
    Button btnImage;
    Button btnFile;
    ProgressBar pb;
    String path = Environment.getExternalStorageDirectory() + "/dlr-preview-img";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        askForStoragePermissions();
        setContentView(R.layout.activity_main);
        btnCaptrue = findViewById(R.id.btn_camera);
        btnImage = findViewById(R.id.btn_selectimage);
        btnFile = findViewById(R.id.btn_selectfile);
        pb = findViewById(R.id.pb_progress_main);

        try {
            // 1.Initialize license.
            // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" here is a 7-day free license. Note that network connection is required for this license to work.
            // If you want to use an offline license, please contact Dynamsoft Support: https://www.dynamsoft.com/company/contact/
            // You can also request a 30-day trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=android
            LabelRecognizer.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", new DLRLicenseVerificationListener() {
                @Override
                public void DLRLicenseVerificationCallback(boolean b, final Exception e) {
                    if(!b && e!=null)
                        showLicenseError(b,e);
                }
            });

            // 2.Create an instance of Label Recognizer.
            mRecognizer = new LabelRecognizer();

            // 3. Initialize MRZ Character Models.
            initDefaultModel();

            // 4. Append config by a template json file.
            mRecognizer.appendSettingsFromString(FileUtil.getJsonStringFromAssert(MainActivity.this));
        } catch (Exception e) {
            Toast.makeText(this, e.getMessage(), Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        btnCaptrue.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, CaptureActivity.class);
                startActivity(intent);
//                takePhoto();
            }
        });
        btnImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                choicePhotoWrapper();
            }
        });
        btnFile.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                fileChooser();
            }
        });

    }
    private static final int REQUEST_CHOOSE_PHOTO = 0x0001;
    private static final int REQUEST_FILE_SELECT = 0x0002;
    private void choicePhotoWrapper() {
        BGAPhotoHelper photoHelper = new BGAPhotoHelper(new File(Environment.getExternalStorageDirectory(), ""));
        startActivityForResult(photoHelper.getChooseSystemGalleryIntent(), REQUEST_CHOOSE_PHOTO);
    }
    private void fileChooser() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        try {
            startActivityForResult(Intent.createChooser(intent, ""), REQUEST_FILE_SELECT);
        } catch (android.content.ActivityNotFoundException ex) {
            ex.printStackTrace();
        }
    }
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CHOOSE_PHOTO && resultCode == RESULT_OK) {
            String filePath = BGAPhotoHelper.getFilePathFromUri(data.getData());
            Intent intent = new Intent(MainActivity.this, resultActivity.class);
            intent.putExtra("fileName", filePath);
            intent.putExtra("imageType", 1);
            startActivity(intent);
        } else if (requestCode == REQUEST_FILE_SELECT && resultCode == RESULT_OK) {
            String filePath = FileUtil.getFilePathFromUri(MainActivity.this,data.getData());
            Intent intent = new Intent(MainActivity.this, resultActivity.class);
            intent.putExtra("fileName", filePath);
            intent.putExtra("imageType", 1);
            startActivity(intent);
        }
    }

    private void askForStoragePermissions() {
        String[] perms = {Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};
        int permission = ActivityCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);
        if (permission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, perms, 1);
        }
    }

    private void initDefaultModel() {
        try {
            String[] fileNames = {"NumberUppercase","NumberUppercase_Assist_1lIJ","NumberUppercase_Assist_8B","NumberUppercase_Assist_8BHR","NumberUppercase_Assist_number","NumberUppercase_Assist_O0DQ","NumberUppercase_Assist_upcase"};
            for(int i = 0;i<fileNames.length;i++) {
                AssetManager manager = getAssets();
                InputStream isPrototxt = manager.open("CharacterModel/"+fileNames[i]+".prototxt");
                byte[] prototxt = new byte[isPrototxt.available()];
                isPrototxt.read(prototxt);
                isPrototxt.close();
                InputStream isCharacterModel = manager.open("CharacterModel/"+fileNames[i]+".caffemodel");
                byte[] characterModel = new byte[isCharacterModel.available()];
                isCharacterModel.read(characterModel);
                isCharacterModel.close();
                InputStream isTxt = manager.open("CharacterModel/"+fileNames[i]+".txt");
                byte[] txt = new byte[isTxt.available()];
                isTxt.read(txt);
                isTxt.close();
                mRecognizer.appendCharacterModelBuffer(fileNames[i], prototxt, txt, characterModel);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    void showLicenseError(final boolean isSuccess, final Exception e){
        (MainActivity.this).runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String msg = "Unable to resolve host";
                String msg1 = "Failed to connect to";
                String tips = "";
                if (e.getMessage().contains(msg) || e.getMessage().contains(msg1)) {
                    tips = getResources().getString(R.string.network_tip);
                } else {
                    tips = e.getMessage();
                }
                if (e instanceof LabelRecognizerException) {
                    Log.e( "run: ", ((LabelRecognizerException)e).getErrorCode()+" "+e.getMessage() );
                    if (((LabelRecognizerException) e).getErrorCode() == EnumDLRErrorCode.DM_LICENSE_EXPIRED) {
                        tips = getResources().getString(R.string.visit);
                    }
                }
                showExDialog(MainActivity.this,"error", tips);
            }
        });
    }

    private boolean bShowing = false;
    void showExDialog(Context context, String tit, String msg) {
        if(bShowing)
            return;
        bShowing=true;
        AlertDialog.Builder builder = new AlertDialog.Builder(context)
                .setOnDismissListener(new DialogInterface.OnDismissListener() {
                    @Override
                    public void onDismiss(DialogInterface dialog) {
                        bShowing = false;
                    }
                });
        if (msg.contains("Please visit")) {
            builder.setTitle("The license has expired.")
                   .setPositiveButton("Ok", null);
            TextView tv = new TextView(context);
            tv.setText(R.string.visit);
            tv.setLineSpacing(8f, 1f);
            tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f);
            tv.setPadding(100, 50, 100, 0);
            tv.setMovementMethod(LinkMovementMethod.getInstance());
            builder.setView(tv);
            builder.show();
        } else {
            builder.setTitle(tit)
                    .setMessage(msg)
                    .setPositiveButton("Ok", null)
                    .show();
        }
    }

    public static LabelRecognizer getMainLabelRecognizer() {
        return mRecognizer;
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
    }

}