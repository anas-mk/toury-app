import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helpers_cubit.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import 'booking_confirmation_page.dart';

class HelperProfilePage extends StatelessWidget {
  final String helperId;

  const HelperProfilePage({super.key, required this.helperId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HelpersCubit>()..loadProfile(helperId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Helper Profile')),
        body: BlocBuilder<HelpersCubit, HelpersState>(
          builder: (context, state) {
            if (state is HelpersLoading) {
              return const LoadingIndicator();
            } else if (state is HelpersError) {
              return ErrorView(
                message: state.message,
                onRetry: () => context.read<HelpersCubit>().loadProfile(helperId),
              );
            } else if (state is HelperProfileSuccess) {
              final helper = state.helper;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: helper.profileImageUrl != null
                          ? NetworkImage(helper.profileImageUrl!)
                          : null,
                      child: helper.profileImageUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(helper.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(' ${helper.rating} (${helper.reviewsCount} reviews)'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Languages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: helper.languages.map((l) => Chip(label: Text(l))).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Professional helper ready to assist you with your needs.'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationPage(helper: helper),
                            ),
                          );
                        },
                        child: Text('Book Now (\$${helper.pricePerHour}/hr)'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
