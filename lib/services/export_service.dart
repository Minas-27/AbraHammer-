import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/daily_report.dart';

class ExportService {
  static Future<void> exportToTextFile(DailyReport report, BuildContext context) async {
    try {
      final String content = _generateReportContent(report);

      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        _showErrorDialog(context, 'Cannot access downloads directory');
        return;
      }

      // Create filename with timestamp
      final timestamp = _formatTimestamp(report.date);
      final filename = 'DailyReport_${report.title}_$timestamp.txt';
      final file = File('${directory.path}/$filename');

      // Write file
      await file.writeAsString(content);

      _showSuccessDialog(context, filename, file.path, report);

    } catch (e) {
      _showErrorDialog(context, 'Failed to export: $e');
    }
  }

  static String _generateReportContent(DailyReport report) {
    return '''
DAILY REPORT
============

Title: ${report.title}
Date: ${_formatDate(report.date)}
Category: ${report.category}
Productivity Score: ${report.productivityScore}/10
${report.tags.isNotEmpty ? 'Tags: ${report.tags.join(', ')}' : ''}

TASKS COMPLETED:
${report.tasks.map((task) => '• $task').join('\n')}

${report.challenges.isNotEmpty ? 'CHALLENGES:\n${report.challenges}\n' : ''}
${report.achievements.isNotEmpty ? 'ACHIEVEMENTS:\n${report.achievements}\n' : ''}
${report.aiEnhancedSummary != null ? 'AI SUMMARY:\n${report.aiEnhancedSummary}\n' : ''}
${report.aiSuggestions != null ? 'AI SUGGESTIONS:\n${report.aiSuggestions}' : ''}

--- Generated with Daily Report App ---
''';
  }

  static void _showSuccessDialog(BuildContext context, String filename, String path, DailyReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $filename'),
            const SizedBox(height: 8),
            Text('Location: ${_getShortPath(path)}'),
            const SizedBox(height: 16),
            const Text(
              'The report has been saved to your Downloads folder.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareReportContent(context, _generateReportContent(report));
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Export Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _shareReportContent(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _copyToClipboard(context, content);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  static void _copyToClipboard(BuildContext context, String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  static String _getShortPath(String path) {
    final parts = path.split('/');
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTimestamp(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  // Quick share methods
  static Future<void> shareReport(DailyReport report, BuildContext context) async {
    final content = _generateReportContent(report);
    _shareReportContent(context, content);
  }

  static String getQuickSummary(DailyReport report) {
    return '''
📊 ${report.title}
📅 ${_formatDate(report.date)}
✅ ${report.tasks.length} tasks completed
${report.aiEnhancedSummary != null ? '🤖 ${report.aiEnhancedSummary!.split('.').first}' : ''}
''';
  }
}