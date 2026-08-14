import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupHelper {
  static Future<String> createBackup() async {
    final dbPath = await getDatabasesPath();
    final sourcePath = join(dbPath, 'masareefi.db');
    
    final docsDir = await getApplicationDocumentsDirectory();
    final backupPath = join(docsDir.path, 'masareefi_backup.db');

    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(backupPath);
      return backupPath;
    } else {
      throw Exception('Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ØºÙŠØ± Ù…ÙˆØ¬ÙˆØ¯Ø©');
    }
  }

  static Future<bool> restoreBackup(String backupFilePath) async {
    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'masareefi.db');

    final backupFile = File(backupFilePath);
    if (await backupFile.exists()) {
      final db = await openDatabase(targetPath);
      await db.close();

      await backupFile.copy(targetPath);
      return true;
    } else {
      return false;
    }
  }
}