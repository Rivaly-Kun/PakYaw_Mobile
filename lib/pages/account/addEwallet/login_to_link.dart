import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:pakyaw/pages/account/addEwallet/verification_otp.dart';

import '../../../shared/size_config.dart';

class LoginToLink extends StatefulWidget {
  const LoginToLink({super.key});

  @override
  State<LoginToLink> createState() => _LoginToLinkState();
}

class _LoginToLinkState extends State<LoginToLink> {
  TextEditingController controller = TextEditingController();

  String? error;

  bool validateNumber(String input){
    num? n = num.tryParse(input);
    if(n == null){
      setState(() {
        error = 'Input a mobile number no spaces/characters';
      });
      return false;
    }

    if(input.length != 10){
      setState(() {
        error = 'Number needs to be 10 integers.';
      });
      return false;
    }
    String sub1 = input.substring(0, 3);
    String sub2 = input.substring(3, 6);
    String sub3 = input.substring(6, 10);
    String compareTo = '$sub1 $sub2-$sub3';
    final compare = RegExp(r'^9\d{2} \d{3}-\d{4}$');
    print(compareTo);
    if(!compare.hasMatch(compareTo)){
      setState(() {
        error = 'Invalid number';
      });
      return false;
    }
    setState(() {
      error = '';
    });
    return true;
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
                    'Login to link with E-wallet',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.black,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    'Enter your mobile number.',
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical * 4,),
                  Container(
                    height: SizeConfig.blockSizeVertical * 4,
                    decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey))
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(width: SizeConfig.blockSizeHorizontal + 3,),
                        Text(
                          '+63',
                          style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                          ),
                        ),
                        const VerticalDivider(color: Colors.grey,),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 1.2),
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 4,
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
                      ],
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
                        if(validateNumber(controller.text)){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationOtp(mobileNum: '+63${controller.text}',)));
                        }else{

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
