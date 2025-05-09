import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import conditional imports based on platform
import 'file_selector_web.dart' if (dart.library.io) 'file_selector.dart' as platform;

/// Platform-agnostic FileSelector widget that works on both mobile/desktop and web
class FileSelector extends StatelessWidget {
  final dynamic selectedFile;
  final Function(dynamic) onFileSelected;

  const FileSelector({
    Key? key,
    required this.selectedFile,
    required this.onFileSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return platform.FileSelector(
      selectedFile: selectedFile,
      onFileSelected: onFileSelected,
    );
  }
}
