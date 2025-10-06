package com.example.pakyaw;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.telephony.SmsManager;
import android.content.pm.PackageManager;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.Manifest;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.app/sms";
    private static final int PERMISSION_REQUEST_CODE = 1;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("sendSMS")) {
                        String phoneNumber = call.argument("phone");
                        String message = call.argument("message");
                        if (phoneNumber != null && message != null) {
                            if (checkPermission()) {
                                sendSMS(phoneNumber, message, result);
                            } else {
                                requestPermission();
                                result.error("PERMISSION_DENIED", "SMS permission not granted", null);
                            }
                        } else {
                            result.error("INVALID_ARGUMENTS", "Phone number or message is null", null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void sendSMS(String phoneNumber, String message, MethodChannel.Result result) {
        try {
            SmsManager smsManager = SmsManager.getDefault();
            smsManager.sendTextMessage(phoneNumber, null, message, null, null);
            result.success("SMS sent successfully");
        } catch (Exception e) {
            result.error("SMS_FAILED", "Failed to send SMS", e.getMessage());
        }
    }

    private boolean checkPermission() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermission() {
        ActivityCompat.requestPermissions(
                this,
                new String[]{Manifest.permission.SEND_SMS},
                PERMISSION_REQUEST_CODE
        );
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, you can send SMS now
            } else {
                // Permission denied, handle accordingly
            }
        }
    }
}