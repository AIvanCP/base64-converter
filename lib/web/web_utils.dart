// Web compatibility support for the app
// This file is a starter template for making the app web-compatible

// 1. File to make your Dart app web-ready:
import 'dart:html' as html;

/// Trigger a file download in the web browser
void downloadFile(List<int> bytes, String fileName) {
  // Create a Blob containing the bytes
  final blob = html.Blob([bytes]);
  
  // Create a URL to the blob
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create an anchor element to trigger the download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  
  // Add the anchor to the document body
  html.document.body!.children.add(anchor);
  
  // Trigger the download
  anchor.click();
  
  // Clean up
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Get a web-compatible file picker
html.FileUploadInputElement createWebFilePicker({List<String>? accept}) {
  final uploadInput = html.FileUploadInputElement();
  if (accept != null && accept.isNotEmpty) {
    uploadInput.accept = accept.join(',');
  }
  return uploadInput;
}
