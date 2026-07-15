import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import 'local_db_service.dart';

/// Dependency dùng chung cho các feature phía Flutter.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final localDbServiceProvider = Provider<LocalDbService>(
  (ref) => LocalDbService.instance,
);
