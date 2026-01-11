import 'dart:convert';

class QuickPrompt {
  final String id; // uuid or timestamp-based
  String title;
  String prompt;
  List<String> tags;
  String? color; // optional hex like #4285F4

  QuickPrompt({
    required this.id,
    required this.title,
    required this.prompt,
    List<String>? tags,
    this.color,
  }) : tags = tags ?? [];

  factory QuickPrompt.fromMap(Map<String, dynamic> map) => QuickPrompt(
    id: map['id'] as String,
    title: map['title'] as String? ?? '',
    prompt: map['prompt'] as String? ?? '',
    tags:
        (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    color: (map['color'] ?? map['colorHex']) as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'prompt': prompt,
    'tags': tags,
    if (color != null) 'color': color,
  };

  static List<QuickPrompt> decodeList(String jsonStr) {
    try {
      final list = json.decode(jsonStr) as List<dynamic>;
      return list
          .map((e) => QuickPrompt.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<QuickPrompt> list) =>
      json.encode(list.map((e) => e.toMap()).toList());
}
