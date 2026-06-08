import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptExtractionResult {
  final String imagePath;
  final String rawText;
  final double? amount;
  final String? merchant;
  final DateTime? date;

  ReceiptExtractionResult({
    required this.imagePath,
    required this.rawText,
    required this.amount,
    required this.merchant,
    required this.date,
  });
}

class ReceiptService {
  Future<ReceiptExtractionResult> extractReceiptDetails(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(File(imagePath).path);
      final recognizedText = await recognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      return ReceiptExtractionResult(
        imagePath: imagePath,
        rawText: rawText,
        amount: _extractAmount(rawText),
        merchant: _extractMerchant(rawText),
        date: _extractDate(rawText),
      );
    } finally {
      await recognizer.close();
    }
  }

  double? _extractAmount(String text) {
    final matches = RegExp(
      r'(?<!\d)(?:[$€£]\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})|\d+(?:[.,]\d{2}))',
    ).allMatches(text);

    final amounts = <double>[];

    for (final match in matches) {
      final amountText = match.group(1);
      if (amountText == null) {
        continue;
      }

      final parsed = _parseAmount(amountText);
      if (parsed != null) {
        amounts.add(parsed);
      }
    }

    if (amounts.isEmpty) {
      return null;
    }

    amounts.sort();
    return amounts.last;
  }

  double? _parseAmount(String amountText) {
    var normalized = amountText.replaceAll(RegExp(r'\s'), '');

    if (normalized.contains(',') && normalized.contains('.')) {
      if (normalized.lastIndexOf(',') > normalized.lastIndexOf('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      final decimalPart = normalized.split(',').last;
      if (decimalPart.length == 2) {
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    }

    normalized = normalized.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized);
  }

  String? _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      final lowered = line.toLowerCase();
      if (RegExp(r'\d').hasMatch(line)) {
        continue;
      }
      if (lowered.contains('total') ||
          lowered.contains('tax') ||
          lowered.contains('vat') ||
          lowered.contains('change') ||
          lowered.contains('subtotal')) {
        continue;
      }
      if (line.length > 2) {
        return line;
      }
    }

    return null;
  }

  DateTime? _extractDate(String text) {
    final datePatterns = <RegExp>[
      RegExp(r'\b(\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'),
      RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b'),
      RegExp(r'\b(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})\b'),
      RegExp(r'\b([A-Za-z]{3,9}\s+\d{1,2},?\s+\d{2,4})\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final candidate = match.group(1);
        if (candidate != null) {
          final parsed = _parseDateCandidate(candidate);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    return null;
  }

  DateTime? _parseDateCandidate(String candidate) {
    final normalized = candidate.replaceAll(',', '');

    final isoMatch = RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$').firstMatch(normalized);
    if (isoMatch != null) {
      return DateTime(
        int.parse(isoMatch.group(1)!),
        int.parse(isoMatch.group(2)!),
        int.parse(isoMatch.group(3)!),
      );
    }

    final dmyMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$').firstMatch(normalized);
    if (dmyMatch != null) {
      final first = int.parse(dmyMatch.group(1)!);
      final second = int.parse(dmyMatch.group(2)!);
      final year = _normalizeYear(int.parse(dmyMatch.group(3)!));
      return DateTime(year, second, first);
    }

    final monthNameMatch = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})$').firstMatch(normalized);
    if (monthNameMatch != null) {
      return DateTime(
        _normalizeYear(int.parse(monthNameMatch.group(3)!)),
        _monthNumber(monthNameMatch.group(2)!),
        int.parse(monthNameMatch.group(1)!),
      );
    }

    final monthFirstMatch = RegExp(r'^([A-Za-z]{3,9})\s+(\d{1,2})\s+(\d{2,4})$').firstMatch(normalized);
    if (monthFirstMatch != null) {
      return DateTime(
        _normalizeYear(int.parse(monthFirstMatch.group(3)!)),
        _monthNumber(monthFirstMatch.group(1)!),
        int.parse(monthFirstMatch.group(2)!),
      );
    }

    return null;
  }

  int _normalizeYear(int year) {
    if (year < 100) {
      return year + 2000;
    }
    return year;
  }

  int _monthNumber(String month) {
    switch (month.toLowerCase().substring(0, 3)) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 1;
    }
  }
}