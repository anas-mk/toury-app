import 'package:flutter/material.dart';
import '../../domain/entities/helper_entity.dart';
import '../widgets/helper_card.dart';
import '../widgets/empty_state.dart';
import 'helper_profile_page.dart';
import 'booking_confirmation_page.dart';

class HelpersListPage extends StatelessWidget {
  final List<HelperEntity> helpers;

  const HelpersListPage({super.key, required this.helpers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: helpers.isEmpty
          ? const EmptyState(message: 'No helpers found for your criteria.')
          : ListView.builder(
              itemCount: helpers.length,
              itemBuilder: (context, index) {
                final helper = helpers[index];
                return HelperCard(
                  helper: helper,
                  onViewProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HelperProfilePage(helperId: helper.id),
                      ),
                    );
                  },
                  onBook: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationPage(helper: helper),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
