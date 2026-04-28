import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../domain/entities/search_params.dart';
import '../cubits/search_helpers_cubit.dart';
import '../cubits/search_helpers_state.dart';
import '../widgets/helper_search_card.dart';

class ScheduledSearchPage extends StatefulWidget {
  final String? initialDestination;

  const ScheduledSearchPage({super.key, this.initialDestination});

  @override
  State<ScheduledSearchPage> createState() => _ScheduledSearchPageState();
}

class _ScheduledSearchPageState extends State<ScheduledSearchPage> {
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  int _hours = 4; // Default trip duration

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('scheduled_search')),
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: AppTheme.shadowLight(context),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: loc.translate('enter_destination'),
                    prefixIcon: const Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColor.lightBorder),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(_startDate == null ? 'Date' : DateFormat('MMM dd').format(_startDate!)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColor.lightBorder),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(_startTime == null ? 'Time' : _startTime!.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),
                CustomButton(
                  text: loc.translate('search_helpers'),
                  onPressed: _onSearch,
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
              builder: (context, state) {
                if (state is SearchHelpersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SearchHelpersError) {
                  return Center(child: Text(state.message));
                }
                if (state is SearchHelpersLoaded) {
                  if (state.helpers.isEmpty) {
                    return const Center(child: Text('No helpers found for this criteria'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    itemCount: state.helpers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
                    itemBuilder: (context, index) {
                      return HelperSearchCard(
                        helper: state.helpers[index],
                        onTap: () => context.pushNamed(
                          'helper-profile',
                          pathParameters: {'id': state.helpers[index].id},
                          extra: {
                            'helper': state.helpers[index],
                            'searchParams': _getSearchParams(),
                            'isInstant': false,
                          },
                        ),
                      );
                    },
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded, size: 64, color: AppColor.lightBorder),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text(
                        'Search for helpers in your destination',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ScheduledSearchParams _getSearchParams() {
    return ScheduledSearchParams(
      destinationCity: _destinationController.text,
      requestedDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      startTime: _startTime != null ? '${_startTime!.hour}:${_startTime!.minute}' : '09:00',
      durationInMinutes: _hours * 60,
      requestedLanguage: 'English',
      requiresCar: false,
      travelersCount: 1,
    );
  }

  void _onSearch() {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    context.read<SearchHelpersCubit>().searchScheduled(_getSearchParams());
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }
}
