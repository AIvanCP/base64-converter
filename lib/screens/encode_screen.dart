import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/converter_service.dart';
import '../widgets/platform_file_selector.dart';
import '../widgets/result_display.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/animated_gradient_button.dart';

class EncodeScreen extends StatefulWidget {
  const EncodeScreen({Key? key}) : super(key: key);

  @override
  State<EncodeScreen> createState() => _EncodeScreenState();
}

class _EncodeScreenState extends State<EncodeScreen> {
  dynamic _selectedFile;
  Map<String, dynamic>? _encodedData;
  String? _encodedJsonString;
  bool _isLoading = false;
  bool _useChunking = false;
  double _progress = 0.0;
  Future<void> _encodeFile(dynamic file) async {
    try {
      setState(() {
        _isLoading = true;
        _progress = 0.0;
      });

      // Encode the file to base64 with metadata
      Map<String, dynamic> encodedData;
      
      if (_useChunking) {
        // Use chunking method for larger files
        encodedData = await ConverterService.encodeFileWithChunking(
          file,
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
        );
      } else {
        // Use traditional full-file method
        encodedData = await ConverterService.encodeFile(file);
      }
      
      final encodedJsonString = json.encode(encodedData);
      
      setState(() {
        _encodedData = encodedData;
        _encodedJsonString = encodedJsonString;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error encoding file: ${e.toString()}'),
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
                      text: 'Encode File to Base64',
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
                      'Convert your files to Base64 format',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // File Selector with improved UI
              FileSelector(
                selectedFile: _selectedFile,
                onFileSelected: (file) {
                  setState(() {
                    _selectedFile = file;
                    _encodedJsonString = null; // Clear previous result
                    _encodedData = null;
                  });
                  
                  // Automatically start encoding when file is selected
                  _encodeFile(file);
                },
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
                          'Recommended for large files to reduce memory usage',
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
              if (_encodedJsonString != null && !_isLoading)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: ResultDisplay(
                    base64Result: _getEncodedDisplayText(),
                    rawBase64Data: _encodedJsonString, // Pass the actual data
                    isEncodeResult: true,
                    onSaveFile: (fileName) {
                      // Not needed for encode result as we're only saving decoded files
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEncodedDisplayText() {
    if (_encodedData == null || _encodedJsonString == null) return '';
    
    // Create a summary of the encoded data with emojis for visual appeal
    String summary = '✓ File encoded successfully!\n';
    
    if (_encodedData!.containsKey('fileName')) {
      summary += '📄 File: ${_encodedData!['fileName']}\n';
    }
    
    if (_encodedData!.containsKey('fileExtension')) {
      summary += '🏷️ Type: ${_encodedData!['fileExtension'].toString().toUpperCase()}\n';
    }
    
    if (_encodedData!.containsKey('fileSize')) {
      summary += '📊 Size: ${_formatFileSize(_encodedData!['fileSize'] as int)}\n';
    }
    
    // Show processing method used
    if (_encodedData!.containsKey('chunked') && _encodedData!['chunked'] == true) {
      summary += '⚙️ Processing: Chunked mode\n';
    } else {
      summary += '⚙️ Processing: Full file mode\n';
    }
    
    // Add note about the format without including the actual data in the display text
    summary += '\n📋 Base64 data (click copy to copy all data)';
    
    return summary;
  }
  
  String _formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}";
  }
}
