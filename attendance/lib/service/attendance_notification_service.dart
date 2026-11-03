import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

enum AttendanceReminderType { morningCheckIn, afternoonCheckIn, checkout }

typedef AttendanceReminderSchedule = ({
  int id,
  DateTime scheduledAt,
  AttendanceReminderType type,
});

@visibleForTesting
List<AttendanceReminderSchedule> buildAttendanceReminderSchedule(
  DateTime now, {
  int days = 30,
}) {
  final nowUtc = now.toUtc();
  final eatNow = nowUtc.add(const Duration(hours: 3));
  final today = DateTime.utc(eatNow.year, eatNow.month, eatNow.day);
  final reminders = <AttendanceReminderSchedule>[];

  for (var offset = 0; offset < days; offset++) {
    final day = today.add(Duration(days: offset));
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      continue;
    }

    void addIfFuture(DateTime scheduledAt, AttendanceReminderType type) {
      if (scheduledAt.isAfter(nowUtc)) {
        reminders.add((
          id: _reminderId(day, type),
          scheduledAt: scheduledAt,
          type: type,
        ));
      }
    }

    addIfFuture(
      DateTime.utc(day.year, day.month, day.day, 5, 20),
      AttendanceReminderType.morningCheckIn,
    );
    addIfFuture(
      DateTime.utc(day.year, day.month, day.day, 10, 20),
      AttendanceReminderType.afternoonCheckIn,
    );
    addIfFuture(
      DateTime.utc(day.year, day.month, day.day, 14),
      AttendanceReminderType.checkout,
    );
  }

  return reminders;
}

int _dayId(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
int _reminderId(DateTime date, AttendanceReminderType type) =>
    _dayId(date) * 3 + type.index;

@visibleForTesting
int attendanceDayIdForUtcTime(DateTime now) =>
    _dayId(now.toUtc().add(const Duration(hours: 3)));

class AttendanceNotificationService {
  AttendanceNotificationService._();

  static final AttendanceNotificationService instance =
      AttendanceNotificationService._();

  static const _scheduledDays = 30;
  static const _preferenceKeyPrefix = 'attendance_notifications_enabled_';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.exactAllowWhileIdle;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null &&
        await android.canScheduleExactNotifications() != true) {
      _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    _initialized = true;
  }

  Future<bool> notificationsEnabled(String employeeId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_preferenceKeyPrefix$employeeId') ?? false;
  }

  Future<bool> setNotificationsEnabled(String employeeId, bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_preferenceKeyPrefix$employeeId';

    if (!enabled) {
      await preferences.setBool(key, false);
      if (_initialized) await _plugin.cancelAll();
      return true;
    }

    if (!_initialized) await initialize();
    if (!_initialized || !await _requestPlatformPermissions()) {
      await preferences.setBool(key, false);
      return false;
    }

    await preferences.setBool(key, true);
    await _scheduleUpcomingReminders();
    return true;
  }

  Future<void> syncTodayStatus({
    required String employeeId,
    required int attendanceCount,
    required bool hasActiveSession,
  }) async {
    if (!_initialized || !await notificationsEnabled(employeeId)) return;
    await _scheduleUpcomingReminders();
    final today = DateTime.now().toUtc().add(const Duration(hours: 3));
    if (attendanceCount >= 1) {
      await _plugin.cancel(
        id: _reminderId(today, AttendanceReminderType.morningCheckIn),
      );
    }
    if (attendanceCount >= 2) {
      await _plugin.cancel(
        id: _reminderId(today, AttendanceReminderType.afternoonCheckIn),
      );
    }
    if (!hasActiveSession) {
      await _plugin.cancel(
        id: _reminderId(today, AttendanceReminderType.checkout),
      );
    }
  }

  Future<void> markAttendanceRecorded() async {
    if (_initialized) {
      final today = DateTime.now().toUtc().add(const Duration(hours: 3));
      await _plugin.cancel(
        id: _reminderId(today, AttendanceReminderType.morningCheckIn),
      );
    }
  }

  Future<void> markCheckedOut() async {
    if (_initialized) {
      final today = DateTime.now().toUtc().add(const Duration(hours: 3));
      await _plugin.cancel(
        id: _reminderId(today, AttendanceReminderType.checkout),
      );
    }
  }

  Future<bool> showTestReminders(String employeeId) async {
    if (!_initialized || !await notificationsEnabled(employeeId)) return false;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_reminders',
        'Attendance reminders',
        channelDescription: 'Daily check-in and checkout reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _showTestReminder(
      id: 99000001,
      title: 'Morning check-in reminder',
      body: 'Please check in before 08:45 EAT.',
      details: details,
    );
    await _showTestReminder(
      id: 99000002,
      title: 'Afternoon check-in reminder',
      body: 'Your second check-in opens at 13:30 EAT.',
      details: details,
    );
    await _showTestReminder(
      id: 99000003,
      title: 'Checkout reminder',
      body: 'Please check out at 17:30 EAT.',
      details: details,
    );
    return true;
  }

  Future<void> _showTestReminder({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
  );

  Future<bool> _requestPlatformPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      if (await android.requestNotificationsPermission() != true) return false;
      _androidScheduleMode =
          await android.requestExactAlarmsPermission() == true
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      return true;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ==
        true;
  }

  Future<void> _scheduleUpcomingReminders() async {
    final now = DateTime.now().toUtc();
    await _plugin.cancelAll();
    final reminders = buildAttendanceReminderSchedule(
      now,
      days: _scheduledDays,
    );
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: switch (reminder.type) {
          AttendanceReminderType.morningCheckIn => 'Morning check-in reminder',
          AttendanceReminderType.afternoonCheckIn =>
            'Afternoon check-in reminder',
          AttendanceReminderType.checkout => 'Checkout reminder',
        },
        body: switch (reminder.type) {
          AttendanceReminderType.morningCheckIn =>
            'Please check in before 08:45 EAT.',
          AttendanceReminderType.afternoonCheckIn =>
            'Your second check-in opens at 13:30 EAT.',
          AttendanceReminderType.checkout =>
            'Please check out before 18:30 EAT.',
        },
        scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_reminders',
            'Attendance reminders',
            channelDescription: 'Daily check-in and checkout reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: _androidScheduleMode,
      );
    }
  }
}
