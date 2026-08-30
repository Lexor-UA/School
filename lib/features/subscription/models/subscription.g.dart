// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      totalClasses: (json['totalClasses'] as num).toInt(),
      remainingClasses: (json['remainingClasses'] as num).toInt(),
      isActive: json['isActive'] as bool,
      serviceName: json['serviceName'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      ownerName: json['ownerName'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'totalClasses': instance.totalClasses,
      'remainingClasses': instance.remainingClasses,
      'isActive': instance.isActive,
      'serviceName': instance.serviceName,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'ownerName': instance.ownerName,
    };
