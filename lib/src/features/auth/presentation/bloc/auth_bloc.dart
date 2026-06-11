import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vault_os/src/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, VaultAuthState> {
  final AuthService _authService;
AuthBloc({required AuthService authService})
    : _authService = authService,
      super(VaultAuthInitial()) {
  on<AppStarted>(_onAppStarted);
  on<SendOtpRequested>(_onSendOtpRequested);
  on<VerifyOtpRequested>(_onVerifyOtpRequested);
  on<LoggedIn>(_onLoggedIn);
  on<LoggedOut>(_onLoggedOut);
  on<UnlockWithBiometricsRequested>(_onUnlockWithBiometricsRequested);
}

Future<void> _onAppStarted(AppStarted event, Emitter<VaultAuthState> emit) async {
  final session = _authService.currentSession;
  if (session != null) {
    final userId = session.user.id;
    // Emit VaultLocked instead of VaultAuthenticated to force biometric/PIN check
    emit(VaultLocked(userId));
  } else {
    emit(VaultUnauthenticated());
  }
}

Future<void> _onUnlockWithBiometricsRequested(UnlockWithBiometricsRequested event, Emitter<VaultAuthState> emit) async {
  emit(VaultAuthLoading());
  try {
    final userId = event.userId;
    final hasProfile = await _authService.checkProfileExists(userId);
    final hasPin = hasProfile ? await _authService.hasTransactionPin(userId) : false;
    
    // Log biometric login activity
    await _authService.logActivity('Biometric Login', userId: userId);
    
    emit(VaultAuthenticated(userId, hasProfile: hasProfile, hasPin: hasPin));
  } catch (e) {
    emit(VaultAuthError(e.toString()));
  }
}


  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<VaultAuthState> emit) async {
    if (state is VaultAuthLoading) return;
    emit(VaultAuthLoading());
    try {
      await _authService.sendOtp(event.email);
      emit(VaultOtpSent());
    } catch (e) {
      emit(VaultAuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtpRequested(VerifyOtpRequested event, Emitter<VaultAuthState> emit) async {
    if (state is VaultAuthLoading) return;
    emit(VaultAuthLoading());
    try {
      final response = await _authService.verifyOtp(event.email, event.otp);
      if (response.user != null) {
        final userId = response.user!.id;
        final hasProfile = await _authService.checkProfileExists(userId);
        final hasPin = hasProfile ? await _authService.hasTransactionPin(userId) : false;
        
        // Log login activity
        await _authService.logActivity('Login', userId: userId);
        
        emit(VaultAuthenticated(userId, hasProfile: hasProfile, hasPin: hasPin));
      } else {
        emit(VaultAuthError('Verification failed'));
      }
    } catch (e) {
      emit(VaultAuthError(e.toString()));
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<VaultAuthState> emit) {
    emit(VaultAuthenticated(event.userId));
  }

  void _onLoggedOut(LoggedOut event, Emitter<VaultAuthState> emit) async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await _authService.logActivity('Sign Out', userId: userId);
    }
    await Supabase.instance.client.auth.signOut();
    emit(VaultUnauthenticated());
  }
}
