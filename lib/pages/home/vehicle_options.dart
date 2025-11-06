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
      data: (data) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'Select a vehicle type',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.1,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          widget.vehicletype(data[index].type);
                          Navigator.pop(context);
                        });
                      },
                      child: Card(
                        elevation: selectedIndex == index ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: selectedIndex == index 
                                ? Colors.black 
                                : Colors.grey.withOpacity(0.2),
                            width: selectedIndex == index ? 2.0 : 1.0,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedIndex == index 
                                ? Colors.grey[100] 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image(
                                image: NetworkImage(data[index].image),
                                height: 60.0,
                                width: 60.0,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                data[index].type,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16.0,
                                  fontWeight: selectedIndex == index 
                                      ? FontWeight.bold 
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
