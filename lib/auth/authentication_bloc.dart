import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

// Events
abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationLoginRequested extends AuthenticationEvent {
  final String email;
  final String password;

  const AuthenticationLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthenticationLogoutRequested extends AuthenticationEvent {}

class AuthenticationRegisterRequested extends AuthenticationEvent {
  final String email;
  final String password;

  const AuthenticationRegisterRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthenticationResetPasswordRequested extends AuthenticationEvent {
  final String email;

  const AuthenticationResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

// States
class AuthenticationState extends Equatable {
  final bool isLoggedIn;
  final String? error;
  final bool isLoading;

  const AuthenticationState._({
    required this.isLoggedIn,
    this.error,
    this.isLoading = false,
  });

  const AuthenticationState.authenticated() : this._(isLoggedIn: true);
  const AuthenticationState.unauthenticated() : this._(isLoggedIn: false);
  const AuthenticationState.loading() : this._(isLoggedIn: false, isLoading: true);
  const AuthenticationState.error(String message) 
      : this._(isLoggedIn: false, error: message);

  @override
  List<Object?> get props => [isLoggedIn, error, isLoading];
}

// Bloc
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState.unauthenticated()) {
    
    on<AuthenticationLoginRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        // TODO: 实现实际的登录逻辑
        await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
        if (true) {
          emit(const AuthenticationState.authenticated());
        } else {
          emit(const AuthenticationState.error("Invalid credentials"));
        }
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationLogoutRequested>((event, emit) {
      emit(const AuthenticationState.unauthenticated());
    });

    on<AuthenticationRegisterRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        // TODO: 实现实际的注册逻辑
        await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
        emit(const AuthenticationState.authenticated());
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationResetPasswordRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        // TODO: 实现实际的密码重置逻辑
        await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
        emit(const AuthenticationState.unauthenticated());
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });
  }
}