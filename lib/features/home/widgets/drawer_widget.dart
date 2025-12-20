import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryBlue),
            accountName: Text("Talaba"),
            accountEmail: Text("Student Portal"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primaryBlue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Sozlamalar"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Yordam"),
            onTap: () {},
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Chiqish", style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
