class User {
  final int id;
  final String firstName;
  final String lastName;
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
    required this.firstName,
    required this.lastName,
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
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      isAdmin: json['isAdmin'],
      isApproved: json['isApproved'],
      position: json['position'],
      imageUrl: json['imageUrl'],
      salary: json['salary']?.toDouble(),
      telephone: json['telephone'],
      streak: json['streak'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'isAdmin': isAdmin,
      'isApproved': isApproved,
      'position': position,
      'imageUrl': imageUrl,
      'salary': salary,
      'telephone': telephone,
      'streak': streak,
    };
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
