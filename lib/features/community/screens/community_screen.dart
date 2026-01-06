import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choyxona (Forum)")),
      body: const Center(
        child: Text("Forum va Munozaralar (Tez Orada)"),
      ),
    );
  }
}
