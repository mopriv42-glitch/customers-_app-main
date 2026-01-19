import 'package:flutter/material.dart';

// 1. Define a class to hold subject information
class SubjectInfo {
  final List<String> keywords; // List of keywords associated with this subject
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  SubjectInfo({
    required this.keywords,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

// 2. Create the lookup list with subject data
// We use lowercase keywords for easier matching
List<SubjectInfo> subjectDatabase = [
  SubjectInfo(
    keywords: ['رياضيات', 'math', 'mathematics', 'حساب', 'جبر', 'هندسة'],
    icon: Icons.functions,
    iconColor: const Color(0xFF1BA39C),
    backgroundColor: const Color(0xFF1BA39C).withOpacity(0.1),
  ),
  SubjectInfo(
    keywords: ['علوم', 'science', 'فيزياء', 'كيمياء', 'أحياء'], // Include specific sciences here too
    icon: Icons.science,
    iconColor: const Color(0xFFFFB547),
    backgroundColor: const Color(0xFFFFB547).withOpacity(0.1),
  ),
  SubjectInfo(
    keywords: ['لغة عربية', 'arabic', ' litterature'],
    icon: Icons.menu_book,
    iconColor: const Color(0xFF482099),
    backgroundColor: const Color(0xFF482099).withOpacity(0.1),
  ),
  SubjectInfo(
    keywords: ['لغة إنجليزية', 'english', 'language'],
    icon: Icons.language,
    iconColor: const Color(0xFF8C6042),
    backgroundColor: const Color(0xFF8C6042).withOpacity(0.1),
  ),
  SubjectInfo(
    keywords: ['فيزياء', 'physics'],
    icon: Icons.bolt,
    iconColor: const Color(0xFFDC3545),
    backgroundColor: const Color(0xFFDC3545).withOpacity(0.1),
  ),
  SubjectInfo(
    keywords: ['كيمياء', 'chemistry'],
    icon: Icons.science_outlined,
    iconColor: const Color(0xFF28A745),
    backgroundColor: const Color(0xFF28A745).withOpacity(0.1),
  ),
  // Add more subjects as needed...
  // Example for a fallback or unknown subject:
  SubjectInfo(
    keywords: [], // Empty keywords means it's a fallback
    icon: Icons.help_outline,
    iconColor: Colors.grey,
    backgroundColor: Colors.grey.withOpacity(0.1),
  ),
];

// 3. Implement the matching function
SubjectInfo? getSubjectInfo(String inputSubjectName) {
  if (inputSubjectName.isEmpty) {
    // Return fallback or null for empty input
    return subjectDatabase.lastWhere((subject) => subject.keywords.isEmpty, orElse: () => subjectDatabase.first); // Or return null;
  }

  // Normalize the input: trim whitespace and convert to lowercase
  String normalizedInput = inputSubjectName.trim().toLowerCase();

  // 1. Try exact match first (against keywords)
  for (var subjectInfo in subjectDatabase) {
    for (var keyword in subjectInfo.keywords) {
      if (keyword.toLowerCase() == normalizedInput) {
        return subjectInfo;
      }
    }
  }

  // 2. Try 'contains' match (against keywords)
  for (var subjectInfo in subjectDatabase) {
    // Skip the fallback entry for contains check if it has no keywords
    if (subjectInfo.keywords.isEmpty) continue;

    for (var keyword in subjectInfo.keywords) {
      // Check if the normalized input contains the keyword
      // Or if the keyword contains part of the normalized input (bi-directional contains can help)
      if (normalizedInput.contains(keyword.toLowerCase()) || keyword.toLowerCase().contains(normalizedInput)) {
        return subjectInfo;
      }
    }
  }

  // 3. If no match found, return the fallback subject (assuming the last one with empty keywords is the fallback)
  try {
    return subjectDatabase.lastWhere((subject) => subject.keywords.isEmpty);
  } catch (e) {
    // If no explicit fallback is defined, return the first subject or null
    return subjectDatabase.isNotEmpty ? subjectDatabase.first : null;
  }
}
