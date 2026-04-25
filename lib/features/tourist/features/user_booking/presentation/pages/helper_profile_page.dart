import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../cubits/booking_details_cubit.dart';

class HelperProfilePage extends StatelessWidget {
  final String helperId;
  final HelperBookingEntity? initialHelper;
  final dynamic searchParams;
  final bool isInstant;

  const HelperProfilePage({
    super.key,
    required this.helperId,
    this.initialHelper,
    this.searchParams,
    this.isInstant = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BookingDetailsCubit>()..getHelperProfile(helperId),
      child: Scaffold(
        body: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
          builder: (context, state) {
            HelperBookingEntity? helper = initialHelper;
            if (state is HelperProfileLoaded) {
              helper = state.helper;
            }

            if (helper == null && state is HelperProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (helper == null) {
              return const Center(child: Text('Failed to load helper profile'));
            }

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, helper),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStats(helper),
                        const SizedBox(height: 25),
                        _buildSection('Bio', helper.bio ?? 'No bio provided'),
                        const SizedBox(height: 25),
                        _buildLanguages(helper),
                        const SizedBox(height: 25),
                        _buildServiceAreas(helper),
                        const SizedBox(height: 25),
                        if (helper.car != null) _buildCarDetails(helper.car!),
                        const SizedBox(height: 25),
                        _buildExperience(helper),
                        const SizedBox(height: 100), // Spacing for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: CustomButton(
            text: 'Continue to Booking',
            onPressed: () {
              context.push('/booking-confirm', extra: {
                'helper': initialHelper, // Use initial or loaded
                'searchParams': searchParams,
                'isInstant': isInstant,
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HelperBookingEntity helper) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'helper_image_${helper.id}',
          child: AppNetworkImage(
            imageUrl: helper.profileImageUrl ?? '',
            fit: BoxFit.cover,
          ),
        ),
      ),
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildStats(HelperBookingEntity helper) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Rating', helper.rating.toString(), Icons.star, Colors.amber),
        _buildStatItem('Trips', helper.completedTrips.toString(), Icons.directions_walk, Colors.blue),
        _buildStatItem('Acceptance', '${helper.acceptanceRate}%', Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(color: Colors.black87, height: 1.5)),
      ],
    );
  }

  Widget _buildLanguages(HelperBookingEntity helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Languages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: helper.languages.map((lang) => Chip(label: Text(lang))).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceAreas(HelperBookingEntity helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Areas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: helper.serviceAreas.map((area) => Chip(
            label: Text(area.city),
            backgroundColor: Colors.blue[50],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCarDetails(CarEntity car) {
    return CustomCard(
      backgroundColor: Colors.grey[50],
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: Colors.blue),
        title: Text('${car.color} ${car.model}'),
        subtitle: Text('Plate: ${car.plateNumber} • ${car.year}'),
      ),
    );
  }

  Widget _buildExperience(HelperBookingEntity helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('${helper.experienceYears} Years'),
      ],
    );
  }
}
