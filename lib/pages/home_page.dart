import 'package:flutter/material.dart';
import 'add_report_page.dart';
import 'view_report_page.dart';
import 'analytics_page.dart';
import '../models/daily_report.dart';
import '../services/storage_service.dart';
import '../services/dialog_service.dart';
import '../widgets/report_card.dart';
import '../widgets/search_delegate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DailyReport> reports = [];
  List<DailyReport> filteredReports = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  final List<String> categories = [
    'All', 'Work', 'Personal', 'Study', 'Health', 'General'
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final loadedReports = await StorageService.loadReports();
    setState(() {
      reports = loadedReports;
      _filterReports();
    });
  }

  Future<void> _saveReports() async {
    await StorageService.saveReports(reports);
  }

  void _filterReports() {
    List<DailyReport> result = reports;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((report) =>
      report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.tasks.any((task) => task.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          report.challenges.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.achievements.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      result = result.where((report) => report.category == _selectedCategory).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      result = result.where((report) => report.isFavorite).toList();
    }

    setState(() {
      filteredReports = result;
    });
  }

  // Delete single report
  Future<void> _deleteReport(String reportId) async {
    final report = reports.firstWhere((r) => r.id == reportId);
    final shouldDelete = await DialogService.showDeleteConfirmationDialog(context, report.title);

    if (shouldDelete) {
      try {
        await StorageService.deleteReport(reportId);
        await _loadReports(); // Reload from storage
        DialogService.showSuccessSnackBar(context, 'Report deleted successfully');
      } catch (e) {
        DialogService.showErrorSnackBar(context, 'Failed to delete report: $e');
      }
    }
  }

  // Clear all reports
  Future<void> _clearAllReports() async {
    if (reports.isEmpty) {
      DialogService.showErrorSnackBar(context, 'No reports to delete');
      return;
    }

    final shouldClear = await DialogService.showClearAllConfirmationDialog(context);

    if (shouldClear) {
      try {
        await StorageService.clearAllReports();
        setState(() {
          reports = [];
          filteredReports = [];
        });
        DialogService.showSuccessSnackBar(context, 'All reports cleared successfully');
      } catch (e) {
        DialogService.showErrorSnackBar(context, 'Failed to clear reports: $e');
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filterReports();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filterReports();
    });
  }

  void _onFavoriteToggle() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      _filterReports();
    });
  }

  void _toggleReportFavorite(String reportId) {
    setState(() {
      final index = reports.indexWhere((report) => report.id == reportId);
      if (index != -1) {
        reports[index] = reports[index].copyWith(isFavorite: !reports[index].isFavorite);
        _filterReports();
        _saveReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayReports = _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showFavoritesOnly
        ? filteredReports
        : reports.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Daily Reports',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black,
        actions: [
          // Analytics
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsPage(reports: reports),
                ),
              );
            },
          ),
          // Favorites filter
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showFavoritesOnly ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _showFavoritesOnly ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
            onPressed: _onFavoriteToggle,
          ),
          // Search
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ReportSearchDelegate(reports),
              ).then((value) {
                if (value != null) {
                  _onSearch(value);
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Clear All Floating Button
          if (reports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                onPressed: _clearAllReports,
                heroTag: 'clear_all',
                mini: true,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: const Icon(Icons.delete_forever_rounded),
              ),
            ),
          // Main Add Button
          FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddReportPage()),
              );
              if (result != null && result is DailyReport) {
                setState(() {
                  reports.add(result);
                });
                await _saveReports();
                _filterReports();
              }
            },
            heroTag: 'add_report',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) => _onCategoryChanged(category),
                    checkmarkColor: Colors.white,
                    selectedColor: Colors.blue[700],
                    backgroundColor: Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),
          // Stats Summary
          if (reports.isNotEmpty) _buildStatsSummary(),
          // Reports List or Empty State
          Expanded(
            child: displayReports.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayReports.length,
              itemBuilder: (context, index) {
                final report = displayReports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ReportCard(
                    report: report,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewReportPage(report: report),
                        ),
                      );
                    },
                    onFavoriteToggle: () => _toggleReportFavorite(report.id),
                    onDelete: () => _deleteReport(report.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final totalReports = reports.length;
    final completedTasks = reports.fold(0, (sum, report) => sum + report.tasks.length);
    final favoriteReports = reports.where((report) => report.isFavorite).length;
    final totalProductivityScore = reports.fold(0, (sum, report) => sum + report.productivityScore);
    final averageScore = reports.isEmpty ? 0 : totalProductivityScore / reports.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Reports', totalReports.toString(), Icons.description_rounded),
          _buildStatItem('Tasks', completedTasks.toString(), Icons.checklist_rounded),
          _buildStatItem('Favorites', favoriteReports.toString(), Icons.favorite_rounded),
          _buildStatItem('Avg Score', averageScore.toStringAsFixed(1), Icons.insights_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.blue[900],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 60,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showFavoritesOnly
                ? 'No Reports Found'
                : 'No Reports Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showFavoritesOnly
                ? 'Try adjusting your filters or create a new report'
                : 'Start tracking your daily progress and achievements',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (!_searchQuery.isNotEmpty && _selectedCategory == 'All' && !_showFavoritesOnly)
            Container(
              width: 200,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create First Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddReportPage()),
                  );
                  if (result != null && result is DailyReport) {
                    setState(() {
                      reports.add(result);
                    });
                    await _saveReports();
                    _filterReports();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}