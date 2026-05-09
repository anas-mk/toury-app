import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/rate_traveler_dialog.dart';

/// Deep-link / legacy route target: opens the same rating UI as a dialog, then
/// pops this route (no full-screen rating page).
class RateUserPage extends StatefulWidget {
  final String bookingId;
  final String travelerName;
  final String travelerAvatar;

  const RateUserPage({
    super.key,
    required this.bookingId,
    required this.travelerName,
    required this.travelerAvatar,
  });

  @override
  State<RateUserPage> createState() => _RateUserPageState();
}

class _RateUserPageState extends State<RateUserPage> {
  var _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDialog());
  }

  Future<void> _openDialog() async {
    if (!mounted) return;
    final rated = await showRateTravelerDialog(
      context,
      bookingId: widget.bookingId,
      travelerName: widget.travelerName,
      travelerAvatar: widget.travelerAvatar,
    );
    if (!mounted) return;
    context.pop(rated == true);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
