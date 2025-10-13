// lib/widgets/test_file_upload_screen.dart
// This is a test screen to verify the enhanced file upload functionality

import 'dart:io';
import 'package:flutter/material.dart';
import 'enhanced_file_upload_widget.dart';

class TestFileUploadScreen extends StatefulWidget {
  const TestFileUploadScreen({super.key});

  @override
  State<TestFileUploadScreen> createState() => _TestFileUploadScreenState();
}

class _TestFileUploadScreenState extends State<TestFileUploadScreen> {
  File? _selectedFile;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Enhanced File Upload'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enhanced File Upload Widget Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test the enhanced file upload widget
            EnhancedFileUploadWidget(
              label: 'Test Document Upload',
              helpText: 'Upload a test document to verify functionality',
              required: true,
              initialFile: _selectedFile,
              onFileChanged: (File? file) {
                setState(() {
                  _selectedFile = file;
                  _errorMessage = null;
                });
              },
              onError: (String? error) {
                setState(() {
                  _errorMessage = error;
                });
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
              maxFileSizeInMB: 5,
              showPreview: true,
              enabled: true,
            ),
            
            const SizedBox(height: 30),
            
            // Status information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Information:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Text('Selected File: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Text(
                          _selectedFile?.path.split('/').last ?? 'None',
                          style: TextStyle(
                            color: _selectedFile != null ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('File Size: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Full Path: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Text(
                            _selectedFile!.path,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Test buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedFile != null ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('File ready for upload: ${_selectedFile!.path.split('/').last}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simulate Upload'),
                ),
                
                const SizedBox(width: 16),
                
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Test Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Click the upload area to select a file\n'
                    '2. Try different file types (PDF, DOC, images)\n'
                    '3. Test file size validation (max 5MB)\n'
                    '4. Use preview and file management buttons\n'
                    '5. Test error handling with invalid files',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
