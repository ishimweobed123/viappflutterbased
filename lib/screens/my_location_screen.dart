import 'package:flutter/material.dart';

class MyLocationScreen extends StatelessWidget {
  const MyLocationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
      ),
      body: const Center(
        child: Text('My Location screen coming soon.'),
      ),
    );
  }
}
