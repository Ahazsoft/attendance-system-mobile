import 'dart:convert';

class Attendance {
  final int? id;
  final int employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? workingHours;
  final bool isBssidAvailable;
  final bool isCheckedIn;

  Attendance({
    this.id,
    required this.employeeId,
    required this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    this.isBssidAvailable = false,
    this.isCheckedIn = true,
  });

  // Copy with method for updates
  Attendance copyWith({
    int? id,
    int? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? workingHours,
    bool? isBssidAvailable,
    bool? isCheckedIn,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      workingHours: workingHours ?? this.workingHours,
      isBssidAvailable: isBssidAvailable ?? this.isBssidAvailable,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'workingHours': workingHours,
      'isBssidAvailable': isBssidAvailable,
      'isCheckedIn': isCheckedIn,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      employeeId: json['employeeId'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      workingHours: (json['workingHours'] as num?)?.toDouble(),
      isBssidAvailable: json['isBssidAvailable'] ?? false,
      isCheckedIn: json['isCheckedIn'] ?? false,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
