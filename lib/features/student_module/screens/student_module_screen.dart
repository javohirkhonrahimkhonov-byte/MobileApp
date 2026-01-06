import 'package:flutter/material.dart';

class StudentModuleScreen extends StatelessWidget {
  const StudentModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Talaba Moduli")),
      body: const Center(
        child: Text("Yangiliklar, E'lonlar va Market (Tez Orada)"),
      ),
    );
  }
}
