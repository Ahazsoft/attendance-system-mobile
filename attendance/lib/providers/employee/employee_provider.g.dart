// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmployeeNotifier)
final employeeProvider = EmployeeNotifierFamily._();

final class EmployeeNotifierProvider
    extends $AsyncNotifierProvider<EmployeeNotifier, User> {
  EmployeeNotifierProvider._({
    required EmployeeNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeNotifierHash();

  @override
  String toString() {
    return r'employeeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EmployeeNotifier create() => EmployeeNotifier();

  @override
  bool operator ==(Object other) {
    return other is EmployeeNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeNotifierHash() => r'291f83697344ef84301680efdb74447270630323';

final class EmployeeNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EmployeeNotifier,
          AsyncValue<User>,
          User,
          FutureOr<User>,
          String
        > {
  EmployeeNotifierFamily._()
    : super(
        retry: null,
        name: r'employeeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  EmployeeNotifierProvider call(String id) =>
      EmployeeNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'employeeProvider';
}

abstract class _$EmployeeNotifier extends $AsyncNotifier<User> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<User> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<User>, User>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User>, User>,
              AsyncValue<User>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
