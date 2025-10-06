import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/discount_model.dart';
import 'package:pakyaw/models/promo_model.dart';
import 'package:pakyaw/providers/disocunt_provider.dart';
import 'package:pakyaw/providers/promo_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

class Discount extends ConsumerStatefulWidget {
  final Function discount;
  const Discount({super.key, required this.discount});

  @override
  ConsumerState<Discount> createState() => _DiscountState();
}

class _DiscountState extends ConsumerState<Discount> {

  int calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final discount = ref.watch(discountProvider);
    final user = ref.watch(usersProvider);
    return user.when(
        data: (user){
          DateTime birthday = user!.birthday.toDate();
          int age = calculateAge(birthday);
          String pattern = r'seniorcitizen';
          RegExp regExp = RegExp(pattern, caseSensitive: false);
          return discount.when(
            data: (data){
              print('length: ${data.length}');
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index){
                  String sanitizedInput = data[index].discountName.replaceAll(RegExp(r'\s+'), '');
                    return GestureDetector(
                      onTap: (){
                        widget.discount(data[index].discount, data[index].discountName);
                        Navigator.pop(context);
                      },
                      child: DiscountTile(discountModel: data[index]),
                    );
                },
              );
            },
            error: (e, stack) => ErrorCatch(error: e.toString()),
            loading: () => const Loading(),
          );
        },
        error: (error, stack) => ErrorCatch(error: '$error'),
        loading: () => const Loading());
  }
}

class DiscountTile extends StatelessWidget {
  final DiscountModel discountModel;
  const DiscountTile({super.key, required this.discountModel});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      height: SizeConfig.blockSizeVertical * 10,
      child: Card(
        elevation: 2,
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 3),
              child: Expanded(
                flex: 40,
                child: Row(
                  children: [
                    Center(
                      child: Text(
                        '${(discountModel.discount * 100).toStringAsFixed(0)}% OFF',
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                            color: Colors.black,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.blockSizeVertical * 6, child: const VerticalDivider(),)
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 60,
                    child: Text(
                      discountModel.discountName,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.w500,
                          color: Colors.black
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 40,
                    child: Text(
                      discountModel.description,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

