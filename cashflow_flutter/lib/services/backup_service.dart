/// BackupService - Automated daily JSON backups
/// Saves to app's external storage as YYMMDD.json
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String _backupFolder = 'CashFlow_Backups';

  /// Get the backup directory, creating it if needed
  static Future<Directory> getBackupDir() async {
    final extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      throw Exception('External storage not available');
    }
    final backupDir = Directory('${extDir.path}/$_backupFolder');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Generate filename from date: YYMMDD.json
  static String _dateFileName(DateTime date) {
    final yy = (date.year % 100).toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yy$mm$dd.json';
  }

  /// Perform daily backup if not already done for yesterday
  /// Called on app startup after data is loaded
  static Future<void> performDailyBackup(String jsonData) async {
    if (kIsWeb) return; // No file access on web

    try {
      final backupDir = await getBackupDir();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final fileName = _dateFileName(yesterday);
      final backupFile = File('${backupDir.path}/$fileName');

      if (await backupFile.exists()) {
        debugPrint('📦 Backup $fileName already exists, skipping');
        return;
      }

      await backupFile.writeAsString(jsonData);
      debugPrint('✅ Daily backup saved: $fileName');

      // Clean old backups (keep last 30 days)
      await _cleanOldBackups(backupDir, keepDays: 30);
    } catch (e) {
      debugPrint('❌ Backup error: $e');
    }
  }

  /// Remove backups older than keepDays
  static Future<void> _cleanOldBackups(
    Directory dir, {
    int keepDays = 30,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: keepDays));
      final files = dir.listSync().whereType<File>();

      for (final file in files) {
        final name = file.path.split(Platform.pathSeparator).last;
        if (!name.endsWith('.json') || name.length != 11) continue;

        // Parse YYMMDD from filename
        final yy = int.tryParse(name.substring(0, 2));
        final mm = int.tryParse(name.substring(2, 4));
        final dd = int.tryParse(name.substring(4, 6));
        if (yy == null || mm == null || dd == null) continue;

        final fileDate = DateTime(2000 + yy, mm, dd);
        if (fileDate.isBefore(cutoff)) {
          await file.delete();
          debugPrint('🗑️ Deleted old backup: $name');
        }
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  /// List all existing backups (newest first)
  static Future<List<FileSystemEntity>> listBackups() async {
    try {
      final backupDir = await getBackupDir();
      final files =
          backupDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return [];
    }
  }
}
