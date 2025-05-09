import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:html' as html;

class ConverterService {
  // Encode a file to base64 with its metadata (full file at once)
  static Future<Map<String, dynamic>> encodeFile(dynamic file) async {
    try {
      Uint8List bytes;
      String fileName;
      String fileExtension;
      
      if (kIsWeb) {
        // Web implementation
        if (file is html.File) {
          bytes = await _readWebFile(file);
          fileName = file.name;
          fileExtension = fileName.contains('.') ? fileName.split('.').last : '';
        } else {
          throw Exception('Invalid file type for web');
        }
      } else {
        // Mobile/Desktop implementation
        if (file is File) {
          bytes = await file.readAsBytes();
          fileName = file.path.split(Platform.pathSeparator).last;
          fileExtension = fileName.contains('.') ? fileName.split('.').last : '';
        } else {
          throw Exception('Invalid file type for native platforms');
        }
      }
      
      final base64String = base64Encode(bytes);
      
      return {
        'data': base64String,
        'fileName': fileName,
        'fileExtension': fileExtension,
        'fileSize': bytes.length,
        'chunked': false,
      };
    } catch (e) {
      throw Exception('Failed to encode file: $e');
    }
  }
  
  // Helper method to read web file
  static Future<Uint8List> _readWebFile(html.File file) async {
    final Completer<Uint8List> completer = Completer<Uint8List>();
    final html.FileReader reader = html.FileReader();
    
    reader.onLoad.listen((event) {
      completer.complete(
        reader.result as Uint8List,
      );
    });
    
    reader.onError.listen((event) {
      completer.completeError('Failed to read file');
    });
    
    reader.readAsArrayBuffer(file);
    return completer.future;
  }
  // Encode a file using chunking method with progress reporting
  static Future<Map<String, dynamic>> encodeFileWithChunking(
    dynamic file, 
    {int chunkSize = 1024 * 1024, // Default 1MB chunks
    Function(double)? onProgress}
  ) async {
    try {
      int fileSize;
      String fileName;
      String fileExtension;
      
      if (kIsWeb) {
        // Web implementation
        if (file is html.File) {
          fileSize = file.size;
          fileName = file.name;
          fileExtension = fileName.contains('.') ? fileName.split('.').last : '';
          
          // For web, we need a different approach to read chunks
          final result = StringBuffer();
          final reader = html.FileReader();
          final completer = Completer<void>();
          
          // Setup a slice method to read the file in chunks
          int offset = 0;
          
          Future<void> readNextChunk() async {
            if (offset >= fileSize) {
              completer.complete();
              return;
            }
            
            // Calculate chunk size
            final end = min(offset + chunkSize, fileSize);
            final blob = file.slice(offset, end);
            
            // Read chunk as array buffer
            final chunkCompleter = Completer<Uint8List>();
            reader.onLoad.listen((event) {
              chunkCompleter.complete(reader.result as Uint8List);
            });
            
            reader.onError.listen((event) {
              chunkCompleter.completeError('Failed to read file chunk');
            });
            
            reader.readAsArrayBuffer(blob);
            
            // Get chunk data and encode
            final chunkData = await chunkCompleter.future;
            final encodedChunk = base64Encode(chunkData);
            result.write(encodedChunk);
            
            // Update progress
            offset = end;
            if (onProgress != null) {
              onProgress(offset / fileSize);
            }
            
            // Process next chunk
            await readNextChunk();
          }
          
          // Start reading chunks
          await readNextChunk();
          await completer.future;
          
          return {
            'data': result.toString(),
            'fileName': fileName,
            'fileExtension': fileExtension,
            'fileSize': fileSize,
            'chunked': true,
          };
        } else {
          throw Exception('Invalid file type for web');
        }
      } else {
        // Native implementation
        if (file is File) {
          fileSize = await file.length();
          fileName = file.path.split(Platform.pathSeparator).last;
          fileExtension = fileName.contains('.') ? fileName.split('.').last : '';
          
          // We can't pass callbacks to compute, so we'll implement chunking in the main isolate
          final result = StringBuffer();
          final raf = await file.open(mode: FileMode.read);
          
          int totalBytesRead = 0;
          
          while (totalBytesRead < fileSize) {
            // Read a chunk of the file
            final buffer = Uint8List(chunkSize);
            final bytesRead = await raf.readInto(buffer, 0, min(chunkSize, fileSize - totalBytesRead));
            
            if (bytesRead <= 0) break;
            
            // Trim the buffer if we read less than a full chunk
            final chunk = bytesRead < chunkSize ? buffer.sublist(0, bytesRead) : buffer;
            
            // Encode the chunk
            final encodedChunk = base64Encode(chunk);
            result.write(encodedChunk);
            
            // Update progress and total bytes read
            totalBytesRead += bytesRead;
            
            // Report progress if callback is provided
            if (onProgress != null) {
              onProgress(totalBytesRead / fileSize);
            }
          }
          
          // Close the file
          await raf.close();
          
          return {
            'data': result.toString(),
            'fileName': fileName,
            'fileExtension': fileExtension,
            'fileSize': fileSize,
            'chunked': true,
          };
        } else {
          throw Exception('Invalid file type for native platforms');
        }
      }
    } catch (e) {
      throw Exception('Failed to encode chunked file: $e');
    }
  }

  // Decode base64 to binary data (full string at once)
  static Uint8List decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      throw Exception('Failed to decode base64: $e');
    }
  }

  // Decode base64 using chunking method with progress reporting
  static Future<Uint8List> decodeBase64WithChunking(
    String base64String, 
    {int chunkSize = 100 * 1024, // Default 100KB chunks for text processing
    Function(double)? onProgress}
  ) async {
    try {
      final totalLength = base64String.length;
      
      // For base64 decoding, we need to ensure chunk sizes are multiples of 4
      final adjustedChunkSize = (chunkSize ~/ 4) * 4;
      
      // First calculate total output size to pre-allocate buffer
      final outputSize = base64String.length * 3 ~/ 4;
      final result = Uint8List(outputSize);
      
      int processedLength = 0;
      int outputOffset = 0;
      
      while (processedLength < totalLength) {
        final int endIndex = min(processedLength + adjustedChunkSize, totalLength);
        final chunk = base64String.substring(processedLength, endIndex);
        
        // Decode this chunk
        final decodedChunk = base64Decode(chunk);
        
        // Copy to result buffer
        result.setRange(outputOffset, outputOffset + decodedChunk.length, decodedChunk);
        
        processedLength = endIndex;
        outputOffset += decodedChunk.length;
        
        // Report progress if callback is provided
        if (onProgress != null) {
          onProgress(processedLength / totalLength);
        }
      }
      
      // Trim if needed (unlikely for base64 but just in case)
      return outputOffset == outputSize ? result : result.sublist(0, outputOffset);
    } catch (e) {
      throw Exception('Failed to decode chunked base64: $e');
    }
  }

  // Parse a Base64 encoded string with metadata
  static Map<String, dynamic> parseEncodedData(String encodedString) {
    try {
      // Try to parse as JSON first
      try {
        final data = json.decode(encodedString);
        if (data is Map && data.containsKey('data') && data.containsKey('fileExtension')) {
          // Convert to Map<String, dynamic>
          return Map<String, dynamic>.from(data);
        }
      } catch (e) {
        // Not a JSON, treat as raw base64
      }
      
      // If not JSON, treat as raw base64
      return {
        'data': encodedString,
        'fileName': 'decoded_file',
        'fileExtension': '',
        'fileSize': decodeBase64(encodedString).length,
      };
    } catch (e) {
      throw Exception('Failed to parse encoded data: $e');
    }
  }
  // Save decoded data to file
  static Future<String> saveDecodedFile(Uint8List bytes, String fileName, [String extension = '']) async {
    try {
      // Add extension if not already in the filename
      if (extension.isNotEmpty && !fileName.endsWith('.$extension')) {
        fileName = '$fileName.$extension';
      }
      
      if (kIsWeb) {
        // Web implementation - trigger download
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        html.document.body!.children.add(anchor);
        anchor.click();
        
        // Clean up
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        return 'Downloaded to browser';
      } else {
        // Native implementation
        // Let user choose where to save the file
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save your file',
          fileName: fileName,
        );
        
        // If user cancels, fall back to default location
        if (outputPath == null) {
          Directory? directory;
          
          try {
            // Try downloads directory first
            directory = await getDownloadsDirectory();
          } catch (e) {
            // Downloads directory not available on this platform
          }
          
          // If downloads not available, use documents
          directory ??= await getApplicationDocumentsDirectory();
          
          outputPath = '${directory.path}${Platform.pathSeparator}$fileName';
        }
        
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
  // Get file size in a readable format
  static String getFileSize(dynamic file, {int decimals = 2}) {
    int bytes;
    
    if (kIsWeb) {
      if (file is html.File) {
        bytes = file.size;
      } else {
        bytes = 0;
      }
    } else if (file is File) {
      bytes = file.lengthSync();
    } else {
      bytes = 0;
    }
    
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }
}
