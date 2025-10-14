// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../utils/settings.dart';
import 'call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  RoleOptions _role = RoleOptions.Broadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Channel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          children: [
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                hintText: 'Channel name',
                errorText: _validateError ? 'Channel name is mandatory' : null,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Broadcaster'),
              leading: Radio<RoleOptions>(
                value: RoleOptions.Broadcaster,
                groupValue: _role,
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Audience'),
              leading: Radio<RoleOptions>(
                value: RoleOptions.Audience,
                groupValue: _role,
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _channelController.text.isEmpty
                      ? _validateError = true
                      : _validateError = false;
                });

                if (_channelController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CallPage(
                            channelName: _channelController.text,
                            role: _role,
                          ),
                    ),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
