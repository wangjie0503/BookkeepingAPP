/// Money is persisted as an integer number of jiao (角), never a double.
class Money {
  const Money._();

  static int parseJiao(String input) {
    final value = input.trim();
    if (!RegExp(r'^\d+(?:\.\d)?$').hasMatch(value)) {
      throw const FormatException('请输入大于 0 且最多一位小数的金额');
    }
    final pieces = value.split('.');
    final yuan = int.parse(pieces.first);
    final jiao = pieces.length == 2 ? int.parse(pieces.last) : 0;
    final result = yuan * 10 + jiao;
    if (result <= 0) {
      throw const FormatException('金额必须大于 0');
    }
    return result;
  }

  static int? tryParseJiao(String input) {
    try {
      return parseJiao(input);
    } on FormatException {
      return null;
    }
  }

  static int parseNonNegativeJiao(String input) {
    final value = input.trim();
    if (!RegExp(r'^\d+(?:\.\d)?$').hasMatch(value)) {
      throw const FormatException('请输入最多一位小数的金额');
    }
    final pieces = value.split('.');
    return int.parse(pieces.first) * 10 +
        (pieces.length == 2 ? int.parse(pieces.last) : 0);
  }

  static String formatJiao(int jiao, {String symbol = '¥'}) {
    final absolute = jiao.abs();
    final sign = jiao < 0 ? '-' : '';
    final yuan = absolute ~/ 10;
    final decimal = absolute % 10;
    return '$sign$symbol$yuan${decimal == 0 ? '' : '.$decimal'}';
  }
}
