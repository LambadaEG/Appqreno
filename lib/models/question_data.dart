import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'models.dart';

class QuestionData {
  static const String googleSheetsUrl =
      'https://docs.google.com/spreadsheets/d/14eVxy56895HpboFqUYAKS4lKm6Q8XYYmZdXkTVCxjVE/export?format=csv&gid=0';

  /// Fetch and parse all questions from Google Sheets
  static Future<Map<String, List<Question>>> loadQuestionsFromSheet() async {
    try {
      final response = await http.get(Uri.parse(googleSheetsUrl));

      if (response.statusCode == 200) {
        // ✅ Force UTF-8 decoding for Arabic
        final csvData = utf8.decode(response.bodyBytes);
        return _parseCSV(csvData);
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching questions: $e');
      rethrow;
    }
  }

  /// Parse CSV into a map of category -> list of questions
  static Map<String, List<Question>> _parseCSV(String csvData) {
    final lines = csvData.split('\n');
    final questionsByCategory = <String, List<Question>>{};

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _parseCSVLine(line);

      if (values.length >= 6) {
        final category = values[0].trim();
        final questionText = values[1].trim();
        final correctAnswer = values[2].trim();

        final options = [
          values[2].trim(),
          values[3].trim(),
          values[4].trim(),
          values[5].trim(),
        ];

        // Ensure unique 4 options
        final uniqueOptions = options.toSet().toList();
        while (uniqueOptions.length < 4) {
          uniqueOptions.add('خيار ${uniqueOptions.length + 1}');
        }
        uniqueOptions.shuffle();

        final question = Question(
          category: category,
          text: questionText,
          correctAnswer: correctAnswer,
          options: uniqueOptions,
        );

        questionsByCategory.putIfAbsent(category, () => []);
        questionsByCategory[category]!.add(question);
      }
    }

    return questionsByCategory;
  }

  /// Handle CSV rows with quotes + commas
  static List<String> _parseCSVLine(String line) {
    final result = <String>[];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current);
    return result;
  }

  /// Returns a set of questions for the selected main category
  static List<Question> getQuestionsForMainCategory(
    String mainCategory,
    Map<String, List<Question>> allQuestionsByCategory,
  ) {
    final Map<String, List<String>> categoryMapping = {
      'العلم': ['جغرافيا', 'تاريخ', 'أدب', 'علوم'],
      'المعرفة': ['معلومات عامة', 'رياضة', 'تكنولوجيا', 'قدرات ذهنية'],
      'الفنون': ['سينما و مسرح', 'اغاني و موسيقى', 'لوحات و معالم', 'سرعة البديهة'],
      'عجلة الحظ': [], // Empty now - handled by wheel
    };

    // Remove the special case for "عجلة الحظ" since it's handled by the wheel screen

    final subcategories = categoryMapping[mainCategory] ?? [];
    final questions = <Question>[];

    for (final subcategory in subcategories) {
      final question = _getRandomQuestion(subcategory, allQuestionsByCategory);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }
  /// Picks a random question from a category
  static Question? _getRandomQuestion(
    String subcategory,
    Map<String, List<Question>> allQuestionsByCategory,
  ) {
    final categoryQuestions = allQuestionsByCategory[subcategory];

    if (categoryQuestions == null || categoryQuestions.isEmpty) {
      // ignore: avoid_print
      print('⚠️ No questions found for category: $subcategory');
      return null;
    }

    final random = Random();
    return categoryQuestions[random.nextInt(categoryQuestions.length)];
  }
  static List<Question> getCustomQuestions(
    List<String> selectedSubcategories,
    Map<String, List<Question>> allQuestionsByCategory,
    int totalNeeded,
  ) {
    List<Question> result = [];
    if (selectedSubcategories.isEmpty) return [];

    int questionsPerCat = (totalNeeded / selectedSubcategories.length).floor();
    final random = Random();

    for (var sub in selectedSubcategories) {
      var available = allQuestionsByCategory[sub] ?? [];
      List<Question> shuffled = List.from(available)..shuffle();
      result.addAll(shuffled.take(questionsPerCat));
    }

    // If there's a remainder (e.g., 16/3 = 5 per cat, 1 left), fill it up
    while (result.length < totalNeeded) {
      String randomSub = selectedSubcategories[random.nextInt(selectedSubcategories.length)];
      var extra = _getRandomQuestion(randomSub, allQuestionsByCategory);
      if (extra != null) result.add(extra);
    }

    result.shuffle(); // Shuffle the final 16 questions
    return result;
  }

}