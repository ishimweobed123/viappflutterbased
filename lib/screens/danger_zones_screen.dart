import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/providers/danger_zone_provider.dart';
import 'package:visual_impaired_assistive_app/models/danger_zone_model.dart';
import 'package:intl/intl.dart';

class DangerZonesScreen extends StatelessWidget {
  const DangerZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danger Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDangerZoneDialog(context),
            tooltip: 'Add Danger Zone',
          ),
        ],
      ),
      body: Consumer<DangerZoneProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.dangerZones.isEmpty) {
            return const Center(
              child: Text('No danger zones reported'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: provider.dangerZones.length,
            itemBuilder: (context, index) {
              final zone = provider.dangerZones[index];
              return _buildDangerZoneCard(context, zone);
            },
          );
        },
      ),
    );
  }

  Widget _buildDangerZoneCard(BuildContext context, DangerZone zone) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(zone.severity).withOpacity(0.2),
          child: Icon(
            Icons.warning,
            color: _getSeverityColor(zone.severity),
          ),
        ),
        title: Text(
          zone.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Last reported: ${_formatDateTime(zone.lastReported)}',
        ),
        trailing: Text(
          '${zone.incidents} incidents',
          style: TextStyle(
            color: _getSeverityColor(zone.severity),
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${zone.description}'),
                const SizedBox(height: 8),
                Text(
                  'Location: ${zone.location.latitude.toStringAsFixed(6)}, ${zone.location.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 8),
                Text('Severity: ${zone.severity.toUpperCase()}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _reportIncident(context, zone),
                      icon: const Icon(Icons.add_alert),
                      label: const Text('Report Incident'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getSeverityColor(zone.severity),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditDangerZoneDialog(context, zone),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteDangerZone(context, zone),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y HH:mm').format(dateTime);
  }

  Future<void> _showAddDangerZoneDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();
    String severity = 'medium';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Danger Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lonController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(labelText: 'Severity'),
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lonController.text.isNotEmpty) {
                final provider =
                    Provider.of<DangerZoneProvider>(context, listen: false);
                final dangerZone = DangerZone(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  location: GeoPoint(
                    double.parse(latController.text),
                    double.parse(lonController.text),
                  ),
                  severity: severity,
                  incidents: 0,
                  lastReported: DateTime.now(),
                );
                provider.addDangerZone(dangerZone);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDangerZoneDialog(
      BuildContext context, DangerZone zone) async {
    final nameController = TextEditingController(text: zone.name);
    final descriptionController = TextEditingController(text: zone.description);
    final latController =
        TextEditingController(text: zone.location.latitude.toString());
    final lonController =
        TextEditingController(text: zone.location.longitude.toString());
    String severity = zone.severity;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Danger Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lonController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(labelText: 'Severity'),
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lonController.text.isNotEmpty) {
                final provider =
                    Provider.of<DangerZoneProvider>(context, listen: false);
                final updatedZone = zone.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  location: GeoPoint(
                    double.parse(latController.text),
                    double.parse(lonController.text),
                  ),
                  severity: severity,
                );
                provider.updateDangerZone(updatedZone);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportIncident(BuildContext context, DangerZone zone) async {
    final provider = Provider.of<DangerZoneProvider>(context, listen: false);
    await provider.reportIncident(zone.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident reported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteDangerZone(BuildContext context, DangerZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Danger Zone'),
        content:
            const Text('Are you sure you want to delete this danger zone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<DangerZoneProvider>(context, listen: false);
      await provider.deleteDangerZone(zone.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danger zone deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
