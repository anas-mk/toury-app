import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/meeting_point_type.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/booking_cubit.dart';
import '../../cubits/booking_state.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF000668);
const _kBlue = Color(0xFF4851C4);
const _kAmber = Color(0xFFFE9331);
const _kSurface = Color(0xFFFBF8FF);
const _kCard = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF767683);
const _kContainerLow = Color(0xFFF4F2FF);
const _kOutlineVariant = Color(0xFFC6C5D3);
const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── Sheet widget (shown via showModalBottomSheet) ─────────────────────────────

/// Multi-step trip review bottom sheet.
/// Step 1 — Trip Details + Notes
/// Step 2 — Meeting Point
/// Step 3 — Price Summary + Confirm
class ScheduledTripReviewSheet extends StatefulWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;

  const ScheduledTripReviewSheet({
    super.key,
    required this.helper,
    required this.params,
  });

  @override
  State<ScheduledTripReviewSheet> createState() =>
      _ScheduledTripReviewSheetState();
}

class _ScheduledTripReviewSheetState extends State<ScheduledTripReviewSheet> {
  final _pageCtrl = PageController();
  final _notesCtrl = TextEditingController();
  int _step = 0; // 0, 1, 2
  MeetingPointType _meetingPoint = MeetingPointType.hotel;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prev() {
    if (_step > 0) {
      HapticFeedback.selectionClick();
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  double get _estimatedTotal {
    final rate = widget.helper.hourlyRate ?? widget.params.durationInMinutes / 60 * 100;
    final hours = widget.params.durationInMinutes / 60;
    return rate * hours;
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => sl<BookingCubit>(),
      child: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            Navigator.of(context).pop();
            context.push(
              AppRouter.bookingDetails.replaceFirst(':id', state.booking.id),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        },
        child: Builder(
          builder: (ctx) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: _kOutlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),

                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _StepIndicator(currentStep: _step),
                  ),

                  // Page content
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.62,
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _Step1TripDetails(
                          helper: widget.helper,
                          params: widget.params,
                          notesCtrl: _notesCtrl,
                          fmtDate: _fmtDate,
                          onNext: _next,
                        ),
                        _Step2MeetingPoint(
                          selected: _meetingPoint,
                          onChanged: (t) =>
                              setState(() => _meetingPoint = t),
                          onNext: _next,
                          onBack: _prev,
                        ),
                        _Step3Summary(
                          helper: widget.helper,
                          params: widget.params,
                          meetingPoint: _meetingPoint,
                          estimatedTotal: _estimatedTotal,
                          fmtDate: _fmtDate,
                          onBack: _prev,
                          onConfirm: () {
                            HapticFeedback.mediumImpact();
                            ctx.read<BookingCubit>().createScheduled(
                                  helperId: widget.helper.id,
                                  params: widget.params,
                                  notes: _notesCtrl.text.trim().isEmpty
                                      ? null
                                      : _notesCtrl.text.trim(),
                                  meetingPointType: _meetingPoint.wire,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              // Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active || done ? _kGradient : null,
                  color: active || done ? null : _kContainerLow,
                ),
                child: Center(
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _kMuted,
                          ),
                        ),
                ),
              ),
              if (i < 2)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: done ? _kGradient : null,
                      color: done ? null : _kOutlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Step 1: Trip details ──────────────────────────────────────────────────────

class _Step1TripDetails extends StatelessWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;
  final TextEditingController notesCtrl;
  final String Function(DateTime) fmtDate;
  final VoidCallback onNext;

  const _Step1TripDetails({
    required this.helper,
    required this.params,
    required this.notesCtrl,
    required this.fmtDate,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final h = params.durationInMinutes ~/ 60;
    final durationLabel = h == 8 ? 'Full Day' : '${h}h';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Trip',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kNavy,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),

          // Guide mini card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kOutlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: helper.profileImageUrl != null
                        ? AppNetworkImage(
                            imageUrl: helper.profileImageUrl,
                            width: 48,
                            height: 48,
                            borderRadius: 24,
                          )
                        : Container(
                            color: _kContainerLow,
                            alignment: Alignment.center,
                            child: Text(
                              helper.name.isNotEmpty
                                  ? helper.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _kNavy,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        helper.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kNavy,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: _kAmber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            helper.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...helper.languages.take(2).map(
                                (lang) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kContainerLow,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      lang,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _kBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Trip detail grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _DetailTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: fmtDate(params.requestedDate)
                    .split(',')
                    .first
                    .trim(),
              ),
              _DetailTile(
                icon: Icons.access_time_rounded,
                label: 'Start Time',
                value: params.startTime,
              ),
              _DetailTile(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Duration',
                value: durationLabel,
              ),
              _DetailTile(
                icon: Icons.people_alt_outlined,
                label: 'Travelers',
                value: '${params.travelersCount} pax',
              ),
              _DetailTile(
                icon: Icons.location_city_rounded,
                label: 'City',
                value: params.destinationCity,
              ),
              _DetailTile(
                icon: Icons.translate_rounded,
                label: 'Language',
                value: params.requestedLanguage,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notes
          const Text(
            'Anything your guide should know?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kOutlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: notesCtrl,
              maxLines: 3,
              minLines: 3,
              maxLength: 500,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF1A1B25),
              ),
              decoration: InputDecoration(
                hintText:
                    'Special requirements, pace preference, mobility needs...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _kMuted.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  color: _kMuted,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _GradientButton(label: 'Next  →', onTap: onNext),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Meeting point ─────────────────────────────────────────────────────

class _Step2MeetingPoint extends StatelessWidget {
  final MeetingPointType selected;
  final ValueChanged<MeetingPointType> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2MeetingPoint({
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  static const _options = [
    (
      MeetingPointType.hotel,
      Icons.hotel_rounded,
      'Hotel Pickup',
      'Your guide will meet you at your accommodation',
    ),
    (
      MeetingPointType.airport,
      Icons.flight_land_rounded,
      'Airport Arrivals',
      'Perfect for a seamless start after landing',
    ),
    (
      MeetingPointType.custom,
      Icons.pin_drop_rounded,
      'Custom Location',
      'Choose any meeting point on the map',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where should your guide find you?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kNavy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a pickup type for your trip.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ..._options.map((opt) {
            final isSelected = selected == opt.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(opt.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kContainerLow
                        : _kCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? _kBlue : _kOutlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kBlue.withValues(alpha: 0.1)
                              : _kSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          opt.$2,
                          size: 22,
                          color: isSelected ? _kBlue : _kMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.$3,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected ? _kNavy : const Color(0xFF1A1B25),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.$4,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Radio circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? _kBlue : _kOutlineVariant,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: _kBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Row(
            children: [
              // Back
              GestureDetector(
                onTap: onBack,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kOutlineVariant),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_rounded, color: _kNavy, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GradientButton(label: 'Next  →', onTap: onNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Price summary + confirm ──────────────────────────────────────────

class _Step3Summary extends StatelessWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;
  final MeetingPointType meetingPoint;
  final double estimatedTotal;
  final String Function(DateTime) fmtDate;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _Step3Summary({
    required this.helper,
    required this.params,
    required this.meetingPoint,
    required this.estimatedTotal,
    required this.fmtDate,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final h = params.durationInMinutes / 60;
    final rate = helper.hourlyRate ?? 0;
    final fee = estimatedTotal * 0.1;

    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final loading = state is BookingLoading;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "You're all set!",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Review and confirm your trip with ${helper.name.split(' ').first}.',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _kMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Price breakdown card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kOutlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label:
                          'Guide fee (EGP ${rate.toStringAsFixed(0)} × ${h % 1 == 0 ? h.toInt() : h}h)',
                      value: 'EGP ${(rate * h).toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 10),
                    _PriceRow(
                      label: 'Platform service fee',
                      value: 'EGP ${fee.toStringAsFixed(0)}',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1,
                        color: _kOutlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL ESTIMATED',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: _kNavy,
                          ),
                        ),
                        Text(
                          'EGP ${(estimatedTotal + fee).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Exact amount confirmed after trip completion.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Trip snapshot
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      Icons.calendar_today_outlined,
                      fmtDate(params.requestedDate),
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      Icons.meeting_room_outlined,
                      meetingPoint.label,
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      Icons.translate_rounded,
                      params.requestedLanguage,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Trust badges
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Badge(Icons.lock_outline_rounded, 'Secure'),
                  SizedBox(width: 20),
                  _Badge(Icons.check_circle_outline_rounded, 'Free Cancel'),
                  SizedBox(width: 20),
                  _Badge(Icons.verified_outlined, 'Verified'),
                ],
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: loading ? null : onBack,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kOutlineVariant),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, color: _kNavy, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: loading ? null : onConfirm,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: loading ? null : _kGradient,
                          color: loading
                              ? _kOutlineVariant.withValues(alpha: 0.4)
                              : null,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: loading
                              ? null
                              : [
                                  BoxShadow(
                                    color: _kNavy.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(
                                  'Request ${helper.name.split(' ').first}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: _kMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: _kNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _kMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kMuted,
          ),
        ),
      ],
    );
  }
}

// ── Shared gradient button ────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _kGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
