import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountModel{
  final String description;
  final double discount;
  final String discountName;
  final double peso;

  DiscountModel({
    required this.description,
    required this.discount,
    required this.discountName,
    required this.peso
  });

  factory DiscountModel.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return DiscountModel(
      description: data['description'] ?? '',
      discount: data['discount'].toDouble() ?? 0.0,
      discountName: data['discount_name'] ?? '',
      peso: data['peso_value'].toDouble()
    );
  }

}