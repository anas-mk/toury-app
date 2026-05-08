import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/meeting_point_type.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/booking_cubit.dart';
import '../../cubits/booking_state.dart';

class ScheduledReviewScreen extends StatefulWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;

  const ScheduledReviewScreen({
    super.key,
    required this.helper,
    required this.params,
  });

  @override
  State<ScheduledReviewScreen> createState() => _ScheduledReviewScreenState();
}

class _ScheduledReviewScreenState extends State<ScheduledReviewScreen> {
  MeetingPointType _meetingPointType = MeetingPointType.custom;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _startInPast {
    final base = widget.params.requestedDate.toLocal();
    final parts = widget.params.startTime.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    final composed = DateTime(base.year, base.month, base.day, h, m);
    return composed.isBefore(DateTime.now());
  }

  void _confirm(BuildContext context) {
    HapticFeedback.lightImpact();
    if (_startInPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trip start is in the past. Please go back and pick a future time.',
          ),
          backgroundColor: BrandTokens.dangerRed,
        ),
      );
      return;
    }

    final notes = _notesCtrl.text.trim();
    context.read<BookingCubit>().createScheduled(
      helperId: widget.helper.id,
      params: widget.params,
      notes: notes.isEmpty ? null : notes,
      meetingPointType: _meetingPointType.wire,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => sl<BookingCubit>(),
      child: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            HapticFeedback.lightImpact();
            context.pushReplacement(
              AppRouter.bookingDetails.replaceFirst(':id', state.booking.id),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: BrandTokens.dangerRed,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) {
            final hours = widget.params.durationInMinutes ~/ 60;
            final hourlyRate = widget.helper.hourlyRate ?? 0;
            final estimatedTotal =
                widget.helper.estimatedPrice ?? (hourlyRate * hours).toDouble();

            return PageScaffold(
              bottomCta: BlocBuilder<BookingCubit, BookingState>(
                builder: (context, state) {
                  final loading = state is BookingLoading;
                  return PrimaryGradientButton(
                    label: 'Confirm and request',
                    icon: Icons.send_rounded,
                    isLoading: loading,
                    onPressed: loading ? null : () => _confirm(context),
                  );
                },
              ),
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: BrandTokens.bgSoft,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(
                      color: BrandTokens.textPrimary,
                    ),
                    title: Text(
                      'Review your trip',
                      style: BrandTypography.title(weight: FontWeight.w700),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        _HelperRow(helper: widget.helper),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Trip',
                          children: [
                            _Row(
                              icon: Icons.flag_rounded,
                              label: 'Destination',
                              value: widget.params.destinationName,
                            ),
                            _Row(
                              icon: Icons.my_location_rounded,
                              label: 'Pickup',
                              value: widget.params.pickupLocationName,
                            ),
                            _Row(
                              icon: Icons.event_rounded,
                              label: 'Date',
                              value: _fmtDate(widget.params.requestedDate),
                            ),
                            _Row(
                              icon: Icons.schedule_rounded,
                              label: 'Start',
                              value: widget.params.startTime.substring(0, 5),
                            ),
                            _Row(
                              icon: Icons.hourglass_top_rounded,
                              label: 'Duration',
                              value: _fmtDuration(
                                widget.params.durationInMinutes,
                              ),
                            ),
                            _Row(
                              icon: Icons.translate_rounded,
                              label: 'Language',
                              value: widget.params.requestedLanguage
                                  .toUpperCase(),
                            ),
                            if (widget.params.requiresCar)
                              const _Row(
                                icon: Icons.directions_car_rounded,
                                label: 'Car',
                                value: 'Required',
                              ),
                            _Row(
                              icon: Icons.group_rounded,
                              label: 'Travelers',
                              value: widget.params.travelersCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Meeting point selector (moved from config sheet)
                        _SectionCard(
                          title: 'Trip details',
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meeting point',
                                  style: BrandTypography.caption(
                                    weight: FontWeight.w700,
                                    color: BrandTokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _MeetingPointPicker(
                                  selected: _meetingPointType,
                                  onChanged: (v) =>
                                      setState(() => _meetingPointType = v),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Notes for helper',
                                  style: BrandTypography.caption(
                                    weight: FontWeight.w700,
                                    color: BrandTokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _notesCtrl,
                                  maxLines: 3,
                                  maxLength: 2000,
                                  decoration: InputDecoration(
                                    hintText: 'Anything we should know…',
                                    hintStyle: BrandTypography.body(
                                      color: BrandTokens.textMuted,
                                    ),
                                    filled: true,
                                    fillColor: BrandTokens.bgSoft,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: BrandTokens.borderSoft,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: BrandTokens.borderSoft,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: BrandTokens.primaryBlue,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _PriceCard(
                          hourlyRate: hourlyRate.toDouble(),
                          hours: hours.toDouble(),
                          estimatedTotal: estimatedTotal.toDouble(),
                        ),
                        const SizedBox(height: 16),
                        _Disclaimer(),
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

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hour${h == 1 ? '' : 's'}';
    return '${h}h ${m}m';
  }
}

// ── Meeting Point Picker ──────────────────────────────────────────────────────

class _MeetingPointPicker extends StatelessWidget {
  final MeetingPointType selected;
  final ValueChanged<MeetingPointType> onChanged;

  const _MeetingPointPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MeetingPointType.values.map((t) {
        final selectedNow = t == selected;
        final IconData icon;
        switch (t) {
          case MeetingPointType.hotel:
            icon = Icons.hotel_rounded;
            break;
          case MeetingPointType.airport:
            icon = Icons.flight_rounded;
            break;
          case MeetingPointType.custom:
            icon = Icons.place_rounded;
            break;
        }
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selectedNow
                  ? BrandTokens.primaryBlue
                  : BrandTokens.surfaceWhite,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selectedNow
                    ? BrandTokens.primaryBlue
                    : BrandTokens.borderSoft,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selectedNow ? Colors.white : BrandTokens.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.label,
                  style: BrandTypography.body(
                    weight: FontWeight.w600,
                    color: selectedNow ? Colors.white : BrandTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _HelperRow extends StatelessWidget {
  final HelperBookingEntity helper;
  const _HelperRow({required this.helper});

  @override
  Widget build(BuildContext context) {
    final initial = helper.name.isEmpty
        ? '?'
        : helper.name.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          ClipOval(
            child:
                helper.profileImageUrl == null ||
                    helper.profileImageUrl!.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    color: BrandTokens.borderTinted,
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: BrandTypography.title(
                        weight: FontWeight.w700,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  )
                : Image.network(
                    helper.profileImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: BrandTokens.borderTinted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.name,
                  style: BrandTypography.title(weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFB45309),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      helper.rating.toStringAsFixed(1),
                      style: BrandTypography.caption(weight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${helper.completedTrips} trips',
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BrandTypography.body(weight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrandTokens.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: BrandTypography.caption()),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: BrandTypography.body(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double hourlyRate;
  final double hours;
  final double estimatedTotal;

  const _PriceCard({
    required this.hourlyRate,
    required this.hours,
    required this.estimatedTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEB), Color(0xFFFDF6E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.accentAmberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                color: Color(0xFFB45309),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated price',
                style: BrandTypography.body(
                  weight: FontWeight.w700,
                  color: BrandTokens.accentAmberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${hourlyRate.toStringAsFixed(0)} EGP / hr',
                style: BrandTypography.caption(
                  color: BrandTokens.accentAmberText,
                ),
              ),
              const Spacer(),
              Text(
                '${hours.toStringAsFixed(0)} hr${hours == 1 ? '' : 's'}',
                style: BrandTypography.caption(
                  color: BrandTokens.accentAmberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: BrandTokens.accentAmberBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Estimated total',
                style: BrandTypography.title(weight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${estimatedTotal.toStringAsFixed(0)} EGP',
                style: BrandTypography.headline(color: BrandTokens.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Final price includes base fee + distance + time. Calculated after the trip.',
            style: BrandTypography.caption(color: BrandTokens.accentAmberText),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: BrandTokens.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You won\'t be charged until the helper accepts. A 20% deposit is required after acceptance to confirm the booking.',
              style: BrandTypography.caption(color: BrandTokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
