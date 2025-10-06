import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/services/storage.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

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
class IdPage extends ConsumerStatefulWidget {
  final String id;
  final Timestamp birthday;
  const IdPage({super.key, required this.id, required this.birthday});

  @override
  ConsumerState<IdPage> createState() => _IdPageState();
}

class _IdPageState extends ConsumerState<IdPage> {
  StorageService storage = StorageService();
  DatabaseService database = DatabaseService();
  bool isLoading = false;
  bool? student = false;
  bool? pwd = false;
  bool? seniorCitizen = false;
  int age = 0;
  Map<String, DiscountUpload> toUpload = {};

  List<String> id = ['Student', 'PWD', 'Senior Citizen'];

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

  showAfterSubmitDocuments(BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: SizedBox(
        height: SizeConfig.blockSizeVertical * 23,
        child: Column(
          children: [
            Image(
              image: const AssetImage('assets/schedule.png'),
              height: SizeConfig.blockSizeVertical * 10,
              width: SizeConfig.blockSizeHorizontal * 30,
            ),
            Text(
              "Verification of ID's will take 3 to 5 business days.",
              style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 5,
                  color: Colors.black,
                  fontWeight: FontWeight.w500
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DateTime date = widget.birthday.toDate();
    final currentDate = DateTime.now();
    age = currentDate.year - date.year;
    if (currentDate.month < date.month || (currentDate.month == date.month && currentDate.day < date.day)) { age--; }

  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final user = ref.watch(usersProvider);
    return user.when(
      data: (users){
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'ID',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: SizeConfig.safeBlockHorizontal * 7,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                users?.student == null || users?.pwd == null || users?.senior == null ? const Text(
                  "Submitted ID's",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ) : Container(),
                users?.student != null ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                      color: users?.student?['verified'] ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student ID',
                        style: TextStyle(
                            fontSize: SizeConfig.blockSizeHorizontal * 6.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.black
                        ),
                      ),
                      Icon(users?.student?['verified'] ? Icons.check_circle_outline : Icons.close, color: Colors.black, size: 35.0,)
                    ],
                  ),
                ) : Container(),
                users?.pwd != null ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                      color: users?.pwd?['verified'] ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PWD ID',
                        style: TextStyle(
                            fontSize: SizeConfig.blockSizeHorizontal * 6.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.black
                        ),
                      ),
                      Icon(users?.pwd?['verified'] ? Icons.check_circle_outline : Icons.close, color: Colors.black, size: 35.0,)
                    ],
                  ),
                ) : Container(),
                users?.senior != null ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                      color: users?.senior?['verified'] ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Senior Citizen ID',
                        style: TextStyle(
                            fontSize: SizeConfig.blockSizeHorizontal * 6.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.black
                        ),
                      ),
                      Icon(users?.senior?['verified'] ? Icons.check_circle_outline : Icons.close, color: Colors.black, size: 35.0,)
                    ],
                  ),
                ) : Container(),
                users?.student == null || users?.pwd == null || users?.senior == null ? const Text(
                  'Are you Any of these?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ) : Container(),
                users?.student == null || users?.pwd == null || users?.senior == null ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 10),
                  child: Text(
                    "Verification of submitted id's will take 3 to 5 business days.",
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 4,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ) : Container(),
                SizedBox(height: SizeConfig.blockSizeVertical * 3,),
                SizedBox(
                  height: SizeConfig.blockSizeVertical * 7.5,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      users?.student == null || !users?.student?['verified'] ? SizedBox(
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
                      ) : Container(),
                      users?.pwd == null || !users?.pwd?['verified'] ? SizedBox(
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
                      ) : Container(),
                      (users?.senior == null || !users?.senior?['verified']) && age >= 60 ? SizedBox(
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
                SizedBox(
                  width: 200.0,
                  height: 50.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        elevation: 2,
                        backgroundColor: Colors.black,
                        shadowColor: Colors.black,
                        disabledBackgroundColor: Colors.grey[800]
                    ),
                    onPressed: toUpload.isNotEmpty && !isLoading ? () async {
                      setState(() => isLoading = true);
                      try {
                        await Future.wait(
                            toUpload.entries.map((entry) async {
                              final reqId = entry.key;
                              final form = entry.value;
                              final url = await storage.uploadPassengerIDPic(
                                  reqId, users!.uid, form.image, form.fileName);
                              toUpload[reqId]!.url = url;
                              toUpload[reqId]!.expiry = Timestamp.fromDate(
                                  DateTime.now().add(
                                      const Duration(days: 365)));
                            })
                        );
                        bool result = await database.submitIDs(users!.uid, toUpload);
                        if(result){
                          showAfterSubmitDocuments(context);
                          toUpload.clear();
                          student = false;
                          pwd = false;
                          seniorCitizen = false;
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error uploading documents'))
                          );
                        }
                      }catch(e){
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error uploading documents: $e'))
                        );
                      }finally{
                        setState(() => isLoading = false);
                      }
                    } : null,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upload',
                          style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                        Icon(Icons.upload, size: 30.0, color: Colors.white),
                      ],
                    ),
                  ),
                ),              ],
            ),
          ),
        );
      },
      error: (error, stack) => ErrorCatch(error: '$error'),
      loading: () => const Loading(),);
  }
}
