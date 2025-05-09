import 'package:flutter/material.dart';
import 'events.dart';
import 'settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'add_blogs_container.dart';

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

class BlogsPage extends StatefulWidget {
  const BlogsPage({super.key});

  @override
  State<BlogsPage> createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  Map<int, bool> selectedRows = {};
  bool isBulkSelecting = false;
  List<Map<String, dynamic>> _blogs = [];
  bool isLoading = false;

  void toggleBulkSelection() {
    setState(() {
      isBulkSelecting = !isBulkSelecting;
      if (isBulkSelecting) {
        // Select all rows
        for (int i = 0; i < _blogs.length; i++) {
          selectedRows[i] = true;
        }
      } else {
        // Deselect all rows
        selectedRows = {};
      }
    });
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  // Function to load blogs from API
  Future<void> _loadBlogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final blogs = await fetchBlogs();
      setState(() {
        _blogs = blogs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading blogs: $e')),
      );
    }
  }

  // Function to refresh blogs after adding a new one
  void _refreshBlogs() {
    _loadBlogs();
  }

  // Function to delete a blog
  Future<bool> _deleteBlog(int blogId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/blogs.php?id=$blogId'),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh blogs list after successful deletion
          _refreshBlogs();
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message'] ?? "Failed to delete blog"}'))
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Server returned status code ${response.statusCode}'))
        );
        return false;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting blog: $e')),
      );
      return false;
    }
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
                GestureDetector(
                  onTap: () {
                    // Show Add Blog dialog using the component from add_blogs_container.dart
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AddBlogDialog(
                        onBlogAdded: _refreshBlogs,
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A3FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
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
                  child: Row(
                    children: [
                      Icon(
                        isBulkSelecting ? Icons.check_box : Icons.check_box_outlined,
                        size: 16
                      ),
                      const SizedBox(width: 6),
                      const Text('Select', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      isBulkSelecting = !isBulkSelecting;
                      if (isBulkSelecting) {
                        // Select all rows
                        for (int i = 0; i < _blogs.length; i++) {
                          selectedRows[i] = true;
                        }
                      } else {
                        // Deselect all rows
                        selectedRows = {};
                      }
                    });
                  },
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
                  _blogs = blogs; // Store blogs in class variable for bulk selection
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _blogs.isEmpty
                        ? const Center(child: Text('No blogs found'))
                        : Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: false,
                                trackVisibility: false,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Scrollbar(
                                    thumbVisibility: false,
                                    trackVisibility: false,
                                    scrollbarOrientation: ScrollbarOrientation.bottom,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                            columnSpacing: 10,
                            headingRowHeight: 56,
                            dataRowHeight: 60,
                            dividerThickness: 0,
                            showCheckboxColumn: false, // Remove built-in checkbox column
                            headingRowColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                        border: TableBorder(
                          horizontalInside: BorderSide.none,
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                        ),
                        columns: const [
                          DataColumn(label: SizedBox.shrink()), // Checkbox column
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
                        rows: blogs.asMap().entries.map((entry) {
                              final index = entry.key;
                              final blog = entry.value;
                              
                              // Function to show blog details dialog
                              void showBlogDetailsDialog() {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                            width: double.infinity,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Close button
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.black54),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ),
                                                
                                                // Image
                                                if (blog['image_url'] != null && blog['image_url'].toString().isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      'http://10.0.2.2/tara-kabataan/tara-kabataan-webapp/uploads/blogs-images/${blog['image_url']}',
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          height: 180,
                                                          width: double.infinity,
                                                          color: Colors.grey[300],
                                                          child: const Center(child: Text('Image not available')),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                const SizedBox(height: 16),
                                                
                                                // Title
                                                Text(
                                                  "Title: ${blog['title'] ?? 'N/A'}",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                                const SizedBox(height: 12),
                                                
                                                // Metadata
                                                Text(
                                                  "Category: ${blog['category'] ?? 'N/A'}",
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                Text(
                                                  "Status: ${blog['blog_status'] ?? 'N/A'}",
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                Text(
                                                  "Date: ${formatDate(blog['created_at'] ?? '')}",
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                const SizedBox(height: 8),
                                                
                                                // Content section
                                                const Text(
                                                  "Content:",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 8),
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(maxHeight: 300),
                                                  child: SingleChildScrollView(
                                                    child: HtmlWidget(
                                                      blog['content'] ?? 'No content.',
                                                      baseUrl: Uri.parse('http://10.0.2.2/tara-kabataan/'),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                
                                                // Action buttons
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () async {
                                                        // Delete functionality
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: const Text("Delete Blog"),
                                                            content: const Text("Are you sure you want to delete this blog?"),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.of(context).pop(false),
                                                                child: const Text("Cancel"),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.of(context).pop(true),
                                                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                              ),
                                                            ],
                                                          ),
                                                        ) ?? false;

                                                        if (confirm) {
                                                          Navigator.of(context).pop(); // Close the blog details dialog
                                                          final success = await _deleteBlog(blog['id']);
                                                          if (success) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Blog deleted successfully')),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(Icons.delete, color: Colors.white),
                                                      label: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red[400],
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        // Edit functionality
                                                        Navigator.of(context).pop();
                                                      },
                                                      icon: const Icon(Icons.edit, color: Colors.white),
                                                      label: const Text('Edit', style: TextStyle(color: Colors.white)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.blue[400],
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                              
                              return DataRow(
                                // Enable row selection for showing dialog
                                onSelectChanged: (value) {
                                  if (value == true) {
                                    showBlogDetailsDialog();
                                  }
                                },
                                cells: [
                                  // Checkbox cell - separate functionality
                                  DataCell(
                                    Checkbox(
                                      value: selectedRows[index] ?? false,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedRows[index] = value ?? false;
                                        });
                                      },
                                    ),
                                    // Empty onTap to prevent row selection when clicking the checkbox
                                    onTap: () {},
                                  ),
                                  // Category cell
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
                                  // Title cell
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
                                  // Status cell
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
                                  // Date cell
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
                                  ),
                                ),
                              ),
                            ),
                          ],
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

Widget _pillButton({required Widget child, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    ),
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
