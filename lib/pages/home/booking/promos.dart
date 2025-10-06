import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/promo_model.dart';
import 'package:pakyaw/providers/promo_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

class Promos extends ConsumerStatefulWidget {
  final Function discount;
  final String vehicleType;
  const Promos({super.key, required this.discount, required this.vehicleType});

  @override
  ConsumerState<Promos> createState() => _PromosState();
}

class _PromosState extends ConsumerState<Promos> {
  @override
  Widget build(BuildContext context) {
    final promo = ref.watch(promoProvider);
    final targetedPromo = ref.watch(promoVehicleTypeProvider(widget.vehicleType));
    return SingleChildScrollView(
      child: Column(
        children: [
          promo.when(
            data: (data) => ListView.builder(
              shrinkWrap: true, // Important for nested lists
              physics: const NeverScrollableScrollPhysics(), // Prevents individual list scrolling
              itemCount: data.length,
              itemBuilder: (context, index){
                return GestureDetector(
                  onTap: (){
                    widget.discount(data[index].discount, data[index].promoName);
                    Navigator.pop(context);
                  },
                  child: PromoTile(promoModel: data[index]),
                );
              },
            ),
            error: (e, stack) => ErrorCatch(error: e.toString()),
            loading: () => const Loading(),
          ),
          targetedPromo.when(
            data: (data) => ListView.builder(
              shrinkWrap: true, // Important for nested lists
              physics: const NeverScrollableScrollPhysics(), // Prevents individual list scrolling
              itemCount: data.length,
              itemBuilder: (context, index){
                return GestureDetector(
                  onTap: (){
                    widget.discount(data[index].discount, data[index].promoName);
                    Navigator.pop(context);
                  },
                  child: PromoTile(promoModel: data[index]),
                );
              },
            ),
            error: (e, stack) => ErrorCatch(error: e.toString()),
            loading: () => const Loading(),
          ),
        ],
      ),
    );
  }
}

class PromoTile extends StatelessWidget {
  final PromoModel promoModel;
  const PromoTile({super.key, required this.promoModel});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    DateTime startingDate = promoModel.startDate.toDate();
    DateTime endingDate = promoModel.endDate.toDate();
    String formattedStartDate = DateFormat('MM/dd/yyyy').format(startingDate);
    String formattedEndDate = DateFormat('MM/dd/yyyy').format(endingDate);

    return Container(
      height: SizeConfig.blockSizeVertical * 10,
      child: Card(
        elevation: 2,
        child: Row(
          children: [
            Expanded(
              flex: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(promoModel.discount * 100).toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.black,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.blockSizeVertical * 6,
                    child: const VerticalDivider(),
                  )
                ],
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
                      promoModel.promoName,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.w500,
                          color: Colors.black
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 40,
                    child: Text(
                      'Start: $formattedStartDate, End: $formattedEndDate',
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

