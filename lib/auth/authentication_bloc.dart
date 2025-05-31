import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String name;

  const AuthenticationRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class AuthenticationResetPasswordRequested extends AuthenticationEvent {
  final String email;

  const AuthenticationResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthenticationGuestRequested extends AuthenticationEvent {}

// States
class AuthenticationState extends Equatable {
  final bool isLoggedIn;
  final bool isGuest;
  final String? error;
  final bool isLoading;

  const AuthenticationState._({
    required this.isLoggedIn,
    this.isGuest = false,
    this.error,
    this.isLoading = false,
  });

  const AuthenticationState.authenticated() : this._(isLoggedIn: true, isGuest: false);
  const AuthenticationState.unauthenticated() : this._(isLoggedIn: false, isGuest: false);
  const AuthenticationState.guest() : this._(isLoggedIn: false, isGuest: true);
  const AuthenticationState.loading() : this._(isLoggedIn: false, isGuest: false, isLoading: true);
  const AuthenticationState.error(String message) 
      : this._(isLoggedIn: false, isGuest: false, error: message);

  @override
  List<Object?> get props => [isLoggedIn, isGuest, error, isLoading];
}

// Bloc
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState.unauthenticated()) {
    
        on<AuthenticationRegisterRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        // 1. 创建用户
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // 2. 设置用户显示名称
        await userCredential.user?.updateDisplayName(event.name);
        
        // 3. 发送验证邮件
        await userCredential.user?.sendEmailVerification();
        
        // 4. 提示用户验证邮箱
        emit(AuthenticationState.error('Registration successful! Please verify your email address.'));
        
        // 5. 登出用户，等待邮箱验证
        await FirebaseAuth.instance.signOut();
        
        // 注意：将 Firestore 写入逻辑移到登录事件中
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationState.error(e.message ?? "注册失败"));
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationLoginRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        final user = userCredential.user;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          emit(AuthenticationState.error('请先前往邮箱完成验证，已重新发送验证邮件'));
          await FirebaseAuth.instance.signOut();
          return;
        }
        emit(const AuthenticationState.authenticated());
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationState.error(e.message ?? "登录失败"));
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationLogoutRequested>((event, emit) async {
      await FirebaseAuth.instance.signOut();
      emit(const AuthenticationState.unauthenticated());
    });

    

      on<AuthenticationResetPasswordRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: event.email,
        );
        emit(const AuthenticationState.unauthenticated());
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'invalid-email':
            emit(const AuthenticationState.error('邮箱格式不正确'));
            break;
          case 'user-not-found':
            emit(const AuthenticationState.error('该邮箱未注册'));
            break;
          default:
            emit(AuthenticationState.error(e.message ?? '重置密码失败'));
        }
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationGuestRequested>((event, emit) async {
      emit(const AuthenticationState.guest());
    });
  }
}