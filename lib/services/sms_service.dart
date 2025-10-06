import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SMSService {
  static const platform = MethodChannel('com.example.app/sms');

  Future<void> sendLongSMS(String phoneNumber, String message, BuildContext context) async {
    try {
      List<String> messageParts = _splitLongSMS(message);

      for (var part in messageParts) {
        print(part);
        final String result = await platform.invokeMethod('sendSMS', {
          'phone': phoneNumber,
          'message': part,
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send SMS: ${e.message}"))
      );
    }
  }

  List<String> _splitLongSMS(String message) {
    const int maxLength = 70;
    List<String> segments = [];

    for (int i = 0; i < message.length; i += maxLength) {
      int end = (i + maxLength < message.length)
          ? i + maxLength
          : message.length;
      segments.add(message.substring(i, end));
    }

    return segments;
  }

  Future<void> sendSMS(String phoneNumber, String message, BuildContext context) async {
    try {
      final String result = await platform.invokeMethod('sendSMS', {
        'phone': phoneNumber,
        'message': message,
      });
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send SMS: ${e.message}"))
      );
    }
  }
}