package com.dynamsoft.passportmrzreading;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.widget.ImageView;
import android.widget.TextView;

import com.dynamsoft.dlr.*;
import com.dynamsoft.core.*;

import java.io.File;
import java.io.FileInputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class resultActivity extends AppCompatActivity {
    TextView tvSurname;
    TextView tvGivenNames;
    TextView tvSex;
    TextView tvBirth;
    TextView tvIssue;
    TextView tvNation;
    TextView tvPassNo;
    TextView tvExpiry;
    ImageView ivPhoto;
    private LabelRecognizer mRecognizer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.result_main);
        tvSurname = findViewById(R.id.tv_surname);
        tvGivenNames = findViewById(R.id.tv_given_names);
        tvSex = findViewById(R.id.tv_sex);
        tvBirth = findViewById(R.id.tv_birth);
        tvNation = findViewById(R.id.tv_Nation);
        tvIssue = findViewById(R.id.tv_issue);
        tvPassNo = findViewById(R.id.tv_pass_no);
        tvExpiry = findViewById(R.id.tv_date_expiry);
        ivPhoto = findViewById(R.id.iv_photo);
        mRecognizer = MainActivity.getMainLabelRecognizer();
        String fileName = getIntent().getStringExtra("fileName");
        File file = null;
        if (fileName != null){
            Log.e( "onCreate: ",fileName );
            file = new File(fileName);
        }
        int imageType = getIntent().getIntExtra("imageType", 0);
        if (file == null || !file.exists()) {
            showExDialog(resultActivity.this, "Recognize unsuccessfully");
            return;
        }

        try {
            FileInputStream fileInputStream = new FileInputStream(fileName);
            Bitmap bitmap = BitmapFactory.decodeStream(fileInputStream);
            Log.e( "onCreate: ",bitmap.getWidth()+" "+bitmap.getHeight() );
            ivPhoto.setImageBitmap(bitmap);
        } catch (Exception e) {
            e.printStackTrace();
        }
        DLRResult[] results = null;
        try {

            // 4. Recognize text from the image file. The second parameter is set to "locr" which is defined in the template json file.
            results = mRecognizer.recognizeByFile(fileName, "locr");
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }

        if (results == null || results.length == 0) {
            if (imageType == 0)
                //file.delete();
            showExDialog(resultActivity.this, "Recognize unsuccessfully");
            return;
        }

        // 5. Get the raw text of MRZ and .
        String reg1 = "P[A-Z<]([A-Z]{3})([A-Z<]{0,35}[A-Z]{1,3})<<([A-Z]{1}[A-Z<]{0,35}[A-Z]{1})<{0,35}";
        String reg2 = "([A-Z0-9]{0,9})[<]{0,9}[0-9]([A-Z]{3})([0-9]{2})([0-1][0-9])([0-3][0-9])[0-9]([MF])([0-9]{2})([0-1][0-9])([0-3][0-9])[0-9][A-Z0-9<]{14}[0-9][0-9]";
        String strLine1;
        String strLine2;
        Log.e( "onCreate: ",results[0].lineResults.length+" " );

        // 5. Get the raw text of MRZ.
        if (results[0].lineResults.length == 2) {
            strLine1 = results[0].lineResults[0].text;
            strLine2 = results[0].lineResults[1].text;
        } else {
            if (imageType == 0)
                //file.delete();
            Log.e( "onCreate: ",results[0].lineResults[0].text );
            showExDialog(resultActivity.this, "Recognize unsuccessfully");
            return;
        }
        Log.e( "onCreate: ",strLine1+" "+strLine2 );

        // 6. Parse the raw text of MRZ into passport info.
        if (!strLine1.matches(reg1) || !strLine2.matches(reg2)) {
            if (imageType == 0)
                //file.delete();
            showExDialog(resultActivity.this, "Recognize unsuccessfully");
            return;
        }
        Pattern pattern = Pattern.compile(reg1);
        Matcher matcher = pattern.matcher(strLine1);
        matcher.find();

        String surname = getNameString(matcher.group(2));
        String givenNames = getNameString(matcher.group(3));


        tvSurname.setText(surname);
        tvGivenNames.setText(givenNames);
        tvNation.setText(matcher.group(1));

        Pattern pattern2 = Pattern.compile(reg2);
        Matcher matcher2 = pattern2.matcher(strLine2);
        matcher2.find();
        tvPassNo.setText(matcher2.group(1));
        tvIssue.setText(matcher2.group(2));
        tvBirth.setText(matcher2.group(3) + "-" + matcher2.group(4)  + "-" + matcher2.group(5));//"YY MM DD"
        tvExpiry.setText(matcher2.group(7) + "-" + matcher2.group(8) + "-" + matcher2.group(9));//"YY MM DD"
        tvSex.setText(matcher2.group(6));
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
    }


    private int Compute(String source) {
        String s = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        int[] w = new int[]{7, 3, 1};
        int c = 0;
        for (int i = 0; i < source.length(); i++) {
            if (source.charAt(i) == '<')
                continue;
            c += s.indexOf(source.charAt(i)) * w[i % 3];
        }
        c %= 10;
        return c;
    }

    private boolean checkLine2(String line2Str) {
        if (line2Str.length() != 44)
            return false;
        String passportNoCheck = line2Str.substring(0, 9);
        String birthCheck = line2Str.substring(13, 19);
        String expiryCheck = line2Str.substring(21, 27);
        String personalCheck = line2Str.substring(28, 42);
        if (Integer.parseInt(line2Str.substring(9, 10)) != Compute(passportNoCheck))
            return false;
        if (Integer.parseInt(line2Str.substring(19, 20)) != Compute(birthCheck))
            return false;
        if (Integer.parseInt(line2Str.substring(27, 28)) != Compute(expiryCheck))
            return false;
        if (Integer.parseInt(line2Str.substring(42, 43)) != Compute(personalCheck))
            return false;
        if (Integer.parseInt(line2Str.substring(43)) != Compute(line2Str.substring(0, 10) + line2Str.substring(13, 20) + line2Str.substring(21, 28) + line2Str.substring(28, 43)))
            return false;
        return true;
    }

    void showExDialog(Context context, String msg) {
        new AlertDialog.Builder(context)
                .setMessage(msg)
                .setPositiveButton("Ok", null)
                .show();
    }

    private String getNameString(String str){
        String[] s = str.split("<");
        String nameStr="";
        for(int i=0;i<s.length;i++){
            nameStr+=s[i]+" ";
        }
        return nameStr;
    }
}

