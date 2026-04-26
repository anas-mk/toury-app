import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../cubit/helper_sos_cubit.dart';

class HelperSosPage extends StatelessWidget {
  const HelperSosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<HelperSosCubit, HelperSosState>(
      builder: (context, state) {
        final isActive = state.status == SosStatus.active;
        return Scaffold(
          backgroundColor: isActive ? const Color(0xFF450000) : theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            title: const Text('Emergency Assistance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              children: [
                _EmergencyWarningCard(isActive: isActive),
                const SizedBox(height: 32),
                _PanicButton(isActive: isActive),
                const SizedBox(height: 40),
                _EmergencyGrid(),
                const SizedBox(height: 32),
                _SafetyChecklist(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmergencyWarningCard extends StatelessWidget {
  final bool isActive;
  const _EmergencyWarningCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: isActive ? AppColor.errorColor : theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? Colors.white24 : AppColor.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.gpp_maybe : Icons.warning_amber_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'PANIC MODE ACTIVE' : 'SOS Emergency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isActive ? 'Authorities are being notified...' : 'Use this only in real emergency situations.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanicButton extends StatefulWidget {
  final bool isActive;
  const _PanicButton({required this.isActive});

  @override
  State<_PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<_PanicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        if (widget.isActive) {
          context.read<HelperSosCubit>().deactivatePanic();
        } else {
          _confirmPanic(context);
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.errorColor,
              boxShadow: [
                BoxShadow(
                  color: AppColor.errorColor.withOpacity(0.4),
                  blurRadius: 20 + (_controller.value * 20),
                  spreadRadius: 5 + (_controller.value * 15),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isActive ? Icons.stop_rounded : Icons.emergency_share_rounded, color: Colors.white, size: 60),
                  const SizedBox(height: 8),
                  Text(
                    widget.isActive ? 'STOP SOS' : 'HOLD TO HELP',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (!widget.isActive)
                    const Text('LONG PRESS', style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmPanic(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColor.errorColor, size: 48),
            const SizedBox(height: 16),
            Text('Confirm Emergency?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Authorities and nearby helpers will be notified.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<HelperSosCubit>().activatePanic(0, 0); // Replace with real location
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                    ),
                    child: const Text('Trigger SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

class _EmergencyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _EmergencyItem(
          label: 'Police',
          icon: Icons.local_police_rounded,
          color: Colors.blue,
          onTap: () => launchUrl(Uri.parse('tel:911')),
        ),
        _EmergencyItem(
          label: 'Ambulance',
          icon: Icons.medical_services_rounded,
          color: Colors.orange,
          onTap: () => launchUrl(Uri.parse('tel:911')),
        ),
        _EmergencyItem(
          label: 'Trusted Contact',
          icon: Icons.person_rounded,
          color: Colors.green,
          onTap: () {}, // Mock
        ),
        _EmergencyItem(
          label: 'Safe Place',
          icon: Icons.shield_rounded,
          color: AppColor.primaryColor,
          onTap: () {}, // Mock
        ),
      ],
    );
  }
}

class _EmergencyItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyItem({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _SafetyChecklist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety Checklist', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _CheckItem(text: 'Park in a well-lit public area'),
          _CheckItem(text: 'Lock all doors and windows'),
          _CheckItem(text: 'Keep your phone charged and ready'),
          _CheckItem(text: 'Don\'t confront aggressive individuals'),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColor.accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
