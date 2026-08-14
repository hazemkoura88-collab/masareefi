import 'dart:crypto';
import 'dart:convert';

class TransactionParsed {
  final double amount;
  final String merchant;
  final DateTime date;
  final String cardLast4;
  final String type;
  final String category;
  final String smsHash;

  TransactionParsed({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.cardLast4,
    required this.type,
    required this.category,
    required this.smsHash,
  });
}

class AlRajhiParser {
  static TransactionParsed? parseSMS(String body, DateTime smsTime) {
    if (!body.contains('Ø§Ù„Ø±Ø§Ø¬Ø­ÙŠ') && !body.contains('Ù…Ø¨Ù„Øº') && !body.contains('Ø¨Ø·Ø§Ù‚Ø©')) {
      return null;
    }

    double amount = 0.0;
    String merchant = 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯';
    String cardLast4 = '0000';
    String type = 'Ø´Ø±Ø§Ø¡';

    RegExp amountReg = RegExp(r'(?:Ø¨Ù‚ÙŠÙ…Ø©|Ø¨Ù…Ø¨Ù„Øº)\s+([0-9]+(?:\.[0-9]+)?)\s*(?:SAR|Ø±.Ø³)?');
    var amountMatch = amountReg.firstMatch(body);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
    } else {
      return null;
    }

    RegExp cardReg = RegExp(r'\(([0-9]{4})\)');
    var cardMatch = cardReg.firstMatch(body);
    if (cardMatch != null) {
      cardLast4 = cardMatch.group(1) ?? '0000';
    }

    if (body.contains('Ø´Ø±Ø§Ø¡') || body.contains('Ù…Ø¯Ù‰')) {
      type = 'Ø´Ø±Ø§Ø¡';
      RegExp merchantReg = RegExp(r'Ù„Ø¯Ù‰\s+([^\n\r]+?)(?=\s+ÙÙŠ|\s+Ø¨Ù‚ÙŠÙ…Ø©|\.$|$)');
      var mMatch = merchantReg.firstMatch(body);
      if (mMatch != null) merchant = mMatch.group(1)!.trim();
    } else if (body.contains('Ø³Ø­Ø¨ Ù†Ù‚Ø¯ÙŠ')) {
      type = 'Ø³Ø­Ø¨';
      merchant = 'ØµØ±Ø§Ù Ø¢Ù„ÙŠ';
    } else if (body.contains('ØªØ­ÙˆÙŠÙ„')) {
      type = 'ØªØ­ÙˆÙŠÙ„Ø§Øª';
      merchant = 'ØªØ­ÙˆÙŠÙ„ ØµØ§Ø¯Ø±';
    }

    String category = _categorize(merchant, body);
    String smsHash = md5.convert(utf8.encode(body + smsTime.toString())).toString();

    return TransactionParsed(
      amount: amount,
      merchant: merchant,
      date: smsTime,
      cardLast4: cardLast4,
      type: type,
      category: category,
      smsHash: smsHash,
    );
  }

  static String _categorize(String merchant, String body) {
    String text = (merchant + " " + body).toLowerCase();

    if (text.contains('Ù‚Ù‡ÙˆØ©') || text.contains('ÙƒØ§ÙÙŠÙ‡') || text.contains('starbucks') || text.contains('barns')) return 'Ù‚Ù‡ÙˆØ©';
    if (text.contains('Ù…Ø·Ø¹Ù…') || text.contains('mcdonalds') || text.contains('albaik')) return 'Ù…Ø·Ø§Ø¹Ù…';
    if (text.contains('Ø¨Ù†Ø²ÙŠÙ†') || text.contains('Ø§Ù„Ø¯Ø±ÙŠØ³') || text.contains('Ø³Ø§Ø³ÙƒÙˆ')) return 'Ø¨Ù†Ø²ÙŠÙ†';
    if (text.contains('Ø¨Ù†Ø¯Ø©') || text.contains('Ø§Ù„Ø¹Ø«ÙŠÙ…') || text.contains('Ø³ÙˆØ¨Ø±Ù…Ø§Ø±ÙƒØª')) return 'Ø³ÙˆØ¨Ø± Ù…Ø§Ø±ÙƒØª';
    if (text.contains('ÙØ§ØªÙˆØ±Ø©') || text.contains('stc') || text.contains('Ù…ÙˆØ¨Ø§ÙŠÙ„ÙŠ')) return 'ÙÙˆØ§ØªÙŠØ±';
    if (text.contains('ØªØ­ÙˆÙŠÙ„')) return 'ØªØ­ÙˆÙŠÙ„Ø§Øª';
    if (text.contains('amazon') || text.contains('noon')) return 'ØªØ³ÙˆÙ‚';
    return 'Ø£Ø®Ø±Ù‰';
  }
}