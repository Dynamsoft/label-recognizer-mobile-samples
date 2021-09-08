package com.example.helloworld;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import java.io.File;

import com.dynamsoft.dlr.*;

public class MainActivity extends AppCompatActivity {
    // Click to take a photo
    private Button btnCapture;
    // Click to recognize thext
    private Button btnRecognize;
    // Display the photo taken with Camera App
    private ImageView imgView;
    // Display the recognition results
    private TextView txtView;

    // Uri of the captured photo
    private Uri imgUri;
    // The full path of the captured photo
    private String imgPath;

    private static final int Image_Capture_Code = 1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnCapture = findViewById(R.id.btnCapture);
        btnRecognize = findViewById(R.id.btnRecognize);
        imgView = findViewById(R.id.imgView);
        txtView = findViewById(R.id.txtView);



        btnCapture.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // take a photo with Camera App
                takePhoto();
            }
        });

        btnRecognize.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // recognize text in the photo
                recognizeText();
            }
        });

        // 1.Initialize license.
        // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" here is a 7-day free license. Note that network connection is required for this license to work.
        // If you want to use an offline license, please contact Dynamsoft Support: https://www.dynamsoft.com/company/contact/
        // You can also request a 30-day trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=android
        LabelRecognizer.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", new DLRLicenseVerificationListener() {
            @Override
            public void DLRLicenseVerificationCallback(boolean isSuccess, Exception error) {
                if(!isSuccess){
                    error.printStackTrace();
                }
            }
        });
    }

    private void recognizeText() {
        try {

            // 2.Create an instance of Label Recognizer.
            LabelRecognizer dlr = new LabelRecognizer();

            // 3.Recognize text from an image file.
            DLRResult[] results = dlr.recognizeByFile(imgPath, "");

            if (results != null && results.length > 0) {
                String strCurResult = "";
                for (int i = 0; i < results.length; i++) {

                    // Get result of each text area (also called label).
                    DLRResult result = results[i];
                    strCurResult += "Result " + i + ":\n";
                    for (int j = 0; j < result.lineResults.length; j++) {

                        // Get the result of each text line in the label.
                        DLRLineResult lineResult = result.lineResults[j];
                        strCurResult += ">>Line Result " + j + ": " + lineResult.text + "\n";
                    }
                }
                txtView.setText(strCurResult);
            } else {
                txtView.setText("No data detected.");
            }
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }
    }

    private void takePhoto() {
        String status= Environment.getExternalStorageState();
        if(status.equals(Environment.MEDIA_MOUNTED)) {
            try {
                File outputImage = new File(getExternalCacheDir(), "output_image.jpg");
                imgPath = outputImage.getAbsolutePath();

                if (outputImage.exists()) {
                    outputImage.delete();
                }
                outputImage.createNewFile();

                if (Build.VERSION.SDK_INT >= 24) {
                    imgUri = FileProvider.getUriForFile(this, "com.example.helloworld", outputImage);
                } else {
                    imgUri = Uri.fromFile(outputImage);
                }

                Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                intent.putExtra(MediaStore.EXTRA_OUTPUT, imgUri);
                startActivityForResult(intent, Image_Capture_Code);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == Image_Capture_Code && resultCode == RESULT_OK) {
            try {
                Bitmap bitmap = BitmapFactory.decodeStream(getContentResolver().openInputStream(imgUri));
                imgView.setImageBitmap(bitmap);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}