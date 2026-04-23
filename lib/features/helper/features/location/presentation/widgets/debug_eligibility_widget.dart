import 'package:flutter/material.dart';
import '../../data/models/location_models.dart';

class DebugEligibilityWidget extends StatelessWidget {
  final InstantEligibility? eligibility;
  final VoidCallback onRefresh;
  final bool isLoading;

  const DebugEligibilityWidget({
    super.key,
    this.eligibility,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Instant Eligibility Debug', style: TextStyle(fontWeight: FontWeight.bold)),
              if (isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh, size: 20)),
            ],
          ),
          const SizedBox(height: 12),
          if (eligibility == null && !isLoading)
            const Text('No data available. Refresh to check.')
          else if (eligibility != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: eligibility!.finalEligible ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    eligibility!.finalEligible ? Icons.check_circle : Icons.cancel,
                    color: eligibility!.finalEligible ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    eligibility!.finalEligible ? 'READY FOR REQUESTS' : 'NOT ELIGIBLE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: eligibility!.finalEligible ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rule Breakdown:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ...eligibility!.rules.map((rule) => _buildRuleItem(rule)),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleItem(InstantEligibilityRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            rule.passed ? Icons.check : Icons.close,
            size: 16,
            color: rule.passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: rule.passed ? Colors.black87 : Colors.red[800],
                  ),
                ),
                if (rule.message != null)
                  Text(rule.message!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
