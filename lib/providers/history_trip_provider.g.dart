// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tripsNotifierHash() => r'82810db813fc86ffcff3a72765e4bcf71195f01c';

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

abstract class _$TripsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Trips>> {
  late final String passengerId;

  FutureOr<List<Trips>> build(
    String passengerId,
  );
}

/// See also [TripsNotifier].
@ProviderFor(TripsNotifier)
const tripsNotifierProvider = TripsNotifierFamily();

/// See also [TripsNotifier].
class TripsNotifierFamily extends Family<AsyncValue<List<Trips>>> {
  /// See also [TripsNotifier].
  const TripsNotifierFamily();

  /// See also [TripsNotifier].
  TripsNotifierProvider call(
    String passengerId,
  ) {
    return TripsNotifierProvider(
      passengerId,
    );
  }

  @override
  TripsNotifierProvider getProviderOverride(
    covariant TripsNotifierProvider provider,
  ) {
    return call(
      provider.passengerId,
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
  String? get name => r'tripsNotifierProvider';
}

/// See also [TripsNotifier].
class TripsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TripsNotifier, List<Trips>> {
  /// See also [TripsNotifier].
  TripsNotifierProvider(
    String passengerId,
  ) : this._internal(
          () => TripsNotifier()..passengerId = passengerId,
          from: tripsNotifierProvider,
          name: r'tripsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripsNotifierHash,
          dependencies: TripsNotifierFamily._dependencies,
          allTransitiveDependencies:
              TripsNotifierFamily._allTransitiveDependencies,
          passengerId: passengerId,
        );

  TripsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.passengerId,
  }) : super.internal();

  final String passengerId;

  @override
  FutureOr<List<Trips>> runNotifierBuild(
    covariant TripsNotifier notifier,
  ) {
    return notifier.build(
      passengerId,
    );
  }

  @override
  Override overrideWith(TripsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TripsNotifierProvider._internal(
        () => create()..passengerId = passengerId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        passengerId: passengerId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TripsNotifier, List<Trips>>
      createElement() {
    return _TripsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripsNotifierProvider && other.passengerId == passengerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, passengerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TripsNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Trips>> {
  /// The parameter `passengerId` of this provider.
  String get passengerId;
}

class _TripsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TripsNotifier, List<Trips>>
    with TripsNotifierRef {
  _TripsNotifierProviderElement(super.provider);

  @override
  String get passengerId => (origin as TripsNotifierProvider).passengerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
