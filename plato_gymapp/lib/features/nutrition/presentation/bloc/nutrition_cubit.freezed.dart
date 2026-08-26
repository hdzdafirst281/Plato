// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NutritionState {
  DailyNutrition get nutritionToday => throw _privateConstructorUsedError;
  List<FoodResult> get recentFoods => throw _privateConstructorUsedError;
  List<FoodResult> get foodDatabase => throw _privateConstructorUsedError;
  List<DailyNutrition> get nutritionHistory =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NutritionStateCopyWith<NutritionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionStateCopyWith<$Res> {
  factory $NutritionStateCopyWith(
          NutritionState value, $Res Function(NutritionState) then) =
      _$NutritionStateCopyWithImpl<$Res, NutritionState>;
  @useResult
  $Res call(
      {DailyNutrition nutritionToday,
      List<FoodResult> recentFoods,
      List<FoodResult> foodDatabase,
      List<DailyNutrition> nutritionHistory});

  $DailyNutritionCopyWith<$Res> get nutritionToday;
}

/// @nodoc
class _$NutritionStateCopyWithImpl<$Res, $Val extends NutritionState>
    implements $NutritionStateCopyWith<$Res> {
  _$NutritionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nutritionToday = null,
    Object? recentFoods = null,
    Object? foodDatabase = null,
    Object? nutritionHistory = null,
  }) {
    return _then(_value.copyWith(
      nutritionToday: null == nutritionToday
          ? _value.nutritionToday
          : nutritionToday // ignore: cast_nullable_to_non_nullable
              as DailyNutrition,
      recentFoods: null == recentFoods
          ? _value.recentFoods
          : recentFoods // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      foodDatabase: null == foodDatabase
          ? _value.foodDatabase
          : foodDatabase // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      nutritionHistory: null == nutritionHistory
          ? _value.nutritionHistory
          : nutritionHistory // ignore: cast_nullable_to_non_nullable
              as List<DailyNutrition>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DailyNutritionCopyWith<$Res> get nutritionToday {
    return $DailyNutritionCopyWith<$Res>(_value.nutritionToday, (value) {
      return _then(_value.copyWith(nutritionToday: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NutritionStateImplCopyWith<$Res>
    implements $NutritionStateCopyWith<$Res> {
  factory _$$NutritionStateImplCopyWith(_$NutritionStateImpl value,
          $Res Function(_$NutritionStateImpl) then) =
      __$$NutritionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DailyNutrition nutritionToday,
      List<FoodResult> recentFoods,
      List<FoodResult> foodDatabase,
      List<DailyNutrition> nutritionHistory});

  @override
  $DailyNutritionCopyWith<$Res> get nutritionToday;
}

/// @nodoc
class __$$NutritionStateImplCopyWithImpl<$Res>
    extends _$NutritionStateCopyWithImpl<$Res, _$NutritionStateImpl>
    implements _$$NutritionStateImplCopyWith<$Res> {
  __$$NutritionStateImplCopyWithImpl(
      _$NutritionStateImpl _value, $Res Function(_$NutritionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nutritionToday = null,
    Object? recentFoods = null,
    Object? foodDatabase = null,
    Object? nutritionHistory = null,
  }) {
    return _then(_$NutritionStateImpl(
      nutritionToday: null == nutritionToday
          ? _value.nutritionToday
          : nutritionToday // ignore: cast_nullable_to_non_nullable
              as DailyNutrition,
      recentFoods: null == recentFoods
          ? _value._recentFoods
          : recentFoods // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      foodDatabase: null == foodDatabase
          ? _value._foodDatabase
          : foodDatabase // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      nutritionHistory: null == nutritionHistory
          ? _value._nutritionHistory
          : nutritionHistory // ignore: cast_nullable_to_non_nullable
              as List<DailyNutrition>,
    ));
  }
}

/// @nodoc

class _$NutritionStateImpl
    with DiagnosticableTreeMixin
    implements _NutritionState {
  const _$NutritionStateImpl(
      {this.nutritionToday = const DailyNutrition(),
      final List<FoodResult> recentFoods = const [],
      final List<FoodResult> foodDatabase = const [],
      final List<DailyNutrition> nutritionHistory = const []})
      : _recentFoods = recentFoods,
        _foodDatabase = foodDatabase,
        _nutritionHistory = nutritionHistory;

  @override
  @JsonKey()
  final DailyNutrition nutritionToday;
  final List<FoodResult> _recentFoods;
  @override
  @JsonKey()
  List<FoodResult> get recentFoods {
    if (_recentFoods is EqualUnmodifiableListView) return _recentFoods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentFoods);
  }

  final List<FoodResult> _foodDatabase;
  @override
  @JsonKey()
  List<FoodResult> get foodDatabase {
    if (_foodDatabase is EqualUnmodifiableListView) return _foodDatabase;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foodDatabase);
  }

  final List<DailyNutrition> _nutritionHistory;
  @override
  @JsonKey()
  List<DailyNutrition> get nutritionHistory {
    if (_nutritionHistory is EqualUnmodifiableListView)
      return _nutritionHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nutritionHistory);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NutritionState(nutritionToday: $nutritionToday, recentFoods: $recentFoods, foodDatabase: $foodDatabase, nutritionHistory: $nutritionHistory)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NutritionState'))
      ..add(DiagnosticsProperty('nutritionToday', nutritionToday))
      ..add(DiagnosticsProperty('recentFoods', recentFoods))
      ..add(DiagnosticsProperty('foodDatabase', foodDatabase))
      ..add(DiagnosticsProperty('nutritionHistory', nutritionHistory));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionStateImpl &&
            (identical(other.nutritionToday, nutritionToday) ||
                other.nutritionToday == nutritionToday) &&
            const DeepCollectionEquality()
                .equals(other._recentFoods, _recentFoods) &&
            const DeepCollectionEquality()
                .equals(other._foodDatabase, _foodDatabase) &&
            const DeepCollectionEquality()
                .equals(other._nutritionHistory, _nutritionHistory));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      nutritionToday,
      const DeepCollectionEquality().hash(_recentFoods),
      const DeepCollectionEquality().hash(_foodDatabase),
      const DeepCollectionEquality().hash(_nutritionHistory));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionStateImplCopyWith<_$NutritionStateImpl> get copyWith =>
      __$$NutritionStateImplCopyWithImpl<_$NutritionStateImpl>(
          this, _$identity);
}

abstract class _NutritionState implements NutritionState {
  const factory _NutritionState(
      {final DailyNutrition nutritionToday,
      final List<FoodResult> recentFoods,
      final List<FoodResult> foodDatabase,
      final List<DailyNutrition> nutritionHistory}) = _$NutritionStateImpl;

  @override
  DailyNutrition get nutritionToday;
  @override
  List<FoodResult> get recentFoods;
  @override
  List<FoodResult> get foodDatabase;
  @override
  List<DailyNutrition> get nutritionHistory;
  @override
  @JsonKey(ignore: true)
  _$$NutritionStateImplCopyWith<_$NutritionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
