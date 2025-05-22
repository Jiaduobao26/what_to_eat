import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

// define events
abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationLoginRequested extends AuthenticationEvent {}

class AuthenticationLogoutRequested extends AuthenticationEvent {}

// define states

class AuthenticationState extends Equatable {
  final bool isLoggedIn;

  const AuthenticationState._({required this.isLoggedIn});

  const AuthenticationState.authenticated() : this._(isLoggedIn: true);
  const AuthenticationState.unauthenticated() : this._(isLoggedIn: false);

  @override
  List<Object> get props => [isLoggedIn];
}

// define bloc
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState.unauthenticated()) {
    
    on<AuthenticationLoginRequested>((event, emit) {
      emit(const AuthenticationState.authenticated());
    });

    on<AuthenticationLogoutRequested>((event, emit) {
      emit(const AuthenticationState.unauthenticated());
    });
  }
}