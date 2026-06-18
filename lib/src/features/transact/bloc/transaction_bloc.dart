import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/transaction_service.dart';
import '../../../models/vault_models.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionService transactionService;
  List<VaultUser> _frequentRecipients = [];
  StreamSubscription? _transactionSubscription;

  TransactionBloc({required TransactionService transactionService})
      : transactionService = transactionService,
        super(TransactionInitial()) {
    on<LoadFrequentRecipients>(_onLoadFrequentRecipients);
    on<SearchRecipients>(_onSearchRecipients);
    on<PerformVaultTransfer>(_onPerformVaultTransfer);
    on<PerformMpesaDeposit>(_onPerformMpesaDeposit);
    on<PerformWithdrawal>(_onPerformWithdrawal);
    on<TransactionStatusUpdated>(_onTransactionStatusUpdated);
    on<TransactionTimeoutOccurred>(_onTransactionTimeoutOccurred);
    on<CreateBillSplit>(_onCreateBillSplit);
    on<PayBillSplit>(_onPayBillSplit);
    on<CancelBillSplit>(_onCancelBillSplit);

    _initRealtimeSubscription();
  }

  Future<void> _onCreateBillSplit(
      CreateBillSplit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      if (event.pin != 'BIOMETRIC_VALIDATED') {
        final isPinValid = await transactionService.verifyPin(event.pin);
        if (!isPinValid) {
          emit(TransactionError('Invalid Transaction PIN'));
          return;
        }
      }

      emit(TransactionInProgress('Creating bill split...'));
      await transactionService.createBillSplit(
        title: event.title,
        totalAmount: event.totalAmount,
        category: event.category,
        members: event.members,
        creatorAmount: event.creatorAmount,
      );
      emit(TransactionSuccess('Bill split created successfully!'));
    } on KycRequiredException {
      emit(KycRequiredState());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onPayBillSplit(
      PayBillSplit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      if (event.pin != 'BIOMETRIC_VALIDATED') {
        final isPinValid = await transactionService.verifyPin(event.pin);
        if (!isPinValid) {
          emit(TransactionError('Invalid Transaction PIN'));
          return;
        }
      }

      emit(TransactionInProgress('Processing payment...'));
      await transactionService.payBillSplit(event.memberId);
      emit(TransactionSuccess('Payment settled successfully!'));
    } on KycRequiredException {
      emit(KycRequiredState());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCancelBillSplit(
      CancelBillSplit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Cancelling split...'));
    try {
      await transactionService.cancelBillSplit(event.splitId);
      emit(TransactionSuccess('Bill split cancelled.'));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  String? _currentTransactionId;
  Timer? _timeoutTimer;

  void _initRealtimeSubscription() {
    _transactionSubscription = transactionService.getTransactionsStream().listen((transactions) {
      if (_currentTransactionId != null) {
        try {
          final tx = transactions.firstWhere((t) => t.description == _currentTransactionId || t.id == _currentTransactionId);
          if (tx.status != 'pending') {
            _timeoutTimer?.cancel();
            add(TransactionStatusUpdated(tx));
            _currentTransactionId = null;
          }
        } catch (e) {
          // Current transaction not found in the stream yet or not updated
        }
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (_currentTransactionId != null) {
        add(TransactionTimeoutOccurred());
        _currentTransactionId = null;
      }
    });
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadFrequentRecipients(
      LoadFrequentRecipients event, Emitter<TransactionState> emit) async {
    if (_frequentRecipients.isNotEmpty) {
      emit(RecipientsLoaded(frequent: _frequentRecipients));
      return;
    }
    try {
      _frequentRecipients = await transactionService.getFrequentRecipients();
      emit(RecipientsLoaded(frequent: _frequentRecipients));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onSearchRecipients(
      SearchRecipients event, Emitter<TransactionState> emit) async {
    if (event.query.isEmpty) {
      emit(RecipientsLoaded(frequent: _frequentRecipients));
      return;
    }
    try {
      final searchResults = await transactionService.searchUsers(event.query);
      emit(RecipientsLoaded(frequent: _frequentRecipients, searchResults: searchResults));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onPerformVaultTransfer(
      PerformVaultTransfer event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      if (event.pin != 'BIOMETRIC_VALIDATED') {
        final isPinValid = await transactionService.verifyPin(event.pin);
        if (!isPinValid) {
          emit(TransactionError('Invalid Transaction PIN'));
          return;
        }
      }

      emit(TransactionInProgress('Processing transfer...'));
      await transactionService.vaultTransfer(
        recipientTag: event.recipientTag,
        amount: event.amount,
        currency: event.currency,
        description: event.description,
      );
      emit(TransactionSuccess('Transfer successful!'));
    } on KycRequiredException {
      emit(KycRequiredState());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onPerformMpesaDeposit(
      PerformMpesaDeposit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      if (event.pin != 'BIOMETRIC_VALIDATED') {
        final isPinValid = await transactionService.verifyPin(event.pin);
        if (!isPinValid) {
          emit(TransactionError('Invalid Transaction PIN'));
          return;
        }
      }

      emit(TransactionInProgress('Requesting M-Pesa STK Push...'));
      final checkoutId = await transactionService.initiateMpesaDeposit(
        phoneNumber: event.phoneNumber,
        walletCredit: event.walletCredit,
        kesEquivalent: event.kesEquivalent,
      ).timeout(const Duration(seconds: 30));
      
      if (checkoutId != null) {
        _currentTransactionId = checkoutId;
        _startTimeoutTimer();
      }
      
      emit(TransactionSuccess('STK Push sent! Please enter your M-Pesa PIN on your phone.', transactionId: checkoutId));
    } on KycRequiredException {
      emit(KycRequiredState());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  void _onTransactionStatusUpdated(
      TransactionStatusUpdated event, Emitter<TransactionState> emit) {
    if (event.transaction.status == 'completed') {
      emit(TransactionSuccess('Transaction completed successfully!', transactionId: event.transaction.id));
    } else if (event.transaction.status == 'failed') {
      emit(TransactionError('Transaction failed: ${event.transaction.description ?? "Unknown error"}'));
    }
  }

  void _onTransactionTimeoutOccurred(
      TransactionTimeoutOccurred event, Emitter<TransactionState> emit) {
    emit(TransactionTimeout('Transaction Pending - We\'ll notify you once it\'s completed.'));
  }

  Future<void> _onPerformWithdrawal(
      PerformWithdrawal event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      if (event.pin != 'BIOMETRIC_VALIDATED') {
        final isPinValid = await transactionService.verifyPin(event.pin);
        if (!isPinValid) {
          emit(TransactionError('Invalid Transaction PIN'));
          return;
        }
      }

      // Fraud protection & balance check
      // For now we get balance from the event or a service, 
      // but evaluateTransaction in TransactionService currently just checks basic limits.
      // Ideally we'd pass the actual balance here.
      await transactionService.evaluateTransaction(amount: event.amount, balance: 1000000); // Placeholder high balance

      emit(TransactionInProgress('Processing withdrawal...'));
      await transactionService.initiateWithdrawal(
        amount: event.amount,
        method: event.method,
        currency: event.currency,
        description: event.description,
        details: event.details,
      );
      emit(TransactionSuccess('Withdrawal initiated successfully!'));
    } on KycRequiredException {
      emit(KycRequiredState());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
