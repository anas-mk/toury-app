import 'package:flutter/material.dart';

class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Skeleton(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Skeleton(width: 120, height: 14),
                  const SizedBox(height: 6),
                  _Skeleton(width: 80, height: 10),
                ],
              ),
              const Spacer(),
              _Skeleton(width: 60, height: 28, radius: 12),
            ],
          ),
          const SizedBox(height: 20),
          _Skeleton(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _Skeleton(width: 200, height: 12),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Skeleton(height: 44, radius: 14)),
              const SizedBox(width: 12),
              Expanded(child: _Skeleton(height: 44, radius: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double? width, height;
  final double radius;

  const _Skeleton({this.width, this.height, this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
