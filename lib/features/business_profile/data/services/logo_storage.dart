import 'dart:io';
import 'package:get_it/get_it.dart' show GetIt;
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart'
    show BusinessProfile;
import 'package:path_provider/path_provider.dart';

/// Persists company logos to a stable local directory so the path stored in
/// [BusinessProfile.logoPath] survives app restarts.
class LogoStorage {
  const LogoStorage();

  static const _logoDir = 'invoice_kit_logos';

  /// Persists [bytes] under [filename] in the app's documents directory and
  /// returns the absolute path.
  Future<String> saveLogoBytes(String filename, List<int> bytes) async {
    final dir = await _logoDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Removes a logo file if it lives inside the managed logo directory.
  /// Silently no-ops when the file does not exist or lives elsewhere.
  Future<void> removeLogo(String? path) async {
    if (path == null || path.isEmpty) return;
    final dir = await _logoDirectory();
    final file = File(path);
    if (!file.existsSync()) return;
    // Only allow removing files inside the managed logo directory.
    if (!file.path.startsWith('${dir.path}${Platform.pathSeparator}')) return;
    try {
      await file.delete();
    } on Exception catch (_) {
      // Best-effort cleanup; ignore.
    }
  }

  Future<Directory> _logoDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_logoDir');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// Helper for callers that don't have access to [GetIt].
LogoStorage get logoStorage => sl<LogoStorage>();
