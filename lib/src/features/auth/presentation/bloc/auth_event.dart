import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String userId;
  LoggedIn(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoggedOut extends AuthEvent {}
