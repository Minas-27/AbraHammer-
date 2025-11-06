import 'package:flutter/material.dart';
import '../models/daily_report.dart';

class ReportCard extends StatelessWidget {
  final DailyReport report;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(report.category),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(report.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.tasks.length} tasks completed',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (report.category != 'General')
              Chip(
                label: Text(
                  report.category,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _getCategoryColor(report.category),
                visualDensity: VisualDensity.compact,
              ),
            if (report.aiEnhancedSummary != null)
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'AI Enhanced',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite button
            if (onFavoriteToggle != null)
              IconButton(
                icon: Icon(
                  report.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: report.isFavorite ? Colors.red : Colors.grey,
                  size: 20,
                ),
                onPressed: onFavoriteToggle,
              ),
            // Delete button
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.blue.shade700;
      case 'Personal':
        return Colors.green.shade700;
      case 'Study':
        return Colors.orange.shade700;
      case 'Health':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.work;
      case 'Personal':
        return Icons.person;
      case 'Study':
        return Icons.school;
      case 'Health':
        return Icons.favorite;
      default:
        return Icons.description;
    }
  }
}