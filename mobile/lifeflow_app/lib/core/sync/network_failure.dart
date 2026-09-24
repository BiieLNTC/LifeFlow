import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lifeflow_app/core/sync/sync_models.dart';

Never throwOfflineOrRethrow(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    throw const OfflineUnavailable();
  }
  throw error;
}
