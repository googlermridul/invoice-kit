import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes PDF bytes to a temp file and invokes the native share sheet.
///
/// Used by Report, Invoice and Quote detail flows. Centralizes the
/// bytes-to-file-to-share dance so it does not get duplicated across
/// features. The share sheet surfaces every installed target on the
/// device (WhatsApp, Gmail, Outlook, Telegram, Messenger, Drive,
/// Nearby Share, "Save to Files", etc.).
class DocumentShareService {
  const DocumentShareService();

  /// Writes [bytes] to a temp file using [filename] and opens the native
  /// share sheet.
  ///
  /// * [filename] must include the `.pdf` extension; it is sanitized
  ///   before being used as a filename.
  /// * [subject] is forwarded to the share intent (e.g. the Mail subject
  ///   on Gmail / Outlook).
  /// * [sharePositionOrigin] is the rect used for the iPad popover
  ///   anchor; callers should pass `RenderBox.localToGlobal` output.
  /// * [text] is the optional text body forwarded alongside the file.
  Future<void> share(
    Uint8List bytes, {
    required String filename,
    String? subject,
    Rect? sharePositionOrigin,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final safe = _safeName(filename);
    final file = File('${dir.path}/$safe');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'application/pdf',
          name: file.uri.pathSegments.last,
        ),
      ],
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
      text: text,
    );
  }

  /// Builds a time-stamped filename suitable for share-sheet payloads
  /// that do not have a meaningful document number (e.g. reports).
  static String reportFilename({String prefix = 'invoicekit_report'}) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$stamp.pdf';
  }

  String _safeName(String filename) {
    final cleaned = filename
        .replaceAll(RegExp('[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp('_+'), '_');
    if (cleaned.trim().isEmpty || cleaned == '.pdf') return 'document.pdf';
    return cleaned;
  }
}
