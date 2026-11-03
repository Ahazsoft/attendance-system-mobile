import 'package:attendance/service/attendance_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceNotificationServiceProvider =
    Provider<AttendanceNotificationService>(
      (ref) => AttendanceNotificationService.instance,
    );
