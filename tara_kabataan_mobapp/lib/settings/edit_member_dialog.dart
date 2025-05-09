import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditMemberDialog extends StatefulWidget {
  final Map<String, dynamic> member;
  final VoidCallback onSaved;

  const EditMemberDialog({super.key, required this.member, required this.onSaved});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late TextEditingController _nameController;
  String? _selectedRoleId;
  String? _memberImage;
  XFile? _newImage;
  bool _isSaving = false;

  final picker = ImagePicker();

  final List<Map<String, String>> _roles = [
    {"role_id": "1", "role_name": "President"},
    {"role_id": "2", "role_name": "Vice President"},
    {"role_id": "3", "role_name": "Secretary"},
    {"role_id": "4", "role_name": "Treasurer"},
    // Add more roles if needed
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member['member_name']);
    _selectedRoleId = widget.member['role_id'];
    _memberImage = widget.member['member_image'];
  }

  Future<void> _uploadImage(String memberId) async {
    if (_newImage == null) return;

    final uri = Uri.parse("http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/upload_member_image.php");
    final request = http.MultipartRequest('POST', uri);
    request.fields['member_id'] = memberId;
    request.files.add(await http.MultipartFile.fromPath('image', _newImage!.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    if (data['success'] == true) {
      _memberImage = data['image_url'];
    } else {
      throw Exception("Upload failed: ${data['message']}");
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final memberId = widget.member['member_id'];

      if (_newImage != null) {
        await _uploadImage(memberId);
      }

      final payload = {
        'member_id': memberId,
        'member_name': _nameController.text.trim(),
        'role_id': _selectedRoleId ?? '',
        'member_image': _memberImage ?? '',
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/update_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF6F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Member', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _newImage = picked);
                }
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _newImage != null
                    ? FileImage(File(_newImage!.path))
                    : (_memberImage != null && _memberImage!.isNotEmpty)
                        ? NetworkImage('http://10.0.2.2/tara-kabataan$_memberImage') as ImageProvider
                        : null,
                child: _newImage == null && (_memberImage == null || _memberImage!.isEmpty)
                    ? const Icon(Icons.camera_alt, size: 32, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRoleId,
              items: _roles
                  .map((role) => DropdownMenuItem(
                        value: role['role_id'],
                        child: Text(role['role_name']!),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedRoleId = val),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB1E3)),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
