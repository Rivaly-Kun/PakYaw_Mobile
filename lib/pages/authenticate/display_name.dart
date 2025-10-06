import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/services/storage.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:file_picker/file_picker.dart';

class DiscountUpload{
  File? image;
  String fileName;
  Timestamp? expiry;
  String? url;
  bool verified = false;
  DiscountUpload({
   required this.image,
   required this.fileName,
    this.expiry,
    this.url
});
}

class SetName extends ConsumerStatefulWidget {
  const SetName({super.key});

  @override
  ConsumerState<SetName> createState() => _SetNameState();
}

class _SetNameState extends ConsumerState<SetName> {

  StorageService storage = StorageService();
  final _formKey = GlobalKey<FormState>();
  bool? student = false;
  bool? pwd = false;
  bool? seniorCitizen = false;
  Map<String, DiscountUpload> toUpload = {};
  String fname = '';
  String lname = '';
  int age = 0;
  TextEditingController expiryDate = TextEditingController();

  Future<void> _selectDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: (365 * 12))),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: (365 * 12))),
    );

    if(date != null){
      setState(() {
        expiryDate.text = date.toString().split(" ")[0];
        final currentDate = DateTime.now();
        age = currentDate.year - date.year;
        if (currentDate.month < date.month || (currentDate.month == date.month && currentDate.day < date.day)) { age--; }

      });
    }

  }

  bool isImageFile(String filePath) {
    final imageExtensions = ["jpg'", "jpeg'", "png'", "gif'", "bmp'", "webp'", "tiff'"];
    String extension = filePath.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }
  Future<void> pickFile(String reqId) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false
    );

    if (result != null) {
      setState(() {
        toUpload.putIfAbsent(reqId, () => DiscountUpload(image: File(result.files.single.path!), fileName: result.files.single.name)) ;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final _dbService = ref.watch(databaseServiceProvider);
    final _authService = ref.watch(authStateProvider);
    return _authService.when(data: (user){
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 0.0),
                  child: const Text(
                    "What's your name?",
                    style: TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0,),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Text(
                    "Let us know how to properly address you",
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 50.0,),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0,),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'First name',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12.0,),
                        TextFormField(
                          onChanged: (val) => fname = val,
                          validator: (val) => val!.isEmpty ? 'First name is empty': null,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                              fillColor: Colors.grey[350],
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10.0)
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.black, width: 3.0,),
                                  borderRadius: BorderRadius.circular(10.0)
                              )
                          ),
                        ),
                        const SizedBox(height: 20.0,),
                        const Text(
                          'Last name',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12.0,),
                        TextFormField(
                          onChanged: (val) => lname = val,
                          validator: (val) => val!.isEmpty ? 'Last name is empty': null,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                              fillColor: Colors.grey[350],
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10.0)
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.black, width: 3.0,),
                                  borderRadius: BorderRadius.circular(10.0)
                              )
                          ),
                        ),
                        const SizedBox(height: 20.0,),
                        const Text(
                          'Birthday',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                            border: Border.all(color: Colors.grey),
                          ),
                          width: 250.0,
                          child: TextFormField(
                            controller: expiryDate,
                            validator: (val) => val!.isEmpty ? 'Last name is empty': null,
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              filled: true,
                              prefixIcon: Icon(Icons.calendar_today),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black)
                              ),
                            ),
                            readOnly: true,
                            onTap: (){
                              _selectDate();
                            },
                          ),
                        ),
                        const SizedBox(height: 20.0,),
                        const Text(
                          'Are you Any of these?',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 10),
                          child: Text(
                            "Verification of submitted id's will take 3 to 5 business days.",
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 4,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10.0,),
                        SizedBox(
                          height: SizeConfig.blockSizeVertical * 7.5,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              SizedBox(
                                width: SizeConfig.safeBlockHorizontal * 43,
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  child: CheckboxListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                                    title: const Text('Student'),
                                    value: student,
                                    onChanged: (newVal){
                                      setState(() {
                                        student = newVal;
                                      });
                                    },
                                    activeColor: Colors.black,
                                    checkColor: Colors.white,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: SizeConfig.safeBlockHorizontal * 38,
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                                    title: const Text('PWD'),
                                    value: pwd,
                                    onChanged: (newVal){
                                      setState(() {
                                        pwd = newVal;
                                      });
                                    },
                                    activeColor: Colors.black,
                                    checkColor: Colors.white,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                              ),
                              age >= 60 ? SizedBox(
                                width: SizeConfig.safeBlockHorizontal * 55,
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                                    title: const Text('Senior Citizen'),
                                    value: seniorCitizen,
                                    onChanged: (newVal){
                                      setState(() {
                                        seniorCitizen = newVal;
                                      });
                                    },
                                    activeColor: Colors.black,
                                    checkColor: Colors.white,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                              ) : Container(),
                            ],
                          ),
                        ),
                        student! ? const SizedBox(height: 20.0,) : Container(),
                        student! ? Center(
                          child: Container(
                            width: SizeConfig.screenWidth,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Student ID',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (student! && toUpload['Student'] != null) ...[
                                  if (isImageFile(toUpload['Student']!.image.toString()))
                                    Container(
                                      height: SizeConfig.blockSizeVertical * 20,
                                      width: SizeConfig.blockSizeHorizontal * 45,
                                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(color: Colors.grey.shade300),
                                          image: DecorationImage(
                                              image: FileImage(toUpload['Student']!.image!),
                                              fit: BoxFit.cover
                                          )
                                      ),
                                    )
                                  else
                                    Text(toUpload['Student']!.fileName),
                                ],
                                student! ? Container(
                                  width: SizeConfig.blockSizeHorizontal * 43,
                                  height: SizeConfig.blockSizeVertical * 6,
                                  decoration: ShapeDecoration(
                                      color: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0)
                                      )
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => pickFile('Student'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent
                                    ),
                                    child: Text(
                                      'Choose image',
                                      style: TextStyle(
                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ) : Container(),
                              ],
                            ),
                          ),
                        ) : Container(),
                        pwd! ? const SizedBox(height: 20.0,) : Container(),
                        pwd! ? Center(
                          child: Container(
                            width: SizeConfig.screenWidth,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'PWD ID',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (pwd! && toUpload['PWD'] != null) ...[
                                  if (isImageFile(toUpload['PWD']!.image.toString()))
                                    Container(
                                      height: SizeConfig.blockSizeVertical * 20,
                                      width: SizeConfig.blockSizeHorizontal * 45,
                                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(color: Colors.grey.shade300),
                                          image: DecorationImage(
                                              image: FileImage(toUpload['PWD']!.image!),
                                              fit: BoxFit.cover
                                          )
                                      ),
                                    )
                                  else
                                    Text(toUpload['PWD']!.fileName),
                                ],
                                pwd! ? Container(
                                  width: SizeConfig.blockSizeHorizontal * 43,
                                  height: SizeConfig.blockSizeVertical * 6,
                                  decoration: ShapeDecoration(
                                      color: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0)
                                      )
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => pickFile('PWD'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent
                                    ),
                                    child: Text(
                                      'Choose image',
                                      style: TextStyle(
                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ) : Container(),
                              ],
                            ),
                          ),
                        ) : Container(),
                        seniorCitizen! ? const SizedBox(height: 20.0,) : Container(),
                        seniorCitizen! ? Center(
                          child: Container(
                            width: SizeConfig.screenWidth,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Senior Citizen ID',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (seniorCitizen! && toUpload['Senior Citizen'] != null) ...[
                                  if (isImageFile(toUpload['Senior Citizen']!.image.toString()))
                                    Container(
                                      height: SizeConfig.blockSizeVertical * 20,
                                      width: SizeConfig.blockSizeHorizontal * 45,
                                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(color: Colors.grey.shade300),
                                          image: DecorationImage(
                                              image: FileImage(toUpload['PWD']!.image!),
                                              fit: BoxFit.cover
                                          )
                                      ),
                                    )
                                  else
                                    Text(toUpload['Senior Citizen']!.fileName),
                                ],
                                seniorCitizen! ? Container(
                                  width: SizeConfig.blockSizeHorizontal * 43,
                                  height: SizeConfig.blockSizeVertical * 6,
                                  decoration: ShapeDecoration(
                                      color: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0)
                                      )
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => pickFile('Senior Citizen'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent
                                    ),
                                    child: Text(
                                      'Choose image',
                                      style: TextStyle(
                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ) : Container(),
                              ],
                            ),
                          ),
                        ) : Container(),
                        const SizedBox(height: 20.0,),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.fromLTRB(32.0, 0.0, 0.0, 20.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[350],
                      padding: const EdgeInsets.fromLTRB(6.0, 15.0, 0.0, 15.0)
                  ),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 30.0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  label: const Text(''),
                ),
                ElevatedButton.icon(
                  iconAlignment: IconAlignment.end,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.all(15.0)
                  ),
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30.0,
                  ),
                  onPressed: () async {
                    if(_formKey.currentState!.validate()){
                      String fullName = '$fname $lname';
                      await Future.wait(
                        toUpload.entries.map((entry) async {
                          final reqId = entry.key;
                          final form = entry.value;
                          final url = await storage.uploadPassengerIDPic(reqId, user!.uid, form.image, form.fileName);
                          toUpload[reqId]!.url = url;
                          toUpload[reqId]!.expiry = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
                        })
                      );
                      _dbService.createUser(user!.uid, fullName, fname, lname, user.phoneNumber, user.email, expiryDate.text, toUpload);
                      Navigator.pushNamedAndRemoveUntil(context, '/Home', (r) => false);
                      print('$fname $lname');
                    }
                  },
                  label: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]
          ),
        ),
      );
    }, error: (e,trace) => SetName(), loading: () => const Loading());
  }
}
