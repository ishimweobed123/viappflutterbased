import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            context,
            'Getting Started',
            'Learn how to use the app',
            Icons.play_circle_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSectionScreen(
                    title: 'Getting Started',
                    content: '''
1. Welcome to the Visual Impaired Assistant
2. Basic Navigation
3. Using Voice Commands
4. Understanding Obstacle Detection
5. Customizing Settings
''',
                  ),
                ),
              );
            },
          ),
          _buildSection(
            context,
            'Navigation Guide',
            'Learn about navigation features',
            Icons.directions_walk,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSectionScreen(
                    title: 'Navigation Guide',
                    content: '''
1. Starting Navigation
2. Understanding Voice Guidance
3. Obstacle Detection
4. Route Planning
5. Emergency Assistance
''',
                  ),
                ),
              );
            },
          ),
          _buildSection(
            context,
            'Settings Guide',
            'Customize your experience',
            Icons.settings,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSectionScreen(
                    title: 'Settings Guide',
                    content: '''
1. Voice Settings
2. Navigation Preferences
3. Notification Settings
4. Accessibility Options
5. Privacy Settings
''',
                  ),
                ),
              );
            },
          ),
          _buildSection(
            context,
            'Troubleshooting',
            'Common issues and solutions',
            Icons.build,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSectionScreen(
                    title: 'Troubleshooting',
                    content: '''
1. Connection Issues
2. Voice Guidance Problems
3. Navigation Accuracy
4. App Performance
5. Battery Usage
''',
                  ),
                ),
              );
            },
          ),
          _buildSection(
            context,
            'Contact Support',
            'Get help from our team',
            Icons.contact_support,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSectionScreen(
                    title: 'Contact Support',
                    content: '''
Email: support@visualimpairedassistant.com
Phone: +1 (555) 123-4567
Hours: Monday-Friday, 9AM-5PM EST

For emergency assistance, please call 911 or your local emergency number.
''',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class HelpSectionScreen extends StatelessWidget {
  final String title;
  final String content;

  const HelpSectionScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
