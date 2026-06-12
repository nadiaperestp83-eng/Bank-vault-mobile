import 'package:equatable/equatable.dart';
import '../../../../models/vault_models.dart';
import '../../../../models/receipt_model.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final VaultUser user;
  final Wallet wallet;
  final List<VaultTransaction> transactions;
  final Map<String, dynamic> growthData;
  final List<VaultNotification> notifications;
  final List<VaultReceipt> receipts;
  final List<VaultUser> frequentContacts;
  final List<VaultUser> suggestedUsers;
  final String? latestInsight;
  final Map<String, double> currencyRates;
  final DateTime lastUpdated;

  DashboardLoaded({
    required this.user,
    required this.wallet,
    required this.transactions,
    required this.growthData,
    required this.notifications,
    required this.receipts,
    required this.frequentContacts,
    required this.suggestedUsers,
    required this.currencyRates,
    required this.lastUpdated,
    this.latestInsight,
  });

  @override
  List<Object?> get props => [
        user,
        wallet,
        transactions,
        growthData,
        notifications,
        receipts,
        frequentContacts,
        suggestedUsers,
        latestInsight,
        currencyRates,
        lastUpdated,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
