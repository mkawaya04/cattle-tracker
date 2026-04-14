import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  final TextEditingController _feedbackController = TextEditingController();
  final darkGreen = const Color(0xFF1B4332);

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        notificationsEnabled = data['notificationsEnabled'] ?? true;
      });
    }
  }

  Future<void> _updateNotifications(bool value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'notificationsEnabled': value,
    });
    setState(() => notificationsEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications enabled' : 'Notifications disabled',
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some feedback first.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': uid,
      'message': feedback,
      'timestamp': DateTime.now(),
    });

    _feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  void _rateApp() async {
    final url = Uri.parse('https://example.com/rate');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the app store.')),
      );
    }
  }

  void _shareApp() {
    Share.share('Check out this cattle tracking app! https://example.com/app');
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                _updateLanguage('English');
              },
            ),
            ListTile(
              title: const Text('Bemba'),
              onTap: () {
                _updateLanguage('Bemba');
              },
            ),
            ListTile(
              title: const Text('Nyanja'),
              onTap: () {
                _updateLanguage('Nyanja');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: darkGreen),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLanguage(String lang) async {
    Navigator.pop(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'language': lang,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language set to $lang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightFill = Colors.grey[100];
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const SizedBox(height: 12),
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.person, color: darkGreen),
              title: Text(user?.displayName ?? 'Unknown User'),
              subtitle: Text(user?.email ?? ''),
              trailing: TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: darkGreen),
                child: const Text('Log Out'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: notificationsEnabled,
            onChanged: (val) => _updateNotifications(val),
            activeColor: darkGreen,
          ),
          const SizedBox(height: 24),
          Text('Language', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.language, color: darkGreen),
            title: const Text('App Language'),
            subtitle: const Text('Tap to change'),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: darkGreen),
              onPressed: _showLanguageDialog,
            ),
          ),
          const SizedBox(height: 24),
          Text('Feedback', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('We\'d love to hear your thoughts!'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback...',
                      filled: true,
                      fillColor: lightFill,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Support & Sharing',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.star_rate, color: darkGreen),
            title: const Text('Rate the App'),
            onTap: _rateApp,
          ),
          ListTile(
            leading: Icon(Icons.share, color: darkGreen),
            title: const Text('Share the App'),
            onTap: _shareApp,
          ),
        ],
      ),
    );
  }
}
