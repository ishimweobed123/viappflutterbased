import 'package:flutter/material.dart';
import 'package:visual_impaired_assistive_app/screens/profile_screen.dart';
import 'package:visual_impaired_assistive_app/screens/help_screen.dart';
import 'package:visual_impaired_assistive_app/screens/notifications_screen.dart';
import 'package:visual_impaired_assistive_app/screens/user_management_screen.dart';
import 'package:visual_impaired_assistive_app/screens/role_management_screen.dart';
import 'package:visual_impaired_assistive_app/screens/permission_management_screen.dart';
import 'package:visual_impaired_assistive_app/screens/session_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Role Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RoleManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Permission Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const PermissionManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Session Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SessionManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDashboardItem(
              context,
              'Profile',
              Icons.person,
              const ProfileScreen(),
            ),
            _buildDashboardItem(
              context,
              'Users',
              Icons.people,
              const UserManagementScreen(),
            ),
            _buildDashboardItem(
              context,
              'Roles',
              Icons.security,
              const RoleManagementScreen(),
            ),
            _buildDashboardItem(
              context,
              'Permissions',
              Icons.lock,
              const PermissionManagementScreen(),
            ),
            _buildDashboardItem(
              context,
              'Sessions',
              Icons.access_time,
              const SessionManagementScreen(),
            ),
            _buildDashboardItem(
              context,
              'Help',
              Icons.help,
              const HelpScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
