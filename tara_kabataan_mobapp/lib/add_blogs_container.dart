import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';

class AddBlogDialog extends StatefulWidget {
  final Function onBlogAdded; // Callback to refresh blog list
  
  const AddBlogDialog({Key? key, required this.onBlogAdded}) : super(key: key);

  @override
  State<AddBlogDialog> createState() => _AddBlogDialogState();
}

class _AddBlogDialogState extends State<AddBlogDialog> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final contentController = TextEditingController();
  String? selectedCategory;
  String? selectedStatus;
  String? imageUrl;
  File? imageFile;
  bool isLoading = false;
  String? errorMessage;

  // Function to upload image to server
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_blog_image.php'),
      );
      
      // Create multipart file
      var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', // field name on server
        stream,
        length,
        filename: path.basename(imageFile.path),
      );
      
      // Add file to request
      request.files.add(multipartFile);
      
      // Send request
      var response = await request.send();
      
      // Get response
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['image_url']; // Return uploaded image URL
      } else {
        throw Exception('Failed to upload image: ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Log the error but don't throw - allow blog creation without image
      print('Error uploading image: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ADD BLOG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              // Title field
              const Text('Title', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Image upload section
              const Text('Image', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(imageFile!, fit: BoxFit.cover),
                    )
                  : imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageUrl!, fit: BoxFit.cover),
                      )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('insert image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Open file picker
                      final ImagePicker picker = ImagePicker();
                      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
                      
                      if (pickedImage != null) {
                        setState(() {
                          imageFile = File(pickedImage.path);
                          // Display local image preview
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Upload'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        imageFile = null;
                        imageUrl = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Category dropdown
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select Category'),
                    value: selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'KALIKASAN', child: Text('KALIKASAN')),
                      DropdownMenuItem(value: 'KALUSUGAN', child: Text('KALUSUGAN')),
                      DropdownMenuItem(value: 'KULTURA', child: Text('KULTURA')),
                      DropdownMenuItem(value: 'KARUNUNGAN', child: Text('KARUNUNGAN')),
                      DropdownMenuItem(value: 'KASARIAN', child: Text('KASARIAN')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Status dropdown
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select Status'),
                    value: selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'PUBLISHED', child: Text('PUBLISHED')),
                      DropdownMenuItem(value: 'PINNED', child: Text('PINNED')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Author field
              const Text('Author', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              TextField(
                controller: authorController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Content field
              const Text('Content', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              // Show error message if any
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Add Blog button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    // Validate form
                    if (titleController.text.isEmpty) {
                      setState(() {
                        errorMessage = 'Please enter a title';
                      });
                      return;
                    }
                    if (selectedCategory == null) {
                      setState(() {
                        errorMessage = 'Please select a category';
                      });
                      return;
                    }
                    if (selectedStatus == null) {
                      setState(() {
                        errorMessage = 'Please select a status';
                      });
                      return;
                    }
                    if (authorController.text.isEmpty) {
                      setState(() {
                        errorMessage = 'Please enter an author';
                      });
                      return;
                    }
                    if (contentController.text.isEmpty) {
                      setState(() {
                        errorMessage = 'Please enter content';
                      });
                      return;
                    }
                    
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    
                    try {
                      // Upload image if selected
                      String? uploadedImageUrl;
                      if (imageFile != null) {
                        uploadedImageUrl = await uploadImage(imageFile!);
                      }
                      
                      // Create blog data
                      final blogData = {
                        'title': titleController.text,
                        'category': selectedCategory,
                        'blog_status': selectedStatus,
                        'author': authorController.text,
                        'content': contentController.text,
                      };
                      
                      // Only add image_url to the data if we actually have an image
                      if (uploadedImageUrl != null) {
                        blogData['image_url'] = uploadedImageUrl;
                      }
                      
                      // Save blog to API
                      final response = await http.post(
                        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_blog.php'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(blogData),
                      );
                      
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        // Blog saved successfully
                        widget.onBlogAdded(); // Refresh blog list
                        Navigator.pop(context); // Close dialog
                      } else {
                        // Error saving blog
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Error saving blog: ${response.body}';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                        errorMessage = 'Error: $e';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CD964),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Blog',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
