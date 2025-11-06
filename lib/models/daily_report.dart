import 'dart:convert';

class DailyReport {
  final String id;
  final DateTime date;
  final String title;
  final List<String> tasks;
  final String challenges;
  final String achievements;
  final String? aiEnhancedSummary;
  final String? aiSuggestions;
  final List<String> tags;
  final bool isFavorite;
  final String category;
  final int productivityScore;

  DailyReport({
    required this.id,
    required this.date,
    required this.title,
    required this.tasks,
    required this.challenges,
    required this.achievements,
    this.aiEnhancedSummary,
    this.aiSuggestions,
    this.tags = const [],
    this.isFavorite = false,
    this.category = 'General',
    this.productivityScore = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'tasks': tasks,
      'challenges': challenges,
      'achievements': achievements,
      'aiEnhancedSummary': aiEnhancedSummary,
      'aiSuggestions': aiSuggestions,
      'tags': tags,
      'isFavorite': isFavorite,
      'category': category,
      'productivityScore': productivityScore,
    };
  }

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      tasks: List<String>.from(json['tasks']),
      challenges: json['challenges'],
      achievements: json['achievements'],
      aiEnhancedSummary: json['aiEnhancedSummary'],
      aiSuggestions: json['aiSuggestions'],
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      category: json['category'] ?? 'General',
      productivityScore: json['productivityScore'] ?? 0,
    );
  }

  DailyReport copyWith({
    String? id,
    DateTime? date,
    String? title,
    List<String>? tasks,
    String? challenges,
    String? achievements,
    String? aiEnhancedSummary,
    String? aiSuggestions,
    List<String>? tags,
    bool? isFavorite,
    String? category,
    int? productivityScore,
  }) {
    return DailyReport(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      challenges: challenges ?? this.challenges,
      achievements: achievements ?? this.achievements,
      aiEnhancedSummary: aiEnhancedSummary ?? this.aiEnhancedSummary,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      productivityScore: productivityScore ?? this.productivityScore,
    );
  }
}