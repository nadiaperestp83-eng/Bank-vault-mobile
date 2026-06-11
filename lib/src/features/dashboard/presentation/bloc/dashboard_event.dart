import 'package:equatable/equatable.dart';
import '../../../../models/vault_models.dart';
import '../../../../models/receipt_model.dart';

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class UpdateWallet extends DashboardEvent {
  final Wallet wallet;
  UpdateWallet(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class UpdateNotifications extends DashboardEvent {
  final List<VaultNotification> notifications;
  UpdateNotifications(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class UpdateReceipts extends DashboardEvent {
  final List<VaultReceipt> receipts;
  UpdateReceipts(this.receipts);
  @override
  List<Object?> get props => [receipts];
}

class UpdateProfile extends DashboardEvent {
  final VaultUser user;
  UpdateProfile(this.user);
  @override
  List<Object?> get props => [user];
}

class UpdateTransactions extends DashboardEvent {
  final List<VaultTransaction> transactions;
  UpdateTransactions(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class UpdateGrowthData extends DashboardEvent {
  final Map<String, dynamic> growthData;
  UpdateGrowthData(this.growthData);
  @override
  List<Object?> get props => [growthData];
}

class UpdateFrequentContacts extends DashboardEvent {
  final List<VaultUser> frequentContacts;
  UpdateFrequentContacts(this.frequentContacts);
  @override
  List<Object?> get props => [frequentContacts];
}

class UpdateSuggestedUsers extends DashboardEvent {
  final List<VaultUser> suggestedUsers;
  UpdateSuggestedUsers(this.suggestedUsers);
  @override
  List<Object?> get props => [suggestedUsers];
}

class UpdateAIInsight extends DashboardEvent {
  final String? insight;
  UpdateAIInsight(this.insight);
  @override
  List<Object?> get props => [insight];
}

class UpdateCurrencyRates extends DashboardEvent {
  final Map<String, double> currencyRates;
  UpdateCurrencyRates(this.currencyRates);
  @override
  List<Object?> get props => [currencyRates];
}

class RefreshAIInsight extends DashboardEvent {}
