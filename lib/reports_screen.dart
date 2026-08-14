import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

/// شاشة التقارير — تاخذ قائمة العمليات الحقيقية وتبني منها
/// توزيع الإنفاق حسب التصنيف (Pie Chart) باستخدام fl_chart
/// المكتبة كانت مستوردة أصلاً بـ main.dart لكن غير مستخدمة — الحين تُستخدم فعليًا
class ReportsScreen extends StatelessWidget {
  final List<Expense> expenses;
  const ReportsScreen({super.key, required this.expenses});

  Map<String, double> get _byCategory {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  static const List<Color> _palette = [
    Colors.teal, Colors.purple, Colors.orange, Colors.redAccent,
    Colors.blue, Colors.green, Colors.amber, Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final data = _byCategory;
    final total = data.values.fold(0.0, (a, b) => a + b);

    if (expenses.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات كافية لعرض تقرير بعد', style: TextStyle(color: Colors.grey)),
      );
    }

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('التقارير', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: [
                  for (int i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value,
                      title: '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                      color: _palette[i % _palette.length],
                      radius: 70,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('الإنفاق حسب التصنيف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: _palette[i % _palette.length], radius: 8),
                title: Text(entries[i].key),
                trailing: Text('${entries[i].value.toStringAsFixed(2)} SAR',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _palette[i % _palette.length])),
              ),
            ),
        ],
      ),
    );
  }
}
