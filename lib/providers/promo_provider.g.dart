// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promoHash() => r'00302754db77322923d2830a46fdd857216c98b4';

/// See also [promo].
@ProviderFor(promo)
final promoProvider = AutoDisposeStreamProvider<List<PromoModel>>.internal(
  promo,
  name: r'promoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$promoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PromoRef = AutoDisposeStreamProviderRef<List<PromoModel>>;
String _$allPromoHash() => r'78f2b25174fd4a1d12b3d577cb58b655ea168950';

/// See also [allPromo].
@ProviderFor(allPromo)
final allPromoProvider = AutoDisposeStreamProvider<List<PromoModel>>.internal(
  allPromo,
  name: r'allPromoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPromoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllPromoRef = AutoDisposeStreamProviderRef<List<PromoModel>>;
String _$promoVehicleTypeHash() => r'ee541adb860d3a398b88d616f800b0c2b838e978';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [promoVehicleType].
@ProviderFor(promoVehicleType)
const promoVehicleTypeProvider = PromoVehicleTypeFamily();

/// See also [promoVehicleType].
class PromoVehicleTypeFamily extends Family<AsyncValue<List<PromoModel>>> {
  /// See also [promoVehicleType].
  const PromoVehicleTypeFamily();

  /// See also [promoVehicleType].
  PromoVehicleTypeProvider call(
    String vehicleType,
  ) {
    return PromoVehicleTypeProvider(
      vehicleType,
    );
  }

  @override
  PromoVehicleTypeProvider getProviderOverride(
    covariant PromoVehicleTypeProvider provider,
  ) {
    return call(
      provider.vehicleType,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'promoVehicleTypeProvider';
}

/// See also [promoVehicleType].
class PromoVehicleTypeProvider
    extends AutoDisposeStreamProvider<List<PromoModel>> {
  /// See also [promoVehicleType].
  PromoVehicleTypeProvider(
    String vehicleType,
  ) : this._internal(
          (ref) => promoVehicleType(
            ref as PromoVehicleTypeRef,
            vehicleType,
          ),
          from: promoVehicleTypeProvider,
          name: r'promoVehicleTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$promoVehicleTypeHash,
          dependencies: PromoVehicleTypeFamily._dependencies,
          allTransitiveDependencies:
              PromoVehicleTypeFamily._allTransitiveDependencies,
          vehicleType: vehicleType,
        );

  PromoVehicleTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.vehicleType,
  }) : super.internal();

  final String vehicleType;

  @override
  Override overrideWith(
    Stream<List<PromoModel>> Function(PromoVehicleTypeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PromoVehicleTypeProvider._internal(
        (ref) => create(ref as PromoVehicleTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        vehicleType: vehicleType,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PromoModel>> createElement() {
    return _PromoVehicleTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PromoVehicleTypeProvider &&
        other.vehicleType == vehicleType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, vehicleType.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PromoVehicleTypeRef on AutoDisposeStreamProviderRef<List<PromoModel>> {
  /// The parameter `vehicleType` of this provider.
  String get vehicleType;
}

class _PromoVehicleTypeProviderElement
    extends AutoDisposeStreamProviderElement<List<PromoModel>>
    with PromoVehicleTypeRef {
  _PromoVehicleTypeProviderElement(super.provider);

  @override
  String get vehicleType => (origin as PromoVehicleTypeProvider).vehicleType;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
