import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/dashboard_service.dart';
import '../../../../models/vault_models.dart';
import '../../../../models/receipt_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<VaultNotification>>? _notificationSubscription;
  StreamSubscription<List<VaultReceipt>>? _receiptSubscription;

  DashboardBloc({required DashboardService dashboardService})
      : _dashboardService = dashboardService,
        super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<UpdateWallet>(_onUpdateWallet);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateReceipts>(_onUpdateReceipts);
    on<RefreshAIInsight>(_onRefreshAIInsight);
  }

  Future<void> _onRefreshAIInsight(
      RefreshAIInsight event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        await _dashboardService.triggerFinancialHealthCheck();
        final freshInsight = await _dashboardService.getLatestFinancialInsight();
        
        emit(DashboardLoaded(
          user: currentState.user,
          wallet: currentState.wallet,
          transactions: currentState.transactions,
          growthData: currentState.growthData,
          notifications: currentState.notifications,
          receipts: currentState.receipts,
          frequentContacts: currentState.frequentContacts,
          suggestedUsers: currentState.suggestedUsers,
          latestInsight: freshInsight,
          currencyRates: currentState.currencyRates,
        ));
      } catch (e) {
        // Option: emit error or just keep old state
      }
    }
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
      final initialReceipts = await _dashboardService.getReceiptsStream().first;

      emit(DashboardLoaded(
        user: user,
        wallet: initialWallet,
        transactions: transactions,
        growthData: growthData,
        notifications: initialNotifications,
        receipts: initialReceipts,
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

      _receiptSubscription?.cancel();
      _receiptSubscription = _dashboardService.getReceiptsStream().listen(
        (receipts) => add(UpdateReceipts(receipts)),
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
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
      ));
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
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
      ));
    }
  }

  void _onUpdateReceipts(UpdateReceipts event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: event.receipts,
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
    _receiptSubscription?.cancel();
    return super.close();
  }
}
