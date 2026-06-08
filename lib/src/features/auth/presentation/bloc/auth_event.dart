import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String email;
  SendOtpRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;
  VerifyOtpRequested(this.email, this.otp);
  @override
  List<Object?> get props => [email, otp];
}

class LoggedIn extends AuthEvent {
  final String userId;
  LoggedIn(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoggedOut extends AuthEvent {}
