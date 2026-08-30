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
  
  print('Fetching subscriptions...');
  final subs = await firestore.collection('subscriptions').get();
  for (final doc in subs.docs) {
    await doc.reference.delete();
    print('Deleted subscription: ${doc.id}');
  }
  
  print('Fetching classes to reset bookings...');
  final classes = await firestore.collection('classes').get();
  for (final doc in classes.docs) {
    await doc.reference.update({'enrolledChildIds': []});
    print('Reset bookings for class: ${doc.id}');
  }
  
  print('All data reset successfully!');
  
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Усі дані (абонементи та записи) успішно очищено!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
    ),
  ));
}
