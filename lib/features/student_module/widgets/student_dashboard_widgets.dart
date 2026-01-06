import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String? gpa;
  final Map<String, int>? attendanceStats;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.gpa,
    this.attendanceStats,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: gpa != null && attendanceStats != null
            ? _buildStatsView()
            : _buildDefaultView(),
      ),
    );
  }

  Widget _buildDefaultView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: Colors.grey[800]
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gpa!,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              "GPA",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatDot(Colors.redAccent, attendanceStats!['unexcused'] ?? 0),
            _buildStatDot(Colors.orangeAccent, attendanceStats!['excused'] ?? 0),
            _buildStatDot(Colors.blueAccent, attendanceStats!['total'] ?? 0),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatDot(Color color, int value) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          "$value",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
