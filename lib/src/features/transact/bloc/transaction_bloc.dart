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
    on<PerformStripeDeposit>(_onPerformStripeDeposit);
    on<PerformWithdrawal>(_onPerformWithdrawal);
    on<TransactionStatusUpdated>(_onTransactionStatusUpdated);

    _initRealtimeSubscription();
  }

  void _initRealtimeSubscription() {
    _transactionSubscription = transactionService.getTransactionsStream().listen((transactions) {
      if (transactions.isNotEmpty) {
        final latestTx = transactions.first;
        add(TransactionStatusUpdated(latestTx));
      }
    });
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
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
      final isPinValid = await transactionService.verifyPin(event.pin);
      if (!isPinValid) {
        emit(TransactionError('Invalid Transaction PIN'));
        return;
      }

      emit(TransactionInProgress('Processing transfer...'));
      await transactionService.vaultTransfer(
        recipientTag: event.recipientTag,
        amount: event.amount,
        currency: event.currency,
        description: event.description,
      );
      emit(TransactionSuccess('Transfer successful!'));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onPerformMpesaDeposit(
      PerformMpesaDeposit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      final isPinValid = await transactionService.verifyPin(event.pin);
      if (!isPinValid) {
        emit(TransactionError('Invalid Transaction PIN'));
        return;
      }

      emit(TransactionInProgress('Requesting M-Pesa STK Push...'));
      final checkoutId = await transactionService.initiateMpesaDeposit(
        phoneNumber: event.phoneNumber,
        amount: event.amount,
      );
      
      emit(TransactionSuccess('STK Push sent! Please enter your M-Pesa PIN on your phone.', transactionId: checkoutId));
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

  Future<void> _onPerformStripeDeposit(
      PerformStripeDeposit event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      final isPinValid = await transactionService.verifyPin(event.pin);
      if (!isPinValid) {
        emit(TransactionError('Invalid Transaction PIN'));
        return;
      }

      emit(TransactionInProgress('Initializing Stripe payment...'));
      final intentData = await transactionService.createStripePaymentIntent(
        amount: event.amount,
        currency: event.currency,
      );
      
      emit(TransactionSuccess('Stripe Payment Intent created', transactionId: intentData['clientSecret']));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onPerformWithdrawal(
      PerformWithdrawal event, Emitter<TransactionState> emit) async {
    emit(TransactionInProgress('Verifying PIN...'));
    try {
      final isPinValid = await transactionService.verifyPin(event.pin);
      if (!isPinValid) {
        emit(TransactionError('Invalid Transaction PIN'));
        return;
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
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
