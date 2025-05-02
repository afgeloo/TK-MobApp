import 'package:flutter/material.dart';
import 'events.dart';
import 'settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

Future<List<Map<String, dynamic>>> fetchBlogs() async {
  final response = await http.get(
    Uri.parse(
      'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/blogs.php',
    ),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List blogs = data['blogs'];
    return List<Map<String, dynamic>>.from(blogs);
  } else {
    throw Exception('Failed to load blogs');
  }
}

String formatDate(String rawDate) {
  try {
    final parsedDate = DateTime.parse(rawDate);
    return DateFormat('MMMM d, y').format(parsedDate);
  } catch (_) {
    return rawDate;
  }
}

class BlogsPage extends StatelessWidget {
  const BlogsPage({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        iconTheme: const IconThemeData(color: Color(0xFFFF5A89)),
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(40),
                ),
                height: 45,
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black54,
              child: Icon(Icons.person, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 15),
            Stack(
              children: [
                const Icon(
                  Icons.notifications_none,
                  color: Colors.black87,
                  size: 35,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFF9DB9),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Image.asset(
                  'assets/public/tarakabataanlogo2.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _SidebarButton(
                        icon: Icons.article_outlined,
                        label: 'Blogs',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.event_outlined,
                        label: 'Events',
                        onTap: () => _navigateTo(context, const EventsPage()),
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => _navigateTo(context, const SettingsPage()),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 30),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Bogart',
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BLOGS',
                  style: TextStyle(
                    fontFamily: 'Bogart',
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'Showing',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                ),
                const SizedBox(width: 8),
                _pillButton(
                  child: const Row(
                    children: [
                      Text('10', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _pillButton(
                  child: const Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Filter', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _pillButton(
                  child: const Row(
                    children: [
                      Icon(Icons.check_box_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Select', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchBlogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No blogs found.'));
                  }

                  final blogs = snapshot.data!;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 10,
                        headingRowHeight: 56,
                        dataRowHeight: 60,
                        dividerThickness: 0,
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        border: TableBorder(
                          horizontalInside: BorderSide.none,
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            blogs.map((blog) {
                              return DataRow(
                                onSelectChanged: (_) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: const Color(
                                          0xFFFFF6F6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          24,
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (blog['image_url'] != null && blog['image_url'].toString().isNotEmpty)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    'http://10.0.2.2/tara-kabataan/tara-kabataan-webapp/uploads/blogs-images/${blog['image_url']}',
                                                    height: 180,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "Title: ${blog['title'] ?? 'N/A'}",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 8),
                                              Text("Category: ${blog['category'] ?? 'N/A'}"),
                                              Text("Status: ${blog['blog_status'] ?? 'N/A'}"),
                                              Text("Date: ${formatDate(blog['created_at'] ?? '')}"),
                                              const SizedBox(height: 8),
                                              Text("Author: ${blog['author'] ?? 'N/A'}"),
                                              const SizedBox(height: 8),
                                              const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              const SizedBox(height: 8),
                                              HtmlWidget(
                                                blog['content'] ?? 'No content.',
                                                baseUrl: Uri.parse('http://10.0.2.2/tara-kabataan/'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text("Close"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        blog['category'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFF5A89),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        blog['title'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        blog['blog_status'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        formatDate(blog['created_at'] ?? ''),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _pillButton({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 35),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Bogart',
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
