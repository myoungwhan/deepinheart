class BankAccountModel {
  final bool success;
  final String message;
  final BankAccount? data;

  BankAccountModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BankAccount.fromJson(json['data']) : null,
    );
  }
}

class BankAccount {
  final int id;
  final int userId;
  final String bankName;
  final String accountNumber;
  final String holderName;
  final String createdAt;
  final String updatedAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountNumber,
    required this.holderName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      holderName: json['holder_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  /// Get formatted display string for account
  String get displayText => '$bankName $accountNumber';

  /// Get masked account number (show only last 4 digits)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '****$lastFour';
  }
}

