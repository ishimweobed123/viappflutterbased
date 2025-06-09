import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visual_impaired_assistive_app/providers/auth_provider.dart';
import 'package:visual_impaired_assistive_app/providers/dashboard_provider.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

// Modern, professional admin dashboard with sidebar navigation and improved UI
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final List<String> _sections = [
    'Overview',
    'Users',
    'Devices',
    'Danger Zones',
  ];

  // Add missing fields for admin/user search and access control
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboardStats();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _handleNonAdminAccess();
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(authProvider.user!.id).get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        _handleNonAdminAccess();
        return;
      }

      setState(() {
        _isAdmin = true;
      });
    } catch (e) {
      _handleNonAdminAccess();
    }
  }

  // Add missing _handleNonAdminAccess method
  void _handleNonAdminAccess() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => role = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .createUser(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  name: nameController.text.trim(),
                  role: role,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Provider.of<DashboardProvider>(context, listen: false)
                      .loadDashboardStats();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Widget _buildSidebar() {
  //   return Container(
  //     width: 220,
  //     color: Colors.blueGrey[900],
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 32),
  //         CircleAvatar(
  //           radius: 36,
  //           backgroundColor: Colors.blue[300],
  //           child: const Icon(Icons.admin_panel_settings,
  //               size: 40, color: Colors.white),
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           'Admin',
  //           style: TextStyle(
  //               color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
  //         ),
  //         const SizedBox(height: 32),
  //         ...List.generate(
  //             _sections.length,
  //             (i) => ListTile(
  //                   leading: Icon(
  //                     i == 0
  //                         ? Icons.dashboard
  //                         : i == 1
  //                             ? Icons.people
  //                             : i == 2
  //                                 ? Icons.device_hub
  //                                 : Icons.warning,
  //                     color: _selectedIndex == i
  //                         ? Colors.blue[200]
  //                         : Colors.white70,
  //                   ),
  //                   title: Text(
  //                     _sections[i],
  //                     style: TextStyle(
  //                       color: _selectedIndex == i
  //                           ? Colors.blue[200]
  //                           : Colors.white70,
  //                       fontWeight: _selectedIndex == i
  //                           ? FontWeight.bold
  //                           : FontWeight.normal,
  //                     ),
  //                   ),
  //                   selected: _selectedIndex == i,
  //                   selectedTileColor: Colors.blueGrey[800],
  //                   onTap: () => setState(() => _selectedIndex = i),
  //                 )),
  //         const Spacer(),
  //         ListTile(
  //           leading: const Icon(Icons.logout, color: Colors.redAccent),
  //           title:
  //               const Text('Logout', style: TextStyle(color: Colors.redAccent)),
  //           onTap: () async {
  //             await Provider.of<AuthProvider>(context, listen: false).signOut();
  //             if (mounted) {
  //               Navigator.of(context).pushReplacementNamed('/login');
  //             }
  //           },
  //         ),
  //         const SizedBox(height: 16),
  //       ],
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     drawer: Drawer(
  //       child: _buildSidebar(),
  //     ),
  //     body: Expanded(
  //       child: Row(
  //         children: [
  //           _buildSidebar(),
  //           Expanded(
  //             child: Column(
  //               children: [
  //                 _buildHeader(),
  //                 Expanded(child: _buildBody()),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     floatingActionButton: _buildFloatingActionButton(),
  //   );
  // }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.blue[300],
            child: const Icon(Icons.admin_panel_settings,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Admin',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ...List.generate(
            _sections.length,
            (i) => ListTile(
              leading: Icon(
                i == 0
                    ? Icons.dashboard
                    : i == 1
                        ? Icons.people
                        : i == 2
                            ? Icons.device_hub
                            : Icons.warning,
                color: _selectedIndex == i ? Colors.blue[200] : Colors.white70,
              ),
              title: Text(
                _sections[i],
                style: TextStyle(
                  color:
                      _selectedIndex == i ? Colors.blue[200] : Colors.white70,
                  fontWeight:
                      _selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: _selectedIndex == i,
              selectedTileColor: Colors.blueGrey[800],
              onTap: () {
                Navigator.pop(context); // ✅ CLOSE the Drawer
                setState(() => _selectedIndex = i); // Update UI
              },
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title:
                const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context); // ✅ CLOSE the Drawer
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildHeader(),
      ),
      drawer: Drawer(
        child: _buildSidebar(),
      ),
      body: Column(
        children: [
          // _buildHeader(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            _sections[_selectedIndex],
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.blueGrey),
            onPressed: _showNotificationsDialog,
            tooltip: 'System Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            onPressed: _showSettingsDialog,
            tooltip: 'Dashboard Settings',
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.blue[200],
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildUsersList();
      case 2:
        return _buildDeviceManagement();
      case 3:
        return _buildDangerZones();
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  Widget _buildOverview() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        if (dashboardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = dashboardProvider.stats;
        if (stats == null) {
          return const Center(child: Text('No data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(stats),
              const SizedBox(height: 24),
              _buildActivityChart(stats.activityStats),
              const SizedBox(height: 24),
              _buildSystemHealth(),
              const SizedBox(height: 24),
              _buildRecentActivities(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          stats.totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Users',
          stats.activeUsers.toString(),
          Icons.person_outline,
          Colors.green,
        ),
        _buildStatCard(
          'People Helped',
          stats.totalHelped.toString(),
          Icons.help_outline,
          Colors.orange,
        ),
        _buildStatCard(
          'Failed Logins',
          stats.failedLogins.toString(),
          Icons.error_outline,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(Map<String, int> activityStats) {
    if (activityStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = activityStats.entries.toList();
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: activityStats.values
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[value.toInt()]
                                    .key
                                    .split('_')
                                    .join('\n'),
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      entries.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entries[index].value.toDouble(),
                            color: Colors.blue,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHealthIndicator(
              'Server Status',
              'Online',
              Icons.cloud_done,
              Colors.green,
            ),
            _buildHealthIndicator(
              'Database',
              'Connected',
              Icons.storage,
              Colors.green,
            ),
            _buildHealthIndicator(
              'API Response Time',
              '120ms',
              Icons.speed,
              Colors.orange,
            ),
            _buildHealthIndicator(
              'Storage Usage',
              '45%',
              Icons.sd_storage,
              Colors.blue,
            ),
            // Custom: Add more system health indicators as needed
            _buildHealthIndicator(
              'Active Admins',
              '1', // You can fetch and display the real count
              Icons.admin_panel_settings,
              Colors.purple,
            ),
            _buildHealthIndicator(
              'Pending Reports',
              '0', // You can fetch and display the real count
              Icons.report,
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (!_isAdmin) return const Center(child: Text('Access Denied'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredUsers = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final role = (data['role'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    email.contains(_searchQuery) ||
                    role.contains(_searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text('No users found matching the search criteria'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final userData =
                      filteredUsers[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(userData['name']?[0] ?? 'U'),
                      ),
                      title: Text(userData['name'] ?? 'Unknown User'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['email'] ?? 'No email'),
                          Text('Role: \\${userData['role'] ?? 'user'}'),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit'),
                              onTap: () {
                                Navigator.pop(context);
                                _showEditUserDialog(filteredUsers[index]);
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Delete'),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteUserDialog(filteredUsers[index].id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditUserDialog(DocumentSnapshot user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String role = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => role = value!,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(user.id).update({
                'name': nameController.text,
                'email': emailController.text,
                'role': role,
              });
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<DashboardProvider>(context, listen: false)
                  .deleteUser(userId);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('devices').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final devices = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Management',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Devices: ${devices.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddDeviceDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Device'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final data = device.data() as Map<String, dynamic>;
                  final isOnline = data['isOnline'] ?? false;
                  final batteryLevel = data['batteryLevel'] ?? 0;

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.device_hub,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                      title: Text(data['name'] ?? 'Unnamed Device'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: \\${device.id}'),
                          Text('Status: \\${isOnline ? 'Online' : 'Offline'}'),
                          LinearProgressIndicator(
                            value: batteryLevel / 60,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              batteryLevel > 20 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text('Battery: \\${batteryLevel}%'),
                          FutureBuilder<DocumentSnapshot>(
                            future: data['userId'] != null
                                ? _firestore
                                    .collection('users')
                                    .doc(data['userId'])
                                    .get()
                                : null,
                            builder: (context, userSnapshot) {
                              if (data['userId'] == null) {
                                return const Text('Assigned User: None');
                              }
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Assigned User: ...');
                              }
                              if (userSnapshot.hasError ||
                                  !userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const Text('Assigned User: Not found');
                              }
                              final userData = userSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              return Text(
                                  'Assigned User: \\${userData['name'] ?? userData['email'] ?? data['userId']}');
                            },
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit'),
                              onTap: () {
                                Navigator.pop(context);
                                _showEditDeviceDialog(device);
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Delete'),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteDeviceDialog(device.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDangerZones() {
    if (!_isAdmin) return const Center(child: Text('Access Denied'));

    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        if (dashboardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = dashboardProvider.stats;
        if (stats == null) {
          return const Center(child: Text('No data available'));
        }

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: FlutterMap(
                options: const MapOptions(),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.visual_impaired_assistive_app',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  MarkerLayer(
                    markers: stats.dangerZones.map((zone) {
                      return Marker(
                        width: 30,
                        height: 30,
                        point: LatLng(
                          zone.coordinates.latitude,
                          zone.coordinates.longitude,
                        ),
                        child: Icon(
                          Icons.warning,
                          color: _getSeverityColor(zone.severity),
                          size: 30,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Show the list of danger zones below the map
            Container(
              height: 220,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildDangerZonesList(stats.dangerZones),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDangerZonesList(List<DangerZone> zones) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zone = zones[index];
        return Card(
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.location,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Incidents: ${zone.incidents}'),
                Text('Severity: ${zone.severity}'),
                Text(
                  'Last reported: ${DateFormat.yMMMd().format(zone.lastReported)}',
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () => _showEditDangerZoneDialog(zone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteDangerZoneDialog(zone),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDangerZoneDialog(DangerZone zone) {
    final locationController = TextEditingController(text: zone.location);
    final descriptionController = TextEditingController(text: zone.description);
    String severity = zone.severity;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Danger Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) => severity = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (locationController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _firestore
                    .collection('danger_zones')
                    .doc(zone.id)
                    .update({
                  'location': locationController.text,
                  'description': descriptionController.text,
                  'severity': severity,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Danger zone updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh dashboard stats after editing
                  Provider.of<DashboardProvider>(context, listen: false)
                      .loadDashboardStats();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating danger zone: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDangerZoneDialog(DangerZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Danger Zone'),
        content:
            const Text('Are you sure you want to delete this danger zone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('danger_zones')
                    .doc(zone.id)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Danger zone deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh dashboard stats after deleting
                  Provider.of<DashboardProvider>(context, listen: false)
                      .loadDashboardStats();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting danger zone: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDangerZoneDialog() {
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    String severity = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Danger Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) => severity = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (locationController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _firestore.collection('danger_zones').add({
                  'location': locationController.text,
                  'description': descriptionController.text,
                  'severity': severity,
                  'incidents': 1,
                  'lastReported': FieldValue.serverTimestamp(),
                  'coordinates': {'latitude': 0.0, 'longitude': 0.0},
                  'createdAt': FieldValue.serverTimestamp(),
                  'isActive': true,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Danger zone added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh dashboard stats after adding
                  Provider.of<DashboardProvider>(context, listen: false)
                      .loadDashboardStats();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding danger zone: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Show Add User FAB on Users tab for admin
    if (_selectedIndex == 1 && _isAdmin) {
      return FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add User',
      );
    }
    // Show Add Danger Zone FAB on Danger Zones tab for admin
    if (_selectedIndex == 3 && _isAdmin) {
      return FloatingActionButton(
        onPressed: _showAddDangerZoneDialog,
        child: const Icon(Icons.add_location_alt),
        tooltip: 'Add Danger Zone',
      );
    }
    // Return an empty SizedBox if no FAB is needed
    return const SizedBox.shrink();
  }

  // Add the missing _buildRecentActivities method
  Widget _buildRecentActivities() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...snapshot.data!.docs.map((activity) {
                  return ListTile(
                    title: Text(activity['type'] ?? 'Unknown Activity'),
                    subtitle: Text(
                      activity['timestamp'] != null
                          ? DateFormat.yMMMd().add_Hm().format(
                                (activity['timestamp'] as Timestamp).toDate(),
                              )
                          : 'No timestamp',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(activity['status'] as String?),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activity['status'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add the missing _getSeverityColor method
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  // Add the missing _getStatusColor method
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Add the missing _buildActiveUsersList method
  Widget _buildActiveUsersList(List<ActiveUser> users) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Status: \\${user.isOnline ? "Online" : "Offline"}'),
                Text(
                  'Last active: \\${DateFormat.yMMMd().add_Hm().format(user.lastActive)}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Add missing methods to resolve errors ---

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Notifications'),
        content: const Text('No notifications yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Settings'),
        content: const Text('Settings dialog placeholder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    final deviceIdController = TextEditingController();
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore.collection('users').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final users = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to User',
                      border: OutlineInputBorder(),
                    ),
                    items: users.map((userDoc) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: userDoc.id,
                        child:
                            Text(data['name'] ?? data['email'] ?? userDoc.id),
                      );
                    }).toList(),
                    onChanged: (value) => selectedUserId = value,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  deviceIdController.text.isEmpty ||
                  selectedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please fill in all fields and select a user'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _firestore.collection('devices').add({
                  'name': nameController.text,
                  'deviceId': deviceIdController.text,
                  'isOnline': false,
                  'batteryLevel': 100,
                  'lastSeen': FieldValue.serverTimestamp(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'userId': selectedUserId,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(DocumentSnapshot device) {
    final data = device.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final deviceIdController = TextEditingController(text: data['deviceId']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('devices').doc(device.id).update({
                  'name': nameController.text,
                  'deviceId': deviceIdController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDeviceDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('devices').doc(deviceId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<UserReport> reports) {
    // Placeholder for reports list
    return const Center(child: Text('Reports feature coming soon.'));
  }
}

// In your main.dart or wherever you set up providers:
// Add ChangeNotifierProvider for UserReportProvider
// Example (in main.dart):
// MultiProvider(
//   providers: [
//     ...
//     ChangeNotifierProvider(create: (_) => UserReportProvider()),
//   ],
//   child: MyApp(),
// )
