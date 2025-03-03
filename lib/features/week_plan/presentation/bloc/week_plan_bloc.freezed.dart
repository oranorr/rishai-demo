// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'week_plan_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WeekPlanEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)
        generate,
    required TResult Function() reset,
    required TResult Function() load,
    required TResult Function() clear,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult? Function()? reset,
    TResult? Function()? load,
    TResult? Function()? clear,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult Function()? reset,
    TResult Function()? load,
    TResult Function()? clear,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WeekPlanGenerate value) generate,
    required TResult Function(WeekPlanReset value) reset,
    required TResult Function(WeekPlanLoad value) load,
    required TResult Function(WeekPlanClear value) clear,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekPlanGenerate value)? generate,
    TResult? Function(WeekPlanReset value)? reset,
    TResult? Function(WeekPlanLoad value)? load,
    TResult? Function(WeekPlanClear value)? clear,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekPlanGenerate value)? generate,
    TResult Function(WeekPlanReset value)? reset,
    TResult Function(WeekPlanLoad value)? load,
    TResult Function(WeekPlanClear value)? clear,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeekPlanEventCopyWith<$Res> {
  factory $WeekPlanEventCopyWith(
          WeekPlanEvent value, $Res Function(WeekPlanEvent) then) =
      _$WeekPlanEventCopyWithImpl<$Res, WeekPlanEvent>;
}

/// @nodoc
class _$WeekPlanEventCopyWithImpl<$Res, $Val extends WeekPlanEvent>
    implements $WeekPlanEventCopyWith<$Res> {
  _$WeekPlanEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$WeekPlanGenerateImplCopyWith<$Res> {
  factory _$$WeekPlanGenerateImplCopyWith(_$WeekPlanGenerateImpl value,
          $Res Function(_$WeekPlanGenerateImpl) then) =
      __$$WeekPlanGenerateImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<String> dietary,
      List<String> cuisines,
      List<String> restrictions,
      int calorieTarget,
      MacrosBreakdown macros,
      bool hasTraining,
      bool hasSnack,
      List<ServingEntity> servings});
}

/// @nodoc
class __$$WeekPlanGenerateImplCopyWithImpl<$Res>
    extends _$WeekPlanEventCopyWithImpl<$Res, _$WeekPlanGenerateImpl>
    implements _$$WeekPlanGenerateImplCopyWith<$Res> {
  __$$WeekPlanGenerateImplCopyWithImpl(_$WeekPlanGenerateImpl _value,
      $Res Function(_$WeekPlanGenerateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dietary = null,
    Object? cuisines = null,
    Object? restrictions = null,
    Object? calorieTarget = null,
    Object? macros = null,
    Object? hasTraining = null,
    Object? hasSnack = null,
    Object? servings = null,
  }) {
    return _then(_$WeekPlanGenerateImpl(
      dietary: null == dietary
          ? _value._dietary
          : dietary // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cuisines: null == cuisines
          ? _value._cuisines
          : cuisines // ignore: cast_nullable_to_non_nullable
              as List<String>,
      restrictions: null == restrictions
          ? _value._restrictions
          : restrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      calorieTarget: null == calorieTarget
          ? _value.calorieTarget
          : calorieTarget // ignore: cast_nullable_to_non_nullable
              as int,
      macros: null == macros
          ? _value.macros
          : macros // ignore: cast_nullable_to_non_nullable
              as MacrosBreakdown,
      hasTraining: null == hasTraining
          ? _value.hasTraining
          : hasTraining // ignore: cast_nullable_to_non_nullable
              as bool,
      hasSnack: null == hasSnack
          ? _value.hasSnack
          : hasSnack // ignore: cast_nullable_to_non_nullable
              as bool,
      servings: null == servings
          ? _value._servings
          : servings // ignore: cast_nullable_to_non_nullable
              as List<ServingEntity>,
    ));
  }
}

/// @nodoc

class _$WeekPlanGenerateImpl implements WeekPlanGenerate {
  const _$WeekPlanGenerateImpl(
      {required final List<String> dietary,
      required final List<String> cuisines,
      required final List<String> restrictions,
      required this.calorieTarget,
      required this.macros,
      required this.hasTraining,
      required this.hasSnack,
      required final List<ServingEntity> servings})
      : _dietary = dietary,
        _cuisines = cuisines,
        _restrictions = restrictions,
        _servings = servings;

  final List<String> _dietary;
  @override
  List<String> get dietary {
    if (_dietary is EqualUnmodifiableListView) return _dietary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dietary);
  }

  final List<String> _cuisines;
  @override
  List<String> get cuisines {
    if (_cuisines is EqualUnmodifiableListView) return _cuisines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cuisines);
  }

  final List<String> _restrictions;
  @override
  List<String> get restrictions {
    if (_restrictions is EqualUnmodifiableListView) return _restrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_restrictions);
  }

  @override
  final int calorieTarget;
  @override
  final MacrosBreakdown macros;
  @override
  final bool hasTraining;
  @override
  final bool hasSnack;
  final List<ServingEntity> _servings;
  @override
  List<ServingEntity> get servings {
    if (_servings is EqualUnmodifiableListView) return _servings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_servings);
  }

  @override
  String toString() {
    return 'WeekPlanEvent.generate(dietary: $dietary, cuisines: $cuisines, restrictions: $restrictions, calorieTarget: $calorieTarget, macros: $macros, hasTraining: $hasTraining, hasSnack: $hasSnack, servings: $servings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeekPlanGenerateImpl &&
            const DeepCollectionEquality().equals(other._dietary, _dietary) &&
            const DeepCollectionEquality().equals(other._cuisines, _cuisines) &&
            const DeepCollectionEquality()
                .equals(other._restrictions, _restrictions) &&
            (identical(other.calorieTarget, calorieTarget) ||
                other.calorieTarget == calorieTarget) &&
            (identical(other.macros, macros) || other.macros == macros) &&
            (identical(other.hasTraining, hasTraining) ||
                other.hasTraining == hasTraining) &&
            (identical(other.hasSnack, hasSnack) ||
                other.hasSnack == hasSnack) &&
            const DeepCollectionEquality().equals(other._servings, _servings));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_dietary),
      const DeepCollectionEquality().hash(_cuisines),
      const DeepCollectionEquality().hash(_restrictions),
      calorieTarget,
      macros,
      hasTraining,
      hasSnack,
      const DeepCollectionEquality().hash(_servings));

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeekPlanGenerateImplCopyWith<_$WeekPlanGenerateImpl> get copyWith =>
      __$$WeekPlanGenerateImplCopyWithImpl<_$WeekPlanGenerateImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)
        generate,
    required TResult Function() reset,
    required TResult Function() load,
    required TResult Function() clear,
  }) {
    return generate(dietary, cuisines, restrictions, calorieTarget, macros,
        hasTraining, hasSnack, servings);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult? Function()? reset,
    TResult? Function()? load,
    TResult? Function()? clear,
  }) {
    return generate?.call(dietary, cuisines, restrictions, calorieTarget,
        macros, hasTraining, hasSnack, servings);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult Function()? reset,
    TResult Function()? load,
    TResult Function()? clear,
    required TResult orElse(),
  }) {
    if (generate != null) {
      return generate(dietary, cuisines, restrictions, calorieTarget, macros,
          hasTraining, hasSnack, servings);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WeekPlanGenerate value) generate,
    required TResult Function(WeekPlanReset value) reset,
    required TResult Function(WeekPlanLoad value) load,
    required TResult Function(WeekPlanClear value) clear,
  }) {
    return generate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekPlanGenerate value)? generate,
    TResult? Function(WeekPlanReset value)? reset,
    TResult? Function(WeekPlanLoad value)? load,
    TResult? Function(WeekPlanClear value)? clear,
  }) {
    return generate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekPlanGenerate value)? generate,
    TResult Function(WeekPlanReset value)? reset,
    TResult Function(WeekPlanLoad value)? load,
    TResult Function(WeekPlanClear value)? clear,
    required TResult orElse(),
  }) {
    if (generate != null) {
      return generate(this);
    }
    return orElse();
  }
}

abstract class WeekPlanGenerate implements WeekPlanEvent {
  const factory WeekPlanGenerate(
      {required final List<String> dietary,
      required final List<String> cuisines,
      required final List<String> restrictions,
      required final int calorieTarget,
      required final MacrosBreakdown macros,
      required final bool hasTraining,
      required final bool hasSnack,
      required final List<ServingEntity> servings}) = _$WeekPlanGenerateImpl;

  List<String> get dietary;
  List<String> get cuisines;
  List<String> get restrictions;
  int get calorieTarget;
  MacrosBreakdown get macros;
  bool get hasTraining;
  bool get hasSnack;
  List<ServingEntity> get servings;

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeekPlanGenerateImplCopyWith<_$WeekPlanGenerateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WeekPlanResetImplCopyWith<$Res> {
  factory _$$WeekPlanResetImplCopyWith(
          _$WeekPlanResetImpl value, $Res Function(_$WeekPlanResetImpl) then) =
      __$$WeekPlanResetImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WeekPlanResetImplCopyWithImpl<$Res>
    extends _$WeekPlanEventCopyWithImpl<$Res, _$WeekPlanResetImpl>
    implements _$$WeekPlanResetImplCopyWith<$Res> {
  __$$WeekPlanResetImplCopyWithImpl(
      _$WeekPlanResetImpl _value, $Res Function(_$WeekPlanResetImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WeekPlanResetImpl implements WeekPlanReset {
  const _$WeekPlanResetImpl();

  @override
  String toString() {
    return 'WeekPlanEvent.reset()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WeekPlanResetImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)
        generate,
    required TResult Function() reset,
    required TResult Function() load,
    required TResult Function() clear,
  }) {
    return reset();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult? Function()? reset,
    TResult? Function()? load,
    TResult? Function()? clear,
  }) {
    return reset?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult Function()? reset,
    TResult Function()? load,
    TResult Function()? clear,
    required TResult orElse(),
  }) {
    if (reset != null) {
      return reset();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WeekPlanGenerate value) generate,
    required TResult Function(WeekPlanReset value) reset,
    required TResult Function(WeekPlanLoad value) load,
    required TResult Function(WeekPlanClear value) clear,
  }) {
    return reset(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekPlanGenerate value)? generate,
    TResult? Function(WeekPlanReset value)? reset,
    TResult? Function(WeekPlanLoad value)? load,
    TResult? Function(WeekPlanClear value)? clear,
  }) {
    return reset?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekPlanGenerate value)? generate,
    TResult Function(WeekPlanReset value)? reset,
    TResult Function(WeekPlanLoad value)? load,
    TResult Function(WeekPlanClear value)? clear,
    required TResult orElse(),
  }) {
    if (reset != null) {
      return reset(this);
    }
    return orElse();
  }
}

abstract class WeekPlanReset implements WeekPlanEvent {
  const factory WeekPlanReset() = _$WeekPlanResetImpl;
}

/// @nodoc
abstract class _$$WeekPlanLoadImplCopyWith<$Res> {
  factory _$$WeekPlanLoadImplCopyWith(
          _$WeekPlanLoadImpl value, $Res Function(_$WeekPlanLoadImpl) then) =
      __$$WeekPlanLoadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WeekPlanLoadImplCopyWithImpl<$Res>
    extends _$WeekPlanEventCopyWithImpl<$Res, _$WeekPlanLoadImpl>
    implements _$$WeekPlanLoadImplCopyWith<$Res> {
  __$$WeekPlanLoadImplCopyWithImpl(
      _$WeekPlanLoadImpl _value, $Res Function(_$WeekPlanLoadImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WeekPlanLoadImpl implements WeekPlanLoad {
  const _$WeekPlanLoadImpl();

  @override
  String toString() {
    return 'WeekPlanEvent.load()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WeekPlanLoadImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)
        generate,
    required TResult Function() reset,
    required TResult Function() load,
    required TResult Function() clear,
  }) {
    return load();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult? Function()? reset,
    TResult? Function()? load,
    TResult? Function()? clear,
  }) {
    return load?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult Function()? reset,
    TResult Function()? load,
    TResult Function()? clear,
    required TResult orElse(),
  }) {
    if (load != null) {
      return load();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WeekPlanGenerate value) generate,
    required TResult Function(WeekPlanReset value) reset,
    required TResult Function(WeekPlanLoad value) load,
    required TResult Function(WeekPlanClear value) clear,
  }) {
    return load(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekPlanGenerate value)? generate,
    TResult? Function(WeekPlanReset value)? reset,
    TResult? Function(WeekPlanLoad value)? load,
    TResult? Function(WeekPlanClear value)? clear,
  }) {
    return load?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekPlanGenerate value)? generate,
    TResult Function(WeekPlanReset value)? reset,
    TResult Function(WeekPlanLoad value)? load,
    TResult Function(WeekPlanClear value)? clear,
    required TResult orElse(),
  }) {
    if (load != null) {
      return load(this);
    }
    return orElse();
  }
}

abstract class WeekPlanLoad implements WeekPlanEvent {
  const factory WeekPlanLoad() = _$WeekPlanLoadImpl;
}

/// @nodoc
abstract class _$$WeekPlanClearImplCopyWith<$Res> {
  factory _$$WeekPlanClearImplCopyWith(
          _$WeekPlanClearImpl value, $Res Function(_$WeekPlanClearImpl) then) =
      __$$WeekPlanClearImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WeekPlanClearImplCopyWithImpl<$Res>
    extends _$WeekPlanEventCopyWithImpl<$Res, _$WeekPlanClearImpl>
    implements _$$WeekPlanClearImplCopyWith<$Res> {
  __$$WeekPlanClearImplCopyWithImpl(
      _$WeekPlanClearImpl _value, $Res Function(_$WeekPlanClearImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeekPlanEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WeekPlanClearImpl implements WeekPlanClear {
  const _$WeekPlanClearImpl();

  @override
  String toString() {
    return 'WeekPlanEvent.clear()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WeekPlanClearImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)
        generate,
    required TResult Function() reset,
    required TResult Function() load,
    required TResult Function() clear,
  }) {
    return clear();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult? Function()? reset,
    TResult? Function()? load,
    TResult? Function()? clear,
  }) {
    return clear?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            List<String> dietary,
            List<String> cuisines,
            List<String> restrictions,
            int calorieTarget,
            MacrosBreakdown macros,
            bool hasTraining,
            bool hasSnack,
            List<ServingEntity> servings)?
        generate,
    TResult Function()? reset,
    TResult Function()? load,
    TResult Function()? clear,
    required TResult orElse(),
  }) {
    if (clear != null) {
      return clear();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WeekPlanGenerate value) generate,
    required TResult Function(WeekPlanReset value) reset,
    required TResult Function(WeekPlanLoad value) load,
    required TResult Function(WeekPlanClear value) clear,
  }) {
    return clear(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekPlanGenerate value)? generate,
    TResult? Function(WeekPlanReset value)? reset,
    TResult? Function(WeekPlanLoad value)? load,
    TResult? Function(WeekPlanClear value)? clear,
  }) {
    return clear?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekPlanGenerate value)? generate,
    TResult Function(WeekPlanReset value)? reset,
    TResult Function(WeekPlanLoad value)? load,
    TResult Function(WeekPlanClear value)? clear,
    required TResult orElse(),
  }) {
    if (clear != null) {
      return clear(this);
    }
    return orElse();
  }
}

abstract class WeekPlanClear implements WeekPlanEvent {
  const factory WeekPlanClear() = _$WeekPlanClearImpl;
}

/// @nodoc
mixin _$WeekPlanState {
  List<WeekPlanEntity?> get weekPlans => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of WeekPlanState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeekPlanStateCopyWith<WeekPlanState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeekPlanStateCopyWith<$Res> {
  factory $WeekPlanStateCopyWith(
          WeekPlanState value, $Res Function(WeekPlanState) then) =
      _$WeekPlanStateCopyWithImpl<$Res, WeekPlanState>;
  @useResult
  $Res call({List<WeekPlanEntity?> weekPlans, bool isLoading, String? error});
}

/// @nodoc
class _$WeekPlanStateCopyWithImpl<$Res, $Val extends WeekPlanState>
    implements $WeekPlanStateCopyWith<$Res> {
  _$WeekPlanStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeekPlanState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekPlans = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      weekPlans: null == weekPlans
          ? _value.weekPlans
          : weekPlans // ignore: cast_nullable_to_non_nullable
              as List<WeekPlanEntity?>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeekPlanStateImplCopyWith<$Res>
    implements $WeekPlanStateCopyWith<$Res> {
  factory _$$WeekPlanStateImplCopyWith(
          _$WeekPlanStateImpl value, $Res Function(_$WeekPlanStateImpl) then) =
      __$$WeekPlanStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<WeekPlanEntity?> weekPlans, bool isLoading, String? error});
}

/// @nodoc
class __$$WeekPlanStateImplCopyWithImpl<$Res>
    extends _$WeekPlanStateCopyWithImpl<$Res, _$WeekPlanStateImpl>
    implements _$$WeekPlanStateImplCopyWith<$Res> {
  __$$WeekPlanStateImplCopyWithImpl(
      _$WeekPlanStateImpl _value, $Res Function(_$WeekPlanStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeekPlanState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekPlans = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$WeekPlanStateImpl(
      weekPlans: null == weekPlans
          ? _value._weekPlans
          : weekPlans // ignore: cast_nullable_to_non_nullable
              as List<WeekPlanEntity?>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$WeekPlanStateImpl implements _WeekPlanState {
  const _$WeekPlanStateImpl(
      {required final List<WeekPlanEntity?> weekPlans,
      this.isLoading = false,
      this.error})
      : _weekPlans = weekPlans;

  final List<WeekPlanEntity?> _weekPlans;
  @override
  List<WeekPlanEntity?> get weekPlans {
    if (_weekPlans is EqualUnmodifiableListView) return _weekPlans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weekPlans);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'WeekPlanState(weekPlans: $weekPlans, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeekPlanStateImpl &&
            const DeepCollectionEquality()
                .equals(other._weekPlans, _weekPlans) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_weekPlans), isLoading, error);

  /// Create a copy of WeekPlanState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeekPlanStateImplCopyWith<_$WeekPlanStateImpl> get copyWith =>
      __$$WeekPlanStateImplCopyWithImpl<_$WeekPlanStateImpl>(this, _$identity);
}

abstract class _WeekPlanState implements WeekPlanState {
  const factory _WeekPlanState(
      {required final List<WeekPlanEntity?> weekPlans,
      final bool isLoading,
      final String? error}) = _$WeekPlanStateImpl;

  @override
  List<WeekPlanEntity?> get weekPlans;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of WeekPlanState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeekPlanStateImplCopyWith<_$WeekPlanStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
