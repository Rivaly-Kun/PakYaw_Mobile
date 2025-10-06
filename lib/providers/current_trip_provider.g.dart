// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTripHash() => r'cd2773d9ac8a5f9c3e37b019b0070b12c6c0e655';

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

/// See also [currentTrip].
@ProviderFor(currentTrip)
const currentTripProvider = CurrentTripFamily();

/// See also [currentTrip].
class CurrentTripFamily extends Family<AsyncValue<CurrentTrip>> {
  /// See also [currentTrip].
  const CurrentTripFamily();

  /// See also [currentTrip].
  CurrentTripProvider call(
    String Tripid,
  ) {
    return CurrentTripProvider(
      Tripid,
    );
  }

  @override
  CurrentTripProvider getProviderOverride(
    covariant CurrentTripProvider provider,
  ) {
    return call(
      provider.Tripid,
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
  String? get name => r'currentTripProvider';
}

/// See also [currentTrip].
class CurrentTripProvider extends AutoDisposeStreamProvider<CurrentTrip> {
  /// See also [currentTrip].
  CurrentTripProvider(
    String Tripid,
  ) : this._internal(
          (ref) => currentTrip(
            ref as CurrentTripRef,
            Tripid,
          ),
          from: currentTripProvider,
          name: r'currentTripProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentTripHash,
          dependencies: CurrentTripFamily._dependencies,
          allTransitiveDependencies:
              CurrentTripFamily._allTransitiveDependencies,
          Tripid: Tripid,
        );

  CurrentTripProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.Tripid,
  }) : super.internal();

  final String Tripid;

  @override
  Override overrideWith(
    Stream<CurrentTrip> Function(CurrentTripRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentTripProvider._internal(
        (ref) => create(ref as CurrentTripRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        Tripid: Tripid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<CurrentTrip> createElement() {
    return _CurrentTripProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentTripProvider && other.Tripid == Tripid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, Tripid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CurrentTripRef on AutoDisposeStreamProviderRef<CurrentTrip> {
  /// The parameter `Tripid` of this provider.
  String get Tripid;
}

class _CurrentTripProviderElement
    extends AutoDisposeStreamProviderElement<CurrentTrip> with CurrentTripRef {
  _CurrentTripProviderElement(super.provider);

  @override
  String get Tripid => (origin as CurrentTripProvider).Tripid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
