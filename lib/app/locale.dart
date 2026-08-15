import 'package:intl/date_symbol_data_local.dart';

/// Loads the Chinese date names used by the expense list and date selectors.
Future<void> initializeAppLocaleData() => initializeDateFormatting('zh_CN');
