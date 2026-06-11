import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/dashboard_service.dart';
import '../../../../services/dashboard_cache.dart';
import '../../../../models/vault_models.dart';
import '../../../../models/receipt_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  final DashboardCache _dashboardCache;
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<VaultNotification>>? _notificationSubscription;
  StreamSubscription<List<VaultReceipt>>? _receiptSubscription;

  DashboardBloc({
    required DashboardService dashboardService,
    DashboardCache? dashboardCache,
  })  : _dashboardService = dashboardService,
        _dashboardCache = dashboardCache ?? DashboardCache(),
        super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<UpdateWallet>(_onUpdateWallet);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateReceipts>(_onUpdateReceipts);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateTransactions>(_onUpdateTransactions);
    on<UpdateGrowthData>(_onUpdateGrowthData);
    on<UpdateFrequentContacts>(_onUpdateFrequentContacts);
    on<UpdateSuggestedUsers>(_onUpdateSuggestedUsers);
    on<UpdateAIInsight>(_onUpdateAIInsight);
    on<UpdateCurrencyRates>(_onUpdateCurrencyRates);
    on<RefreshAIInsight>(_onRefreshAIInsight);
  }

  Future<void> _onRefreshAIInsight(
      RefreshAIInsight event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoaded) {
      try {
        await _dashboardService.triggerFinancialHealthCheck();
        final freshInsight = await _dashboardService.getLatestFinancialInsight();
        add(UpdateAIInsight(freshInsight));
      } catch (e) {
        // Option: emit error or just keep old state
      }
    }
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event, Emitter<DashboardState> emit) async {
    // If we already have data in memory, just background refresh
    if (state is DashboardLoaded) {
      _backgroundRefresh();
      return;
    }

    // Try loading from cache first
    final cachedData = await _dashboardCache.getCachedDashboardData();
    if (cachedData != null) {
      emit(DashboardLoaded(
        user: cachedData['user'] as VaultUser,
        wallet: cachedData['wallet'] as Wallet,
        transactions: cachedData['transactions'] as List<VaultTransaction>,
        growthData: cachedData['growthData'] as Map<String, dynamic>,
        notifications: cachedData['notifications'] as List<VaultNotification>,
        receipts: cachedData['receipts'] as List<VaultReceipt>,
        frequentContacts: cachedData['frequentContacts'] as List<VaultUser>,
        suggestedUsers: cachedData['suggestedUsers'] as List<VaultUser>,
        currencyRates: cachedData['currencyRates'] as Map<String, double>,
        latestInsight: cachedData['latestInsight'] as String?,
        lastUpdated: cachedData['cachedAt'] as DateTime,
      ));
      
      // Start subscriptions and background refresh
      _initSubscriptions();
      _backgroundRefresh();
      return;
    }
    
    emit(DashboardLoading());

    try {
      // Parallelize independent fetches for speed
      final results = await Future.wait([
        _dashboardService.getProfile(),
        _dashboardService.getBalanceHistory(),
        _dashboardService.getTransactions(),
        _dashboardService.getFrequentContacts(),
        _dashboardService.getSuggestedUsers(),
        _dashboardService.getLatestFinancialInsight(),
        _dashboardService.getCurrencyRates(),
        _dashboardService.getWalletStream().first,
        _dashboardService.getNotificationStream().first,
        _dashboardService.getReceiptsStream().first,
      ]);

      final user = results[0] as VaultUser;
      final history = results[1] as List<BalanceHistory>;
      final growthData = _dashboardService.calculatePortfolioGrowth(history);
      final transactions = results[2] as List<VaultTransaction>;
      final frequentContacts = results[3] as List<VaultUser>;
      final suggestedUsers = results[4] as List<VaultUser>;
      final latestInsight = results[5] as String?;
      final currencyRates = results[6] as Map<String, double>;
      final initialWallet = results[7] as Wallet;
      final initialNotifications = results[8] as List<VaultNotification>;
      final initialReceipts = results[9] as List<VaultReceipt>;

      final newState = DashboardLoaded(
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
        lastUpdated: DateTime.now(),
      );

      emit(newState);
      _saveToCache(newState);

      // Start real-time streams for updates if not already active
      _initSubscriptions();
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _saveToCache(DashboardLoaded state) {
    _dashboardCache.saveDashboardData(
      user: state.user,
      wallet: state.wallet,
      transactions: state.transactions,
      growthData: state.growthData,
      notifications: state.notifications,
      receipts: state.receipts,
      frequentContacts: state.frequentContacts,
      suggestedUsers: state.suggestedUsers,
      currencyRates: state.currencyRates,
      latestInsight: state.latestInsight,
    );
  }

  void _initSubscriptions() {
    if (_walletSubscription == null) {
      _walletSubscription = _dashboardService.getWalletStream().listen(
        (wallet) => add(UpdateWallet(wallet)),
      );
    }

    if (_notificationSubscription == null) {
      _notificationSubscription = _dashboardService.getNotificationStream().listen(
        (notifications) => add(UpdateNotifications(notifications)),
      );
    }

    if (_receiptSubscription == null) {
      _receiptSubscription = _dashboardService.getReceiptsStream().listen(
        (receipts) => add(UpdateReceipts(receipts)),
      );
    }
  }

  void _backgroundRefresh() {
    // Throttle refreshes to once every 60 seconds for background updates
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      if (DateTime.now().difference(currentState.lastUpdated).inSeconds < 60) {
        return;
      }
    }

    // Run updates in background "threads" (async futures)
    _dashboardService.getProfile().then((user) => add(UpdateProfile(user))).catchError((_) => null);
    _dashboardService.getBalanceHistory().then((history) {
      final growthData = _dashboardService.calculatePortfolioGrowth(history);
      add(UpdateGrowthData(growthData));
    }).catchError((_) => null);
    _dashboardService.getTransactions().then((txs) => add(UpdateTransactions(txs))).catchError((_) => null);
    _dashboardService.getFrequentContacts().then((users) => add(UpdateFrequentContacts(users))).catchError((_) => null);
    _dashboardService.getSuggestedUsers().then((users) => add(UpdateSuggestedUsers(users))).catchError((_) => null);
    _dashboardService.getLatestFinancialInsight().then((insight) => add(UpdateAIInsight(insight))).catchError((_) => null);
    _dashboardService.getCurrencyRates().then((rates) => add(UpdateCurrencyRates(rates))).catchError((_) => null);
    
    // Ensure subscriptions are active
    _initSubscriptions();
  }

  void _onUpdateWallet(UpdateWallet event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      if (currentState.wallet == event.wallet) return;
      
      final newState = DashboardLoaded(
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
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateNotifications(
      UpdateNotifications event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
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
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateReceipts(UpdateReceipts event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
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
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateProfile(UpdateProfile event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      if (currentState.user == event.user) return;

      final newState = DashboardLoaded(
        user: event.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateTransactions(UpdateTransactions event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: event.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateGrowthData(UpdateGrowthData event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: event.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateFrequentContacts(UpdateFrequentContacts event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: event.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateSuggestedUsers(UpdateSuggestedUsers event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: event.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateAIInsight(UpdateAIInsight event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: event.insight,
        currencyRates: currentState.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
    }
  }

  void _onUpdateCurrencyRates(UpdateCurrencyRates event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newState = DashboardLoaded(
        user: currentState.user,
        wallet: currentState.wallet,
        transactions: currentState.transactions,
        growthData: currentState.growthData,
        notifications: currentState.notifications,
        receipts: currentState.receipts,
        frequentContacts: currentState.frequentContacts,
        suggestedUsers: currentState.suggestedUsers,
        latestInsight: currentState.latestInsight,
        currencyRates: event.currencyRates,
        lastUpdated: DateTime.now(),
      );
      emit(newState);
      _saveToCache(newState);
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
