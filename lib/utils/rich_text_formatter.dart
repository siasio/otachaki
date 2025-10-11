import 'package:flutter/material.dart';

/// Utility class for formatting text with markdown-like syntax
class RichTextFormatter {
  /// Create a RichText widget with support for **bold** and *italic* formatting
  ///
  /// Supported syntax:
  /// - **text** for bold formatting
  /// - *text* for italic formatting
  /// - Can be combined: ***text*** for bold italic
  ///
  /// Example:
  /// ```dart
  /// RichTextFormatter.format(
  ///   'This is **bold** and this is *italic* text',
  ///   style: TextStyle(fontSize: 16),
  /// )
  /// ```
  static Widget format(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final spans = _parseText(text, style ?? const TextStyle());

    return RichText(
      text: TextSpan(
        style: style,
        children: spans,
      ),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  /// Parse text and return list of TextSpans with formatting applied
  static List<TextSpan> _parseText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    // Combined regex for both bold (**text**) and italic (*text*) patterns
    // This regex handles nested patterns correctly by matching the longest sequences first
    final RegExp combinedPattern = RegExp(r'\*\*\*(.*?)\*\*\*|\*\*(.*?)\*\*|\*(.*?)\*');

    for (final match in combinedPattern.allMatches(text)) {
      // Add normal text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      // Determine the formatting type and add formatted text
      String matchedText;
      TextStyle formattedStyle;

      if (match.group(1) != null) {
        // ***text*** - bold italic
        matchedText = match.group(1)!;
        formattedStyle = baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
      } else if (match.group(2) != null) {
        // **text** - bold
        matchedText = match.group(2)!;
        formattedStyle = baseStyle.copyWith(
          fontWeight: FontWeight.bold,
        );
      } else {
        // *text* - italic
        matchedText = match.group(3)!;
        formattedStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
      }

      spans.add(TextSpan(
        text: matchedText,
        style: formattedStyle,
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining normal text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}