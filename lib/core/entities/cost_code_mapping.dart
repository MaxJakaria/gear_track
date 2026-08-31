import 'package:equatable/equatable.dart';

/// Entity representing Character-to-Digit mapping for Cost Codes (0-9).
/// Supports multiple characters/symbols per digit (e.g. A, @ -> 3; S, $ -> 6; C, # -> 4, etc.).
class CostCodeMapping extends Equatable {
  /// Map of character -> digit (0 to 9)
  /// e.g. {'B': 1, 'L': 2, 'A': 3, '@': 3, 'C': 4, '#': 4, 'K': 5, 'S': 6, '$': 6, 'M': 7, 'I': 8, '!': 8, 'T': 9, 'H': 0}
  final Map<String, int> charToDigit;

  const CostCodeMapping({required this.charToDigit});

  /// Default 10-character keyword mapping with common symbol aliases
  factory CostCodeMapping.defaultMapping() {
    return const CostCodeMapping(
      charToDigit: {
        'B': 1,
        'L': 2,
        'A': 3,
        '@': 3,
        'C': 4,
        '#': 4,
        'K': 5,
        'S': 6,
        r'$': 6,
        'M': 7,
        'I': 8,
        '!': 8,
        'T': 9,
        'H': 0,
      },
    );
  }

  /// Create from a raw 10-character keyword/phrase
  factory CostCodeMapping.fromKeyword(String keyword) {
    final clean = keyword.trim().replaceAll(RegExp(r'\s+'), '');
    final map = <String, int>{};
    for (int i = 0; i < clean.length && i < 10; i++) {
      final digit = (i + 1) % 10; // 0th -> 1, 1st -> 2, ... 8th -> 9, 9th -> 0
      final char = clean[i].toUpperCase();
      map[char] = digit;
    }
    return CostCodeMapping(charToDigit: map);
  }

  /// Decodes an encrypted cost code string (with letters, special characters, or numbers) into a numeric value.
  /// Example: With {'@': 3, 'A': 3, 'B': 1, 'T': 9}, 'BL@CK' -> '12345' -> 12345.0
  double decode(String costCode) {
    if (costCode.trim().isEmpty) return 0.0;

    final buffer = StringBuffer();
    final raw = costCode.trim();

    for (int i = 0; i < raw.length; i++) {
      final char = raw[i];
      final upperChar = char.toUpperCase();

      if (charToDigit.containsKey(char)) {
        buffer.write(charToDigit[char]);
      } else if (charToDigit.containsKey(upperChar)) {
        buffer.write(charToDigit[upperChar]);
      } else if (RegExp(r'[0-9.]').hasMatch(char)) {
        buffer.write(char);
      }
    }

    final decodedStr = buffer.toString();
    if (decodedStr.isEmpty) return 0.0;
    return double.tryParse(decodedStr) ?? 0.0;
  }

  /// Get all characters assigned to a specific digit (0-9), e.g. "A, @" or "S, $"
  String getCharsForDigit(int digit, {String separator = ', '}) {
    final chars = <String>[];
    for (final entry in charToDigit.entries) {
      if (entry.value == digit && !chars.contains(entry.key)) {
        chars.add(entry.key);
      }
    }
    return chars.join(separator);
  }

  /// Alias for backward compatibility
  String getCharForDigit(int digit) => getCharsForDigit(digit);

  Map<String, dynamic> toMap() {
    return charToDigit.map((key, value) => MapEntry(key, value));
  }

  factory CostCodeMapping.fromMap(Map<String, dynamic> map) {
    final converted = <String, int>{};
    map.forEach((key, value) {
      if (value is int) {
        converted[key.toUpperCase()] = value;
      } else if (value is num) {
        converted[key.toUpperCase()] = value.toInt();
      }
    });

    if (converted.isEmpty) {
      return CostCodeMapping.defaultMapping();
    }
    return CostCodeMapping(charToDigit: converted);
  }

  @override
  List<Object?> get props => [charToDigit];
}
