import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/sms_service.dart';
import '../../../shared/size_config.dart';
import '4_digit_pin.dart';

class VerificationOtp extends StatefulWidget {
  final String mobileNum;
  const VerificationOtp({super.key, required this.mobileNum});

  @override
  State<VerificationOtp> createState() => _VerificationOtpState();
}

class _VerificationOtpState extends State<VerificationOtp> {
  TextEditingController controller = TextEditingController();
  int? verificationCode;
  final smsService = SMSService();


  Future<void> sendsms(String recipients, String message) async {
    // First, request SMS permission
    smsService.sendSMS(recipients, message, context);
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var random = Random();
    int randomNumber = random.nextInt(900000) + 100000;
    verificationCode = randomNumber;
    print('$randomNumber is your verification code');
    sendsms(widget.mobileNum, '$randomNumber is your verification code.');
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Linking E-wallet',
          style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 5,
              color: Colors.black,
              fontWeight: FontWeight.w500
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0.0,
            child: Container(
              color: Colors.blue[800],
              height: SizeConfig.blockSizeVertical * 23,
              width: SizeConfig.screenWidth,
            ),
          ),
          Positioned(
            top: SizeConfig.blockSizeVertical * 9,
            left: SizeConfig.blockSizeHorizontal * 5,
            right: SizeConfig.blockSizeHorizontal * 5,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.blockSizeVertical * 3, horizontal: SizeConfig.blockSizeHorizontal * 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0,3), // changes position of shadow
                  ),
                ],
              ),
              height: SizeConfig.blockSizeVertical * 30.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login to pay with E-Wallet',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.black,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    'Enter the 6-digit authentication code sent to your registered mobile number',
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical,),
                  Center(
                    child: Container(
                      height: SizeConfig.blockSizeVertical * 7.7,
                      width: SizeConfig.blockSizeHorizontal * 42,
                      decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey))
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical),
                        child: TextFormField(
                          inputFormatters: [LengthLimitingTextInputFormatter(6)],
                          controller: controller,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 9,
                          ),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none
                              )
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800]
                      ),
                      onPressed: (){
                        if(controller.text == verificationCode.toString()){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DigitPin(mobileNum: widget.mobileNum,)));
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Verification code is incorrect."))
                          );
                        }
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
