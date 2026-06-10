import 'package:flutter/material.dart';
import 'package:stuff_ride/features/auth/screens/login_screen.dart';
import 'package:stuff_ride/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  final String _languageSelected = 'English';
  final AuthService _authService = AuthService();

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() async {
    await _authService.logoutUser();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSettingsSection('Notifications', [
              SwitchListTile(
                title: const Text('Trip Notifications'),
                subtitle: const Text('Receive trip updates'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Location Tracking'),
                subtitle: const Text('Allow real-time location sharing'),
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                },
              ),
            ]),
            _buildSettingsSection('Preferences', [
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_languageSelected),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () =>
                    _showMessage('Language settings will be added soon'),
              ),
              ListTile(
                title: const Text('Theme'),
                subtitle: const Text('Light'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _showMessage('Theme settings will be added soon'),
              ),
            ]),
            _buildSettingsSection('About', [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () =>
                    _showMessage('Privacy policy will be available soon'),
              ),
              ListTile(
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _showMessage('Terms will be available soon'),
              ),
              ListTile(
                title: const Text('Contact Support'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _showMessage('Support contact will be added soon'),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}
