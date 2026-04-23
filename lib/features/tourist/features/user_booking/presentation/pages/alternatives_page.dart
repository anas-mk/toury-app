import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helpers_cubit.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state.dart';
import 'helper_profile_page.dart';

class AlternativesPage extends StatelessWidget {
  final String bookingId;

  const AlternativesPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HelpersCubit>()..loadAlternatives(bookingId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Alternative Helpers')),
        body: BlocBuilder<HelpersCubit, HelpersState>(
          builder: (context, state) {
            if (state is HelpersLoading) {
              return const LoadingIndicator();
            } else if (state is HelpersError) {
              return ErrorView(
                message: state.message,
                onRetry: () => context.read<HelpersCubit>().loadAlternatives(bookingId),
              );
            } else if (state is AlternativesSuccess) {
              final alternatives = state.alternatives;
              
              if (alternatives.isEmpty) {
                return const EmptyState(message: 'No alternatives available right now.');
              }

              return ListView.builder(
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(alt.name),
                      subtitle: Text('Distance: ${alt.distance} km \nRating: ${alt.rating}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HelperProfilePage(helperId: alt.id)),
                          );
                        },
                        child: const Text('View'),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
