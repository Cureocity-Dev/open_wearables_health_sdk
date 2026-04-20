import 'package:flutter/material.dart';

import 'app.dart';

/// Entry point for the Cureocity parity probe.
///
/// Run with: `flutter run -t lib/parity_probe.dart`
///
/// Kept separate from `lib/main.dart` so upstream updates to main.dart
/// do not conflict with Cureocity's additions. See the fork's
/// `cureocity/` strategy in docs/.
void main() {
  runApp(const ParityProbeApp());
}
