// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityLog {

 String get id; String get action; DateTime get timestamp; String get adminId;
/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityLogCopyWith<ActivityLog> get copyWith => _$ActivityLogCopyWithImpl<ActivityLog>(this as ActivityLog, _$identity);

  /// Serializes this ActivityLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityLog&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.adminId, adminId) || other.adminId == adminId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,timestamp,adminId);

@override
String toString() {
  return 'ActivityLog(id: $id, action: $action, timestamp: $timestamp, adminId: $adminId)';
}


}

/// @nodoc
abstract mixin class $ActivityLogCopyWith<$Res>  {
  factory $ActivityLogCopyWith(ActivityLog value, $Res Function(ActivityLog) _then) = _$ActivityLogCopyWithImpl;
@useResult
$Res call({
 String id, String action, DateTime timestamp, String adminId
});




}
/// @nodoc
class _$ActivityLogCopyWithImpl<$Res>
    implements $ActivityLogCopyWith<$Res> {
  _$ActivityLogCopyWithImpl(this._self, this._then);

  final ActivityLog _self;
  final $Res Function(ActivityLog) _then;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? timestamp = null,Object? adminId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityLog].
extension ActivityLogPatterns on ActivityLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityLog value)  $default,){
final _that = this;
switch (_that) {
case _ActivityLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityLog value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  DateTime timestamp,  String adminId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
return $default(_that.id,_that.action,_that.timestamp,_that.adminId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  DateTime timestamp,  String adminId)  $default,) {final _that = this;
switch (_that) {
case _ActivityLog():
return $default(_that.id,_that.action,_that.timestamp,_that.adminId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  DateTime timestamp,  String adminId)?  $default,) {final _that = this;
switch (_that) {
case _ActivityLog() when $default != null:
return $default(_that.id,_that.action,_that.timestamp,_that.adminId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityLog implements ActivityLog {
  const _ActivityLog({required this.id, required this.action, required this.timestamp, required this.adminId});
  factory _ActivityLog.fromJson(Map<String, dynamic> json) => _$ActivityLogFromJson(json);

@override final  String id;
@override final  String action;
@override final  DateTime timestamp;
@override final  String adminId;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityLogCopyWith<_ActivityLog> get copyWith => __$ActivityLogCopyWithImpl<_ActivityLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityLog&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.adminId, adminId) || other.adminId == adminId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,timestamp,adminId);

@override
String toString() {
  return 'ActivityLog(id: $id, action: $action, timestamp: $timestamp, adminId: $adminId)';
}


}

/// @nodoc
abstract mixin class _$ActivityLogCopyWith<$Res> implements $ActivityLogCopyWith<$Res> {
  factory _$ActivityLogCopyWith(_ActivityLog value, $Res Function(_ActivityLog) _then) = __$ActivityLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, DateTime timestamp, String adminId
});




}
/// @nodoc
class __$ActivityLogCopyWithImpl<$Res>
    implements _$ActivityLogCopyWith<$Res> {
  __$ActivityLogCopyWithImpl(this._self, this._then);

  final _ActivityLog _self;
  final $Res Function(_ActivityLog) _then;

/// Create a copy of ActivityLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? timestamp = null,Object? adminId = null,}) {
  return _then(_ActivityLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
