import 'package:flutter/material.dart';
import '../../../../core/monitoring/supabase_perf_monitor.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = SupabasePerfMonitor.logs;
    final slow = SupabasePerfMonitor.slowQueries;
    final avgByOp = SupabasePerfMonitor.avgByOperation;

    return Scaffold(
      appBar: AppBar(title: const Text('مراقبة الأداء')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _metricCard(
            'إجمالي العمليات',
            '${logs.length}',
            Icons.analytics,
            Colors.blue,
          ),
          _metricCard(
            'عمليات بطيئة (> 1s)',
            '${slow.length}',
            Icons.warning,
            slow.isEmpty ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text('متوسط الأداء حسب العملية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...avgByOp.entries.map((e) => Card(
            child: ListTile(
              title: Text(e.key),
              subtitle: LinearProgressIndicator(
                value: (e.value / 2000).clamp(0.0, 1.0),
                color: e.value < 500
                    ? Colors.green
                    : e.value < 1000
                    ? Colors.orange
                    : Colors.red,
              ),
              trailing: Text('${e.value}ms'),
            ),
          )),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}