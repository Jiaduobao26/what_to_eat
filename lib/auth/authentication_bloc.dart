import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }
}