import 'package:flutter/material.dart';
import 'blogs.dart';
import 'settings.dart';
import 'map_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart' as img_picker;


// Fetch Events Data
Future<List<Map<String, dynamic>>> fetchEvents() async {
  final response = await http.get(
    Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/events1.php'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List events = data['events'];
    return List<Map<String, dynamic>>.from(events);
  } else {
    throw Exception('Failed to load events');
  }
}

// Format Date
String formatDate(String rawDate) {
  try {
    final parsedDate = DateTime.parse(rawDate);
    return DateFormat('MMMM d, y').format(parsedDate);
  } catch (_) {
    return rawDate;
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

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
                const Icon(Icons.notifications_none, color: Colors.black87, size: 35),
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
                        onTap: () => _navigateTo(context, const BlogsPage()),
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.event_outlined,
                        label: 'Events',
                        onTap: () {
                          Navigator.pop(context);
                        },
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
                  'EVENTS',
                  style: TextStyle(
                    fontFamily: 'Bogart',
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                GestureDetector(
                  onTap: () => showAddEventDialog(context),
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
                future: fetchEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No events found.'));
                  }

                  final events = snapshot.data!;
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
                        headingRowColor: MaterialStateProperty.all(Colors.transparent),
                        border: TableBorder(
                          horizontalInside: BorderSide.none,
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                        ),
                        columns: const [
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: events.map((event) {
                          return DataRow(
                            onSelectChanged: (_) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFFFFF6F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    contentPadding: const EdgeInsets.all(24),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (event['image_url'] != null && event['image_url'].toString().isNotEmpty)
                                                SizedBox(
                                                height: 180,
                                                width: double.infinity,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    'http://10.0.2.2${event['image_url']}',
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Title: ${event['title'] ?? 'N/A'}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          Text("Category: ${event['category'] ?? 'N/A'}"),
                                          Text("Status: ${event['event_status'] ?? 'N/A'}"),
                                          Text("Date: ${formatDate(event['created_at'] ?? '')}"),
                                          const SizedBox(height: 8),
                                          const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          HtmlWidget(
                                            event['content'] ?? 'No content.',
                                            baseUrl: Uri.parse('http://10.0.2.2/tara-kabataan/'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            cells: [
                              DataCell(SizedBox(width: 60, child: Text(event['category'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Color(0xFFFF5A89))))),
                              DataCell(SizedBox(width: 80, child: Text(event['title'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10)))),
                              DataCell(SizedBox(width: 60, child: Text(event['event_status'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10)))),
                              DataCell(SizedBox(width: 60, child: Text(formatDate(event['created_at'] ?? ''), overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10)))),
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

String getDayOfWeek(int weekday) {
  switch (weekday) {
    case 1:
      return "Monday";
    case 2:
      return "Tuesday";
    case 3:
      return "Wednesday";
    case 4:
      return "Thursday";
    case 5:
      return "Friday";
    case 6:
      return "Saturday";
    case 7:
      return "Sunday";
    default:
      return "";
  }
}

Future<void> openMapPicker(BuildContext context, TextEditingController venueController) async {
  final LatLng? pickedLocation = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MapPickerScreen()),
  );

  if (pickedLocation != null) {
    venueController.text = '${pickedLocation.latitude}, ${pickedLocation.longitude}';
  }
}

// Upload image and return its server URL
Future<String?> uploadEventImage(img_picker.XFile imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_event_image.php'),
  );

  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  var response = await request.send();
  var resBody = await response.stream.bytesToString();
  var data = jsonDecode(resBody);

  if (data['success'] == true) {
    return data['image_url'];
  } else {
    debugPrint('Image upload failed: ${data['error']}');
    return null;
  }
}

Future<void> showAddEventDialog(BuildContext context) async {
  debugPrint('ImagePicker initialized: ${img_picker.ImagePicker().toString()}');
  img_picker.XFile? pickedImage;
  String? uploadedImageUrl;
  final img_picker.ImagePicker picker = img_picker.ImagePicker();
  String? selectedCategory;
  String? selectedStatus;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController speakerController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController timeController = TextEditingController();


  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Dialog(
            backgroundColor: const Color(0xFFFFF6F6),
            insetPadding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,   // <<<--- FULL SCREEN WIDTH
              height: MediaQuery.of(context).size.height, // <<<--- FULL SCREEN HEIGHT (optional if you want)
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // -- everything you wrote inside --
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ADD EVENT',
                            style: TextStyle(
                              fontFamily: 'Bogart',
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close, size: 28, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                      const Text('Image', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        height: 180,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: pickedImage != null
                          ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                          : const Text("Image Preview Here"),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final img_picker.XFile? image = await picker.pickImage(source: img_picker.ImageSource.gallery);
                              if (image != null) {
                                setModalState(() {
                                  pickedImage = image;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Image selected. It will be uploaded when you add the event.")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 20),
                              backgroundColor: const Color(0xFF4DB1E3), // Upload blue
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            child: const Text('Upload'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 20),
                              backgroundColor: const Color(0xFFE94B4B), // Remove red
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                        items: ['Seminar', 'Outreach', 'Training']
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) => selectedCategory = val,
                      ),
                      // Venue Field
                      const SizedBox(height: 12),
                      const Text('Venue', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: venueController,
                        readOnly: true,
                        onTap: () async {
                          await openMapPicker(context, venueController);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                          suffixIconConstraints: const BoxConstraints(
                            minHeight: 24,
                            minWidth: 24,
                            maxHeight: 24,
                            maxWidth: 24,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Date, Day and Time Row
                      Row(
                        children: [
                          // Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: () async {
                                    final DateTime now = DateTime.now();
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: now, // 👈 Disables past dates
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      dateController.text = "${picked.month}/${picked.day}/${picked.year}";
                                      dayController.text = getDayOfWeek(picked.weekday);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    suffixIcon: const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                                    suffixIconConstraints: const BoxConstraints(
                                      minHeight: 24,
                                      minWidth: 24,
                                      maxHeight: 24,
                                      maxWidth: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Day
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: dayController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Time
                      const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: timeController,
                        readOnly: true,
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            // Combine picked time with selected date
                            final selectedDate = DateFormat("MM/dd/yyyy").parse(dateController.text);
                            final pickedDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );

                            final now = DateTime.now();
                            if (pickedDateTime.isBefore(now)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Time cannot be in the past.")),
                              );
                              return;
                            }

                            timeController.text = picked.format(context);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: const Icon(Icons.access_time, size: 15, color: Colors.grey),
                          suffixIconConstraints: const BoxConstraints(
                            minHeight: 24,
                            minWidth: 24,
                            maxHeight: 24,
                            maxWidth: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        items: ['Ongoing', 'Upcoming', 'Completed']
                            .map((stat) => DropdownMenuItem(value: stat, child: Text(stat)))
                            .toList(),
                        onChanged: (val) => selectedStatus = val,
                      ),
                      const SizedBox(height: 12),
                      const Text('Speakers', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                          controller: speakerController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text('Content', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // 👈 move to right
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isEmpty || pickedImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Title and image are required")),
                                );
                                return;
                              }

                              // 🔁 Upload the image here
                              final uploadedUrl = await uploadEventImage(pickedImage!);
                              if (uploadedUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Image upload failed. Try again.")),
                                );
                                return;
                              }

                              final Map<String, dynamic> newEvent = {
                                "title": titleController.text,
                                "category": selectedCategory ?? "Uncategorized",
                                "event_date": dateController.text,
                                "event_start_time": timeController.text,
                                "event_end_time": timeController.text,
                                "event_venue": venueController.text,
                                "event_status": selectedStatus ?? "UPCOMING",
                                "event_speakers": speakerController.text,
                                "content": contentController.text,
                                "image_url": uploadedUrl,
                              };

                              final response = await http.post(
                                Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_event.php'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode(newEvent),
                              );

                              final result = jsonDecode(response.body);
                              if (result['success']) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Event added successfully")),
                                );
                                Navigator.of(context).pop(); // Close modal
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: ${result['error']}")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(150, 20),
                              backgroundColor: const Color.fromARGB(255, 54, 230, 139),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6), // 👈 minimal roundness
                              ),
                            ),
                            child: const Text(
                              'Add Event',
                              style: TextStyle(fontSize: 16),
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
        },
      );
    },
  );
}