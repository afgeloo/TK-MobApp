import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_member_dialog.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({super.key});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = fetchMembers();
  }

  Future<List<Map<String, dynamic>>> fetchMembers() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/members.php'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return List<Map<String, dynamic>>.from(json['members']);
      }
    }
    throw Exception('Failed to load members');
  }

  void _showMemberDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MEMBER DETAILS',
              style: TextStyle(
                fontFamily: 'Bogart',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF3D3D3D),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(
              imageUrl: 'http://10.0.2.2/tara-kabataan${member['member_image']}',
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 50,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(Icons.broken_image, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(member['member_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(member['role_name'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _editMember(member),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Edit', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFF4DB1E3)),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _deleteMember(member['member_id']),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Delete', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFE94B4B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editMember(Map<String, dynamic> member) {
    Navigator.pop(context); // close the member dialog
    showDialog(
      context: context,
      builder: (context) => EditMemberDialog(
        member: member,
        onSaved: () {
          setState(() {
            _membersFuture = fetchMembers(); // refresh list
          });
        },
      ),
    );
  }

  Future<void> _deleteMember(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Member"),
        content: const Text("Are you sure you want to delete this member?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"member_id": memberId}),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        setState(() {
          _membersFuture = fetchMembers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member deleted successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: ${result['error']}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final members = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 2;
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...members.map((member) => _MemberCard(
                          name: member['member_name'],
                          role: member['role_name'],
                          imageUrl: 'http://10.0.2.2//tara-kabataan${member['member_image']}',
                          onTap: () => _showMemberDialog(member),
                          width: itemWidth,
                        )),
                    _AddMemberTile(
                      onTap: () => debugPrint('Add Member'), // placeholder
                      width: itemWidth,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;
  final VoidCallback onTap;
  final double width;

  const _MemberCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 60, right: 16),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(role, style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFF5A89), Color(0xFF4DB1E3)]),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberTile extends StatelessWidget {
  final VoidCallback onTap;
  final double width;

  const _AddMemberTile({required this.onTap, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: Colors.grey.shade400,
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        dashPattern: const [6, 3],
        strokeWidth: 1.5,
        child: Container(
          width: width,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.grey),
                SizedBox(height: 4),
                Text('Add Member', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
