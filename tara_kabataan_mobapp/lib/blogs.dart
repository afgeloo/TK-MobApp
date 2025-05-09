import 'package:flutter/material.dart';
import 'events.dart';
import 'settings/settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'add_blogs_container.dart';
import 'package:html_editor_enhanced/html_editor.dart';

Future<List<Map<String, dynamic>>> fetchBlogs() async {
  final response = await http.get(
    Uri.parse(
      'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/mob-blogs.php',
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
  Set<String> selectedBlogIds = {};
  bool isSelecting = false;
  List<Map<String, dynamic>> _blogs = [];
  List<Map<String, dynamic>> _filteredBlogs = [];
  bool isLoading = false;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  TextEditingController _searchController = TextEditingController();

  void toggleSelection() {
    setState(() {
      isSelecting = !isSelecting;
      if (isSelecting) {
        // Select all rows when entering selection mode
        for (var blog in _filteredBlogs) {
          selectedBlogIds.add(blog['blog_id']);
        }
      } else {
        // Deselect all rows when exiting selection mode
        selectedBlogIds.clear();
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
    _searchController.addListener(_searchBlogs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _filteredBlogs = blogs;
        _totalPages = (_blogs.length / _itemsPerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blogs: $e')),
        );
      }
    }
  }

  // Function to refresh blogs after adding a new one
  Future<void> _refreshBlogs() async {
    await _loadBlogs();
    setState(() {
      _currentPage = 1;
    });
    return Future.value();
  }

  // Function to search blogs based on query
  void _searchBlogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBlogs = _blogs;
      } else {
        _filteredBlogs = _blogs.where((blog) {
          final title = blog['title']?.toString().toLowerCase() ?? '';
          final category = blog['category']?.toString().toLowerCase() ?? '';
          final content = blog['content']?.toString().toLowerCase() ?? '';
          final status = blog['blog_status']?.toString().toLowerCase() ?? '';
          
          return title.contains(query) || 
                 category.contains(query) || 
                 content.contains(query) || 
                 status.contains(query);
        }).toList();
      }
      _totalPages = (_filteredBlogs.length / _itemsPerPage).ceil();
      _currentPage = 1; // Reset to first page when searching
    });
  }

  // Function to delete a blog - this is now handled by _deleteBlog(Map<String, dynamic> blog, BuildContext context)

  @override
  Widget build(BuildContext context) {
    // Calculate pagination
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage > _filteredBlogs.length 
        ? _filteredBlogs.length 
        : startIndex + _itemsPerPage;
    final List<Map<String, dynamic>> paginatedBlogs = 
        _filteredBlogs.isEmpty ? [] : _filteredBlogs.sublist(startIndex, endIndex);
    
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
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: (_) => _searchBlogs(),
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
                        onTap: () {
                          _navigateTo(context, const EventsPage());
                        },
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () {
                          _navigateTo(context, const SettingsPage());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BLOGS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBlogDialog(false, null),
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
                        Icons.check_box_outlined,
                        size: 16
                      ),
                      const SizedBox(width: 6),
                      const Text('Select', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  onTap: toggleSelection,
                ),
              ],
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(10),
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBlogs.isEmpty
                    ? const Center(child: Text('No blogs found'))
                    : Column(
                        children: [
                          // Selection controls
                          if (isSelecting)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Text(
                                    '${selectedBlogIds.length} selected',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isSelecting = false;
                                        selectedBlogIds.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: selectedBlogIds.isEmpty ? null : _deleteSelectedBlogs,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE94B4B),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Blog table
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _refreshBlogs,
                              color: const Color(0xFFFF5A89),
                              backgroundColor: Colors.white,
                              displacement: 40,
                              strokeWidth: 3,
                              child: ListView(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 10,
                                      headingRowHeight: 56,
                                      dataRowHeight: 60,
                                      dividerThickness: 0,
                                      showCheckboxColumn: isSelecting,
                                      headingRowColor: MaterialStateProperty.all(Colors.transparent),
                                      border: const TableBorder(
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
                                      rows: paginatedBlogs.map((blog) {
                                        return DataRow(
                                          selected: isSelecting && selectedBlogIds.contains(blog['blog_id']),
                                          onSelectChanged: (selected) {
                                            if (isSelecting) {
                                              setState(() {
                                                if (selected!) {
                                                  selectedBlogIds.add(blog['blog_id']);
                                                } else {
                                                  selectedBlogIds.remove(blog['blog_id']);
                                                }
                                              });
                                            } else {
                                              _showBlogDetails(blog);
                                            }
                                          },
                                          onLongPress: () {
                                            if (!isSelecting) {
                                              setState(() {
                                                isSelecting = true;
                                                selectedBlogIds.add(blog['blog_id']);
                                              });
                                            }
                                          },
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 80,
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
                                ],
                              ),
                            ),
                          ),
                          
                          // Pagination UI
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Previous page button
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() {
                                            _currentPage--;
                                          });
                                        }
                                      : null,
                                  color: _currentPage > 1
                                      ? const Color(0xFFFF5A89)
                                      : Colors.grey,
                                ),
                                
                                // Page numbers
                                for (int i = 1; i <= _totalPages; i++)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentPage = i;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == i
                                            ? const Color(0xFFFF5A89)
                                            : Colors.white,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$i',
                                          style: TextStyle(
                                            color: _currentPage == i
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                // Next page button
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                        }
                                      : null,
                                  color: _currentPage < _totalPages
                                      ? const Color(0xFFFF5A89)
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          
                          // Page info text
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '${((_currentPage - 1) * _itemsPerPage) + 1} - ${_currentPage * _itemsPerPage > _filteredBlogs.length ? _filteredBlogs.length : _currentPage * _itemsPerPage} of ${_filteredBlogs.length} blogs',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show blog details dialog
  void _showBlogDetails(Map<String, dynamic> blog) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFF6F6),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.black54),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          if (blog['image_url'] != null && blog['image_url'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                blog['image_url'].toString().startsWith('http') 
                                  ? blog['image_url']
                                  : 'http://10.0.2.2${blog['image_url']}',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  );
                                },
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
                          HtmlWidget(
                            blog['content'] ?? 'No content.',
                            baseUrl: Uri.parse('http://10.0.2.2/tara-kabataan/'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Fixed buttons at the bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F6),
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _deleteBlog(blog, context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94B4B), // red
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the current view modal
                          _showBlogDialog(true, blog);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DB1E3), // blue
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete a single blog function
  void _deleteBlog(Map<String, dynamic> blog, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Blog"),
        content: const Text("Are you sure you want to delete this blog?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Cancel")
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete")
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_blogs.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"blog_id": blog['blog_id']}),
        );
        
        if (!mounted) return;
        
        final result = jsonDecode(response.body);
        if (result['success']) {
          Navigator.of(context).pop(); // Close the details dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Blog deleted successfully")),
          );
          _loadBlogs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${result['message'] ?? 'Failed to delete blog'}")),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }
  
  // Delete multiple selected blogs
  Future<void> _deleteSelectedBlogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Blogs"),
        content: Text("Are you sure you want to delete ${selectedBlogIds.length} blogs?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        isLoading = true;
      });

      bool hasError = false;
      String errorMessage = '';

      for (final blogId in selectedBlogIds) {
        try {
          final deleteResponse = await http.post(
            Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_blogs.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"blog_id": blogId}),
          );

          final deleteResult = jsonDecode(deleteResponse.body);
          if (!deleteResult['success']) {
            hasError = true;
            errorMessage = deleteResult['message'] ?? 'Unknown error';
            break;
          }
        } catch (e) {
          hasError = true;
          errorMessage = e.toString();
          break;
        }
      }

      // Reset selection mode
      setState(() {
        isSelecting = false;
        selectedBlogIds.clear();
      });

      // Reload blogs
      await _loadBlogs();

      // Show appropriate message
      if (hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting blogs: $errorMessage")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blogs deleted successfully")),
        );
      }
    }
  }



  // Show blog dialog (Add/Edit)
  void _showBlogDialog(bool isEdit, Map<String, dynamic>? blogData) {
    // Ensure we have the latest data if editing
    if (isEdit && blogData != null) {
      // Refresh the blog data to ensure we have the latest content
      http.get(
        Uri.parse(
          'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/get_blog.php?blog_id=${blogData['blog_id']}',
        ),
      ).then((response) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['blog'] != null) {
            // Show dialog with the fresh data
            _showBlogDialogWithData(isEdit, data['blog']);
          } else {
            // Fallback to original data if refresh fails
            _showBlogDialogWithData(isEdit, blogData);
          }
        } else {
          // Fallback to original data if refresh fails
          _showBlogDialogWithData(isEdit, blogData);
        }
      }).catchError((error) {
        // Fallback to original data if refresh fails
        _showBlogDialogWithData(isEdit, blogData);
      });
    } else {
      // For new blogs, just show the dialog
      _showBlogDialogWithData(isEdit, blogData);
    }
  }

  // Helper method to show the dialog with the provided data
  void _showBlogDialogWithData(bool isEdit, Map<String, dynamic>? blogData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _BlogDialog(
          isEdit: isEdit,
          blogData: blogData,
          onComplete: () {
            _loadBlogs();
          },
        );
      },
    );
  }
}

class _BlogDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? blogData;
  final VoidCallback onComplete;

  const _BlogDialog({
    required this.isEdit,
    required this.blogData,
    required this.onComplete,
  });

  @override
  State<_BlogDialog> createState() => _BlogDialogState();
}

class _BlogDialogState extends State<_BlogDialog> {
  img_picker.XFile? pickedImage;
  String? uploadedImageUrl;
  String? selectedCategory;
  String? selectedStatus;
  bool isProcessing = false;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final htmlEditorController = HtmlEditorController();
  final img_picker.ImagePicker picker = img_picker.ImagePicker();

  @override
  void initState() {
    super.initState();
    
    if (widget.isEdit && widget.blogData != null) {
      // Set title
      titleController.text = widget.blogData!['title'] ?? '';
      
      // Handle HTML content safely by removing any DOCTYPE or HTML tags if present
      String content = widget.blogData!['content'] ?? '';
      // Simple cleanup to avoid FormatException
      if (content.trim().startsWith('<!DOCTYPE') || content.trim().startsWith('<html')) {
        // Extract just the body content if possible
        final bodyStartIndex = content.indexOf('<body>');
        final bodyEndIndex = content.indexOf('</body>');
        if (bodyStartIndex != -1 && bodyEndIndex != -1) {
          content = content.substring(bodyStartIndex + 6, bodyEndIndex).trim();
        } else {
          // If we can't find body tags, just use a basic cleanup
          content = content.replaceAll(RegExp(r'<!DOCTYPE[^>]*>'), '')
                        .replaceAll(RegExp(r'<html[^>]*>'), '')
                        .replaceAll('</html>', '')
                        .trim();
        }
      }
      
      // Set content to both the text controller (as backup) and HTML editor
      contentController.text = content;
      
      // Delay setting HTML editor content to ensure it's initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          htmlEditorController.setText(content);
        }
      });
      
      // Set dropdown values
      selectedCategory = widget.blogData!['category'];
      selectedStatus = widget.blogData!['blog_status'];
      uploadedImageUrl = widget.blogData!['image_url'];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title is required")),
      );
      return;
    }
    
    // Get HTML content from editor
    final htmlContent = await htmlEditorController.getText();
    if (htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Content is required")),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // If a new image was picked, upload it
      if (pickedImage != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/mob-add_new_blog_image.php'),
        );

        request.files.add(await http.MultipartFile.fromPath('image', pickedImage!.path));

        var response = await request.send();
        var resBody = await response.stream.bytesToString();
        var data = jsonDecode(resBody);

        if (!mounted) return;

        if (data['success'] == true) {
          uploadedImageUrl = data['image_url'];
        } else {
          // Continue even if image upload fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image upload failed: ${data['error'] ?? 'Unknown error'}, continuing with blog creation")),
          );
        }
      }

      // Default author for simplicity (in a real app, get from login)
      const defaultAuthorId = 'users-2025-000001';

      // Build payload - only include image_url if it exists
      final payload = <String, dynamic>{
        if (widget.isEdit) 'blog_id': widget.blogData!['blog_id'],
        'title': titleController.text,
        'category': selectedCategory ?? 'Uncategorized',
        'blog_status': selectedStatus ?? 'DRAFT',
        'content': htmlContent,
        if (!widget.isEdit) 'author': defaultAuthorId,
      };
      
      // Only add image_url to payload if it exists
      if (uploadedImageUrl != null) {
        payload['image_url'] = uploadedImageUrl;
      }

      // Use the correct endpoints based on what's available on the server
      final uri = Uri.parse(widget.isEdit
          ? 'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/update_blogs.php'
          : 'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_blog.php');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      if (!mounted) return;
      
      final result = jsonDecode(response.body);

      if (result['success'] == true) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? "Blog updated successfully"
                : "Blog added successfully"),
          ),
        );
        widget.onComplete();
      } else {
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['error'] ?? 'Unknown error'}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF6F6),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isEdit ? 'EDIT BLOG' : 'ADD BLOG',
                      style: const TextStyle(
                        fontFamily: 'Bogart',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    GestureDetector(
                      onTap: isProcessing ? null : () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, size: 28, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // Image
                const Text('Image (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  height: 180,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: pickedImage != null
                      ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                      : (uploadedImageUrl != null
                          ? Image.network(
                              uploadedImageUrl!.toString().startsWith('http')
                                ? uploadedImageUrl!
                                : 'http://10.0.2.2$uploadedImageUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Text("Image could not be loaded"));
                              },
                            )
                          : const Text("No Image Selected (Optional)")),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: isProcessing ? null : () async {
                        final img_picker.XFile? image =
                            await picker.pickImage(source: img_picker.ImageSource.gallery);
                        if (image != null && mounted) {
                          setState(() {
                            pickedImage = image;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Image selected. It will be saved on submit."),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 20),
                        backgroundColor: const Color(0xFF4DB1E3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('Upload'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isProcessing ? null : () {
                        setState(() {
                          pickedImage = null;
                          uploadedImageUrl = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 20),
                        backgroundColor: const Color(0xFFE94B4B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['KALUSUGAN', 'KALIKASAN', 'KARUNUNGAN', 'KULTURA', 'KASARIAN']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: isProcessing ? null : (val) => setState(() => selectedCategory = val),
                ),
                const SizedBox(height: 12),

                // Status
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['DRAFT', 'PUBLISHED', 'PINNED', 'ARCHIVED']
                      .map((stat) => DropdownMenuItem(value: stat, child: Text(stat)))
                      .toList(),
                  onChanged: isProcessing ? null : (val) => setState(() => selectedStatus = val),
                ),
                const SizedBox(height: 12),

                // Content
                const Text('Content', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HtmlEditor(
                    controller: htmlEditorController,
                    htmlEditorOptions: HtmlEditorOptions(
                      hint: 'Enter your content here...',
                      shouldEnsureVisible: true,
                      initialText: widget.isEdit ? contentController.text : '',
                    ),
                    htmlToolbarOptions: HtmlToolbarOptions(
                      toolbarPosition: ToolbarPosition.aboveEditor,
                      toolbarType: ToolbarType.nativeScrollable,
                      renderBorder: true,
                      initiallyExpanded: false,
                      // Simplified toolbar with just basic formatting options
                      defaultToolbarButtons: [
                        StyleButtons(style: true),
                        FontButtons(bold: true, italic: true, underline: true, clearAll: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: isProcessing ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 20),
                        backgroundColor: const Color.fromARGB(255, 54, 230, 139),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: isProcessing 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Save Changes' : 'Add Blog',
                            style: const TextStyle(fontSize: 16),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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