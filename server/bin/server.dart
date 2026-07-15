import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:flashly_server/flashly_server.dart';
import 'package:flashly_server/src/core/auth/firebase_identity.dart';
import 'package:flashly_server/src/core/auth/firebase_token_verifier.dart';
import 'package:flashly_server/src/core/database/server_database.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final databasePath =
      Platform.environment['DATABASE_PATH'] ?? 'data/flashly_server.db';
  final useDevelopmentAuth =
      Platform.environment['FIREBASE_DEV_AUTH'] == 'true';

  final database = ServerDatabase.open(
    databasePath: databasePath,
    migrationDirectory: 'migrations',
  );

  final IdentityTokenVerifier tokenVerifier;
  if (useDevelopmentAuth) {
    stderr.writeln(
      'WARNING: FIREBASE_DEV_AUTH đang bật. Không dùng chế độ này khi deploy.',
    );
    tokenVerifier = const DevelopmentTokenVerifier();
  } else {
    tokenVerifier = FirebaseTokenVerifier(FirebaseApp.initializeApp());
  }

  final server = await shelf_io.serve(
    buildFlashlyHandler(database: database, tokenVerifier: tokenVerifier),
    InternetAddress.anyIPv4,
    port,
  );

  stdout.writeln(
    'Flashly backend: http://${server.address.host}:${server.port}',
  );
}
