import 'package:equatable/equatable.dart';
import '../../../../models/vault_models.dart';

abstract class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

class FetchGoalsRequested extends SavingsEvent {}

class GoalsUpdated extends SavingsEvent {
  final List<SavingsGoal> goals;
  const GoalsUpdated(this.goals);

  @override
  List<Object?> get props => [goals];
}

class FetchLedgerRequested extends SavingsEvent {
  final String goalId;
  const FetchLedgerRequested(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class LedgerUpdated extends SavingsEvent {
  final List<SavingsLedgerEntry> ledger;
  const LedgerUpdated(this.ledger);

  @override
  List<Object?> get props => [ledger];
}

class AddContributionRequested extends SavingsEvent {
  final SavingsGoal goal;
  final double amount;
  final String source;

  const AddContributionRequested({
    required this.goal,
    required this.amount,
    required this.source,
  });

  @override
  List<Object?> get props => [goal, amount, source];
}

class CreateGoalRequested extends SavingsEvent {
  final String title;
  final double targetAmount;
  final DateTime? deadline;

  const CreateGoalRequested({
    required this.title,
    required this.targetAmount,
    this.deadline,
  });

  @override
  List<Object?> get props => [title, targetAmount, deadline];
}
