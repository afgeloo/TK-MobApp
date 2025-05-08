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
	import 'package:html_editor_enhanced/html_editor.dart';


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
			return DateFormat('MMM. d, y').format(parsedDate);
		} catch (_) {
			return rawDate;
		}
	}

	class EventsPage extends StatefulWidget {
		const EventsPage({super.key});

		@override
		State<EventsPage> createState() => _EventsPageState();
	}

	class _EventsPageState extends State<EventsPage> {
		final TextEditingController _searchController = TextEditingController();
		List<Map<String, dynamic>> _allEvents = [];
		List<Map<String, dynamic>> _filteredEvents = [];
		bool _isLoading = true;
		String _searchQuery = '';
		bool _isSelecting = false;
		Set<String> _selectedEventIds = {};
		int _currentPage = 1;
		int _itemsPerPage = 10;
		int _totalPages = 1;

		@override
		void initState() {
			super.initState();
			_loadEvents();
			_searchController.addListener(_onSearchChanged);
		}

		void _onSearchChanged() {
			setState(() {
				_searchQuery = _searchController.text.toLowerCase();
				_filteredEvents = _allEvents
						.where((event) =>
								event['title']?.toLowerCase().contains(_searchQuery) == true ||
								event['category']?.toLowerCase().contains(_searchQuery) == true ||
								event['event_status']?.toLowerCase().contains(_searchQuery) == true)
						.toList();
						_currentPage = 1;
			});
		}

		Future<void> _loadEvents() async {
			try {
				final events = await fetchEvents();
				setState(() {
					_allEvents = events;
					_filteredEvents = events;
					_isLoading = false;
					_currentPage = 1;
				});
			} catch (e) {
				setState(() {
					_isLoading = false;
				});
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading events: $e")));
			}
		}

		void _navigateTo(BuildContext context, Widget page) {
			Navigator.pop(context);
			Navigator.push(context, MaterialPageRoute(builder: (context) => page));
		}

		Future<void> _deleteSelectedEvents() async {
			final confirm = await showDialog<bool>(
				context: context,
				builder: (context) => AlertDialog(
					title: const Text("Delete Events"),
					content: Text("Are you sure you want to delete ${_selectedEventIds.length} events?"),
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
				setState(() {
					_isLoading = true;
				});
				
				bool hasError = false;
				String errorMessage = '';

				for (final eventId in _selectedEventIds) {
					try {
						final deleteResponse = await http.post(
							Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_event.php'),
							headers: {'Content-Type': 'application/json'},
							body: jsonEncode({"event_id": eventId}),
						);

						final deleteResult = jsonDecode(deleteResponse.body);
						if (!deleteResult['success']) {
							hasError = true;
							errorMessage = deleteResult['error'];
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
					_isSelecting = false;
					_selectedEventIds.clear();
				});
				
				// Reload events
				await _loadEvents();
				
				// Show appropriate message
				if (hasError) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text("Error deleting events: $errorMessage")),
					);
				} else {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(content: Text("Events deleted successfully")),
					);
				}
			}
		}

	Widget _buildEventTable(List<Map<String, dynamic>> events) {
	_totalPages = (events.length / _itemsPerPage).ceil();
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > events.length) endIndex = events.length;

	    final paginatedEvents = events.isEmpty ? [] : events.sublist(startIndex, endIndex);

		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
			),
			padding: const EdgeInsets.all(10),
			child: Column(
				children: [
					// Selection controls row when in selection mode
					if (_isSelecting)
						Padding(
							padding: const EdgeInsets.only(bottom: 10),
							child: Row(
								children: [
									Text('${_selectedEventIds.length} selected', 
											style: const TextStyle(fontWeight: FontWeight.bold)),
									const Spacer(),
									ElevatedButton.icon(
										onPressed: () {
											setState(() {
												_isSelecting = false;
												_selectedEventIds.clear();
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
										onPressed: _selectedEventIds.isEmpty ? null : () => _deleteSelectedEvents(),
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
						Container(
  width: double.infinity,
					child: SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: DataTable(
							columnSpacing: 10,
  headingRowHeight: 56,
  dataRowMinHeight: 60,
  dataRowMaxHeight: 60, 
							dividerThickness: 0,
							showCheckboxColumn: _isSelecting,
							headingRowColor: WidgetStateProperty.all(Colors.transparent),
							border: TableBorder(
								horizontalInside: BorderSide.none,
								top: BorderSide.none,
								bottom: BorderSide.none,
							),
							columns: [
								if (_isSelecting)
									const DataColumn(label: Text('')), // checkbox column
								const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
								const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
								const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
								const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
							],
							rows: paginatedEvents.map((event) {
								return DataRow(
									selected: _isSelecting && _selectedEventIds.contains(event['event_id']),
									onSelectChanged: _isSelecting 
											? (selected) {
													setState(() {
														if (selected!) {
															_selectedEventIds.add(event['event_id']);
														} else {
															_selectedEventIds.remove(event['event_id']);
														}
													});
												}
											: null,
									onLongPress: () {
										// Start selection mode on long press if not already selecting
										if (!_isSelecting) {
											setState(() {
												_isSelecting = true;
												_selectedEventIds.add(event['event_id']);
											});
										}
									},
									cells: [
										if (_isSelecting)
											DataCell(Container()), // Empty cell for checkbox column
										DataCell(
											SizedBox(width: 75, child: Text(
												event['category'] ?? 'Uncategorized',
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(fontSize: 10, color: Color(0xFFFF5A89))
											)),
										),
										DataCell(
											SizedBox(width: 80, child: Text(
												event['title'] ?? 'Untitled',
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(fontSize: 10)
											)),
											onTap: _isSelecting ? null : () {
												showDialog(
													context: context, 
													builder: (context) {
														return AlertDialog(
															backgroundColor: const Color(0xFFFFF6F6),
															shape: RoundedRectangleBorder(
																borderRadius: BorderRadius.circular(10),
															),
															contentPadding: const EdgeInsets.all(24),
															content: SingleChildScrollView(
																child: Column(
																	mainAxisSize: MainAxisSize.min,
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
																		HtmlWidget(
																		event['title'] ?? '',
																		textStyle: const TextStyle(fontSize: 16),
																		),
																		const SizedBox(height: 8),
																		Text("Category: ${event['category'] ?? 'N/A'}"),
																		Text("Status: ${event['event_status'] ?? 'N/A'}"),
																		Text("Date: ${formatDate(event['event_date'] ?? '')}"),
																		const SizedBox(height: 8),
																		const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
																		const SizedBox(height: 4),
															HtmlWidget(
																		(event['content'] ?? 'No content.').replaceAll('http://localhost', 'http://10.0.2.2'),
																		baseUrl: Uri.parse('http://10.0.2.2'),
																		),
																		const SizedBox(height: 20),
																		Row(
																			children: [
																				Spacer(), // pushes buttons to the right
																				ElevatedButton.icon(
																					onPressed: () async {
																						final confirm = await showDialog<bool>(
																							context: context,
																							builder: (context) => AlertDialog(
																								title: const Text("Delete Event"),
																								content: const Text("Are you sure you want to delete this event?"),
																								actions: [
																									TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
																									TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
																								],
																							),
																						);

																						if (confirm == true) {
																							final deleteResponse = await http.post(
																								Uri.parse('http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/delete_event.php'),
																								headers: {'Content-Type': 'application/json'},
																								body: jsonEncode({"event_id": event['event_id']}),
																							);

																							final deleteResult = jsonDecode(deleteResponse.body);
																							if (deleteResult['success']) {
																								Navigator.of(context).pop(); // Close the modal
																								ScaffoldMessenger.of(context).showSnackBar(
																									const SnackBar(content: Text("Event deleted successfully.")),
																								);
																								_loadEvents(); // Reload events after deletion
																							} else {
																								ScaffoldMessenger.of(context).showSnackBar(
																									SnackBar(content: Text("Failed to delete: ${deleteResult['error']}")),
																								);
																							}
																						}
																					},
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
																						showEventDialog(context, isEdit: true, eventData: event);
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
																	],
																),
															),
														);
													},
												);
											},
										),
										DataCell(SizedBox(width: 60, child: Text(
											event['event_status'] ?? 'Unknown',
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(fontSize: 10)
										))),
										DataCell(SizedBox(width: 65, child: Text(
											formatDate(event['event_date'] ?? ''),
											style: const TextStyle(fontSize: 10)
										))),
									],
								);
							}).toList(),
						),
					),
						),
					// Pagination controls UI
// ADDED: Pagination controls UI with the design you requested
if (events.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous page button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: _currentPage > 1
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
              color: _currentPage > 1 ? const Color(0xFFFF5A89) : Colors.grey,
            ),
            const SizedBox(width: 8),
            
            // Page number indicators with custom styling
            for (int i = 1; i <= _totalPages; i++)
              if (_totalPages <= 5 || 
                  i == 1 || 
                  i == _totalPages || 
                  (i >= _currentPage - 1 && i <= _currentPage + 1))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  // MODIFIED: Use different widgets based on whether page is selected
                  child: i == _currentPage
                    // Selected page: Circle with pink background
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A89),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$i',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    // Unselected page: Just the number with onTap
                    : InkWell(
                        onTap: () {
                          setState(() {
                            _currentPage = i;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$i',
                            style: const TextStyle(
                              color: Color(0xFF3D3D3D),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                )
              else if ((i == 2 && _currentPage > 3) || 
                       (i == _totalPages - 1 && _currentPage < _totalPages - 2))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(fontSize: 16)),
                ),
            const SizedBox(width: 8),
            
            // Next page button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _currentPage < _totalPages
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
              color: _currentPage < _totalPages ? const Color(0xFFFF5A89) : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Page info text
        Text(
          'Showing ${events.isEmpty ? 0 : startIndex + 1} to $endIndex of ${events.length} entries',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  ),
				],
			),
		);
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
									child:  TextField(
										controller: _searchController,
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
										onTap: () => showEventDialog(context),
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
							child: _isLoading
	? const Center(child: CircularProgressIndicator())
				: RefreshIndicator(
						onRefresh: _loadEvents,
						child: _filteredEvents.isEmpty
								?  ListView(
										children: [Center(child: Padding(
											padding: EdgeInsets.only(top: 100),
											child: Text('No events found.'),
										))],
									)
								: ListView(
										children: [
											_buildEventTable( _filteredEvents),
										],
									),
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

	Future<void> showEventDialog(
		BuildContext context, {
		bool isEdit = false,
		Map<String, dynamic>? eventData,
	}) async {
		TimeOfDay? pickedStartTime;
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
		final TextEditingController timeControllerEnd = TextEditingController();

		// If editing, pre-fill fields and existing image URL
		if (isEdit && eventData != null) {
			titleController.text = eventData['title'] ?? '';
			speakerController.text = eventData['event_speakers'] ?? '';
			contentController.text = eventData['content'] ?? '';
			venueController.text = eventData['event_venue'] ?? '';
			selectedCategory = eventData['category'];
			selectedStatus = eventData['event_status'];
			uploadedImageUrl = eventData['image_url'];
			dateController.text = eventData['event_date'] ?? '';
			timeController.text = eventData['event_start_time'] ?? '';
			timeControllerEnd.text = eventData['event_end_time'] ?? '';
		}

		await showDialog(
			context: context,
			barrierDismissible: false,
			builder: (BuildContext context) {
				return StatefulBuilder(
					builder: (context, setModalState) {
						 final htmlEditorController = HtmlEditorController();

						return Dialog(
							backgroundColor: const Color(0xFFFFF6F6),
							insetPadding: const EdgeInsets.symmetric(horizontal: 10),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(10),
							),
							child: SizedBox(
								width: MediaQuery.of(context).size.width,
								height: MediaQuery.of(context).size.height,
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
															isEdit ? 'EDIT EVENT' : 'ADD EVENT',
															style: const TextStyle(
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
												const Text('Image', style: TextStyle(fontWeight: FontWeight.bold)),
												const SizedBox(height: 6),
												Container(
													height: 180,
													color: Colors.grey[200],
													alignment: Alignment.center,
													child: pickedImage != null
															? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
															: (uploadedImageUrl != null
																	? Image.network(
																			'http://10.0.2.2$uploadedImageUrl',
																			fit: BoxFit.cover,
																		)
																	: const Text("Image Preview Here")),
												),
												const SizedBox(height: 6),
												Row(
													mainAxisAlignment: MainAxisAlignment.end,
													children: [
														ElevatedButton(
															onPressed: () async {
																final img_picker.XFile? image =
																		await picker.pickImage(source: img_picker.ImageSource.gallery);
																if (image != null) {
																	setModalState(() {
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
															onPressed: () {
																setModalState(() {
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
													items: ['Uncategorized', 'KALUSUGAN', 'KALIKASAN', 'KARUNUNGAN', 'KULTURA', 'KASARIAN']
															.map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
															.toList(),
													onChanged: (val) => selectedCategory = val,
												),
												const SizedBox(height: 12),

												// Venue (Map Picker)
												const Text('Venue', style: TextStyle(fontWeight: FontWeight.bold)),
												const SizedBox(height: 6),
												TextField(
													controller: venueController,
													readOnly: true,
													onTap: () async {
														final LatLng? pickedLocation = await Navigator.push(
															context,
															MaterialPageRoute(builder: (_) => MapPickerScreen()),
														);
														if (pickedLocation != null) {
															setModalState(() {
																venueController.text =
																		'${pickedLocation.latitude}, ${pickedLocation.longitude}';
															});
														}
													},
													decoration: InputDecoration(
														filled: true,
														fillColor: Colors.white,
														border: InputBorder.none,
														isDense: true,
														contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
														suffixIcon:
																const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
														suffixIconConstraints: const BoxConstraints(
															minHeight: 24, minWidth: 24, maxHeight: 24, maxWidth: 24,
														),
													),
												),
												const SizedBox(height: 12),

												// Only for "Add" mode: Date, Day, Start & End time
										
													Row(
														children: [
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
																				final now = DateTime.now();
																				final picked = await showDatePicker(
																					context: context,
																					initialDate: now,
																					firstDate: now,
																					lastDate: DateTime(2100),
																				);
																				if (picked != null) {
																					setModalState(() {
																						dateController.text = DateFormat('yyyy-MM-dd').format(picked);
																						dayController.text = getDayOfWeek(picked.weekday);
																					});
																				}
																			},
																			decoration: InputDecoration(
																				filled: true,
																				fillColor: Colors.white,
																				border: InputBorder.none,
																				isDense: true,
																				contentPadding:
																						const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
																				suffixIcon:
																						const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
																				suffixIconConstraints: const BoxConstraints(
																						minHeight: 24, minWidth: 24, maxHeight: 24, maxWidth: 24),
																			),
																		),
																	],
																),
															),
															const SizedBox(width: 12),
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
																				contentPadding:
																						EdgeInsets.symmetric(horizontal: 12, vertical: 8),
																			),
																		),
																	],
																),
															),
														],
													),
													const SizedBox(height: 12),
													Row(
														children: [
															Expanded(
																child: Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		const Text('Time Start',
																				style: TextStyle(fontWeight: FontWeight.bold)),
																		const SizedBox(height: 4),
																		TextField(
																			controller: timeController,
																			readOnly: true,
																			onTap: () async {
																				final picked = await showTimePicker(
																					context: context,
																					initialTime: TimeOfDay.now(),
																				);
																				if (picked != null) {
																					final selectedDate =
																							DateFormat("yyyy-MM-dd").parse(dateController.text);
																					final dt = DateTime(selectedDate.year, selectedDate.month,
																							selectedDate.day, picked.hour, picked.minute);
																					if (dt.isBefore(DateTime.now())) {
																						ScaffoldMessenger.of(context).showSnackBar(
																							const SnackBar(
																									content: Text("Start time cannot be in the past.")),
																						);
																						return;
																					}
																					setModalState(() {
																						pickedStartTime = picked;
																						timeController.text = picked.format(context);
																					});
																				}
																			},
																			decoration: const InputDecoration(
																				filled: true,
																				fillColor: Colors.white,
																				border: InputBorder.none,
																				isDense: true,
																				contentPadding:
																						EdgeInsets.symmetric(horizontal: 12, vertical: 8),
																				suffixIcon: Icon(Icons.access_time, size: 15, color: Colors.grey),
																				suffixIconConstraints:
																						BoxConstraints(minHeight: 24, minWidth: 24),
																			),
																		),
																	],
																),
															),
															const SizedBox(width: 12),
															Expanded(
																child: Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		const Text('Time End',
																				style: TextStyle(fontWeight: FontWeight.bold)),
																		const SizedBox(height: 4),
																		TextField(
																			controller: timeControllerEnd,
																			readOnly: true,
																			onTap: () async {
																				final picked = await showTimePicker(
																					context: context,
																					initialTime: TimeOfDay.now(),
																				);
																				if (picked != null) {
																					if (pickedStartTime == null) {
																						ScaffoldMessenger.of(context).showSnackBar(
																							const SnackBar(
																									content:
																											Text("Please select the start time first.")),
																						);
																						return;
																					}
																					final selectedDate =
																							DateFormat("yyyy-MM-dd").parse(dateController.text);
																					final start = DateTime(
																							selectedDate.year,
																							selectedDate.month,
																							selectedDate.day,
																							pickedStartTime!.hour,
																							pickedStartTime!.minute);
																					final end = DateTime(selectedDate.year, selectedDate.month,
																							selectedDate.day, picked.hour, picked.minute);
																					if (end.isBefore(start)) {
																						ScaffoldMessenger.of(context).showSnackBar(
																							const SnackBar(
																									content: Text("End time cannot be before start.")),
																						);
																						return;
																					}
																					setModalState(() {
																						timeControllerEnd.text = picked.format(context);
																					});
																				}
																			},
																			decoration: const InputDecoration(
																				filled: true,
																				fillColor: Colors.white,
																				border: InputBorder.none,
																				isDense: true,
																				contentPadding:
																						EdgeInsets.symmetric(horizontal: 12, vertical: 8),
																				suffixIcon: Icon(Icons.access_time, size: 15, color: Colors.grey),
																				suffixIconConstraints:
																						BoxConstraints(minHeight: 24, minWidth: 24),
																			),
																		),
																	],
																),
															),
														],
													),
													const SizedBox(height: 12),
												

												// Status (with limited choices when editing)
												const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
												const SizedBox(height: 6),
												isEdit? DropdownButtonFormField<String>(
														value: selectedStatus,
														decoration: const InputDecoration(
															filled: true,
															fillColor: Colors.white,
															border: InputBorder.none,
															isDense: true,
															contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
														),
														items: ['UPCOMING', 'CANCELLED', 'COMPLETED', 'ONGOING']
																.map((stat) => DropdownMenuItem(value: stat, child: Text(stat)))
																.toList(),
														onChanged: (val) => selectedStatus = val,
													)
												: const TextField(
														readOnly: true,
														decoration: InputDecoration(
															filled: true,
															fillColor: Colors.white,
															border: InputBorder.none,
															isDense: true,
															contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
															hintText: 'UPCOMING',
														),
													),
												const SizedBox(height: 12),

												// Speakers
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

												// Content
											const Text('Content', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 6),

// Create a controller for the HTML Editor
// HTML Editor component
Container(
  height: 300,  // Adjust height as needed
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: HtmlEditor(
    controller: htmlEditorController,
    htmlEditorOptions: HtmlEditorOptions(
      hint: 'Enter your content here...',
      initialText: contentController.text,
    ),
    htmlToolbarOptions: HtmlToolbarOptions(
      toolbarPosition: ToolbarPosition.aboveEditor,
      toolbarType: ToolbarType.nativeScrollable,
      defaultToolbarButtons: [
        StyleButtons(), // Bold, italic, underline buttons
        FontButtons(), // Font formatting without parameters
        ListButtons(), // Bullet and numbered lists
        InsertButtons(picture: true), // Just enable the image upload
      ],
    ),
    callbacks: Callbacks(
      onInit: () {
        if (isEdit && eventData != null && eventData['content'] != null) {
          htmlEditorController.setText(eventData['content']);
        }
      },
      onChangeContent: (String? changed) {
        if (changed != null) {
          contentController.text = changed;
        }
      },
    ),
  ),
),
const SizedBox(height: 20),

												// Submit button
												Row(
													mainAxisAlignment: MainAxisAlignment.end,
													children: [
														ElevatedButton(
															onPressed: () async {
																//   final htmlContent = await htmlEditorController.getText();
																// contentController.text = htmlContent;	

																// Basic validation
																if (titleController.text.isEmpty ||
																		(!isEdit && pickedImage == null && uploadedImageUrl == null)) {
																	ScaffoldMessenger.of(context).showSnackBar(
																		const SnackBar(
																				content: Text("Title and image are required")),
																	);
																	return;
																}
																
															

																// If a new image was picked, upload it
																if (pickedImage != null) {
																	final url = await uploadEventImage(pickedImage!);
																	if (url == null) {
																		ScaffoldMessenger.of(context).showSnackBar(
																			const SnackBar(
																					content: Text("Image upload failed. Try again.")),
																		);
																		return;
																	}
																	uploadedImageUrl = url;
																}

																// Build payload
																final payload = <String, dynamic>{
																	if (isEdit) 'event_id': eventData!['event_id'],
																	'title': titleController.text,
																	'category': selectedCategory ?? 'Uncategorized',
																	'event_venue': venueController.text,
																	'event_status': isEdit ? (selectedStatus ?? 'UPCOMING') : 'UPCOMING',
																	'event_speakers': speakerController.text,
																	'content': contentController.text,
																	'image_url': uploadedImageUrl,
																	'event_date': dateController.text,
																	'event_start_time': timeController.text,
																	'event_end_time': timeControllerEnd.text,
																};

																final uri = Uri.parse(isEdit
																		? 'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/update_event.php'
																		: 'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api/add_new_event.php');

																final response = await http.post(
																	uri,
																	headers: {'Content-Type': 'application/json'},
																	body: jsonEncode(payload),
																);
																final result = jsonDecode(response.body);

																if (result['success'] == true) {
																	ScaffoldMessenger.of(context).showSnackBar(
																		SnackBar(
																			content: Text(isEdit
																					? "Event updated successfully"
																					: "Event added successfully"),
																		),
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
																backgroundColor: isEdit
																		? const Color.fromARGB(255, 54, 230, 139)
																		: const Color.fromARGB(255, 54, 230, 139),
																foregroundColor: Colors.white,
																padding: const EdgeInsets.symmetric(
																		horizontal: 15, vertical: 5),
																shape: RoundedRectangleBorder(
																		borderRadius: BorderRadius.circular(6)),
															),
															child: Text(
																isEdit ? 'Save Changes' : 'Add Event',
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
					},
				);
			},
		);
	}