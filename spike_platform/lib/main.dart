import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options_spike.dart';
import 'firebase_service.dart';
import 'platform_config.dart';
import 'sqlite_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with emulator-safe dummy options (never a real
  // Firebase project — see firebase_options_spike.dart).
  await Firebase.initializeApp(options: spikeFirebaseOptions);

  // Point Auth and Firestore at the local Firebase Emulator Suite.
  FirebaseAuth.instance.useAuthEmulator(kAuthEmulatorHost, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(
    kFirestoreEmulatorHost,
    kFirestoreEmulatorPort,
  );

  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Spike',
      home: const SpikeHomePage(),
    );
  }
}

class SpikeHomePage extends StatefulWidget {
  const SpikeHomePage({super.key});

  @override
  State<SpikeHomePage> createState() => _SpikeHomePageState();
}

class _SpikeHomePageState extends State<SpikeHomePage> {
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    final sqliteResult = await testSqliteInsertAndRead();
    _log.add(sqliteResult);
    debugPrint('[SPIKE] $sqliteResult');
    setState(() {});

    final firebaseResult = await testFirebaseInitAuthFirestore();
    _log.add(firebaseResult);
    debugPrint('[SPIKE] $firebaseResult');
    setState(() {});
  }

  Future<void> _rerunSqliteTest() async {
    final result = await testSqliteInsertAndRead();
    _log.add(result);
    debugPrint('[SPIKE] $result');
    setState(() {});
  }

  Future<void> _rerunFirebaseTest() async {
    final result = await testFirebaseInitAuthFirestore();
    _log.add(result);
    debugPrint('[SPIKE] $result');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Spike')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _rerunSqliteTest,
                child: const Text('Re-run SQLite Test'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _rerunFirebaseTest,
                child: const Text('Re-run Firebase Test'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: _log.map((line) => Text(line)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
