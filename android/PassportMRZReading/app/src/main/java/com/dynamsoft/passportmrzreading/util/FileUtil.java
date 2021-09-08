package com.dynamsoft.passportmrzreading.util;

import android.content.ContentUris;
import android.content.Context;
import android.content.res.AssetManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.support.v4.content.FileProvider;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;

public class FileUtil {

    public static String getFilePathFromUri(final Context context, final Uri uri) {
        if (uri == null) {
            return null;
        }
        if(uri.toString().contains("/storage/emulated/0/")){
            int index = uri.toString().indexOf("/storage/emulated/0/");
            return uri.toString().substring(index);
        }
        if (DocumentsContract.isDocumentUri(context, uri)) {
            final String authority = uri.getAuthority();
            if ("com.android.externalstorage.documents".equals(authority)) {
                final String doc = DocumentsContract.getDocumentId(uri);
                final String[] divide = doc.split(":");
                final String type = divide[0];
                if ("primary".equals(type)) {
                    String path = Environment.getExternalStorageDirectory().getAbsolutePath().concat("/").concat(divide[1]);
                    return path;
                } else {
                    String path = "/storage/".concat(type).concat("/").concat(divide[1]);
                    return path;
                }
            } else if ("com.android.providers.downloads.documents".equals(authority)) {
                final String doc = DocumentsContract.getDocumentId(uri);
                if (doc.startsWith("raw:")) {
                    final String path = doc.replaceFirst("raw:", "");
                    return path;
                }
                final Uri downloadUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), Long.parseLong(doc));
                String path = queryAbsolutePath(context, downloadUri, null, null);
                return path;
            } else if ("com.android.providers.media.documents".equals(authority)) {
                final String doc = DocumentsContract.getDocumentId(uri);
                final String[] splits = doc.split(":");
                final String type = splits[0];
                Uri mediaUri = null;
                if ("image".equals(type)) {
                    mediaUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    mediaUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    mediaUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                } else {
                    return null;
                }
                final String selection = "_id=?";
                final String[] selectionArgs = new String[]{splits[1]};
                mediaUri = ContentUris.withAppendedId(mediaUri, Long.parseLong(splits[1]));
                String path = queryAbsolutePath(context, mediaUri,selection,selectionArgs);
                return path;
            }
        } else {
            final String scheme = uri.getScheme();
            String path = null;
            if ("content".equals(scheme)) {
                path = queryAbsolutePath(context, uri, null, null);
            } else if ("file".equals(scheme)) {
                path = uri.getPath();
            }
            return path;
        }
        return null;
    }

    private static String queryAbsolutePath(final Context context, final Uri uri, String selection, String[] selectionArgs) {
        final String[] projection = {MediaStore.MediaColumns.DATA};
        Cursor cursor = null;
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);
                return cursor.getString(index);
            }
        } catch (final Exception ex) {
            ex.printStackTrace();
            if (cursor != null) {
                cursor.close();
            }
        }
        return null;
    }

    public static Uri getUriForFile(Context context, File file) {
        Uri fileUri;
        if (Build.VERSION.SDK_INT >= 24) {
            fileUri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", file);
        } else {
            fileUri = Uri.fromFile(file);
        }
        return fileUri;
    }

    public static String getJsonStringFromAssert(Context context) {
        StringBuilder stringBuilder = new StringBuilder();
        try {
            AssetManager manager = context.getAssets();
            BufferedReader bf = new BufferedReader(new InputStreamReader(
                    manager.open("wholeImgMRZTemplate.json")));
            String line;
            while ((line = bf.readLine()) != null) {
                stringBuilder.append(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return stringBuilder.toString();
    }

}
