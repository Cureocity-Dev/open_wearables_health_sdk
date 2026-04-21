import 'package:flutter/material.dart';

import '../../config/demo_credentials.dart';
import '../../services/health_service_controller.dart';

class ConnectionSection extends StatefulWidget {
  const ConnectionSection({super.key, required this.controller});
  final HealthServiceController controller;

  @override
  State<ConnectionSection> createState() => _ConnectionSectionState();
}

class _ConnectionSectionState extends State<ConnectionSection> {
  final _userId = TextEditingController(text: kDemoUserId);
  final _apiKey = TextEditingController(text: kDemoApiKey);
  final _accessToken = TextEditingController();

  @override
  void dispose() {
    _userId.dispose();
    _apiKey.dispose();
    _accessToken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CONNECTION',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _userId,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: _apiKey,
              decoration:
                  const InputDecoration(labelText: 'API Key (optional)'),
              obscureText: true,
            ),
            TextField(
              controller: _accessToken,
              decoration: const InputDecoration(
                  labelText: 'Access Token (optional)'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton(
                onPressed: () => widget.controller.configureAndSignIn(
                  userId: _userId.text.trim(),
                  apiKey: _apiKey.text.trim().isEmpty ? null : _apiKey.text.trim(),
                  accessToken: _accessToken.text.trim().isEmpty
                      ? null
                      : _accessToken.text.trim(),
                ),
                child: const Text('Configure + Sign In'),
              ),
              OutlinedButton(
                onPressed: widget.controller.signOut,
                child: const Text('Sign Out'),
              ),
            ]),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (_, __) => Text(
                'Status: initialized=${widget.controller.isInitialized}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
