import 'package:flutter/material.dart';
// Shared models for the entire app
class Category {
  final String name;
  final Color color;
  final IconData icon;
  final String description;

  const Category({
    required this.name,
    required this.color,
    required this.icon,
    required this.description,
  });
}

class Question {
  final String category;
  final String text;
  final String correctAnswer;
  final List<String> options;

  const Question({
    required this.category,
    required this.text,
    required this.correctAnswer,
    required this.options,
  });

  int get correctAnswerIndex {
    return options.indexOf(correctAnswer);
  }

  String get categoryType => category;
}