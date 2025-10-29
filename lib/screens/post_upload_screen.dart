import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/media_upload_service.dart';
import '../services/posts_management_service.dart';
import '../services/local_storage_service.dart';
import '../models/post_model.dart';

class PostUploadScreen extends StatefulWidget {
  final String token;

  const PostUploadScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends State<PostUploadScreen> {
  dynamic _selectedImage; // Use dynamic to support both File and XFile
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          if (kIsWeb) {
            // On web, use the photo object directly
            _selectedImage = photo;
          } else {
            // On mobile, convert to File
            _selectedImage = File(photo.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _uploadPost() async {
    if (!mounted) return;
    
    // Get token from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    
    if (token == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    // Check if at least caption or media is provided
    final caption = _captionController.text.trim();
    if (_selectedImage == null && caption.isEmpty) {
      _showErrorSnackBar('Please add a caption or select media');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      File? mediaFile;
      
      // Convert XFile to File if needed
      if (_selectedImage != null) {
        if (_selectedImage is File) {
          mediaFile = _selectedImage as File;
        } else if (_selectedImage is XFile) {
          mediaFile = File((_selectedImage as XFile).path);
        }
      }

      // Upload post using Posts Management API (supports text-only posts)
      final response = await PostsManagementService.uploadPost(
        token: token,
        media: mediaFile, // Can be null for text-only posts
        caption: caption.isEmpty ? null : caption,
        isPublic: true,
      );

      if (!mounted) return;

      if (response.success) {
        _showSuccessSnackBar(response.message);
        
        // Clear form
        _captionController.clear();
        setState(() {
          _selectedImage = null;
        });
        
        // Navigate back and refresh profile
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error uploading post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<String> _extractHashtags(String text) {
    final hashtagRegex = RegExp(r'#\w+');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: ((_selectedImage != null || _captionController.text.trim().isNotEmpty) && !_isUploading) 
                ? _uploadPost 
                : null,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image selection area
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add a photo to your post',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share a moment from your spiritual journey',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Image selection buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Caption input
            const Text(
              'Caption',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption for your post...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Upload info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your image will be uploaded to local storage and shared with your spiritual community.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6366F1),
                        fontFamily: 'Poppins',
                      ),
                    ),
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
