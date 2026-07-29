import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';

/// Remote provider for authentication using Supabase, Google and Apple.
class AuthRemoteProvider {
  final SupabaseClient _client;
  final GoogleSignIn? _googleSignIn;

  /// Creates a provider with the given [client] and optional [googleSignIn].
  AuthRemoteProvider({
    required SupabaseClient client,
    GoogleSignIn? googleSignIn,
  })  : _client = client,
        _googleSignIn = googleSignIn;

  /// Identifier of the currently authenticated user, or `null`.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Checks whether a user session exists.
  Future<bool> checkAuth() async {
    return _client.auth.currentSession != null;
  }

  /// Signs in with platform identity provider and returns the user.
  Future<UserModel> signIn() async {
    if (Platform.isIOS) {
      return _signInWithApple();
    }
    return _signInWithGoogle();
  }

  /// Attempts to sign in silently using a previously authorized platform
  /// account. On iOS this may present the Apple ID sheet.
  Future<UserModel> signInSilently() async {
    if (Platform.isIOS) {
      return _signInWithApple();
    }
    if (Platform.isAndroid) {
      return _signInWithGoogleSilently();
    }
    throw Exception(RequestConstants.platformNotSupported);
  }

  Future<UserModel> _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = _googleSignIn ?? GoogleSignIn.instance;
    final GoogleSignInAccount account = await googleSignIn.authenticate();
    return _signInWithGoogleAccount(account);
  }

  Future<UserModel> _signInWithGoogleSilently() async {
    final GoogleSignIn googleSignIn = _googleSignIn ?? GoogleSignIn.instance;
    final Future<GoogleSignInAccount?>? attempt =
        googleSignIn.attemptLightweightAuthentication();
    final GoogleSignInAccount? account = attempt == null ? null : await attempt;
    if (account == null) {
      throw Exception(RequestConstants.silentSignInNotAvailable);
    }
    return _signInWithGoogleAccount(account);
  }

  Future<UserModel> _signInWithGoogleAccount(
      GoogleSignInAccount account) async {
    final GoogleSignInAuthentication auth = account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null) {
      throw Exception(RequestConstants.googleIdTokenNull);
    }

    final AuthResponse response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final User? user = response.user;
    if (user == null) {
      throw Exception(RequestConstants.googleSignInFailed);
    }

    return _toUserModel(user, account.displayName ?? 'User');
  }

  Future<UserModel> _signInWithApple() async {
    final String rawNonce = _generateNonce();
    final String hashedNonce = _sha256(rawNonce);

    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final String? idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception(RequestConstants.appleIdTokenNull);
    }

    final AuthResponse response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final User? user = response.user;
    if (user == null) {
      throw Exception(RequestConstants.appleSignInFailed);
    }

    final String name = credential.givenName ?? 'User';
    return _toUserModel(user, name);
  }

  UserModel _toUserModel(User user, String name) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: name,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  String _generateNonce() {
    final Random secureRandom = Random.secure();
    final List<int> randomBytes =
        List<int>.generate(32, (_) => secureRandom.nextInt(256));
    return base64UrlEncode(randomBytes);
  }

  String _sha256(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }
}
