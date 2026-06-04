import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../domain/entities/search_params.dart';
import '../instant/location_picker_page.dart';
import '../instant/location_pick_result.dart';

// ── Design tokens (matching Stitch output) ──────────────────────────────────
const _kNavy = Color(0xFF000668);
const _kBlue = Color(0xFF4851C4);
const _kAmber = Color(0xFFFE9331);
const _kSurface = Color(0xFFFBF8FF);
const _kCard = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF767683);
const _kContainerLow = Color(0xFFF4F2FF);
const _kOutlineVariant = Color(0xFFC6C5D3);
const _kOnSurface = Color(0xFF1A1B25);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _kCardShadow = [
  BoxShadow(
    color: Color(0x141B237E),
    blurRadius: 32,
    offset: Offset(0, 12),
  ),
];

const _languages = <(String code, String label)>[
  ('en', 'English'),
  ('ar', 'Arabic'),
  ('fr', 'French'),
  ('es', 'Spanish'),
  ('de', 'German'),
  ('it', 'Italian'),
  ('ru', 'Russian'),
  ('zh', 'Chinese'),
  ('ja', 'Japanese'),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class ScheduledSearchFormScreen extends StatefulWidget {
  final String? initialDestination;
  const ScheduledSearchFormScreen({super.key, this.initialDestination});

  @override
  State<ScheduledSearchFormScreen> createState() =>
      _ScheduledSearchFormScreenState();
}

class _ScheduledSearchFormScreenState extends State<ScheduledSearchFormScreen>
    with TickerProviderStateMixin {
  // Destination
  final _cityCtrl = TextEditingController();
  String? _destName;
  double? _destLat;
  double? _destLng;

  // Trip details
  DateTime _date = () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 180;
  int _travelers = 2;
  String _languageCode = 'en';
  int _companionIndex = 0; // 0=Local Expert, 1=Driver Guide, 2=Full Service

  // Notes
  final _notesCtrl = TextEditingController();

  // Cursor blink animation
  late final AnimationController _cursorCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _cityCtrl.text = widget.initialDestination!;
    }
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    _cursorCtrl.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  String get _durationLabel {
    if (_durationMinutes == 480) return 'Full Day';
    final h = _durationMinutes ~/ 60;
    final m = _durationMinutes % 60;
    if (m == 0) return '~$h HRS';
    return '${h}h ${m}m';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }


  bool get _canSearch =>
      _cityCtrl.text.trim().isNotEmpty &&
      _destLat != null &&
      _destLng != null;

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _pickDestination() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(
          title: 'Pick Destination',
          isPickup: false,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _cityCtrl.text = result.name;
      _destName = result.name;
      _destLat = result.latitude;
      _destLng = result.longitude;
    });
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kNavy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kNavy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _showDurationSheet() {
    HapticFeedback.selectionClick();
    const options = [60, 120, 180, 240, 300, 360, 480];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _kOutlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TRIP DURATION',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _kMuted,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((mins) {
                  final selected = mins == _durationMinutes;
                  final lbl = mins == 480
                      ? 'Full Day'
                      : mins < 60
                          ? '${mins}m'
                          : '${mins ~/ 60}h';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _durationMinutes = mins);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? _kGradient : null,
                        color: selected ? null : _kContainerLow,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        lbl,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _kNavy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    if (!_canSearch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please fill in destination and pickup location.',
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _kNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    context.push(
      AppRouter.scheduledResults,
      extra: ScheduledSearchParams(
        destinationCity: _cityCtrl.text.trim(),
        destinationName: _destName ?? _cityCtrl.text.trim(),
        requestedDate: _date,
        startTime: _fmtTime(_time),
        durationInMinutes: _durationMinutes,
        requestedLanguage: _languageCode,
        requiresCar: _companionIndex >= 1,
        travelersCount: _travelers,
        destinationLatitude: _destLat!,
        destinationLongitude: _destLng!,
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Stack(
        children: [
          // Subtle topographic background
          const Positioned.fill(child: _TopographicBackground()),

          // Right edge dashed scroll indicator
          Positioned(
            right: 6,
            top: topPad + 80,
            bottom: 136 + bottomPad,
            child: const _DashedEdgeIndicator(),
          ),

          // Scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad + 76)),

              // ── Destination hero card ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _DestinationHeroCard(
                    cityCtrl: _cityCtrl,
                    cursorAnim: _cursorCtrl,
                    date: _date,
                    time: _time,
                    destLat: _destLat,
                    onPickDestination: _pickDestination,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _IconDivider(icon: Icons.luggage_outlined),
              ),

              // ── Itinerary flow ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _ItineraryFlowSection(
                    durationLabel: _durationLabel,
                    time: _time,
                    onTapDuration: _showDurationSheet,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _IconDivider(icon: Icons.map_outlined),
              ),

              // ── Travelers + Language ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _TravelDetailsCard(
                    travelers: _travelers,
                    languageCode: _languageCode,
                    onIncrease: () {
                      if (_travelers < 12) setState(() => _travelers++);
                    },
                    onDecrease: () {
                      if (_travelers > 1) setState(() => _travelers--);
                    },
                    onLanguagePicked: (code) =>
                        setState(() => _languageCode = code),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Travel companion ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _TravelCompanionSection(
                  selected: _companionIndex,
                  onSelected: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _companionIndex = i);
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Journal notes ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _JournalNotesCard(controller: _notesCtrl),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 140 + bottomPad),
              ),
            ],
          ),

          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(topPad: topPad),
          ),

          // Sticky footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SearchFooter(
              canSearch: _canSearch,
              onSearch: _onSearch,
              bottomPad: bottomPad,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background topographic pattern ──────────────────────────────────────────

class _TopographicBackground extends StatelessWidget {
  const _TopographicBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TopoPainter());
  }
}

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000568).withValues(alpha: 0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 10; i++) {
      final y = (size.height / 10) * i;
      final path = Path();
      path.moveTo(0, y);
      for (var x = 0.0; x < size.width; x += 20) {
        path.quadraticBezierTo(
          x + 10,
          y + math.sin(x / 30) * 12,
          x + 20,
          y,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Right dashed indicator ───────────────────────────────────────────────────

class _DashedEdgeIndicator extends StatelessWidget {
  const _DashedEdgeIndicator();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedPainter());
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kAmber.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashH = 8.0;
    const gap = 6.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(1, y), Offset(1, y + dashH), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Fixed header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: topPad,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.85),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B237E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _kCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A1B237E),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _kNavy,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Plan Your Journey',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kNavy,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Compass icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: _kAmber,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Destination hero card ─────────────────────────────────────────────────────

class _DestinationHeroCard extends StatelessWidget {
  final TextEditingController cityCtrl;
  final AnimationController cursorAnim;
  final DateTime date;
  final TimeOfDay time;
  final double? destLat;
  final VoidCallback onPickDestination;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _DestinationHeroCard({
    required this.cityCtrl,
    required this.cursorAnim,
    required this.date,
    required this.time,
    required this.destLat,
    required this.onPickDestination,
    required this.onPickDate,
    required this.onPickTime,
  });

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final destLabel = cityCtrl.text.trim().isEmpty ? '' : cityCtrl.text.trim();
    final shortDest =
        destLabel.length > 12 ? '${destLabel.substring(0, 10)}…' : destLabel;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "WHERE TO?" label
          const Text(
            'WHERE TO?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 6),

          // Destination city input row
          GestureDetector(
            onTap: onPickDestination,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    destLabel.isEmpty ? 'Enter city...' : destLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: destLabel.isEmpty
                          ? _kMuted.withValues(alpha: 0.4)
                          : _kNavy,
                      height: 1.1,
                    ),
                  ),
                ),
                // Blinking cursor
                if (destLabel.isEmpty)
                  AnimatedBuilder(
                    animation: cursorAnim,
                    builder: (_, __) => Opacity(
                      opacity: cursorAnim.value,
                      child: Container(
                        width: 3,
                        height: 36,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: _kAmber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                if (destLat != null)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1DB97A),
                    size: 20,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Flight path: static "Meet Pt" → destination arc
          _FlightPathRow(
            destLabel: shortDest.isEmpty ? '?' : shortDest,
            hasDest: destLat != null,
            onDestTap: onPickDestination,
          ),

          const SizedBox(height: 16),

          // Date & Time chips
          Row(
            children: [
              Expanded(
                child: _TapChip(
                  icon: Icons.calendar_today_outlined,
                  label: _fmtDate(date),
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TapChip(
                  icon: Icons.access_time_rounded,
                  label: _fmtTime(time),
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Flight path row ─────────────────────────────────────────────────────────

class _FlightPathRow extends StatelessWidget {
  final String destLabel;
  final bool hasDest;
  final VoidCallback onDestTap;

  const _FlightPathRow({
    required this.destLabel,
    required this.hasDest,
    required this.onDestTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          // Arc
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(),
            ),
          ),
          // Plane icon at top of arc
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.flight_rounded,
                color: _kNavy,
                size: 18,
              ),
            ),
          ),
          // Left dot + label (Meeting Point — chosen later)
          Positioned(
            left: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _kOutlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Meet Pt',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kOutlineVariant,
                  ),
                ),
              ],
            ),
          ),
          // Right dot + label (Destination)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onDestTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hasDest ? _kAmber : _kOutlineVariant,
                      shape: BoxShape.circle,
                      boxShadow: hasDest
                          ? [
                              BoxShadow(
                                color: _kAmber.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: hasDest ? _kMuted : _kOutlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kAmber.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(6, size.height - 18);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height * 0.1,
      size.width - 6,
      size.height - 18,
    );

    // Dashed drawing
    const dashLen = 6.0;
    const gapLen = 4.0;
    final pathMetrics = path.computeMetrics();
    for (final pm in pathMetrics) {
      var distance = 0.0;
      while (distance < pm.length) {
        final start = distance;
        final end = math.min(distance + dashLen, pm.length);
        canvas.drawPath(
          pm.extractPath(start, end),
          paint,
        );
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Tap chip (date/time) ─────────────────────────────────────────────────────

class _TapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TapChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _kOutlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _kBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon divider ─────────────────────────────────────────────────────────────

class _IconDivider extends StatelessWidget {
  final IconData icon;
  const _IconDivider({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Icon(
          icon,
          size: 18,
          color: _kNavy.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// ── Itinerary flow section ────────────────────────────────────────────────────

class _ItineraryFlowSection extends StatelessWidget {
  final String durationLabel;
  final TimeOfDay time;
  final VoidCallback onTapDuration;

  const _ItineraryFlowSection({
    required this.durationLabel,
    required this.time,
    required this.onTapDuration,
  });

  bool get _isMorning => time.hour < 12;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ITINERARY FLOW',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Sunrise node
            _TimeNode(
              icon: Icons.wb_twilight_rounded,
              color: _kAmber,
              active: _isMorning,
              label: 'Morning',
            ),
            // Connecting line
            Expanded(
              child: Container(
                height: 2,
                color: _kOutlineVariant.withValues(alpha: 0.6),
              ),
            ),
            // Duration pill (tappable)
            GestureDetector(
              onTap: onTapDuration,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: _kGradient,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: _kNavy.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  durationLabel,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kAmber,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Connecting line
            Expanded(
              child: Container(
                height: 2,
                color: _kOutlineVariant.withValues(alpha: 0.6),
              ),
            ),
            // Sunset/night node
            _TimeNode(
              icon: Icons.nightlight_round_outlined,
              color: _kNavy.withValues(alpha: 0.5),
              active: !_isMorning,
              label: 'Evening',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap the pill to change duration',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: _kMuted.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final String label;

  const _TimeNode({
    required this.icon,
    required this.color,
    required this.active,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _kCard,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? color : _kOutlineVariant,
              width: 2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: active ? color : _kMuted, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? color : _kMuted,
          ),
        ),
      ],
    );
  }
}

// ── Travel details card (travelers + language) ────────────────────────────────

class _TravelDetailsCard extends StatelessWidget {
  final int travelers;
  final String languageCode;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final ValueChanged<String> onLanguagePicked;

  const _TravelDetailsCard({
    required this.travelers,
    required this.languageCode,
    required this.onIncrease,
    required this.onDecrease,
    required this.onLanguagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travelers stepper
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: _kAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Travelers',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    const Text(
                      'Including children',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Stepper
              Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: onDecrease,
                    enabled: travelers > 1,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$travelers',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrease,
                    enabled: travelers < 12,
                  ),
                ],
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              height: 1,
              color: _kOutlineVariant.withValues(alpha: 0.5),
            ),
          ),

          // Language
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: _kBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Guide Language',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languages.map((lang) {
                final selected = lang.$1 == languageCode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onLanguagePicked(lang.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? _kGradient : null,
                        color: selected ? null : _kContainerLow,
                        borderRadius: BorderRadius.circular(99),
                        border: selected
                            ? null
                            : Border.all(
                                color: _kOutlineVariant.withValues(alpha: 0.5),
                              ),
                      ),
                      child: Text(
                        lang.$2,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _kNavy,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? _kBlue : _kOutlineVariant,
          ),
          color: enabled ? _kBlue.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _kBlue : _kOutlineVariant,
        ),
      ),
    );
  }
}

// ── Travel companion section ──────────────────────────────────────────────────

class _TravelCompanionSection extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _TravelCompanionSection({
    required this.selected,
    required this.onSelected,
  });

  static const _companions = [
    (Icons.person_pin_circle_rounded, 'Local Expert', 'Walking & transit tours'),
    (Icons.directions_car_rounded, 'Driver Guide', 'Includes private vehicle'),
    (Icons.room_service_rounded, 'Full Service', 'Premium VIP experience'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'TRAVEL COMPANION',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: _kMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _companions.length,
            itemBuilder: (ctx, i) {
              final item = _companions[i];
              final isComingSoon = i == 2;
              final isSelected = i == selected && !isComingSoon;
              return Padding(
                padding: EdgeInsets.only(right: i < _companions.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: isComingSoon ? null : () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 130,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isComingSoon
                          ? _kContainerLow.withValues(alpha: 0.5)
                          : isSelected
                              ? _kNavy.withValues(alpha: 0.04)
                              : _kCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isComingSoon
                            ? _kOutlineVariant.withValues(alpha: 0.25)
                            : isSelected
                                ? _kNavy
                                : _kOutlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? _kCardShadow : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isComingSoon
                                    ? _kOutlineVariant.withValues(alpha: 0.12)
                                    : isSelected
                                        ? _kContainerLow
                                        : _kOutlineVariant.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.$1,
                                size: 18,
                                color: isComingSoon
                                    ? _kOutlineVariant.withValues(alpha: 0.5)
                                    : isSelected
                                        ? _kBlue
                                        : _kMuted,
                              ),
                            ),
                            const Spacer(),
                            if (isComingSoon)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SOON',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: _kAmber,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              )
                            else if (isSelected)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _kAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isComingSoon
                                ? _kOutlineVariant
                                : isSelected
                                    ? _kNavy
                                    : _kMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            color: isComingSoon
                                ? _kOutlineVariant.withValues(alpha: 0.6)
                                : _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Journal notes card ────────────────────────────────────────────────────────

class _JournalNotesCard extends StatelessWidget {
  final TextEditingController controller;
  const _JournalNotesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.012, // -1 degree tilt
      child: Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: _kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Stamp" header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'JOURNAL NOTES',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: _kNavy,
                    ),
                  ),
                  const Spacer(),
                  // Stamp corner decoration
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _kAmber.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.sell_outlined,
                      size: 14,
                      color: _kAmber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Lined input area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 3,
                maxLength: 500,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: _kOnSurface,
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  hintText: 'Any special requests? Must-see places, pace preference, dietary needs...',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _kMuted.withValues(alpha: 0.4),
                  ),
                  counterStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    color: _kMuted,
                  ),
                ),
              ),
            ),
            // Dashed bottom line (postcard effect)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1.5,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _kOutlineVariant,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ── Sticky search footer ──────────────────────────────────────────────────────

class _SearchFooter extends StatelessWidget {
  final bool canSearch;
  final VoidCallback onSearch;
  final double bottomPad;

  const _SearchFooter({
    required this.canSearch,
    required this.onSearch,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BadgeItem(Icons.lock_outline_rounded, 'Secure'),
              const SizedBox(width: 20),
              _BadgeItem(Icons.check_circle_outline_rounded, 'Free Search'),
              const SizedBox(width: 20),
              _BadgeItem(Icons.verified_outlined, 'Verified Guides'),
            ],
          ),
          const SizedBox(height: 14),
          // CTA button
          GestureDetector(
            onTap: onSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: canSearch ? _kGradient : null,
                color: canSearch ? null : _kOutlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(40),
                boxShadow: canSearch
                    ? [
                        BoxShadow(
                          color: _kNavy.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find Available Guides',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: canSearch
                          ? Colors.white
                          : _kMuted.withValues(alpha: 0.6),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: canSearch
                        ? Colors.white
                        : _kMuted.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Free to search · Pay only after your trip',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: _kMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeItem(this.icon, this.label);

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
