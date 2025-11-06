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
    String formattedStartDate = DateFormat('MMM dd').format(startingDate);
    String formattedEndDate = DateFormat('MMM dd').format(endingDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(promoModel.discount * 100).toStringAsFixed(0)}%\nOFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promoModel.promoName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$formattedStartDate - $formattedEndDate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

