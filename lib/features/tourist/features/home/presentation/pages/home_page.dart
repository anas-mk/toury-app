import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Placeholder
          Container(color: Colors.grey[300]),

          // Top Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0B3D91), blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF0B3D91)),
                  SizedBox(width: 10),
                  Text(
                    "Where to?",
                    style: TextStyle(fontSize: 16, color: const Color(0xFF0B3D91)),
                  )
                ],
              ),
            ),
          ),

          // Bottom Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0B3D91).withOpacity(0.1), blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Go anywhere, anytime",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3D91),
                    ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOption(Icons.local_taxi, "Ride"),
                      _buildOption(Icons.delivery_dining, "Delivery"),
                      _buildOption(Icons.shopping_bag, "Shop"),
                      _buildOption(Icons.more_horiz, "More"),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFF0B3D91),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
