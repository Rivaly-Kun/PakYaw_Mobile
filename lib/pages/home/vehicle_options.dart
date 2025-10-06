import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/models/vehicle_options_model.dart';
import 'package:pakyaw/pages/home/home.dart';
import 'package:pakyaw/providers/vehicle_types_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';

class VehicleOptions extends ConsumerStatefulWidget {

  final Function vehicletype;

  const VehicleOptions({super.key, required this.vehicletype});

  @override
  ConsumerState<VehicleOptions> createState() => _VehicleOptionsState();
}

class _VehicleOptionsState extends ConsumerState<VehicleOptions> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = ref.watch(vehicleTypesProvider);
    return vehicleTypes.when(
      data: (data){
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Select a vehicle type',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30.0,),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        widget.vehicletype(data[index].type);
                        if(mounted) Navigator.pop(context);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedIndex == index ? Colors.grey[350] : Colors.white,
                        border: Border.all(
                          color: selectedIndex == index ? Colors.black : Colors.black,
                          width: 3.0,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image(
                            image: NetworkImage(data[index].image),
                            height: 50.0,
                            width: 50.0,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10.0,),
                          Text(
                            data[index].type,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (e, stack) => ErrorCatch(error: e.toString()),
      loading: () => const Loading(),

    );
  }
}

class VehicleOptionsModel {
  List<String> vehicleOptions = ['Bike', 'Sedan', 'SUV', 'Tricycle'];

  List<String> get vehicleTypes {
    return vehicleOptions;
  }
}
