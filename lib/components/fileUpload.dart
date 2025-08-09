import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FileUpload extends StatelessWidget {
  final String title;
  final List<String> acceptedTypes;
  final File? uploadedFile;
  final void Function(File file) onFileUpload;
  final void Function()? onRemoveFile;
  final IconType icon;

  const FileUpload({
    super.key,
    required this.title,
    required this.acceptedTypes,
    required this.onFileUpload,
    this.uploadedFile,
    this.onRemoveFile,
    this.icon = IconType.image,
  });

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: acceptedTypes,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      onFileUpload(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData fileIcon =
        icon == IconType.image ? LucideIcons.fileImage : LucideIcons.fileText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFFECACA), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (uploadedFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF991B1B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(fileIcon, color: const Color(0xFFFECACA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uploadedFile!.path.split('/').last,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRemoveFile != null)
                  IconButton(
                    icon: const Icon(LucideIcons.x,
                        size: 18, color: Color(0xFFFECACA)),
                    onPressed: onRemoveFile,
                    splashRadius: 20,
                  ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () => _pickFile(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFF87171).withOpacity(0.4),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.upload,
                      color: Color(0xFFFCA5A5), size: 26),
                  const SizedBox(height: 8),
                  const Text(
                    "Click to upload",
                    style: TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                  ),
                  Text(
                    acceptedTypes.join(', '),
                    style:
                        const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}

enum IconType {
  image,
  document,
}
