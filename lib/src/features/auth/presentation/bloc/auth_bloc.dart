import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, VaultAuthState> {
  final SupabaseClient _supabaseClient;

  AuthBloc({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient,
        super(VaultAuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  void _onAppStarted(AppStarted event, Emitter<VaultAuthState> emit) {
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      emit(VaultAuthenticated(session.user.id));
    } else {
      emit(VaultUnauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<VaultAuthState> emit) {
    emit(VaultAuthenticated(event.userId));
  }

  void _onLoggedOut(LoggedOut event, Emitter<VaultAuthState> emit) async {
    await _supabaseClient.auth.signOut();
    emit(VaultUnauthenticated());
  }
}
