class User {
  final String clientNumber;
  final String status;
  final double balance;
  final String fullName;
  final String email;
  final String? ticketId; // ID encriptado del boleto para QR
  final String? ticketStatus; // Estado del boleto: 'active', 'used', 'expired', etc.

  User({
    required this.clientNumber,
    required this.status,
    required this.balance,
    required this.fullName,
    required this.email,
    this.ticketId,
    this.ticketStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      clientNumber: json['clientNumber'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'Desconocido',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      fullName: json['fullName'] as String? ?? 'Nombre Desconocido',
      email: json['email'] as String? ?? 'email@desconocido.com',
      ticketId: json['ticketId'] as String?,
      ticketStatus: json['ticketStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientNumber': clientNumber,
      'status': status,
      'balance': balance,
      'fullName': fullName,
      'email': email,
      'ticketId': ticketId,
      'ticketStatus': ticketStatus,
    };
  }
}