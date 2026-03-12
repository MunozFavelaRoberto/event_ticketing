class AuthResponse {
  final String message;
  final AuthData data;

  AuthResponse({
    required this.message,
    required this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String? ?? '',
      data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data.toJson(),
    };
  }
}

class AuthData {
  final Auth auth;

  AuthData({
    required this.auth,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      auth: Auth.fromJson(json['auth'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auth': auth.toJson(),
    };
  }
}

class Auth {
  final String token;
  final UserData user;

  Auth({
    required this.token,
    required this.user,
  });

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      token: json['token'] as String,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

class UserData {
  final int id;
  final int roleId;
  final String email;
  final String fullName;
  final Role role;

  UserData({
    required this.id,
    required this.roleId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as int,
      roleId: json['role_id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: Role.fromJson(json['role'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'email': email,
      'full_name': fullName,
      'role': role.toJson(),
    };
  }
}

class Role {
  final String name;

  Role({
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}