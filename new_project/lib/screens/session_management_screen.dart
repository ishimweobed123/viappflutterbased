import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visual_impaired_assistive_app/providers/auth_provider.dart';

class SessionManagementScreen extends StatelessWidget {
  const SessionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false)
                  .refreshSession();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('No active session'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Text(
                    'Last login: ${_formatDateTime(user.lastLogin)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Role'),
                      trailing: Text(user.role),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Permissions'),
                      subtitle: Wrap(
                        spacing: 8,
                        children: user.permissions
                            .map(
                              (permission) => Chip(
                                label: Text(permission),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Terminate Session'),
                      content: const Text(
                        'Are you sure you want to terminate this session?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Terminate'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terminate Session'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
