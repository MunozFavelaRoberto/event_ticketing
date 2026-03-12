class User {
  final int id;
  final String fullName;
  final String email;
  final String? ticketId;
  final String? ticketStatus;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.ticketId,
    this.ticketStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? 'Usuario',
      email: json['email'] as String? ?? 'email@desconocido.com',
      ticketId: json['ticketId'] as String?,
      ticketStatus: json['ticketStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'ticketId': ticketId,
      'ticketStatus': ticketStatus,
    };
  }
}
