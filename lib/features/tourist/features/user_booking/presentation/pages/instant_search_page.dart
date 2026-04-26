import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/search_params.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../cubits/search_helpers_cubit.dart';
import '../cubits/search_helpers_state.dart';
import '../widgets/helper_search_card.dart';

class InstantSearchPage extends StatefulWidget {
  final HelperBookingEntity? preSelectedHelper;

  const InstantSearchPage({super.key, this.preSelectedHelper});

  @override
  State<InstantSearchPage> createState() => _InstantSearchPageState();
}

class _InstantSearchPageState extends State<InstantSearchPage> {
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // In a real app, we might use current location to pre-fill city
    _cityController.text = 'Cairo'; 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('instant_search')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Enter city',
                prefixIcon: const Icon(Icons.near_me_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
              builder: (context, state) {
                if (state is SearchHelpersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SearchHelpersLoaded) {
                  if (state.helpers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_off_rounded, size: 64, color: AppColor.lightBorder),
                          const SizedBox(height: AppTheme.spaceMD),
                          const Text('No helpers currently available in this area'),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    itemCount: state.helpers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
                    itemBuilder: (context, index) {
                      final helper = state.helpers[index];
                      return HelperSearchCard(
                        helper: helper,
                        onTap: () => context.pushNamed(
                          'helper-profile',
                          pathParameters: {'id': helper.id},
                          extra: {
                            'helper': helper,
                            'searchParams': InstantSearchParams(
                              pickupLocationName: _cityController.text,
                              pickupLatitude: 0.0,
                              pickupLongitude: 0.0,
                              durationInMinutes: 60,
                              requestedLanguage: 'English',
                              requiresCar: false,
                              travelersCount: 1,
                            ),
                            'isInstant': true,
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearch() {
    if (_cityController.text.isNotEmpty) {
      context.read<SearchHelpersCubit>().searchInstant(
        InstantSearchParams(
          pickupLocationName: _cityController.text,
          pickupLatitude: 0.0,
          pickupLongitude: 0.0,
          durationInMinutes: 60,
          requestedLanguage: 'English',
          requiresCar: false,
          travelersCount: 1,
        ),
      );
    }
  }
}
