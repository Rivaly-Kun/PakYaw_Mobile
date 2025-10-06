// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_types_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vehicleTypesHash() => r'2a71a2e11d7ba72521bf835d7f4b9eced6e3518c';

/// See also [vehicleTypes].
@ProviderFor(vehicleTypes)
final vehicleTypesProvider =
    AutoDisposeStreamProvider<List<VehicleTypes>>.internal(
  vehicleTypes,
  name: r'vehicleTypesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vehicleTypesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VehicleTypesRef = AutoDisposeStreamProviderRef<List<VehicleTypes>>;
String _$maxCapacityHash() => r'32dd10d33c87492a23813223527ab2f309ce38f5';

/// See also [maxCapacity].
@ProviderFor(maxCapacity)
final maxCapacityProvider = AutoDisposeFutureProvider<Capacity>.internal(
  maxCapacity,
  name: r'maxCapacityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$maxCapacityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MaxCapacityRef = AutoDisposeFutureProviderRef<Capacity>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
