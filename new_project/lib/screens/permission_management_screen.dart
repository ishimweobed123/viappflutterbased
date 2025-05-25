import 'package:flutter/material.dart';

class PermissionManagementScreen extends StatefulWidget {
  const PermissionManagementScreen({super.key});

  @override
  State<PermissionManagementScreen> createState() =>
      _PermissionManagementScreenState();
}

class _PermissionManagementScreenState
    extends State<PermissionManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _permissionController = TextEditingController();
  final List<String> _availablePermissions = [
    'read',
    'write',
    'delete',
    'manage_users',
    'manage_roles',
    'manage_permissions',
  ];

  @override
  void dispose() {
    _permissionController.dispose();
    super.dispose();
  }

  void _showAddPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Permission'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _permissionController,
            decoration: const InputDecoration(
              labelText: 'Permission Name',
              hintText: 'Enter permission name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a permission name';
              }
              if (_availablePermissions.contains(value.toLowerCase())) {
                return 'This permission already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _availablePermissions
                      .add(_permissionController.text.toLowerCase());
                });
                _permissionController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handlePermissionAction(String permission, String action) async {
    switch (action) {
      case 'edit':
        final updatedPermission = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Permission'),
            content: TextFormField(
              initialValue: permission,
              decoration: const InputDecoration(
                labelText: 'Permission Name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, permission),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (updatedPermission != null && updatedPermission != permission) {
          setState(() {
            final index = _availablePermissions.indexOf(permission);
            _availablePermissions[index] = updatedPermission.toLowerCase();
          });
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Permission'),
            content: Text(
                'Are you sure you want to delete the permission "$permission"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _availablePermissions.remove(permission);
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPermissionDialog,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _availablePermissions.length,
        itemBuilder: (context, index) {
          final permission = _availablePermissions[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(permission),
              subtitle: Text(_getPermissionDescription(permission)),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (value) =>
                    _handlePermissionAction(permission, value),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getPermissionDescription(String permission) {
    switch (permission) {
      case 'read':
        return 'Can view content';
      case 'write':
        return 'Can create and edit content';
      case 'delete':
        return 'Can remove content';
      case 'manage_users':
        return 'Can manage user accounts';
      case 'manage_roles':
        return 'Can manage user roles';
      case 'manage_permissions':
        return 'Can manage permissions';
      default:
        return 'Custom permission';
    }
  }
}
