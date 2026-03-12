import 'package:flutter/material.dart';

String safeOptionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '' : trimmed;
}

String safeVarietyName(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Unbenannte Sorte' : trimmed;
}

String normalizedText(String? value) => safeOptionalText(value).toLowerCase();

String codeLabel(int? number) {
  if (number == null || number <= 0) return '—';
  return number.toString();
}

Widget buildEmptyState(
  BuildContext context, {
  String message = 'Keine Treffer',
}) {
  return Center(
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
    ),
  );
}
