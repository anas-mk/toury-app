import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/location_status_cubits.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';

class EligibilityDebugPage extends StatefulWidget {
  const EligibilityDebugPage({super.key});

  @override
  State<EligibilityDebugPage> createState() => _EligibilityDebugPageState();
}

class _EligibilityDebugPageState extends State<EligibilityDebugPage> {
  late final EligibilityCubit _cubit;
  final TextEditingController _languageController = TextEditingController(text: 'en');
  bool _requiresCar = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EligibilityCubit>();
    _load();
  }

  void _load() {
    _cubit.loadEligibility(
      language: _languageController.text,
      requiresCar: _requiresCar,
    );
  }

  @override
  void dispose() {
    _languageController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.colorScheme.secondary.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + AppTheme.spaceSM),
              _buildFilters(context),
              Expanded(
                child: BlocBuilder<EligibilityCubit, EligibilityState>(
                  builder: (context, state) {
                    if (state is EligibilityLoading) {
                      return _buildLoading(context);
                    }
                    if (state is EligibilityError) {
                      return _buildError(context, state.message);
                    }
                    if (state is EligibilityLoaded) {
                      return _buildContent(context, state.eligibility);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
            elevation: 0,
            title: Text('SYSTEM DIAGNOSTICS', 
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.secondary),
                onPressed: _load,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceSM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _languageController,
                    onSubmitted: (_) => _load(),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'LOCALE FILTER',
                      labelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                      prefixIcon: Icon(Icons.language_rounded, color: theme.colorScheme.secondary, size: 18),
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceLG),
                Column(
                  children: [
                    Text('CAR REQ', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 8)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _requiresCar,
                        onChanged: (v) => setState(() {
                          _requiresCar = v;
                          _load();
                        }),
                        activeColor: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 20),
          Text('ANALYZING MATCHING ENGINE...', 
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: theme.colorScheme.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic eligibility) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      children: [
        _StatusHeader(isEligible: eligibility.isEligible),
        const SizedBox(height: AppTheme.spaceXL),
        Row(
          children: [
            Icon(Icons.security_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 16),
            const SizedBox(width: 8),
            Text('VALIDATION PROTOCOLS', 
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
        const SizedBox(height: 16),
        if (eligibility.eligibilityWarnings.isEmpty)
          _buildSuccessCard(context)
        else
          ...eligibility.eligibilityWarnings.map((w) => _WarningCard(warning: w)),
        const SizedBox(height: AppTheme.spaceXL),
        Row(
          children: [
            Icon(Icons.terminal_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 16),
            const SizedBox(width: 8),
            Text('RAW TELEMETRY DATA', 
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
        const SizedBox(height: 16),
        if (eligibility.debugDetails != null)
          _DebugInfoGrid(info: Map<String, dynamic>.from(eligibility.debugDetails))
        else
          const _EmptyCard(message: 'Telemetry unavailable'),
      ],
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColor.accentColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text('All matching protocols passed. System is fully operational and visible.', 
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColor.errorColor, size: 48),
            const SizedBox(height: 16),
            Text('CONNECTION INTERRUPTED', 
              style: theme.textTheme.titleSmall?.copyWith(color: AppColor.errorColor, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(msg, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RETRY CONNECTION'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final bool isEligible;
  const _StatusHeader({required this.isEligible});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isEligible ? AppColor.accentColor : AppColor.errorColor;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _PulseIcon(isEligible: isEligible),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'PROTOCOL ACTIVE' : 'PROTOCOL BLOCKED',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEligible ? 'You are broadcasting to all active explorers.' : 'Matching engine has restricted your visibility.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final bool isEligible;
  const _PulseIcon({required this.isEligible});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = widget.isEligible ? AppColor.accentColor : AppColor.errorColor;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3 * (1 - _controller.value)), width: 2),
              ),
            ),
            Icon(widget.isEligible ? Icons.radar_rounded : Icons.gpp_bad_rounded, color: color, size: 32),
          ],
        );
      },
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String warning;
  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.warningColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_gmailerrorred_rounded, color: AppColor.warningColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(warning,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _DebugInfoGrid extends StatelessWidget {
  final Map<String, dynamic> info;
  const _DebugInfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: info.entries.map((e) => _InfoRow(label: e.key, value: e.value.toString())).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1))),
          const SizedBox(width: 16),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.02), 
        borderRadius: BorderRadius.circular(AppTheme.radiusLG), 
        border: Border.all(color: theme.dividerColor.withOpacity(0.1))
      ),
      child: Center(child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.2), fontWeight: FontWeight.bold))),
    );
  }
}
