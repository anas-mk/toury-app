import 'package:flutter/material.dart';
import '../../domain/entities/car_entity.dart';
import '../widgets/car/car_management_card.dart';

class VehicleManagementPage extends StatelessWidget {
  final CarEntity? car;
  const VehicleManagementPage({super.key, this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1120),
        title: const Text('Vehicle Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Vehicle Details',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CarManagementCard(car: car),
          const SizedBox(height: 24),
          if (car != null) ...[
            _DetailRow(label: 'Brand', value: car!.brand),
            _DetailRow(label: 'Model', value: car!.model),
            _DetailRow(label: 'Color', value: car!.color),
            _DetailRow(label: 'Plate Number', value: car!.licensePlate),
            _DetailRow(label: 'Car Type', value: car?.carType ?? 'Standard'),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
