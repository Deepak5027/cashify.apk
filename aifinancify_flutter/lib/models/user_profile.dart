class UserProfileModel {
  final String id;
  final String? name;
  final String? email;
  final String? image;
  final String? phone;
  final String? location;
  final String currency;
  final String timezone;
  final DateTime? lastLogin;
  final String? lastLoginDevice;
  final DateTime? createdAt;

  UserProfileModel({
    required this.id,
    this.name,
    this.email,
    this.image,
    this.phone,
    this.location,
    this.currency = '₹',
    this.timezone = 'UTC+5:30',
    this.lastLogin,
    this.lastLoginDevice,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      image: json['image']?.toString() ?? json['picture']?.toString(),
      phone: json['phone']?.toString(),
      location: json['location']?.toString(),
      currency: json['currency']?.toString() ?? '₹',
      timezone: json['timezone']?.toString() ?? 'UTC+5:30',
      lastLogin: json['lastLogin'] != null ? DateTime.tryParse(json['lastLogin'].toString()) : null,
      lastLoginDevice: json['lastLoginDevice']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'phone': phone,
      'location': location,
      'currency': currency,
      'timezone': timezone,
    };
  }
}
