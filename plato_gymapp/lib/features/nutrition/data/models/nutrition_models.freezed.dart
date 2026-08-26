// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Macros _$MacrosFromJson(Map<String, dynamic> json) {
  return _Macros.fromJson(json);
}

/// @nodoc
mixin _$Macros {
  @JsonKey(name: 'cal')
  int get calories => throw _privateConstructorUsedError;
  @JsonKey(name: 'p')
  int get protein => throw _privateConstructorUsedError;
  @JsonKey(name: 'c')
  int get carbs => throw _privateConstructorUsedError;
  @JsonKey(name: 'f')
  int get fat => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MacrosCopyWith<Macros> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MacrosCopyWith<$Res> {
  factory $MacrosCopyWith(Macros value, $Res Function(Macros) then) =
      _$MacrosCopyWithImpl<$Res, Macros>;
  @useResult
  $Res call(
      {@JsonKey(name: 'cal') int calories,
      @JsonKey(name: 'p') int protein,
      @JsonKey(name: 'c') int carbs,
      @JsonKey(name: 'f') int fat});
}

/// @nodoc
class _$MacrosCopyWithImpl<$Res, $Val extends Macros>
    implements $MacrosCopyWith<$Res> {
  _$MacrosCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_value.copyWith(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as int,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as int,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MacrosImplCopyWith<$Res> implements $MacrosCopyWith<$Res> {
  factory _$$MacrosImplCopyWith(
          _$MacrosImpl value, $Res Function(_$MacrosImpl) then) =
      __$$MacrosImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'cal') int calories,
      @JsonKey(name: 'p') int protein,
      @JsonKey(name: 'c') int carbs,
      @JsonKey(name: 'f') int fat});
}

/// @nodoc
class __$$MacrosImplCopyWithImpl<$Res>
    extends _$MacrosCopyWithImpl<$Res, _$MacrosImpl>
    implements _$$MacrosImplCopyWith<$Res> {
  __$$MacrosImplCopyWithImpl(
      _$MacrosImpl _value, $Res Function(_$MacrosImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_$MacrosImpl(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as int,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as int,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MacrosImpl implements _Macros {
  const _$MacrosImpl(
      {@JsonKey(name: 'cal') this.calories = 2000,
      @JsonKey(name: 'p') this.protein = 150,
      @JsonKey(name: 'c') this.carbs = 200,
      @JsonKey(name: 'f') this.fat = 60});

  factory _$MacrosImpl.fromJson(Map<String, dynamic> json) =>
      _$$MacrosImplFromJson(json);

  @override
  @JsonKey(name: 'cal')
  final int calories;
  @override
  @JsonKey(name: 'p')
  final int protein;
  @override
  @JsonKey(name: 'c')
  final int carbs;
  @override
  @JsonKey(name: 'f')
  final int fat;

  @override
  String toString() {
    return 'Macros(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MacrosImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, calories, protein, carbs, fat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MacrosImplCopyWith<_$MacrosImpl> get copyWith =>
      __$$MacrosImplCopyWithImpl<_$MacrosImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MacrosImplToJson(
      this,
    );
  }
}

abstract class _Macros implements Macros {
  const factory _Macros(
      {@JsonKey(name: 'cal') final int calories,
      @JsonKey(name: 'p') final int protein,
      @JsonKey(name: 'c') final int carbs,
      @JsonKey(name: 'f') final int fat}) = _$MacrosImpl;

  factory _Macros.fromJson(Map<String, dynamic> json) = _$MacrosImpl.fromJson;

  @override
  @JsonKey(name: 'cal')
  int get calories;
  @override
  @JsonKey(name: 'p')
  int get protein;
  @override
  @JsonKey(name: 'c')
  int get carbs;
  @override
  @JsonKey(name: 'f')
  int get fat;
  @override
  @JsonKey(ignore: true)
  _$$MacrosImplCopyWith<_$MacrosImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DailyNutrition _$DailyNutritionFromJson(Map<String, dynamic> json) {
  return _DailyNutrition.fromJson(json);
}

/// @nodoc
mixin _$DailyNutrition {
  String get formattedDateString => throw _privateConstructorUsedError;
  List<FoodResult> get breakfastMealsList => throw _privateConstructorUsedError;
  List<FoodResult> get lunchMealsList => throw _privateConstructorUsedError;
  List<FoodResult> get dinnerMealsList => throw _privateConstructorUsedError;
  List<FoodResult> get snackMealsList => throw _privateConstructorUsedError;
  double get waterConsumedLiters => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DailyNutritionCopyWith<DailyNutrition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyNutritionCopyWith<$Res> {
  factory $DailyNutritionCopyWith(
          DailyNutrition value, $Res Function(DailyNutrition) then) =
      _$DailyNutritionCopyWithImpl<$Res, DailyNutrition>;
  @useResult
  $Res call(
      {String formattedDateString,
      List<FoodResult> breakfastMealsList,
      List<FoodResult> lunchMealsList,
      List<FoodResult> dinnerMealsList,
      List<FoodResult> snackMealsList,
      double waterConsumedLiters});
}

/// @nodoc
class _$DailyNutritionCopyWithImpl<$Res, $Val extends DailyNutrition>
    implements $DailyNutritionCopyWith<$Res> {
  _$DailyNutritionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formattedDateString = null,
    Object? breakfastMealsList = null,
    Object? lunchMealsList = null,
    Object? dinnerMealsList = null,
    Object? snackMealsList = null,
    Object? waterConsumedLiters = null,
  }) {
    return _then(_value.copyWith(
      formattedDateString: null == formattedDateString
          ? _value.formattedDateString
          : formattedDateString // ignore: cast_nullable_to_non_nullable
              as String,
      breakfastMealsList: null == breakfastMealsList
          ? _value.breakfastMealsList
          : breakfastMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      lunchMealsList: null == lunchMealsList
          ? _value.lunchMealsList
          : lunchMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      dinnerMealsList: null == dinnerMealsList
          ? _value.dinnerMealsList
          : dinnerMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      snackMealsList: null == snackMealsList
          ? _value.snackMealsList
          : snackMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      waterConsumedLiters: null == waterConsumedLiters
          ? _value.waterConsumedLiters
          : waterConsumedLiters // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyNutritionImplCopyWith<$Res>
    implements $DailyNutritionCopyWith<$Res> {
  factory _$$DailyNutritionImplCopyWith(_$DailyNutritionImpl value,
          $Res Function(_$DailyNutritionImpl) then) =
      __$$DailyNutritionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String formattedDateString,
      List<FoodResult> breakfastMealsList,
      List<FoodResult> lunchMealsList,
      List<FoodResult> dinnerMealsList,
      List<FoodResult> snackMealsList,
      double waterConsumedLiters});
}

/// @nodoc
class __$$DailyNutritionImplCopyWithImpl<$Res>
    extends _$DailyNutritionCopyWithImpl<$Res, _$DailyNutritionImpl>
    implements _$$DailyNutritionImplCopyWith<$Res> {
  __$$DailyNutritionImplCopyWithImpl(
      _$DailyNutritionImpl _value, $Res Function(_$DailyNutritionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formattedDateString = null,
    Object? breakfastMealsList = null,
    Object? lunchMealsList = null,
    Object? dinnerMealsList = null,
    Object? snackMealsList = null,
    Object? waterConsumedLiters = null,
  }) {
    return _then(_$DailyNutritionImpl(
      formattedDateString: null == formattedDateString
          ? _value.formattedDateString
          : formattedDateString // ignore: cast_nullable_to_non_nullable
              as String,
      breakfastMealsList: null == breakfastMealsList
          ? _value._breakfastMealsList
          : breakfastMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      lunchMealsList: null == lunchMealsList
          ? _value._lunchMealsList
          : lunchMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      dinnerMealsList: null == dinnerMealsList
          ? _value._dinnerMealsList
          : dinnerMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      snackMealsList: null == snackMealsList
          ? _value._snackMealsList
          : snackMealsList // ignore: cast_nullable_to_non_nullable
              as List<FoodResult>,
      waterConsumedLiters: null == waterConsumedLiters
          ? _value.waterConsumedLiters
          : waterConsumedLiters // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyNutritionImpl extends _DailyNutrition {
  const _$DailyNutritionImpl(
      {this.formattedDateString = "",
      final List<FoodResult> breakfastMealsList = const [],
      final List<FoodResult> lunchMealsList = const [],
      final List<FoodResult> dinnerMealsList = const [],
      final List<FoodResult> snackMealsList = const [],
      this.waterConsumedLiters = 0.0})
      : _breakfastMealsList = breakfastMealsList,
        _lunchMealsList = lunchMealsList,
        _dinnerMealsList = dinnerMealsList,
        _snackMealsList = snackMealsList,
        super._();

  factory _$DailyNutritionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyNutritionImplFromJson(json);

  @override
  @JsonKey()
  final String formattedDateString;
  final List<FoodResult> _breakfastMealsList;
  @override
  @JsonKey()
  List<FoodResult> get breakfastMealsList {
    if (_breakfastMealsList is EqualUnmodifiableListView)
      return _breakfastMealsList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_breakfastMealsList);
  }

  final List<FoodResult> _lunchMealsList;
  @override
  @JsonKey()
  List<FoodResult> get lunchMealsList {
    if (_lunchMealsList is EqualUnmodifiableListView) return _lunchMealsList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lunchMealsList);
  }

  final List<FoodResult> _dinnerMealsList;
  @override
  @JsonKey()
  List<FoodResult> get dinnerMealsList {
    if (_dinnerMealsList is EqualUnmodifiableListView) return _dinnerMealsList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dinnerMealsList);
  }

  final List<FoodResult> _snackMealsList;
  @override
  @JsonKey()
  List<FoodResult> get snackMealsList {
    if (_snackMealsList is EqualUnmodifiableListView) return _snackMealsList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_snackMealsList);
  }

  @override
  @JsonKey()
  final double waterConsumedLiters;

  @override
  String toString() {
    return 'DailyNutrition(formattedDateString: $formattedDateString, breakfastMealsList: $breakfastMealsList, lunchMealsList: $lunchMealsList, dinnerMealsList: $dinnerMealsList, snackMealsList: $snackMealsList, waterConsumedLiters: $waterConsumedLiters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyNutritionImpl &&
            (identical(other.formattedDateString, formattedDateString) ||
                other.formattedDateString == formattedDateString) &&
            const DeepCollectionEquality()
                .equals(other._breakfastMealsList, _breakfastMealsList) &&
            const DeepCollectionEquality()
                .equals(other._lunchMealsList, _lunchMealsList) &&
            const DeepCollectionEquality()
                .equals(other._dinnerMealsList, _dinnerMealsList) &&
            const DeepCollectionEquality()
                .equals(other._snackMealsList, _snackMealsList) &&
            (identical(other.waterConsumedLiters, waterConsumedLiters) ||
                other.waterConsumedLiters == waterConsumedLiters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      formattedDateString,
      const DeepCollectionEquality().hash(_breakfastMealsList),
      const DeepCollectionEquality().hash(_lunchMealsList),
      const DeepCollectionEquality().hash(_dinnerMealsList),
      const DeepCollectionEquality().hash(_snackMealsList),
      waterConsumedLiters);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyNutritionImplCopyWith<_$DailyNutritionImpl> get copyWith =>
      __$$DailyNutritionImplCopyWithImpl<_$DailyNutritionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyNutritionImplToJson(
      this,
    );
  }
}

abstract class _DailyNutrition extends DailyNutrition {
  const factory _DailyNutrition(
      {final String formattedDateString,
      final List<FoodResult> breakfastMealsList,
      final List<FoodResult> lunchMealsList,
      final List<FoodResult> dinnerMealsList,
      final List<FoodResult> snackMealsList,
      final double waterConsumedLiters}) = _$DailyNutritionImpl;
  const _DailyNutrition._() : super._();

  factory _DailyNutrition.fromJson(Map<String, dynamic> json) =
      _$DailyNutritionImpl.fromJson;

  @override
  String get formattedDateString;
  @override
  List<FoodResult> get breakfastMealsList;
  @override
  List<FoodResult> get lunchMealsList;
  @override
  List<FoodResult> get dinnerMealsList;
  @override
  List<FoodResult> get snackMealsList;
  @override
  double get waterConsumedLiters;
  @override
  @JsonKey(ignore: true)
  _$$DailyNutritionImplCopyWith<_$DailyNutritionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
