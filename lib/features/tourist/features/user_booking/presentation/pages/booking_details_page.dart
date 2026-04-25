import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_bottom_sheet.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_details_cubit.dart';
import '../cubits/cancel_booking_cubit.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final BookingDetailEntity? initialBooking;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<BookingDetailsCubit>()..getBookingDetails(widget.bookingId)),
        BlocProvider(create: (context) => sl<CancelBookingCubit>()),
      ],
      child: Scaffold(
        body: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
          builder: (context, state) {
            BookingDetailEntity? booking = widget.initialBooking;
            if (state is BookingDetailsLoaded) {
              booking = state.booking;
            }

            if (booking == null && state is BookingDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (booking == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load booking'),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: 'Retry',
                      onPressed: () => context.read<BookingDetailsCubit>().getBookingDetails(widget.bookingId),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // 1. Dynamic Map or Header
                _buildHeader(booking),

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

                // 3. Status Action
                if (booking.status == BookingStatus.pending)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        onPressed: () => _showCancelSheet(context, widget.bookingId),
                      ),
                    ),
                  ),

                // 4. Content Sheet
                _buildDetailsSheet(context, booking),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BookingDetailEntity booking) {
    final showMap = booking.status == BookingStatus.inProgress || booking.status == BookingStatus.confirmed;
    
    if (showMap) {
      final helperLoc = LatLng(booking.helper?.latitude ?? 30.0444, booking.helper?.longitude ?? 31.2357);
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: helperLoc,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.toury.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: helperLoc,
                  width: 50,
                  height: 50,
                  child: _buildMarkerIcon(booking.helper?.profileImageUrl ?? '', Colors.green),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primaryColor, Color(0xFF1E3A8A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, color: Colors.white, size: 64),
            const SizedBox(height: 15),
            Text(
              'Trip ID: #${widget.bookingId.substring(widget.bookingId.length - 6).toUpperCase()}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerIcon(String imageUrl, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        border: Border.all(color: color, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AppNetworkImage(imageUrl: imageUrl, width: 40, height: 40),
      ),
    );
  }

  Widget _buildDetailsSheet(BuildContext context, BookingDetailEntity booking) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(booking.status),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.requestedDate),
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildHelperSection(context, booking),
              const SizedBox(height: 32),
              const Text('Trip Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTripInfo(booking),
              const SizedBox(height: 32),
              const Text('Trip Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTimeline(booking.timeline),
              const SizedBox(height: 32),
              if (booking.priceBreakdown != null) ...[
                const Text('Payment Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPriceSection(booking),
              ],
              const SizedBox(height: 40),
              if (booking.status == BookingStatus.inProgress || booking.status == BookingStatus.confirmed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(
                    text: 'Track Live',
                    icon: Icons.map_outlined,
                    color: AppColor.primaryColor,
                    onPressed: () {
                      context.push(
                        '/user-tracking/${booking.id}?pickupLat=${booking.pickupLatitude ?? 0}&pickupLng=${booking.pickupLongitude ?? 0}&destLat=${booking.destinationLatitude ?? 0}&destLng=${booking.destinationLongitude ?? 0}',
                      );
                    },
                  ),
                ),
              if (booking.chatEnabled)
                CustomButton(
                  text: 'Chat with Helper',
                  icon: Icons.chat_bubble_outline,
                  onPressed: () {
                    context.push(
                      '/user-chat/${booking.id}?name=${booking.helper?.name ?? "Helper"}&image=${booking.helper?.profileImageUrl ?? ""}',
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String text;
    switch (status) {
      case BookingStatus.pending: color = Colors.orange; text = 'Pending'; break;
      case BookingStatus.confirmed: color = Colors.green; text = 'Confirmed'; break;
      case BookingStatus.inProgress: color = AppColor.primaryColor; text = 'On Trip'; break;
      case BookingStatus.completed: color = Colors.grey; text = 'Completed'; break;
      case BookingStatus.cancelled: color = Colors.red; text = 'Cancelled'; break;
      case BookingStatus.declined: color = Colors.red; text = 'Declined'; break;
      default: color = Colors.black; text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHelperSection(BuildContext context, BookingDetailEntity booking) {
    if (booking.helper == null) {
      return CustomCard(
        variant: CardVariant.outlined,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Waiting for Helper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('We are assigning someone...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }

    final helper = booking.helper!;
    return CustomCard(
      variant: CardVariant.elevated,
      onTap: () => context.push('/helper-profile/${helper.id}', extra: {'helper': helper}),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(imageUrl: helper.profileImageUrl ?? '', width: 64, height: 64),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helper.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${helper.rating} • Tour Guide', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.phone, color: AppColor.primaryColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(BookingDetailEntity booking) {
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_outlined, 'Destination', booking.destinationCity),
          const Divider(height: 24),
          _buildInfoRow(Icons.timer_outlined, 'Duration', '${booking.durationInMinutes} Minutes'),
          if (booking.startTime != null) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time_outlined, 'Start Time', booking.startTime!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColor.primaryColor, size: 22),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(List<BookingTimelineStep> timeline) {
    return Column(
      children: timeline.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == timeline.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.3), blurRadius: 6)],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColor.primaryColor.withOpacity(0.2)),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(step.status),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(step.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (step.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(step.description!, style: const TextStyle(fontSize: 13, height: 1.4)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 'Request Sent';
      case BookingStatus.confirmed: return 'Confirmed by Helper';
      case BookingStatus.inProgress: return 'Trip Started';
      case BookingStatus.completed: return 'Trip Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.declined: return 'Declined';
      default: return 'Status Updated';
    }
  }

  Widget _buildPriceSection(BookingDetailEntity booking) {
    final pb = booking.priceBreakdown!;
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPriceRow('Base Fee', '\$${pb.basePrice}'),
          _buildPriceRow('Duration Fee', '\$${pb.durationPrice}'),
          if (pb.carSurcharge > 0) _buildPriceRow('Car Surcharge', '\$${pb.carSurcharge}'),
          _buildPriceRow('Service Fee', '\$${pb.serviceFee}'),
          const Divider(height: 24),
          _buildPriceRow('Total Amount', '\$${pb.total}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? AppColor.primaryColor : Colors.black)),
        ],
      ),
    );
  }

  void _showCancelSheet(BuildContext context, String bookingId) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: 'Cancel Trip',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel? Please provide a reason.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            BlocConsumer<CancelBookingCubit, CancelBookingState>(
              bloc: context.read<CancelBookingCubit>(),
              listener: (context, state) {
                if (state is CancelBookingSuccess) {
                  Navigator.pop(ctx);
                  context.read<BookingDetailsCubit>().getBookingDetails(bookingId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled successfully.')));
                }
              },
              builder: (context, state) {
                return CustomButton(
                  text: 'Cancel My Trip',
                  color: Colors.red,
                  isLoading: state is CancelBookingLoading,
                  onPressed: () {
                    if (reasonController.text.isNotEmpty) {
                      context.read<CancelBookingCubit>().cancelBooking(bookingId, reasonController.text);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
