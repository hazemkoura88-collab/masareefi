import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final VoidCallback onBackup;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.onExportExcel,
    required this.onExportPdf,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('الإعدادات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('تغيير المظهر (فاتح/داكن)'),
            onTap: onToggleTheme,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('تصدير Excel'),
            onTap: onExportExcel,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('تصدير / طباعة PDF'),
            onTap: onExportPdf,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('نسخ احتياطي محلي'),
            onTap: onBackup,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
