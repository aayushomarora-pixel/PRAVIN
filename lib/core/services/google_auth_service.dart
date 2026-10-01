import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Google OAuth 2.0 authentication service
/// Handles sign-in and token management for Google Calendar/Tasks sync
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/tasks',
      'email',
      'profile',
    ],
  );

  GoogleSignInAccount? _currentUser;
  AuthClient? _authClient;

  /// Get current signed-in user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Sign in to Google
  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser == null) {
      return null;
    }

    final auth = await _currentUser!.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      return null;
    }

    final credentials = AccessCredentials(
      AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1))),
      auth.idToken,
      ['https://www.googleapis.com/auth/calendar', 'https://www.googleapis.com/auth/tasks'],
    );

    _authClient = authenticatedClient(http.Client(), credentials);
    return _currentUser;
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _authClient = null;
  }

  /// Get authenticated HTTP client
  AuthClient? get authClient => _authClient;

  /// Listen to sign-in changes
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _googleSignIn.onCurrentUserChanged;
}