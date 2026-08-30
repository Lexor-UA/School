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
  
  print('All subscriptions cleared successfully!');
  
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Усі абонементи успішно видалено! Можете закрити це вікно і повернутися до основного додатку.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
    ),
  ));
}
