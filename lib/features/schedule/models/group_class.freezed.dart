// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupClass {

 String get id; String get title; DateTime get startTime; DateTime get endTime; String get coachId; String get coachName; int get maxCapacity; List<String> get enrolledChildIds; String get category; String get lane;
/// Create a copy of GroupClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupClassCopyWith<GroupClass> get copyWith => _$GroupClassCopyWithImpl<GroupClass>(this as GroupClass, _$identity);

  /// Serializes this GroupClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupClass&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.coachId, coachId) || other.coachId == coachId)&&(identical(other.coachName, coachName) || other.coachName == coachName)&&(identical(other.maxCapacity, maxCapacity) || other.maxCapacity == maxCapacity)&&const DeepCollectionEquality().equals(other.enrolledChildIds, enrolledChildIds)&&(identical(other.category, category) || other.category == category)&&(identical(other.lane, lane) || other.lane == lane));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,startTime,endTime,coachId,coachName,maxCapacity,const DeepCollectionEquality().hash(enrolledChildIds),category,lane);

@override
String toString() {
  return 'GroupClass(id: $id, title: $title, startTime: $startTime, endTime: $endTime, coachId: $coachId, coachName: $coachName, maxCapacity: $maxCapacity, enrolledChildIds: $enrolledChildIds, category: $category, lane: $lane)';
}


}

/// @nodoc
abstract mixin class $GroupClassCopyWith<$Res>  {
  factory $GroupClassCopyWith(GroupClass value, $Res Function(GroupClass) _then) = _$GroupClassCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime startTime, DateTime endTime, String coachId, String coachName, int maxCapacity, List<String> enrolledChildIds, String category, String lane
});




}
/// @nodoc
class _$GroupClassCopyWithImpl<$Res>
    implements $GroupClassCopyWith<$Res> {
  _$GroupClassCopyWithImpl(this._self, this._then);

  final GroupClass _self;
  final $Res Function(GroupClass) _then;

/// Create a copy of GroupClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? startTime = null,Object? endTime = null,Object? coachId = null,Object? coachName = null,Object? maxCapacity = null,Object? enrolledChildIds = null,Object? category = null,Object? lane = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,coachId: null == coachId ? _self.coachId : coachId // ignore: cast_nullable_to_non_nullable
as String,coachName: null == coachName ? _self.coachName : coachName // ignore: cast_nullable_to_non_nullable
as String,maxCapacity: null == maxCapacity ? _self.maxCapacity : maxCapacity // ignore: cast_nullable_to_non_nullable
as int,enrolledChildIds: null == enrolledChildIds ? _self.enrolledChildIds : enrolledChildIds // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,lane: null == lane ? _self.lane : lane // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupClass].
extension GroupClassPatterns on GroupClass {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupClass() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupClass value)  $default,){
final _that = this;
switch (_that) {
case _GroupClass():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupClass value)?  $default,){
final _that = this;
switch (_that) {
case _GroupClass() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startTime,  DateTime endTime,  String coachId,  String coachName,  int maxCapacity,  List<String> enrolledChildIds,  String category,  String lane)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupClass() when $default != null:
return $default(_that.id,_that.title,_that.startTime,_that.endTime,_that.coachId,_that.coachName,_that.maxCapacity,_that.enrolledChildIds,_that.category,_that.lane);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startTime,  DateTime endTime,  String coachId,  String coachName,  int maxCapacity,  List<String> enrolledChildIds,  String category,  String lane)  $default,) {final _that = this;
switch (_that) {
case _GroupClass():
return $default(_that.id,_that.title,_that.startTime,_that.endTime,_that.coachId,_that.coachName,_that.maxCapacity,_that.enrolledChildIds,_that.category,_that.lane);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime startTime,  DateTime endTime,  String coachId,  String coachName,  int maxCapacity,  List<String> enrolledChildIds,  String category,  String lane)?  $default,) {final _that = this;
switch (_that) {
case _GroupClass() when $default != null:
return $default(_that.id,_that.title,_that.startTime,_that.endTime,_that.coachId,_that.coachName,_that.maxCapacity,_that.enrolledChildIds,_that.category,_that.lane);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupClass implements GroupClass {
  const _GroupClass({required this.id, required this.title, required this.startTime, required this.endTime, required this.coachId, required this.coachName, required this.maxCapacity, final  List<String> enrolledChildIds = const [], required this.category, this.lane = ''}): _enrolledChildIds = enrolledChildIds;
  factory _GroupClass.fromJson(Map<String, dynamic> json) => _$GroupClassFromJson(json);

@override final  String id;
@override final  String title;
@override final  DateTime startTime;
@override final  DateTime endTime;
@override final  String coachId;
@override final  String coachName;
@override final  int maxCapacity;
 final  List<String> _enrolledChildIds;
@override@JsonKey() List<String> get enrolledChildIds {
  if (_enrolledChildIds is EqualUnmodifiableListView) return _enrolledChildIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrolledChildIds);
}

@override final  String category;
@override@JsonKey() final  String lane;

/// Create a copy of GroupClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupClassCopyWith<_GroupClass> get copyWith => __$GroupClassCopyWithImpl<_GroupClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupClassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupClass&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.coachId, coachId) || other.coachId == coachId)&&(identical(other.coachName, coachName) || other.coachName == coachName)&&(identical(other.maxCapacity, maxCapacity) || other.maxCapacity == maxCapacity)&&const DeepCollectionEquality().equals(other._enrolledChildIds, _enrolledChildIds)&&(identical(other.category, category) || other.category == category)&&(identical(other.lane, lane) || other.lane == lane));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,startTime,endTime,coachId,coachName,maxCapacity,const DeepCollectionEquality().hash(_enrolledChildIds),category,lane);

@override
String toString() {
  return 'GroupClass(id: $id, title: $title, startTime: $startTime, endTime: $endTime, coachId: $coachId, coachName: $coachName, maxCapacity: $maxCapacity, enrolledChildIds: $enrolledChildIds, category: $category, lane: $lane)';
}


}

/// @nodoc
abstract mixin class _$GroupClassCopyWith<$Res> implements $GroupClassCopyWith<$Res> {
  factory _$GroupClassCopyWith(_GroupClass value, $Res Function(_GroupClass) _then) = __$GroupClassCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime startTime, DateTime endTime, String coachId, String coachName, int maxCapacity, List<String> enrolledChildIds, String category, String lane
});




}
/// @nodoc
class __$GroupClassCopyWithImpl<$Res>
    implements _$GroupClassCopyWith<$Res> {
  __$GroupClassCopyWithImpl(this._self, this._then);

  final _GroupClass _self;
  final $Res Function(_GroupClass) _then;

/// Create a copy of GroupClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? startTime = null,Object? endTime = null,Object? coachId = null,Object? coachName = null,Object? maxCapacity = null,Object? enrolledChildIds = null,Object? category = null,Object? lane = null,}) {
  return _then(_GroupClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,coachId: null == coachId ? _self.coachId : coachId // ignore: cast_nullable_to_non_nullable
as String,coachName: null == coachName ? _self.coachName : coachName // ignore: cast_nullable_to_non_nullable
as String,maxCapacity: null == maxCapacity ? _self.maxCapacity : maxCapacity // ignore: cast_nullable_to_non_nullable
as int,enrolledChildIds: null == enrolledChildIds ? _self._enrolledChildIds : enrolledChildIds // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,lane: null == lane ? _self.lane : lane // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
