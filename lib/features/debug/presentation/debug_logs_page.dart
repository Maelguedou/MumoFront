import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme_colors.dart';

class DebugLogsPage extends StatefulWidget {
  const DebugLogsPage({super.key});

  @override
  State<DebugLogsPage> createState() => _DebugLogsPageState();
}

class _DebugLogsPageState extends State<DebugLogsPage> {
  late Future<List<String>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = AppLogger.getLogs();
  }

  void _refresh() {
    setState(() {
      _logsFuture = AppLogger.getLogs();
    });
  }

  Future<void> _copyLogs() async {
    final logs = await AppLogger.dump();
    await Clipboard.setData(ClipboardData(text: logs));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copies dans le presse-papiers')),
    );
  }

  Future<void> _clearLogs() async {
    await AppLogger.clear();
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logs effaces')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        foregroundColor: colors.textPrimary,
        title: const Text('Logs de test'),
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Copier',
            onPressed: _copyLogs,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Effacer',
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'Aucun log disponible.',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (context, index) => Divider(color: colors.border),
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index];
              return SelectableText(
                log,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
