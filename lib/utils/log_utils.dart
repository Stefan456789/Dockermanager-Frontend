import 'package:flutter/material.dart';

Color getLogColor(String log) {
  if (log.startsWith('>')) {
    return Colors.cyan;
  } else if (log.contains('ERROR')) {
    return Colors.red;
  } else if (log.contains('Connected to container') ||
      log.contains('Start successful') ||
      log.contains('started') ||
      log.toLowerCase().contains('starting') ||
      log.contains('Stop successful')) {
    return Colors.green;
  } else if (log.contains('stopped') ||
      log.contains('Disconnected') ||
      log.toLowerCase().contains('stopping') ||
      log.contains('shutting down')) {
    return Colors.orange;
  }
  return Colors.white;
}
