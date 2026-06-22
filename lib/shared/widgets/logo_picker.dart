import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/features/business_profile/data/services/logo_storage.dart';

/// Lets the user pick, preview, and remove a company logo. Returns the
/// persisted absolute file path (or null when removed) via [onChanged].
class LogoPicker extends StatefulWidget {
  const LogoPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Absolute path of the currently selected logo, or null when none.
  final String? value;

  /// Called whenever the user picks or removes a logo. Passes null on remove.
  final ValueChanged<String?> onChanged;

  @override
  State<LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends State<LogoPicker> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pickFrom(ImageSource source) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final filename = 'logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = await sl<LogoStorage>().saveLogoBytes(filename, bytes);
      widget.onChanged(path);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load logo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(HugeIconsStroke.image01, size: 18),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(HugeIconsStroke.camera01, size: 18),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickFrom(source);
  }

  Future<void> _remove() async {
    final path = widget.value;
    await sl<LogoStorage>().removeLogo(path);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.value != null && File(widget.value!).existsSync();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.tokens.brandSubtle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.tokens.border),
          ),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          child: hasLogo
              ? Image.file(
                  File(widget.value!),
                  fit: BoxFit.cover,
                  width: 72,
                  height: 72,
                )
              : Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: context.colors.onSurfaceVariant,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company logo',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasLogo ? 'Shown on invoices and PDF exports.' : 'Add a logo to brand your invoices and PDFs.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _showSourceSheet,
                    icon: const Icon(HugeIconsStroke.upload01, size: 18),
                    label: Text(hasLogo ? 'Replace' : 'Upload'),
                  ),
                  if (hasLogo)
                    TextButton.icon(
                      onPressed: _busy ? null : _remove,
                      icon: const Icon(HugeIconsStroke.delete01, size: 18),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
