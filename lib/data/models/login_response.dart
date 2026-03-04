class LoginResponse {
  final int? id;
  final String? token;
  final String? username;
  final String? fullName;
  final String? province;
  final String? relativePhone;

  LoginResponse({
    this.id,
    this.token,
    this.username,
    this.fullName,
    this.province,
    this.relativePhone,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] as int?,
      token: json['token'] as String?,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      province: json['province'] as String?,
      relativePhone: json['relativePhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'username': username,
      'fullName': fullName,
      'province': province,
      'relativePhone': relativePhone,
    };
  }
}
