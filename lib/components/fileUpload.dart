// lib/widgets/fileUpload.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' show exp, log, math, pow;

enum IconType { image, document }

class FileUpload extends StatelessWidget {
  final String title;
  final List<String> acceptedTypes; // e.g. ['pdf','jpg','png']
  final File? uploadedFile;
  final void Function(File file) onFileUpload;
  final void Function()? onRemoveFile;
  final IconType icon;
  final String? helperText;

  const FileUpload({
    super.key,
    required this.title,
    required this.acceptedTypes,
    required this.onFileUpload,
    this.uploadedFile,
    this.onRemoveFile,
    this.icon = IconType.image,
    this.helperText,
  });

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: acceptedTypes,
      allowMultiple: false,
      withData: false,
    );
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      onFileUpload(File(result.files.first.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final fileIcon =
        icon == IconType.image ? LucideIcons.fileImage : LucideIcons.fileText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.textTheme.titleLarge),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText!, style: t.textTheme.bodySmall),
        ],
        const SizedBox(height: 8),

        // If a file is uploaded, show it
        if (uploadedFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fileIcon, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name
                      Text(
                        uploadedFile!.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      // File meta
                      Text(
                        _fileMeta(uploadedFile!),
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onRemoveFile != null)
                  Tooltip(
                    message: 'Remove file',
                    child: IconButton(
                      onPressed: onRemoveFile,
                      icon: Icon(LucideIcons.x, color: cs.error),
                      splashRadius: 22,
                    ),
                  ),
              ],
            ),
          )
        else
          // Upload area (keyboard + screen reader friendly)
          Semantics(
            button: true,
            label: 'Upload file',
            hint: 'Accepted types: ${acceptedTypes.join(', ')}',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickFile(context),
              onLongPress: () => _pickFile(context),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.outline.withOpacity(0.6),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.upload, color: cs.primary),
                    const SizedBox(height: 8),
                    Text('Click to upload', style: t.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      acceptedTypes.join(', '),
                      style: t.textTheme.bodySmall?.copyWith(
                          color:
                              t.textTheme.bodySmall?.color?.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
        // Secondary actions row
        Row(
          children: [
            if (uploadedFile == null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(LucideIcons.folderOpen),
                  label: const Text('Choose file'),
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(LucideIcons.repeat),
                  label: const Text('Replace file'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _fileMeta(File f) {
    try {
      final bytes = f.lengthSync();
      return _formatBytes(bytes);
    } catch (_) {
      return '';
    }
  }

  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(k)).floor();
    final value = bytes / pow(k, i);
    return '${value.toStringAsFixed(decimals)} ${sizes[i]}';
  }
}

// Tiny helpers since dart:math pow returns num and we want double
double MathPow(num x, num exponent) => x == 0 && exponent == 0
    ? 1.0
    : (x is double ? x : x.toDouble()).pow(exponent);

extension on double {
  double pow(num e) =>
      e == 0 ? 1.0 : (e is int ? _intPow(e) : _doublePow(e.toDouble()));
  double _intPow(int e) {
    if (e < 0) return (1.0 / this).pow(-e);
    var base = this, result = 1.0, exp = e;
    while (exp > 0) {
      if (exp & 1 == 1) result *= base;
      base *= base;
      exp >>= 1;
    }
    return result;
  }

  double _doublePow(double e) => mathExp(e * mathLog(this));
}

double mathLog(double x) => log(x);
double mathExp(double x) => exp(x);

// Needed imports for math helpers
