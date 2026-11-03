import 'package:attendance/service/attendance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todayAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (ref, employeeId) => AttendanceService.getTodayStatus(employeeId),
    );
