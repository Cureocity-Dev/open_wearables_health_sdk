import 'package:flutter/material.dart';

class ParityProbeApp extends StatelessWidget {
  const ParityProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Wearables Parity Probe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('Parity probe — wiring in progress (Task 4)'),
          ),
        ),
      ),
    );
  }
}
