import 'package:equatable/equatable.dart';
import '../../../../models/vault_models.dart';

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
