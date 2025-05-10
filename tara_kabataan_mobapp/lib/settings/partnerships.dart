import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class PartnershipsTab extends StatefulWidget {
  const PartnershipsTab({super.key});

  @override
  State<PartnershipsTab> createState() => _PartnershipsTabState();
}

class _PartnershipsTabState extends State<PartnershipsTab> {
  late Future<List<Map<String, dynamic>>> _partnersFuture;

  @override
  void initState() {
    super.initState();
    _partnersFuture = fetchPartners();
  }

  // Fetch partners from the API
  Future<List<Map<String, dynamic>>> fetchPartners() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/partners.php'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['partners'] != null) {
          return List<Map<String, dynamic>>.from(json['partners']);
        }
        return [];
      } else {
        if (kDebugMode) {
          print('Failed to load partners. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception('Failed to load partners');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching partners: $e');
      }
      throw Exception('Failed to load partners: $e');
    }
  }

  // Helper method to upload partner image
  Future<String?> _uploadPartnerImage(XFile image) async {
    try {
      final uri = Uri.parse("http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_partner_image.php");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      
      // Safely try to parse the JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(resBody);
        
        if (data['success'] == true && data['image_url'] != null) {
          return data['image_url'];
        } else {
          // Log error but don't throw exception
          if (kDebugMode) {
            print("Upload warning: ${data['error'] ?? 'Unknown error'}");
          }
          return null;
        }
      } catch (e) {
        // Handle invalid JSON response
        if (kDebugMode) {
          print("Invalid JSON response from image upload: $resBody");
        }
        return null;
      }
    } catch (e) {
      // Log error but continue with partner update
      if (kDebugMode) {
        print("Image upload error: $e");
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _partnersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No partners found'));
          }

          final partners = snapshot.data!;
          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              final imageUrl = partner['partner_image'] != null && partner['partner_image'].toString().isNotEmpty
                  ? 'http://10.0.2.2${partner['partner_image']}'
                  : '';
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.business),
                      )
                    : const Icon(Icons.business),
                  title: Text(partner['partner_name'] ?? 'Unknown'),
                  subtitle: Text(partner['partner_dec'] ?? 'No description'),
                  onTap: () => _showPartnerDetails(partner),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPartnerDialog(),
        backgroundColor: const Color(0xFF4DB1E3),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Show partner details
  void _showPartnerDetails(Map<String, dynamic> partner) {
    final imageUrl = partner['partner_image'] != null && partner['partner_image'].toString().isNotEmpty
        ? 'http://10.0.2.2${partner['partner_image']}'
        : '';
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(partner['partner_name'] ?? 'Unknown Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.business, size: 100),
              )
            else
              const Icon(Icons.business, size: 100),
            const SizedBox(height: 16),
            Text(partner['partner_dec'] ?? 'No description'),
            if (partner['partner_contact_email'] != null)
              Text('Email: ${partner['partner_contact_email']}'),
            if (partner['partner_phone_number'] != null)
              Text('Phone: ${partner['partner_phone_number']}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditPartnerDialog(partner);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB1E3),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(partner);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to add a new partner
  void _showAddPartnerDialog() {
    // Create controllers for the form fields
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    XFile? selectedImage;
    bool isSaving = false;
    
    // Show dialog with form
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Partner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              File(selectedImage!.path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to add image (optional)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Form fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Partner Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                // Validate form
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Partner name is required')),
                  );
                  return;
                }
                
                // Set saving state
                setDialogState(() => isSaving = true);
                
                // Prepare partner data
                final partnerData = {
                  'partner_name': nameController.text.trim(),
                  'partner_dec': descriptionController.text.trim(),
                  'partner_contact_email': emailController.text.trim(),
                  'partner_phone_number': phoneController.text.trim(),
                };
                
                // Upload image if selected (optional)
                if (selectedImage != null) {
                  final imageUrl = await _uploadPartnerImage(selectedImage!);
                  if (imageUrl != null) {
                    partnerData['partner_image'] = imageUrl;
                  }
                }
                
                // Add partner to database
                try {
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_partner.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(partnerData),
                  );
                  
                  final result = jsonDecode(response.body);
                  
                  if (result['success'] == true) {
                    // Refresh partners list
                    setState(() {
                      _partnersFuture = fetchPartners();
                    });
                    
                    // Close dialog and show success message
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partner added successfully')),
                    );
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: ${result['message'] ?? "Unknown error"}')),
                    );
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error adding partner: $e');
                  }
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
                
                // Reset saving state
                setDialogState(() => isSaving = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB1E3)),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to update partner image
  Future<String?> _updatePartnerImage(String partnerId, XFile image) async {
    try {
      final uri = Uri.parse("http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/upload_partner_image.php");
      final request = http.MultipartRequest('POST', uri);
      request.fields['partner_id'] = partnerId;
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      
      // Safely try to parse the JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(resBody);
        
        if (data['success'] == true && data['image_url'] != null) {
          return data['image_url'];
        } else {
          // Log error but don't throw exception
          if (kDebugMode) {
            print("Upload warning: ${data['error'] ?? 'Unknown error'}");
          }
          return null;
        }
      } catch (e) {
        // Handle invalid JSON response
        if (kDebugMode) {
          print("Invalid JSON response from image upload: $resBody");
        }
        return null;
      }
    } catch (e) {
      // Log error but continue with partner update
      if (kDebugMode) {
        print("Image upload error: $e");
      }
      return null;
    }
  }
  
  // Show dialog to edit an existing partner
  void _showEditPartnerDialog(Map<String, dynamic> partner) {
    // Create controllers for the form fields
    final nameController = TextEditingController(text: partner['partner_name']);
    final descriptionController = TextEditingController(text: partner['partner_dec']);
    final emailController = TextEditingController(text: partner['partner_contact_email']);
    final phoneController = TextEditingController(text: partner['partner_phone_number']);
    XFile? selectedImage;
    bool isSaving = false;
    
    // Show dialog with form
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Partner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipOval(
                      child: selectedImage != null
                          ? Image.file(
                              File(selectedImage!.path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : (partner['partner_image'] != null && partner['partner_image'].toString().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: 'http://10.0.2.2${partner['partner_image']}',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.business, size: 50),
                                )
                              : const Icon(Icons.business, size: 50)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to change image (optional)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Form fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Partner Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                // Validate form
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Partner name is required')),
                  );
                  return;
                }
                
                // Set saving state
                setDialogState(() => isSaving = true);
                
                // Prepare partner data
                final partnerData = {
                  'partner_id': partner['partner_id'],
                  'partner_name': nameController.text.trim(),
                  'partner_dec': descriptionController.text.trim(),
                  'partner_contact_email': emailController.text.trim(),
                  'partner_phone_number': phoneController.text.trim(),
                };
                
                // Upload image if selected (optional)
                if (selectedImage != null) {
                  final imageUrl = await _updatePartnerImage(partner['partner_id'], selectedImage!);
                  if (imageUrl != null) {
                    partnerData['partner_image'] = imageUrl;
                  }
                }
                
                // Update partner in database
                try {
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/update_partners.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(partnerData),
                  );
                  
                  final result = jsonDecode(response.body);
                  
                  if (result['success'] == true) {
                    // Refresh partners list
                    setState(() {
                      _partnersFuture = fetchPartners();
                    });
                    
                    // Close dialog and show success message
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partner updated successfully')),
                    );
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: ${result['message'] ?? "Unknown error"}')),
                    );
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error updating partner: $e');
                  }
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
                
                // Reset saving state
                setDialogState(() => isSaving = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB1E3)),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show confirmation dialog before deleting a partner
  void _showDeleteConfirmation(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Are you sure you want to delete ${partner['partner_name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePartner(partner['partner_id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  // Delete a partner
  Future<void> _deletePartner(String partnerId) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text("Deleting partner..."),
          ],
        ),
        duration: Duration(seconds: 60), // Long duration that will be dismissed manually
      ),
    );
    
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_partners.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"partner_id": partnerId}),
      );
      
      // Hide the loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        // Refresh partners list
        setState(() {
          _partnersFuture = fetchPartners();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Partner deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${result['message'] ?? 'Unknown error'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide the loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show error message
      if (kDebugMode) {
        print('Error deleting partner: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
