import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  final now = DateTime.now();

  print('Seeding classes...');

  await firestore.collection('classes').add({
    'title': 'Юніори (Батерфляй)',
    'startTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 2))),
    'endTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 3))),
    'coachId': '2', // Coach id from auth controller mock
    'coachName': 'Тренер Алекс',
    'maxCapacity': 10,
    'enrolledUserIds': [],
    'category': 'Плавання',
  });
  
  await firestore.collection('classes').add({
    'title': 'Стрибки у воду',
    'startTime': Timestamp.fromDate(now.add(const Duration(days: 2, hours: 3))),
    'endTime': Timestamp.fromDate(now.add(const Duration(days: 2, hours: 4))),
    'coachId': '2',
    'coachName': 'Тренер Олена',
    'maxCapacity': 5,
    'enrolledUserIds': [],
    'category': 'Стрибки',
  });

  print('Done seeding classes!');
}
