import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/converter_service.dart';
import '../widgets/result_display.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/animated_gradient_button.dart';

class DecodeScreen extends StatefulWidget {
  const DecodeScreen({Key? key}) : super(key: key);

  @override
  State<DecodeScreen> createState() => _DecodeScreenState();
}

class _DecodeScreenState extends State<DecodeScreen> {
  final TextEditingController _base64Controller = TextEditingController();
  Uint8List? _decodedData;
  Map<String, dynamic>? _parsedData;
  bool _isLoading = false;
  bool _isValid = false;
  bool _useChunking = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _base64Controller.addListener(_validateBase64);
  }

  @override
  void dispose() {
    _base64Controller.dispose();
    super.dispose();
  }

  void _validateBase64() {
    final text = _base64Controller.text.trim();
    setState(() {
      // First check if it's valid JSON
      try {
        json.decode(text);
        _isValid = true;
        return;
      } catch (e) {
        // Not JSON, check if it's base64
      }
      
      // Simple validation - check if it's not empty and has valid base64 characters
      _isValid = text.isNotEmpty && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(text);
    });
  }
  Future<void> _decodeBase64() async {
    try {
      setState(() {
        _isLoading = true;
        _progress = 0.0;
      });

      final inputText = _base64Controller.text.trim();
      
      // Try to parse the input text for metadata
      final parsedData = ConverterService.parseEncodedData(inputText);
      
      // Get the base64 string from parsed data
      final base64String = parsedData['data'] as String;
      
      // Decode base64 to binary data based on the selected processing method
      Uint8List decodedData;
      
      if (_useChunking) {
        // Use chunking method for larger base64 strings
        decodedData = await ConverterService.decodeBase64WithChunking(
          base64String,
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
        );
        
        // Add chunking info to parsed data
        parsedData['chunkedProcessing'] = true;
      } else {
        // Use traditional full-string method
        decodedData = ConverterService.decodeBase64(base64String);
        parsedData['chunkedProcessing'] = false;
      }
      
      setState(() {
        _decodedData = decodedData;
        _parsedData = parsedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error decoding base64: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }  }  Future<void> _saveDecodedFile(String fileName) async {
    try {
      if (_decodedData == null) return;
      
      // Get file extension from metadata if available
      String fileExtension = '';
      if (_parsedData != null && _parsedData!.containsKey('fileExtension')) {
        fileExtension = _parsedData!['fileExtension'] as String;
      }
      
      // Show a loading indicator while saving
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving file... Please select a location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Save decoded data to file with the original extension if available
      final filePath = await ConverterService.saveDecodedFile(_decodedData!, fileName, fileExtension);
      
      if (mounted) {
        if (kIsWeb) {
          // For web, we don't have a file path - just show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File downloaded successfully!'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // For native platforms, show the file path
          // Get just the file name from the path for display
          final savedFileName = filePath.split(Platform.pathSeparator).last;
          // Get directory path for display
          final directoryPath = filePath.substring(0, filePath.length - savedFileName.length - 1);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File saved successfully!'),
                  const SizedBox(height: 4),
                  Text(
                    'Location: $directoryPath',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Filename: $savedFileName',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
          ],
          stops: const [0.1, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              // Header with animated gradient text
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedGradientText(
                      text: 'Decode Base64',
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Convert Base64 string back to file format',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Base64 Input Section with animated border
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: _isValid 
                        ? Theme.of(context).primaryColor.withOpacity(0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                child: _buildBase64Input(),
              ),

              const SizedBox(height: 24),
              
              // Processing options with improved styling
              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).cardColor,
                        Theme.of(context).cardColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Processing Options',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        title: Text(
                          'Use Chunked Processing',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Recommended for large Base64 strings',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        value: _useChunking,
                        activeColor: Theme.of(context).primaryColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _useChunking = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
                // Action Button with improved design
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedGradientButton(
                    text: 'Decode Base64',
                    icon: Icons.transform_rounded,
                    onPressed: _isValid && !_isLoading ? _decodeBase64 : null,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    height: 56,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Progress indicators with improved styling
              if (_isLoading)
                _useChunking && _progress > 0
                  ? Column(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor.withOpacity(0.7),
                                        Theme.of(context).primaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Processing: ${(_progress * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
              
              // Result Display
              if (_decodedData != null && !_isLoading)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: ResultDisplay(
                    base64Result: _getResultDisplayText(),
                    isEncodeResult: false,
                    onSaveFile: _saveDecodedFile,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  String _getResultDisplayText() {
    if (_decodedData == null) return '';
    
    String resultText = '✓ Decoded successfully!';
    
    // Add file information if available
    if (_parsedData != null) {
      if (_parsedData!.containsKey('fileName')) {
        resultText += '\n📄 Original file name: ${_parsedData!['fileName']}';
      }
      
      if (_parsedData!.containsKey('fileExtension') && _parsedData!['fileExtension'].toString().isNotEmpty) {
        resultText += '\n🏷️ File type: ${_parsedData!['fileExtension'].toString().toUpperCase()}';
      }
      
      if (_parsedData!.containsKey('fileSize')) {
        final int fileSize = _parsedData!['fileSize'] as int;
        resultText += '\n📊 File size: ${_formatFileSize(fileSize)}';
      } else {
        resultText += '\n📊 Decoded size: ${_formatFileSize(_decodedData!.length)}';
      }
      
      // Show processing method used
      if (_parsedData!.containsKey('chunkedProcessing')) {
        resultText += _parsedData!['chunkedProcessing'] == true 
            ? '\n⚙️ Processing: Chunked mode' 
            : '\n⚙️ Processing: Full string mode';
      }
    } else {
      resultText += '\n📊 Decoded size: ${_formatFileSize(_decodedData!.length)}';
    }
    
    return resultText;
  }
  
  String _formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  Widget _buildBase64Input() {
    return TextField(
      controller: _base64Controller,
      maxLines: 8,
      decoration: InputDecoration(
        hintText: 'Paste your Base64 string here...',
        contentPadding: const EdgeInsets.all(20),
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Colors.grey.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        suffixIcon: _base64Controller.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  onPressed: () {
                    _base64Controller.clear();
                    setState(() {
                      _decodedData = null;
                      _isValid = false;
                    });
                  },
                ),
              )
            : null,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
          child: Icon(
            Icons.code,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}
