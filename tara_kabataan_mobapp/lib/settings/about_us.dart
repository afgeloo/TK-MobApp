import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AboutUsTab extends StatefulWidget {
  const AboutUsTab({super.key});

  @override
  State<AboutUsTab> createState() => _AboutUsTabState();
}

class _AboutUsTabState extends State<AboutUsTab> {
  Map<String, dynamic>? aboutUs;
  bool isLoading = true;
  String error = '';

  final List<Map<String, String>> sections = [
    {'key': 'overview', 'title': 'Overview'},
    {'key': 'background', 'title': 'Background'},
    {'key': 'vision', 'title': 'Vision'},
    {'key': 'mission', 'title': 'Mission'},
    {'key': 'core_values', 'title': 'Core Values'},
    {'key': 'advocacy', 'title': 'Adbokasiya'},
    {'key': 'council', 'title': 'TK Council'},
    {'key': 'contact', 'title': 'Contact'}, // <-- new grouped card
  ];

  final Map<String, String> coreValuesMap = {
    'Kapwa': 'core_kapwa',
    'Kalinangan': 'core_kalinangan',
    'Kaginhawaan': 'core_kaginhawaan',
  };

  final Map<String, String> advocaciesMap = {
    'Kalusugan': 'adv_kalusugan',
    'Kalikasan': 'adv_kalikasan',
    'Karunungan': 'adv_karunungan',
    'Kultura': 'adv_kultura',
    'Kasarian': 'adv_kasarian',
  };

  final Map<String, String> contactMap = {
    'Phone': 'contact_no',
    'Email': 'about_email',
    'Facebook': 'facebook',
    'Instagram': 'instagram',
    'Address': 'address',
  };

  @override
  void initState() {
    super.initState();
    fetchAboutUs();
  }

  Future<void> fetchAboutUs() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/aboutus.php',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          aboutUs = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load About Us content';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateAboutUs(Map<String, String> updatedFields) async {
    final url = Uri.parse(
      'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/update_aboutus.php',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedFields),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        setState(() {
          aboutUs?.addAll(updatedFields); // Update local state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw result['message'] ?? 'Update failed.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void showSectionModal(String title, String content, String key) {
    final TextEditingController controller = TextEditingController(
      text: content,
    );

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: controller,
                          maxLines: null,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
onPressed: () async {
  final updatedField = {key: controller.text};
  await updateAboutUs(updatedField);
  Navigator.of(context).pop();
},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F91),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void showFilteredModal(String title, Map<String, String> keyMap) {
    String selectedKey = keyMap.keys.first;
    final Map<String, Color> chipColors = {
      'Kalusugan': const Color(0xFFFF6F91),
      'Kalikasan': const Color(0xFF3ECC84),
      'Karunungan': const Color(0xFF6BA4FF),
      'Kultura': const Color(0xFFDDCC2A),
      'Kasarian': const Color(0xFFEF59BD),
    };

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final TextEditingController controller = TextEditingController(
              text: aboutUs?[keyMap[selectedKey]] ?? '',
            );

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 550),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$title',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      /// 👇 Horizontal scrollable filter row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              keyMap.keys.map((label) {
                                final bool isSelected = label == selectedKey;
                                final Color? selectedColor =
                                    title == 'Adbokasiya'
                                        ? chipColors[label]
                                        : const Color(0xFFFF6F91);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: RawChip(
                                    label: Text(label),
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    backgroundColor: const Color(0xFFF1F1F1),
                                    selectedColor: selectedColor,
                                    selected: isSelected,
                                    showCheckmark:
                                        false, // 👈 remove check icon
                                    onSelected:
                                        (_) => setState(() {
                                          selectedKey = label;
                                          controller.text =
                                              aboutUs?[keyMap[selectedKey]] ??
                                              '';
                                        }),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? Colors.transparent
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
onPressed: () async {
  final updatedField = {keyMap[selectedKey]!: controller.text};
  await updateAboutUs(updatedField);
  Navigator.of(context).pop();
},

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F91),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  if (isLoading) return const Center(child: CircularProgressIndicator());
  if (error.isNotEmpty) return Center(child: Text(error));

  final visibleSections = sections.where((section) => section['key'] != 'overview').toList();

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: visibleSections.length,
    itemBuilder: (context, index) {
      final section = visibleSections[index];
      final key = section['key']!;
      final title = section['title']!;

      return GestureDetector(
        onTap: () {
          if (key == 'core_values') {
            showFilteredModal('Core Values', coreValuesMap);
          } else if (key == 'advocacy') {
            showFilteredModal('Adbokasiya', advocaciesMap);
          } else if (key == 'contact') {
            showContactModal();
          } else {
            final content = aboutUs![key]?.toString() ?? "No content available.";
            showSectionModal(title, content, key);
          }
        },
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        ),
      );
    },
  );
}


  void showContactModal() {
    // Initialize individual controllers for each contact field
    final Map<String, TextEditingController> controllers = {
      for (var entry in contactMap.entries)
        entry.key: TextEditingController(text: aboutUs?[entry.value] ?? ''),
    };

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              contactMap.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: controllers[entry.key],
                                        maxLines: null,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
onPressed: () async {
  final updatedFields = {
    for (var entry in contactMap.entries)
      entry.value: controllers[entry.key]!.text,
  };
  await updateAboutUs(updatedFields);
  Navigator.of(context).pop();
},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F91),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
