import 'package:flutter/material.dart';
import 'package:pakyaw/shared/size_config.dart';

class ErrorCatch extends StatelessWidget {
  final String error;
  const ErrorCatch({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: SafeArea
        (
        child: Center(
          child: Text(
            error,
            style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 10,
                color: Colors.black,
                fontWeight: FontWeight.w500
            ),
          ),
        ),
      ),
    );
  }
}
