import 'package:flutter/material.dart';
import '../models/daily_report.dart';
import '../services/ai_service.dart';

class AddReportPage extends StatefulWidget {
  const AddReportPage({super.key});

  @override
  State<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tasksController = TextEditingController();
  final _challengesController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isGeneratingAI = false;
  String _aiStatus = '';
  String _selectedCategory = 'General';
  final List<String> _tags = [];

  final List<String> _availableCategories = [
    'Work',
    'Personal',
    'Study',
    'Health',
    'General'
  ];

  List<String> get tasksList => _tasksController.text
      .split('\n')
      .where((task) => task.trim().isNotEmpty)
      .toList();

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _generateAIEnhancement() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGeneratingAI = true;
        _aiStatus = 'Connecting to AI...';
      });

      final reportContent = '''
Title: ${_titleController.text}
Category: $_selectedCategory
Tasks: ${tasksList.join(', ')}
Challenges: ${_challengesController.text}
Achievements: ${_achievementsController.text}
Tags: ${_tags.join(', ')}
''';

      try {
        setState(() {
          _aiStatus = 'Analyzing your report...';
        });

        final aiResponse = await AIService.enhanceReportWithAI(reportContent);

        if (mounted) {
          setState(() {
            _aiStatus = 'Processing response...';
          });

          if (aiResponse != null) {
            final (summary, achievements, suggestions) =
            AIService.parseAIResponse(aiResponse);

            // Create report with AI enhancements
            final report = DailyReport(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              date: DateTime.now(),
              title: _titleController.text,
              tasks: tasksList,
              challenges: _challengesController.text,
              achievements: _achievementsController.text,
              aiEnhancedSummary: summary,
              aiSuggestions: suggestions,
              tags: _tags,
              category: _selectedCategory,
              productivityScore: _calculateProductivityScore(),
            );

            Navigator.pop(context, report);
          } else {
            setState(() {
              _aiStatus = 'AI service unavailable. Saving without AI...';
            });
            await Future.delayed(const Duration(seconds: 1));
            _saveWithoutAI();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _aiStatus = 'Error: $e. Saving without AI...';
          });
          await Future.delayed(const Duration(seconds: 2));
          _saveWithoutAI();
        }
      }
    }
  }

  int _calculateProductivityScore() {
    int score = tasksList.length * 2;
    if (_challengesController.text.isNotEmpty) score += 1;
    if (_achievementsController.text.isNotEmpty) score += 2;
    if (_tags.isNotEmpty) score += 1;
    return score.clamp(0, 10);
  }

  void _saveWithoutAI() {
    final report = DailyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: _titleController.text,
      tasks: tasksList,
      challenges: _challengesController.text,
      achievements: _achievementsController.text,
      tags: _tags,
      category: _selectedCategory,
      productivityScore: _calculateProductivityScore(),
    );
    Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'New Daily Report',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isGeneratingAI)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[700],
                ),
              ),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title Field
              _buildModernTextField(
                controller: _titleController,
                label: 'Report Title *',
                icon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: InputBorder.none,
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(_selectedCategory),
                        color: _getCategoryColor(_selectedCategory),
                        size: 20,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _availableCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            category,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),

              // Tasks Field
              _buildModernTextField(
                controller: _tasksController,
                label: 'Tasks Completed',
                icon: Icons.checklist_rounded,
                maxLines: 4,
                hintText: 'Enter each task on a new line...',
              ),
              const SizedBox(height: 20),

              // Challenges Field
              _buildModernTextField(
                controller: _challengesController,
                label: 'Challenges Faced',
                icon: Icons.warning_rounded,
                maxLines: 3,
                hintText: 'What challenges did you face today?',
              ),
              const SizedBox(height: 20),

              // Achievements Field
              _buildModernTextField(
                controller: _achievementsController,
                label: 'Key Achievements',
                icon: Icons.emoji_events_rounded,
                maxLines: 3,
                hintText: 'What are you proud of accomplishing today?',
              ),
              const SizedBox(height: 20),

              // Tags Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add relevant tags to categorize your report',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags Input Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                hintText: 'Enter a tag...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onFieldSubmitted: (value) => _addTag(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addTag,
                          child: Container(
                            width: 50,
                            height: 50,
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
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Tags Display
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[50]!, Colors.blue[100]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeTag(tag),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.blue[800],
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Status
              if (_aiStatus.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _aiStatus.contains('Error')
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _aiStatus.contains('Error')
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _aiStatus.contains('Error')
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _aiStatus.contains('Error')
                              ? Icons.error_outline_rounded
                              : Icons.auto_awesome_rounded,
                          color: _aiStatus.contains('Error')
                              ? Colors.red
                              : Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _aiStatus,
                          style: TextStyle(
                            color: _aiStatus.contains('Error')
                                ? Colors.red.shade800
                                : Colors.blue.shade800,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_aiStatus.isNotEmpty) const SizedBox(height: 16),

              // Action Buttons
              Column(
                children: [
                  // AI Generate Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isGeneratingAI ? null : _generateAIEnhancement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isGeneratingAI
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Generating AI Insights...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Generate with AI ✨',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save without AI Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: _isGeneratingAI ? null : _saveWithoutAI,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide.none,
                      ),
                      child: const Text(
                        'Save without AI',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Helper methods for category icons and colors
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Study':
        return Icons.school_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.blue;
      case 'Personal':
        return Colors.green;
      case 'Study':
        return Colors.orange;
      case 'Health':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tasksController.dispose();
    _challengesController.dispose();
    _achievementsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}