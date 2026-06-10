import 'package:equatable/equatable.dart';
import '../../../../models/vault_models.dart';

abstract class SavingsState extends Equatable {
  const SavingsState();

  @override
  List<Object?> get props => [];
}

class SavingsInitial extends SavingsState {}

class SavingsLoading extends SavingsState {}

class SavingsLoaded extends SavingsState {
  final List<SavingsGoal> goals;
  final List<SavingsLedgerEntry> selectedGoalLedger;
  final String? error;

  const SavingsLoaded({
    required this.goals,
    this.selectedGoalLedger = const [],
    this.error,
  });

  @override
  List<Object?> get props => [goals, selectedGoalLedger, error];
}

class SavingsError extends SavingsState {
  final String message;
  const SavingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContributionSuccess extends SavingsState {}
