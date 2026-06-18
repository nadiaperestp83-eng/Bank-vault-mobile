import 'package:equatable/equatable.dart';
import '../../../models/vault_models.dart';

abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFrequentRecipients extends TransactionEvent {}

class SearchRecipients extends TransactionEvent {
  final String query;
  SearchRecipients(this.query);
  @override
  List<Object?> get props => [query];
}

class PerformVaultTransfer extends TransactionEvent {
  final String recipientTag;
  final double amount;
  final String currency;
  final String? description;
  final String pin;

  PerformVaultTransfer({
    required this.recipientTag,
    required this.amount,
    required this.currency,
    this.description,
    required this.pin,
  });

  @override
  List<Object?> get props => [recipientTag, amount, currency, description, pin];
}

class PerformMpesaDeposit extends TransactionEvent {
  final String phoneNumber;
  final double walletCredit;
  final double kesEquivalent;
  final String pin;

  PerformMpesaDeposit({
    required this.phoneNumber,
    required this.walletCredit,
    required this.kesEquivalent,
    required this.pin,
  });

  @override
  List<Object?> get props => [phoneNumber, walletCredit, kesEquivalent, pin];
}

class PerformWithdrawal extends TransactionEvent {
  final double amount;
  final String method;
  final String currency;
  final String description;
  final Map<String, dynamic> details;
  final String pin;

  PerformWithdrawal({
    required this.amount,
    required this.method,
    required this.currency,
    required this.description,
    required this.details,
    required this.pin,
  });

  @override
  List<Object?> get props => [amount, method, currency, description, details, pin];
}

class TransactionStatusUpdated extends TransactionEvent {
  final VaultTransaction transaction;
  TransactionStatusUpdated(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class TransactionTimeoutOccurred extends TransactionEvent {}

class ToggleCurrency extends TransactionEvent {
  final String currency;
  ToggleCurrency(this.currency);
  @override
  List<Object?> get props => [currency];
}

class CreateBillSplit extends TransactionEvent {
  final String title;
  final double totalAmount;
  final String category;
  final List<Map<String, dynamic>> members;
  final double creatorAmount;
  final String pin;

  CreateBillSplit({
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.members,
    required this.creatorAmount,
    required this.pin,
  });

  @override
  List<Object?> get props => [title, totalAmount, category, members, creatorAmount, pin];
}

class PayBillSplit extends TransactionEvent {
  final String memberId;
  final String pin;
  PayBillSplit({required this.memberId, required this.pin});
  @override
  List<Object?> get props => [memberId, pin];
}

class CancelBillSplit extends TransactionEvent {
  final String splitId;
  CancelBillSplit({required this.splitId});
  @override
  List<Object?> get props => [splitId];
}
