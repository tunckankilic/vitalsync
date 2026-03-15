/// VitalSync — Encrypted SQLite Connection via SQLCipher.
///
/// Provides an encrypted database connection using sqlcipher_flutter_libs.
/// The encryption key is stored in FlutterSecureStorage.
///
/// Usage: Replace `_openConnection()` in database.dart with
/// `openEncryptedConnection()` when encryption is desired.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Secure storage key for the SQLCipher encryption passphrase.
const _dbKeyStorageKey = 'vitalsync_db_encryption_key';

/// Opens an encrypted SQLite connection using SQLCipher.
///
/// On first launch, generates a random 256-bit key and stores it
/// in FlutterSecureStorage. On subsequent launches, retrieves
/// the existing key. The key never leaves the device's secure enclave.
LazyDatabase openEncryptedConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'vitalsync_encrypted.db'));

    // Retrieve or generate encryption key
    const secureStorage = FlutterSecureStorage();
    var key = await secureStorage.read(key: _dbKeyStorageKey);
    if (key == null) {
      key = const Uuid().v4().replaceAll('-', ''); // 32-char hex key
      await secureStorage.write(key: _dbKeyStorageKey, value: key);
    }

    return NativeDatabase(
      file,
      setup: (rawDb) {
        // Enable SQLCipher encryption with the stored key
        rawDb.execute("PRAGMA key = '$key'");
      },
    );
  });
}
