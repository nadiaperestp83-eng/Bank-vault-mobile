import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/dashboard_service.dart';
import '../../../../models/vault_models.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<VaultNotification>>? _notificationSubscription;

  DashboardBloc({required DashboardService dashboardService})
      : _dashboardService = dashboardService,
        super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<UpdateWallet>(_onUpdateWallet);
    on<UpdateNotifications>(_onUpdateNotifications);
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final user = await _dashboardService.getProfile();
      final history = await _dashboardService.getBalanceHistory();
      final growthData = _dashboardService.calculatePortfolioGrowth(history);
      final transactions = await _dashboardService.getTransactions();
      final frequentContacts = await _dashboardService.getFrequentContacts();
      final suggestedUsers = await _dashboardService.getSuggestedUsers();
      final latestInsight = await _dashboardService.getLatestFinancialInsight();
      final currencyRates = await _dashboardService.getCurrencyRates();

      // Fetch initial data for immediate emission
      final initialWallet = await _dashboardService.getWalletStream().first;
      final initialNotifications = await _dashboardService.getNotificationStream().first;

      emit(DashboardLoaded(
        user: user,
        wallet: initialWallet,
        transactions: transactions,
        growthData: growthData,
        notifications: initialNotifications,
        frequentContacts: frequentContacts,
        suggestedUsers: suggestedUsers,
        latestInsight: latestInsight,
        currencyRates: currencyRates,
      ));

      // Start real-time streams for updates
      _walletSubscription?.cancel();
      _walletSubscription = _dashboardService.getWalletStream().listen(
        (wallet) => add(UpdateWallet(wallet)),
      );

      _notificationSubscription?.cancel();
      _notificationSubscription = _dashboardService.getNotificationStream().listen(
        (notifications) => add(UpdateNotifications(notifications)),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _onUpdateWallet(UpdateWallet event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(DashboardLoaded(
        user: currentState.user,
        wallet: event.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
      ));
    } else if (state is DashboardLoading || state is DashboardInitial) {
      // Handle the case where wallet comes before other data is fully loaded
      // In a real app, you'd probably use RxDart to combine these streams
    }
  }

  void _onUpdateNotifications(
      UpdateNotifications event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: event.notifications,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
      ));
    }
  }

  @override
  Future<void> close() {
    _walletSubscription?.cancel();
    _notificationSubscription?.cancel();
    return super.close();
  }
}
