class User {
  final String id;
  final String fullName;
  final String email;
  final bool isAdmin;
  final bool isApproved;
  final String? position;
  final String? imageUrl;
  final double? salary;
  final String? telephone;
  final int streak;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isAdmin,
    required this.isApproved,
    this.position,
    this.imageUrl,
    this.salary,
    this.telephone,
    required this.streak,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      isAdmin: json['isAdmin'],
      isApproved: json['isApproved'],
      position: json['position'],
      imageUrl: json['imageUrl'],
      salary: json['salary']?.toDouble(),
      telephone: json['telephone'],
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'isAdmin': isAdmin,
      'isApproved': isApproved,
      'position': position,
      'imageUrl': imageUrl,
      'salary': salary,
      'telephone': telephone,
      'streak': 0,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    bool? isAdmin,
    bool? isApproved,
    String? position,
    String? imageUrl,
    double? salary,
    String? telephone,
    int? streak,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isApproved: isApproved ?? this.isApproved,
      position: position ?? this.position,
      imageUrl: imageUrl ?? this.imageUrl,
      salary: salary ?? this.salary,
      telephone: telephone ?? this.telephone,
      streak: streak ?? this.streak,
    );
  }
}

const data = {
  "id": 1,
  "email": "admin@domain.com",
  "firstName": "Fine",
  "lastName": "Guy",
  "isAdmin": false,
  "isApproved": false,
  "position": "Software Developer",
  "imageUrl": null,
  "salary": null,
  "telephone": null,
  "streak": 0,
};
