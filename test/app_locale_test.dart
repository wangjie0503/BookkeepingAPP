import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personal_bookkeeping/app/locale.dart';

void main() {
  test(
    'initializes Chinese locale data used by expense date headings',
    () async {
      await initializeAppLocaleData();

      expect(
        DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime(2026, 8, 15)),
        contains('2026年8月15日'),
      );
    },
  );
}
