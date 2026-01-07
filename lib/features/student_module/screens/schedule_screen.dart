import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/lesson.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late Future<List<Lesson>> _scheduleFuture;
  late TabController _tabController;

  final List<String> _days = ["Dush", "Sesh", "Chor", "Pay", "Juma", "Shan"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
    
    // Auto-select current day (if Mon-Sat)
    final now = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    if (now >= 1 && now <= 6) {
      _tabController.index = now - 1;
    }
  }

  void _loadData() {
    setState(() {
      _scheduleFuture = _dataService.getSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Dars Jadvali", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Xatolik: ${snapshot.error}"));
          }

          final allLessons = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: List.generate(6, (index) {
              // Filter logic: WeekDay 11, 12... or just 1, 2 ? 
              // HEMIS usually uses 11=Mon?? No, usually 1=Mon.
              // Let's assume standard 1=Mon.
              // User said "11 start time"? No.
              
              // We will filter by `weekDay == index + 1`
              final dayLessons = allLessons.where((l) => l.weekDay == (index + 1)).toList();
              
              // Sort by startTime (Unix string or HH:mm)
              dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));

              if (dayLessons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Bu kunda darslar yo'q", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dayLessons.length,
                itemBuilder: (ctx, i) {
                  final lesson = dayLessons[i];
                  return _buildLessonCard(lesson);
                },
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    // Format Time: 1688974400 -> 09:00? Or "14:00"?
    // If it's a long timestamp, convert. If HH:mm, use as is.
    String timeStr = lesson.startTime;
    if (int.tryParse(lesson.startTime) != null) {
       final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(lesson.startTime) * 1000);
       timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          // Time Column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                // End time could be added here if needed
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(lesson.auditorium.isNotEmpty ? lesson.auditorium : "Xona aniq emas", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(lesson.teacherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
