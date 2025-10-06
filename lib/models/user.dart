import 'package:cloud_firestore/cloud_firestore.dart';

class Users{
  final String uid;
  final String profilePicPath;
  final String name;
  final Timestamp birthday;
  final String phoneNumber;
  final String email;
  final int ratingCount;
  final double totalRating;
  final List<dynamic> savedPlaces;
  final DateTime? createdAt;
  final bool blockedStatus;
  final String reason;
  Map<String, dynamic>? student;
  Map<String, dynamic>? pwd;
  Map<String, dynamic>? senior;

  Users({
    required this.uid,
    required this.profilePicPath,
    required this.name,
    required this.birthday,
    required this.phoneNumber,
    required this.email,
    required this.ratingCount,
    required this.totalRating,
    required this.savedPlaces,
    required this.blockedStatus,
    required this.reason,
    this.createdAt,
    this.student,
    this.pwd,
    this.senior,
  });

  factory Users.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Users(
      uid: doc.id,
      profilePicPath: data['profile_pic'] ?? '',
      name: data['name'] ?? '',
      birthday: data['birthday'],
      blockedStatus: data['blocked'],
      phoneNumber: data['phone_number'] ?? '',
      email: data['email'] ?? '',
      totalRating: data['totalRating'].toDouble(),
      ratingCount: data['ratingCount'],
      savedPlaces: data['saved_places'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] ?? '',
      student: data['Student'],
      pwd: data['PWD'],
      senior: data['Senior Citizen']

    );
  }

}

class PaymentMethod{
  final bool method;
  final String accountNum;
  final int linked;
  PaymentMethod({required this.method, required this.accountNum, required this.linked});

  factory PaymentMethod.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      method: data['e-wallet'],
      accountNum: data['account_number'] ?? '',
      linked: data['currently_linked'] ?? 0,
    );
  }
}