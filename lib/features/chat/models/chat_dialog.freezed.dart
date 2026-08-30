// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_dialog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatDialog {

 String get id; String get clientId; String get clientName; String get clientAvatar; String get lastMessage;@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime get lastMessageTime; int get unreadAdminCount; int get unreadClientCount;@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime get updatedAt;
/// Create a copy of ChatDialog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatDialogCopyWith<ChatDialog> get copyWith => _$ChatDialogCopyWithImpl<ChatDialog>(this as ChatDialog, _$identity);

  /// Serializes this ChatDialog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatDialog&&(identical(other.id, id) || other.id == id)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientAvatar, clientAvatar) || other.clientAvatar == clientAvatar)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&(identical(other.unreadAdminCount, unreadAdminCount) || other.unreadAdminCount == unreadAdminCount)&&(identical(other.unreadClientCount, unreadClientCount) || other.unreadClientCount == unreadClientCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,clientId,clientName,clientAvatar,lastMessage,lastMessageTime,unreadAdminCount,unreadClientCount,updatedAt);

@override
String toString() {
  return 'ChatDialog(id: $id, clientId: $clientId, clientName: $clientName, clientAvatar: $clientAvatar, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadAdminCount: $unreadAdminCount, unreadClientCount: $unreadClientCount, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChatDialogCopyWith<$Res>  {
  factory $ChatDialogCopyWith(ChatDialog value, $Res Function(ChatDialog) _then) = _$ChatDialogCopyWithImpl;
@useResult
$Res call({
 String id, String clientId, String clientName, String clientAvatar, String lastMessage,@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime lastMessageTime, int unreadAdminCount, int unreadClientCount,@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime updatedAt
});




}
/// @nodoc
class _$ChatDialogCopyWithImpl<$Res>
    implements $ChatDialogCopyWith<$Res> {
  _$ChatDialogCopyWithImpl(this._self, this._then);

  final ChatDialog _self;
  final $Res Function(ChatDialog) _then;

/// Create a copy of ChatDialog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clientId = null,Object? clientName = null,Object? clientAvatar = null,Object? lastMessage = null,Object? lastMessageTime = null,Object? unreadAdminCount = null,Object? unreadClientCount = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientAvatar: null == clientAvatar ? _self.clientAvatar : clientAvatar // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,lastMessageTime: null == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime,unreadAdminCount: null == unreadAdminCount ? _self.unreadAdminCount : unreadAdminCount // ignore: cast_nullable_to_non_nullable
as int,unreadClientCount: null == unreadClientCount ? _self.unreadClientCount : unreadClientCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatDialog].
extension ChatDialogPatterns on ChatDialog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatDialog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatDialog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatDialog value)  $default,){
final _that = this;
switch (_that) {
case _ChatDialog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatDialog value)?  $default,){
final _that = this;
switch (_that) {
case _ChatDialog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clientId,  String clientName,  String clientAvatar,  String lastMessage, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime lastMessageTime,  int unreadAdminCount,  int unreadClientCount, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatDialog() when $default != null:
return $default(_that.id,_that.clientId,_that.clientName,_that.clientAvatar,_that.lastMessage,_that.lastMessageTime,_that.unreadAdminCount,_that.unreadClientCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clientId,  String clientName,  String clientAvatar,  String lastMessage, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime lastMessageTime,  int unreadAdminCount,  int unreadClientCount, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatDialog():
return $default(_that.id,_that.clientId,_that.clientName,_that.clientAvatar,_that.lastMessage,_that.lastMessageTime,_that.unreadAdminCount,_that.unreadClientCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clientId,  String clientName,  String clientAvatar,  String lastMessage, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime lastMessageTime,  int unreadAdminCount,  int unreadClientCount, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatDialog() when $default != null:
return $default(_that.id,_that.clientId,_that.clientName,_that.clientAvatar,_that.lastMessage,_that.lastMessageTime,_that.unreadAdminCount,_that.unreadClientCount,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatDialog implements ChatDialog {
  const _ChatDialog({required this.id, required this.clientId, required this.clientName, this.clientAvatar = '', this.lastMessage = '', @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) required this.lastMessageTime, this.unreadAdminCount = 0, this.unreadClientCount = 0, @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) required this.updatedAt});
  factory _ChatDialog.fromJson(Map<String, dynamic> json) => _$ChatDialogFromJson(json);

@override final  String id;
@override final  String clientId;
@override final  String clientName;
@override@JsonKey() final  String clientAvatar;
@override@JsonKey() final  String lastMessage;
@override@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) final  DateTime lastMessageTime;
@override@JsonKey() final  int unreadAdminCount;
@override@JsonKey() final  int unreadClientCount;
@override@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) final  DateTime updatedAt;

/// Create a copy of ChatDialog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatDialogCopyWith<_ChatDialog> get copyWith => __$ChatDialogCopyWithImpl<_ChatDialog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatDialogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatDialog&&(identical(other.id, id) || other.id == id)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientAvatar, clientAvatar) || other.clientAvatar == clientAvatar)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&(identical(other.unreadAdminCount, unreadAdminCount) || other.unreadAdminCount == unreadAdminCount)&&(identical(other.unreadClientCount, unreadClientCount) || other.unreadClientCount == unreadClientCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,clientId,clientName,clientAvatar,lastMessage,lastMessageTime,unreadAdminCount,unreadClientCount,updatedAt);

@override
String toString() {
  return 'ChatDialog(id: $id, clientId: $clientId, clientName: $clientName, clientAvatar: $clientAvatar, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadAdminCount: $unreadAdminCount, unreadClientCount: $unreadClientCount, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatDialogCopyWith<$Res> implements $ChatDialogCopyWith<$Res> {
  factory _$ChatDialogCopyWith(_ChatDialog value, $Res Function(_ChatDialog) _then) = __$ChatDialogCopyWithImpl;
@override @useResult
$Res call({
 String id, String clientId, String clientName, String clientAvatar, String lastMessage,@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime lastMessageTime, int unreadAdminCount, int unreadClientCount,@JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime updatedAt
});




}
/// @nodoc
class __$ChatDialogCopyWithImpl<$Res>
    implements _$ChatDialogCopyWith<$Res> {
  __$ChatDialogCopyWithImpl(this._self, this._then);

  final _ChatDialog _self;
  final $Res Function(_ChatDialog) _then;

/// Create a copy of ChatDialog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clientId = null,Object? clientName = null,Object? clientAvatar = null,Object? lastMessage = null,Object? lastMessageTime = null,Object? unreadAdminCount = null,Object? unreadClientCount = null,Object? updatedAt = null,}) {
  return _then(_ChatDialog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientAvatar: null == clientAvatar ? _self.clientAvatar : clientAvatar // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,lastMessageTime: null == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime,unreadAdminCount: null == unreadAdminCount ? _self.unreadAdminCount : unreadAdminCount // ignore: cast_nullable_to_non_nullable
as int,unreadClientCount: null == unreadClientCount ? _self.unreadClientCount : unreadClientCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
