import 'package:equatable/equatable.dart';

abstract class VaultAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VaultAuthInitial extends VaultAuthState {}

class VaultAuthenticated extends VaultAuthState {
  final String userId;
  VaultAuthenticated(this.userId);
  @override
  List<Object?> get props => [userId];
}

class VaultUnauthenticated extends VaultAuthState {}

class VaultAuthLoading extends VaultAuthState {}
