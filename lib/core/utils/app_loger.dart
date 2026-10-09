import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

final _logger = TalkerFlutter.init(
  settings: TalkerSettings(enabled: kDebugMode),
);

class _Log {
  final Talker logger;

  _Log(this.logger);

  void d(String message) {
    if (kDebugMode) logger.debug(message);
  }

  void i(String message) {
    if (kDebugMode) logger.info(message);
  }

  void w(String message) {
    if (kDebugMode) logger.warning(message);
  }

  void e(String message) {
    if (kDebugMode) logger.error(message);
  }

  void c(String message) {
    if (kDebugMode) logger.critical(message);
  }

  void v(String message) {
    if (kDebugMode) logger.verbose(message);
  }
}

final myLog = _Log(_logger);
