class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? language;

  const UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.language,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      fullName: (json['full_name'] ?? json['fullName']) as String?,
      email: json['email'] as String?,
      phoneNumber: (json['phone_number'] ?? json['mobileNumber']) as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl']) as String?,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'language': language,
      };
}
