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

class DiscountTile extends StatefulWidget {
  final DiscountModel discountModel;
  const DiscountTile({super.key, required this.discountModel});

  @override
  State<DiscountTile> createState() => _DiscountTileState();
}

class _DiscountTileState extends State<DiscountTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: SizeConfig.blockSizeVertical * 12,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(widget.discountModel.discount * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.discountModel.discountName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.discountModel.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

