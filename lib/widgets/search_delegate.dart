import 'package:flutter/material.dart';
import '../models/daily_report.dart';
import '../pages/view_report_page.dart';

class ReportSearchDelegate extends SearchDelegate<String> {
  final List<DailyReport> reports;

  ReportSearchDelegate(this.reports);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = reports.where((report) =>
    report.title.toLowerCase().contains(query.toLowerCase()) ||
        report.tasks.any((task) => task.toLowerCase().contains(query.toLowerCase())) ||
        report.challenges.toLowerCase().contains(query.toLowerCase()) ||
        report.achievements.toLowerCase().contains(query.toLowerCase()) ||
        report.category.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final report = results[index];
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(report.title),
          subtitle: Text('${report.tasks.length} tasks • ${report.category}'),
          onTap: () {
            close(context, query);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewReportPage(report: report),
              ),
            );
          },
        );
      },
    );
  }
}