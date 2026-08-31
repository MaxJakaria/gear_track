import 'package:equatable/equatable.dart';

/// Entity representing Character-to-Digit mapping for Cost Codes (0-9).
/// Supports alphabetic characters, digits, and special characters (e.g. @, #, *, !, -, _, +, %, etc.).
class CostCodeMapping extends Equatable {
  /// Map of character -> digit (0 to 9)
  /// e.g. {'B': 1, 'L': 2, '@': 3, '#': 4, '*': 5, 'S': 6, 'M': 7, '!': 8, 'T': 9, 'H': 0}
  final Map<String, int> charToDigit;

  const CostCodeMapping({required this.charToDigit});

  /// Default 10-character keyword mapping (BLACKSMITH -> 1234567890)
  factory CostCodeMapping.defaultMapping() {
    return const CostCodeMapping(
      charToDigit: {
        'B': 1,
        'L': 2,
        'A': 3,
        'C': 4,
        'K': 5,
        'S': 6,
        'M': 7,
        'I': 8,
        'T': 9,
        'H': 0,
      },
    );
  }

  /// Create from a raw 10-character keyword/phrase (including special characters, symbols, and letters)
  factory CostCodeMapping.fromKeyword(String keyword) {
    // Only strip whitespace; allow all symbols and characters
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
  /// Example: With {'@': 1, 'A': 3, '*': 9}, '@A*' -> '139' -> 139.0
  /// Supports direct numeric digits and decimals (e.g. '@A*.5' -> 139.5)
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

  /// Get the character assigned to a specific digit (0-9)
  String getCharForDigit(int digit) {
    for (final entry in charToDigit.entries) {
      if (entry.value == digit) return entry.key;
    }
    return '';
  }

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
