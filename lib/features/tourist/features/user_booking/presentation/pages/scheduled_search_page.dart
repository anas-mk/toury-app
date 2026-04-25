import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
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
    return BlocProvider(
      create: (context) => sl<SearchHelpersCubit>(),
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Map Background
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.toury.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      child: const Icon(Icons.location_on, color: AppColor.primaryColor, size: 45),
                    ),
                  ],
                ),
              ],
            ),

            // 2. Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            // 3. Top Search Card
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              right: 20,
              child: CustomCard(
                variant: CardVariant.glass,
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _destinationController,
                      label: 'Destination',
                      hintText: 'Where to?',
                      prefixIcon: Icons.search,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            Icons.calendar_month,
                            DateFormat('MMM dd').format(_selectedDate),
                            _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPickerTile(
                            Icons.access_time,
                            _selectedTime.format(context),
                            _pickTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Results / Action
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColor.primaryColor),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showResults)
            CustomButton(
              text: 'Find Available Helpers',
              onPressed: _performSearch,
            )
          else
            _buildResultsList(),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Helpers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
            builder: (context, state) {
              if (state is SearchHelpersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchHelpersLoaded) {
                if (state.helpers.isEmpty) return const Center(child: Text('No helpers found'));
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.helpers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
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
              return const Text('Search for helpers');
            },
          ),
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Edit Trip Details',
          variant: ButtonVariant.text,
          onPressed: () => setState(() => _showResults = false),
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
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }
}
