List<String> parseContentInput(String raw) {
  return raw
      .split(RegExp(r'[\n,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String formatContentForInput(List<String> content) {
  return content.join('\n');
}
