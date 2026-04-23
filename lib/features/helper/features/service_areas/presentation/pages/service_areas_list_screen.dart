import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../profile/presentation/widgets/empty_states/empty_state_card.dart';
import '../../domain/entities/service_area_entity.dart';
import '../cubit/helper_service_areas_cubit.dart';
import '../cubit/helper_service_areas_state.dart';
import '../widgets/service_area_card.dart';
import 'add_edit_service_area_screen.dart';

class ServiceAreasListScreen extends StatefulWidget {
  const ServiceAreasListScreen({super.key});

  @override
  State<ServiceAreasListScreen> createState() => _ServiceAreasListScreenState();
}

class _ServiceAreasListScreenState extends State<ServiceAreasListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperServiceAreasCubit>().getServiceAreas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        title: 'Service Areas',
      ),
      body: BlocConsumer<HelperServiceAreasCubit, HelperServiceAreasState>(
        listener: (context, state) {
          if (state is HelperServiceAreasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
        builder: (context, state) {
          if (state is HelperServiceAreasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HelperServiceAreasLoaded) {
            final areas = state.serviceAreas;

            if (areas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Center(
                  child: EmptyStateCard(
                    icon: Icons.map_outlined,
                    title: 'No Service Areas',
                    description: 'Add a service area to appear in scheduled bookings',
                    actionLabel: 'Add Service Area',
                    onAction: () => _navigateToAddEdit(context),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<HelperServiceAreasCubit>().getServiceAreas(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                itemCount: areas.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return ServiceAreaCard(
                    area: area,
                    onEdit: () => _navigateToAddEdit(context, area: area),
                    onDelete: () => _confirmDelete(context, area, areas.length == 1),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<HelperServiceAreasCubit, HelperServiceAreasState>(
        builder: (context, state) {
          if (state is HelperServiceAreasLoaded && state.serviceAreas.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: CustomButton(
                text: 'Add New Area',
                icon: Icons.add,
                onPressed: () => _navigateToAddEdit(context),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _navigateToAddEdit(BuildContext context, {ServiceAreaEntity? area}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HelperServiceAreasCubit>(),
          child: AddEditServiceAreaScreen(area: area),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServiceAreaEntity area, bool isLast) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service Area'),
        content: Text(
          isLast
              ? 'Are you sure? You will not appear in scheduled bookings if you delete your only service area.'
              : 'Are you sure you want to delete this service area?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HelperServiceAreasCubit>().deleteServiceArea(area.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: AppColor.errorColor)),
          ),
        ],
      ),
    );
  }
}
