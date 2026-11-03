import 'package:attendance/service/attendance_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedules reminders at the requested UTC times', () {
    final reminders = buildAttendanceReminderSchedule(
      DateTime.utc(2026, 11, 2, 4),
      days: 1,
    );

    expect(reminders.map((reminder) => reminder.scheduledAt).toList(), [
      DateTime.utc(2026, 11, 2, 5, 20),
      DateTime.utc(2026, 11, 2, 10, 20),
      DateTime.utc(2026, 11, 2, 14),
    ]);
    expect(reminders.map((reminder) => reminder.id).toList(), [
      60783306,
      60783307,
      60783308,
    ]);
  });

  test('does not queue reminders whose time has passed', () {
    final reminders = buildAttendanceReminderSchedule(
      DateTime.utc(2026, 11, 2, 5, 1),
      days: 1,
    );

    expect(reminders.map((reminder) => reminder.scheduledAt).toList(), [
      DateTime.utc(2026, 11, 2, 10, 20),
      DateTime.utc(2026, 11, 2, 14),
    ]);
  });

  test('does not schedule reminders on Saturday or Sunday', () {
    final saturday = buildAttendanceReminderSchedule(
      DateTime.utc(2026, 11, 7),
      days: 1,
    );
    final sunday = buildAttendanceReminderSchedule(
      DateTime.utc(2026, 11, 8),
      days: 1,
    );

    expect(saturday, isEmpty);
    expect(sunday, isEmpty);
  });

  test('uses the EAT date for reminder cancellation IDs', () {
    expect(
      attendanceDayIdForUtcTime(DateTime.utc(2026, 11, 1, 21, 30)),
      20261102,
    );
  });
}
