import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/entities/location_entity.dart';
import '../../../maps/presentation/pages/map_screen.dart';
import '../cubit/search_helpers_cubit.dart';
import 'helpers_list_page.dart';

class SearchHelpersPage extends StatelessWidget {
  const SearchHelpersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchHelpersCubit>(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Find a Helper'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Scheduled'),
                Tab(text: 'Instant'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ScheduledSearchTab(),
              _InstantSearchTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledSearchTab extends StatefulWidget {
  const _ScheduledSearchTab();

  @override
  State<_ScheduledSearchTab> createState() => _ScheduledSearchTabState();
}

class _ScheduledSearchTabState extends State<_ScheduledSearchTab> {
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController(text: '120'); // Default 2 hours
  DateTime? _selectedDateTime;
  String _selectedLanguage = 'English';
  bool _needArabic = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchHelpersCubit, SearchHelpersState>(
      listener: (context, state) {
        if (state is SearchHelpersSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HelpersListPage(helpers: state.helpers)),
          );
        } else if (state is SearchHelpersError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        _dateController.text = "${date.toString().split(' ')[0]} ${time.format(context)}";
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (in minutes)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 120 for 2 hours',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                items: ['English', 'French', 'Spanish', 'German']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLanguage = val ?? 'English'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Need Arabic Support?'),
                value: _needArabic,
                onChanged: (val) => setState(() => _needArabic = val),
              ),
              const SizedBox(height: 32),
              BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is SearchHelpersLoading
                        ? null
                        : () {
                            if (_selectedDateTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select Date & Time')),
                              );
                              return;
                            }
                            context.read<SearchHelpersCubit>().searchScheduledHelpers(
                                  destination: _destinationController.text,
                                  date: _selectedDateTime!,
                                  language: _selectedLanguage,
                                  needArabic: _needArabic,
                                  durationInMinutes: int.tryParse(_durationController.text) ?? 120,
                                );
                          },
                    child: state is SearchHelpersLoading
                        ? const CircularProgressIndicator()
                        : const Text('Search Scheduled Helpers'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstantSearchTab extends StatefulWidget {
  const _InstantSearchTab();

  @override
  State<_InstantSearchTab> createState() => _InstantSearchTabState();
}

class _InstantSearchTabState extends State<_InstantSearchTab> {
  LocationEntity? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchHelpersCubit, SearchHelpersState>(
      listener: (context, state) {
        if (state is SearchHelpersSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HelpersListPage(helpers: state.helpers)),
          );
        } else if (state is SearchHelpersError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.map, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            if (_selectedLocation != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(_selectedLocation!.address),
                  subtitle: Text('${_selectedLocation!.lat}, ${_selectedLocation!.lng}'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                // Navigate to Map Screen
                final result = await Navigator.push<LocationEntity>(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                );
                
                if (result != null) {
                  setState(() {
                    _selectedLocation = result;
                  });
                  // MapCubit fires LocationSelected event and SearchHelpersCubit listens to it automatically!
                }
              },
              icon: const Icon(Icons.place),
              label: const Text('Select from Map'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
              builder: (context, state) {
                if (state is SearchHelpersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_selectedLocation == null && state is SearchHelpersError) {
                  return const Text(
                    'Please select a location first.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
