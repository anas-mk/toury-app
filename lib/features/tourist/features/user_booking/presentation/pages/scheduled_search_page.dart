import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/search_params.dart';
import '../cubits/search_helpers_cubit.dart';
import '../widgets/helper_search_item.dart';

class ScheduledSearchPage extends StatefulWidget {
  final String? initialDestination;
  const ScheduledSearchPage({super.key, this.initialDestination});

  @override
  State<ScheduledSearchPage> createState() => _ScheduledSearchPageState();
}

class _ScheduledSearchPageState extends State<ScheduledSearchPage> {
  final MapController _mapController = MapController();
  final _destinationController = TextEditingController();
  LatLng _center = const LatLng(30.0444, 31.2357);
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 120;
  bool _requiresCar = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  void _performSearch() {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination city')),
      );
      return;
    }
    setState(() => _showResults = true);
    context.read<SearchHelpersCubit>().searchScheduled(ScheduledSearchParams(
      destinationCity: _destinationController.text,
      requestedDate: _selectedDate,
      startTime: '${_selectedTime.hour}:${_selectedTime.minute}',
      durationInMinutes: _duration,
      requestedLanguage: 'English',
      requiresCar: _requiresCar,
      travelersCount: 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.toury.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(point: _center, child: const Icon(Icons.location_on, color: Colors.black, size: 45)),
                ],
              ),
            ],
          ),

          // 2. Safe Area UI
          SafeArea(
            child: Column(
              children: [
                // Top Search Panel
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      // Header with Back Button
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 8, right: 16),
                        child: Row(
                          children: [
                            IconButton(icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black), onPressed: () => context.pop()),
                            Text('Plan your trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          ],
                        ),
                      ),
                      // Inputs
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _destinationController,
                              hintText: 'Where to?',
                              prefixIcon: Icons.search,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildPickerTile(Icons.calendar_today, DateFormat('MMM dd').format(_selectedDate), _pickDate, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildPickerTile(Icons.access_time, _selectedTime.format(context), _pickTime, isDark)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Results / Action
                _buildBottomUI(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String text, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomUI(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showResults)
            CustomButton(text: 'Search Helpers', onPressed: _performSearch, isFullWidth: true)
          else
            _buildResultsList(isDark),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available Helpers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => setState(() => _showResults = false),
              child: const Text('Edit Search', style: TextStyle(color: AppColor.secondaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
            builder: (context, state) {
              if (state is SearchHelpersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchHelpersLoaded) {
                if (state.helpers.isEmpty) return const Center(child: Text('No helpers found in this area.'));
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: state.helpers.length,
                  separatorBuilder: (context, index) => Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final helper = state.helpers[index];
                    return HelperSearchItem(
                      helper: helper,
                      onTap: () => context.push('/helper-profile/${helper.id}', extra: {
                        'helper': helper,
                        'searchParams': ScheduledSearchParams(
                          destinationCity: _destinationController.text,
                          requestedDate: _selectedDate,
                          startTime: '${_selectedTime.hour}:${_selectedTime.minute}',
                          durationInMinutes: _duration,
                          requestedLanguage: 'English',
                          requiresCar: _requiresCar,
                          travelersCount: 1,
                        ),
                      }),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }
}
