import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel{
  final String banner;
  final String bannerPath;
  final String description;
  final double discount;
  final Timestamp endDate;
  final Timestamp startDate;
  final String promoName;

  PromoModel({
    required this.banner,
    required this.bannerPath,
    required this.description,
    required this.discount,
    required this.endDate,
    required this.startDate,
    required this.promoName,
});

  factory PromoModel.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return PromoModel(
      banner: data['banner'],
      bannerPath: data['banner_path'],
      description: data['description'],
      discount: data['discount'],
      endDate: data['end_date'],
      startDate: data['start_date'],
      promoName: data['name'],
    );
  }

}