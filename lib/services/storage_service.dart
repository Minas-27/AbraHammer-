import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_report.dart';

class StorageService {
  static const String _reportsKey = 'daily_reports';

  static Future<void> saveReports(List<DailyReport> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((report) => report.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));
      print('✅ Saved ${reports.length} reports to storage');
    } catch (e) {
      print('❌ Error saving reports: $e');
    }
  }

  static Future<List<DailyReport>> loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);

      if (reportsJson != null) {
        final List<dynamic> reportsList = jsonDecode(reportsJson);
        final reports = reportsList.map((json) => DailyReport.fromJson(json)).toList();
        print('✅ Loaded ${reports.length} reports from storage');
        return reports;
      }

      print('ℹ️ No reports found in storage');
      return [];
    } catch (e) {
      print('❌ Error loading reports: $e');
      return [];
    }
  }

  // Delete single report
  static Future<void> deleteReport(String reportId) async {
    try {
      final reports = await loadReports();
      final updatedReports = reports.where((report) => report.id != reportId).toList();
      await saveReports(updatedReports);
      print('✅ Deleted report: $reportId');
    } catch (e) {
      print('❌ Error deleting report: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Clear all reports
  static Future<void> clearAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reportsKey);
      print('✅ Cleared all reports from storage');
    } catch (e) {
      print('❌ Error clearing all reports: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Update existing report
  static Future<void> updateReport(DailyReport updatedReport) async {
    try {
      final reports = await loadReports();
      final index = reports.indexWhere((report) => report.id == updatedReport.id);

      if (index != -1) {
        reports[index] = updatedReport;
        await saveReports(reports);
        print('✅ Updated report: ${updatedReport.id}');
      } else {
        print('❌ Report not found for update: ${updatedReport.id}');
      }
    } catch (e) {
      print('❌ Error updating report: $e');
    }
  }
}