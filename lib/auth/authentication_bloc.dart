import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';

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

class AuthenticationGuestLoginButtonPressed extends AuthenticationEvent {}

class AuthenticationCleanupUnverifiedRequested extends AuthenticationEvent {}

class AuthenticationCheckGuestStatusRequested extends AuthenticationEvent {}

class AuthenticationInitialCheckCompleted extends AuthenticationEvent {
  final bool isAuthenticated;

  const AuthenticationInitialCheckCompleted({required this.isAuthenticated});

  @override
  List<Object> get props => [isAuthenticated];
}

// States
class AuthenticationState extends Equatable {
  final bool isLoggedIn;
  final bool isGuest;
  final bool isGuestLoggedIn;
  final String? error;
  final String? successMessage;
  final bool isLoading;

  const AuthenticationState._({
    required this.isLoggedIn,
    this.isGuest = false,
    this.isGuestLoggedIn = false,
    this.error,
    this.successMessage,
    this.isLoading = false,
  });

  const AuthenticationState.authenticated() : this._(isLoggedIn: true, isGuest: false);
  const AuthenticationState.unauthenticated() : this._(isLoggedIn: false, isGuest: false);
  const AuthenticationState.guest() : this._(isLoggedIn: false, isGuest: true);
  const AuthenticationState.guestLoggedIn() : this._(isLoggedIn: false, isGuest: true, isGuestLoggedIn: true);
  const AuthenticationState.loading() : this._(isLoggedIn: false, isGuest: false, isLoading: true);
  const AuthenticationState.error(String message) 
      : this._(isLoggedIn: false, isGuest: false, error: message);
  const AuthenticationState.success(String message) 
      : this._(isLoggedIn: false, isGuest: false, successMessage: message);

  @override
  List<Object?> get props => [isLoggedIn, isGuest, isGuestLoggedIn, error, successMessage, isLoading];
}

// Bloc
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState.unauthenticated()) {
    // 检查初始认证状态
    _checkInitialAuthState();
    
    // 监听Firebase Auth状态变化
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.emailVerified) {
        // 用户已登录且邮箱已验证
        add(AuthenticationInitialCheckCompleted(isAuthenticated: true));
      } else {
        // 用户未登录或邮箱未验证，检查guest状态
        add(AuthenticationInitialCheckCompleted(isAuthenticated: false));
      }
    });
    
    on<AuthenticationRegisterRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        UserCredential? userCredential;
        
        try {
          // 1. Try to create account directly
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: event.email,
            password: event.password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // 2. Email already in use, send password reset to let real owner handle it
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: event.email);
              emit(const AuthenticationState.error('This email is already registered. A password reset email has been sent. Please check your email to access your account.'));
            } catch (resetError) {
              emit(const AuthenticationState.error('This email is already registered. Please use a different email address.'));
            }
            return;
          } else {
            // Other registration errors
            rethrow;
          }        }
        
        // 3. Handle successful account creation
        if (userCredential != null) {
          // Set user display name
          await userCredential.user?.updateDisplayName(event.name);
          
          // Send verification email immediately
          await userCredential.user?.sendEmailVerification();
          
          // Write to Firestore immediately without emailVerified field
          await FirebaseFirestore.instanceFor(
            app: FirebaseFirestore.instance.app,
            databaseId: 'userinfo',
          ).collection('userinfo').doc(userCredential.user!.uid).set({
            'name': event.name,
            'email': event.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // 注册成功后立即标记为需要设置偏好
          final prefs = await SharedPreferences.getInstance();
          final needsPreferenceEmails = prefs.getStringList('needsPreferenceSetup') ?? [];
          if (!needsPreferenceEmails.contains(event.email)) {
            needsPreferenceEmails.add(event.email);
            await prefs.setStringList('needsPreferenceSetup', needsPreferenceEmails);
            print('🔍 Register Debug: Added ${event.email} to needsPreferenceSetup list');
            print('🔍 Register Debug: Current list = $needsPreferenceEmails');
          } else {
            print('🔍 Register Debug: ${event.email} already in needsPreferenceSetup list');
          }
          
          // Log out user, require email verification first
          await FirebaseAuth.instance.signOut();
          
          // Prompt user to verify email
          emit(const AuthenticationState.error('Registration successful! Please check your email and click the verification link, then return to log in.'));
        }
        
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationState.error(e.message ?? "Registration failed"));
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
        
        // Check if email is verified
        if (user != null && !user.emailVerified) {
          // Resend verification email
          await user.sendEmailVerification();
          emit(const AuthenticationState.error('Please verify your email first. Verification email has been resent, please check your inbox.'));
          await FirebaseAuth.instance.signOut();
          return;
        }
        
        // If email is verified, user can proceed to login
        if (user != null && user.emailVerified) {
          // No need to update Firestore since we're using Firebase Auth's emailVerified directly
        }
        
        emit(const AuthenticationState.authenticated());
        
        // Send welcome notification after successful login
        try {
          await FCMService().showWelcomeNotification();
        } catch (e) {
          // Don't fail login if notification fails
          print('Failed to send welcome notification: $e');
        }
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationState.error(e.message ?? "Login failed"));
      } catch (e) {
        emit(AuthenticationState.error(e.toString()));
      }
    });

    on<AuthenticationLogoutRequested>((event, emit) async {
      // Clear guest status when logout is pressed
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guestLoggedIn');
      // Keep guestHasCompletedSetup to avoid showing preference choose again
      await FirebaseAuth.instance.signOut();
      emit(const AuthenticationState.unauthenticated());
    });    on<AuthenticationResetPasswordRequested>((event, emit) async {
      emit(const AuthenticationState.loading());
      try {
        // Send password reset email using Firebase Auth
        await FirebaseAuth.instance.sendPasswordResetEmail(email: event.email);
        emit(const AuthenticationState.success('Password reset email sent successfully! Please check your email inbox.'));
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to send password reset email.';
        }
        emit(AuthenticationState.error(errorMessage));
      } catch (e) {
        emit(AuthenticationState.error('An unexpected error occurred: ${e.toString()}'));
      }
    });

    on<AuthenticationGuestRequested>((event, emit) async {
      // Check if guest has completed setup before
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedSetup = prefs.getBool('guestHasCompletedSetup') ?? false;
      
      if (hasCompletedSetup) {
        // Guest has been here before, mark as logged in directly
        await prefs.setBool('guestLoggedIn', true);
        emit(const AuthenticationState.guestLoggedIn());
        
        // 发送欢迎通知
        try {
          await FCMService().showWelcomeNotification();
        } catch (e) {
          // 通知发送失败不影响登录流程
          print('Failed to send welcome notification: $e');
        }
      } else {
        // First time guest login - goes to preference choose
        emit(const AuthenticationState.guest());
      }
    });

    on<AuthenticationGuestLoginButtonPressed>((event, emit) async {
      // Mark guest as logged in and save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guestLoggedIn', true);
      await prefs.setBool('guestHasCompletedSetup', true); // Mark setup as completed
      emit(const AuthenticationState.guestLoggedIn());
      
      // 发送欢迎通知
      try {
        await FCMService().showWelcomeNotification();
      } catch (e) {
        // 通知发送失败不影响登录流程
        print('Failed to send welcome notification: $e');
      }
    });

    on<AuthenticationCleanupUnverifiedRequested>((event, emit) async {
      // Implementation of cleanup logic
      emit(const AuthenticationState.unauthenticated());
    });

    on<AuthenticationCheckGuestStatusRequested>((event, emit) async {
      // Check if user was previously logged in as guest
      final prefs = await SharedPreferences.getInstance();
      final isGuestLoggedIn = prefs.getBool('guestLoggedIn') ?? false;
      
      if (isGuestLoggedIn) {
        emit(const AuthenticationState.guestLoggedIn());
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    });

    on<AuthenticationInitialCheckCompleted>((event, emit) async {
      if (event.isAuthenticated) {
        // 清除guest状态，用户已登录
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('guestLoggedIn');
        emit(const AuthenticationState.authenticated());
        
        // 检查是否为新注册用户（在needsPreferenceSetup列表中的用户不发送通知，因为他们已经在登录时收到了）
        final user = FirebaseAuth.instance.currentUser;
        final needsPreferenceEmails = prefs.getStringList('needsPreferenceSetup') ?? [];
        final isNewUser = user?.email != null && needsPreferenceEmails.contains(user!.email);
        
        // 只有非新注册用户才发送欢迎通知（新注册用户已经在登录时收到了）
        if (!isNewUser) {
          try {
            await FCMService().showWelcomeNotification();
          } catch (e) {
            // 通知发送失败不影响登录流程
            print('Failed to send welcome notification: $e');
          }
        }
      } else {
        // 检查guest状态
        final prefs = await SharedPreferences.getInstance();
        final isGuestLoggedIn = prefs.getBool('guestLoggedIn') ?? false;
        
        if (isGuestLoggedIn) {
          emit(const AuthenticationState.guestLoggedIn());
        } else {
          emit(const AuthenticationState.unauthenticated());
        }
      }
    });
  }

  Future<void> _checkInitialAuthState() async {
    // 延迟一下，让Firebase Auth完全初始化
    await Future.delayed(const Duration(milliseconds: 100));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      add(const AuthenticationInitialCheckCompleted(isAuthenticated: true));
    } else {
      add(const AuthenticationInitialCheckCompleted(isAuthenticated: false));
    }
  }
}