import 'package:flutter/material.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final List<String> _availableRoles = ['admin', 'user', 'moderator'];

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  void _showAddRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Role'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Role Name',
              hintText: 'Enter role name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a role name';
              }
              if (_availableRoles.contains(value.toLowerCase())) {
                return 'This role already exists';
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
                  _availableRoles.add(_roleController.text.toLowerCase());
                });
                _roleController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleRoleAction(String role, String action) async {
    switch (action) {
      case 'edit':
        final updatedRole = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Role'),
            content: TextFormField(
              initialValue: role,
              decoration: const InputDecoration(
                labelText: 'Role Name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, role),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (updatedRole != null && updatedRole != role) {
          setState(() {
            final index = _availableRoles.indexOf(role);
            _availableRoles[index] = updatedRole.toLowerCase();
          });
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Role'),
            content: Text('Are you sure you want to delete the role "$role"?'),
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
            _availableRoles.remove(role);
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRoleDialog,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _availableRoles.length,
        itemBuilder: (context, index) {
          final role = _availableRoles[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(role),
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
                onSelected: (value) => _handleRoleAction(role, value),
              ),
            ),
          );
        },
      ),
    );
  }
}
