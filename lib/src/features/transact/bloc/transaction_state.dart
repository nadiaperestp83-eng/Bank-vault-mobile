import 'package:equatable/equatable.dart';
import '../../../models/vault_models.dart';

abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionInProgress extends TransactionState {
  final String message;
  TransactionInProgress(this.message);
  @override
  List<Object?> get props => [message];
}

class RecipientsLoaded extends TransactionState {
  final List<VaultUser> frequent;
  final List<VaultUser> searchResults;

  RecipientsLoaded({
    required this.frequent,
    this.searchResults = const [],
  });

  @override
  List<Object?> get props => [frequent, searchResults];
}

class TransactionSuccess extends TransactionState {
  final String message;
  final String? transactionId;
  TransactionSuccess(this.message, {this.transactionId});
  @override
  List<Object?> get props => [message, transactionId];
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}

class KycRequiredState extends TransactionState {
  @override
  List<Object?> get props => [];
}
