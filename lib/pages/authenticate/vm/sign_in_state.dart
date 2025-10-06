import 'package:equatable/equatable.dart';

class SignInState extends Equatable{
  const SignInState();

  @override
  List<Object> get props => [];
}

class SignInStateInitial extends SignInState{
  const SignInStateInitial();

  @override
  List<Object> get props => [];
}

class SignInStateLoading extends SignInState {
  const SignInStateLoading();

  @override
  List<Object> get props => [];
}

class SignInStateSuccess extends SignInState {
  const SignInStateSuccess();

  @override
  List<Object> get props => [];
}

class SignInStateError extends SignInState {
  final String error;
  const SignInStateError(this.error);

  @override
  List<Object> get props => [error];
}