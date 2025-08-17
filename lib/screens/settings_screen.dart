// lib/screens/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:products/providers/theme_notifier.dart';
import 'package:products/services/auth_services.dart';
import 'package:products/services/storage_services.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final Future<void> Function() onResetApp;
  final ThemeNotifier themeNotifier;
  final StorageService storageService;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onResetApp,
    required this.themeNotifier,
    required this.storageService,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _expiringDays;
  @override
  void initState() {
    super.initState();
    _expiringDays = (widget.settings['expiringSoonDays'] ?? 7).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "No user";
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Logged in as"),
                subtitle: Text(
                  userEmail,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: widget.themeNotifier.themeMode == ThemeMode.dark,
              onChanged: (value) {
                final newMode = value ? ThemeMode.dark : ThemeMode.light;
                widget.themeNotifier.setThemeMode(newMode);
                widget.storageService.saveTheme(newMode);
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expiring Soon Threshold",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Notify about items expiring in the next ${_expiringDays.toInt()} days.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _expiringDays,
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: _expiringDays.round().toString(),
                    onChanged: (value) => setState(() => _expiringDays = value),
                    onChangeEnd:
                        (value) => widget.onSettingsChanged({
                          'expiringSoonDays': value.toInt(),
                        }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.red.shade50
                    : Colors.red.shade900.withOpacity(0.4),
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
              ),
              title: Text(
                "Clear All Data",
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.red.shade900
                          : Colors.red.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "This will delete all your products.",
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.red.shade800
                          : Colors.red.shade300,
                ),
              ),
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text("Are you sure?"),
                          content: const Text(
                            "This action cannot be undone. All your products and categories will be permanently deleted for this account.",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Delete Everything"),
                              onPressed: () {
                                widget.onResetApp();
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text("Sign Out"),
              onTap: () async {
                await AuthService().signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
