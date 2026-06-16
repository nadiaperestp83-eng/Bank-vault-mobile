import 'package:equatable/equatable.dart';

abstract class VaultAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VaultAuthInitial extends VaultAuthState {}

class VaultAuthLoading extends VaultAuthState {}

class VaultOtpSent extends VaultAuthState {}

class VaultAuthenticated extends VaultAuthState {
  final String userId;
  final bool hasProfile;
  final bool hasPin;

  VaultAuthenticated(this.userId, {this.hasProfile = true, this.hasPin = false});

  @override
  List<Object?> get props => [userId, hasProfile, hasPin];
}

class VaultUnauthenticated extends VaultAuthState {}

class VaultLocked extends VaultAuthState {
  final String userId;
  VaultLocked(this.userId);
  @override
  List<Object?> get props => [userId];
}

class VaultAuthError extends VaultAuthState {
  final String message;
  VaultAuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class VaultSecurityCompromised extends VaultAuthState {
  final String reason;
  VaultSecurityCompromised(this.reason);
  @override
  List<Object?> get props => [reason];
}
