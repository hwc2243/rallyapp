import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'models/app_session.dart';
import 'models/organization_dto.dart';
import 'models/organization_membership_dto.dart';
import 'models/rally_dto.dart';
import 'models/rally_setup_selection.dart';
import 'models/route_dto.dart';
import 'models/user_dto.dart';
import 'providers/external_api_client.dart';
import 'providers/me_provider.dart';
import 'screens/main_screen.dart';
import 'screens/organization_selection_screen.dart';
import 'services/session_lock_controller.dart';
import 'widgets/session_lock_overlay.dart';

const _keycloakIssuer = String.fromEnvironment(
  'KEYCLOAK_ISSUER',
  defaultValue: 'https://login.connors.ddns.net/realms/rallymaster',
);
const _keycloakClientId = String.fromEnvironment(
  'KEYCLOAK_CLIENT_ID',
  defaultValue: 'rallymaster-mobile',
);
const _redirectUrl = 'com.rallyapp.rallymaster:/oauthredirect';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RallyMasterApp());
}

class RallyMasterApp extends StatefulWidget {
  const RallyMasterApp({super.key});

  @override
  State<RallyMasterApp> createState() => _RallyMasterAppState();
}

class _RallyMasterAppState extends State<RallyMasterApp> {
  late final SessionLockController _sessionLock = SessionLockController(
    authenticate: () => LocalAuthentication().authenticate(
      localizedReason: 'Unlock RallyMaster',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    ),
  );

  @override
  void dispose() {
    _sessionLock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RallyMaster',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffe56a24)),
      useMaterial3: true,
    ),
    builder: (context, child) => SessionLockOverlay(
      controller: _sessionLock,
      child: child ?? const SizedBox.shrink(),
    ),
    home: AuthenticationGate(onOrganizationSelected: _sessionLock.activate),
  );
}

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key, required this.onOrganizationSelected});

  final VoidCallback onOrganizationSelected;

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  final _authentication = AuthenticationService();
  String? _error;
  bool _busy = true;
  Future<void>? _authenticationAttempt;

  @override
  void initState() {
    super.initState();
    _authenticateAndLoadSession();
  }

  Future<void> _authenticateAndLoadSession() {
    return _authenticationAttempt ??= _authenticateAndLoadSessionInternal()
        .whenComplete(() => _authenticationAttempt = null);
  }

  Future<void> _authenticateAndLoadSessionInternal() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _authentication.restoreSession()) {
        await _authentication.signIn();
      }

      final apiClient = ExternalApiClient(
        accessToken: _authentication.getAccessToken,
      );
      final meProvider = MeProvider(apiClient: apiClient);
      final user = await meProvider.me();
      final organizations = await meProvider.mine();

      if (!mounted) return;
      final selection = await Navigator.of(context).push<RallySetupSelection>(
        MaterialPageRoute<RallySetupSelection>(
          builder: (_) => OrganizationSelectionScreen(
            user: user,
            organizations: organizations,
            accessToken: _authentication.getAccessToken,
          ),
        ),
      );
      if (selection != null && mounted) {
        widget.onOrganizationSelected();
        _openMainScreen(
          user,
          selection.organization,
          selection.organizationMembership,
          selection.rally,
          selection.route,
        );
      }
    } on FlutterAppAuthUserCancelledException {
      if (mounted) {
        setState(() => _error = 'Sign in was cancelled.');
      }
    } on BiometricAuthenticationCancelledException {
      if (mounted) {
        setState(() => _error = 'RallyMaster was not unlocked.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to start RallyMaster: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openMainScreen(
    UserDto user,
    OrganizationDto organization,
    OrganizationMembershipDto organizationMembership,
    RallyDto rally,
    RouteDto route,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainScreen(
          session: AppSession(
            user: user,
            organization: organization,
            organizationMembership: organizationMembership,
            rally: rally,
            route: route,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route, size: 72),
              const SizedBox(height: 16),
              Text(
                'RallyMaster',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (_busy)
                const CircularProgressIndicator()
              else ...[
                Text(
                  _error ?? 'Sign in to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _authenticateAndLoadSession,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthenticationService {
  // Versioned to avoid reusing tokens created with per-Keychain-operation
  // biometric access controls. Those legacy items can prompt repeatedly.
  static const _refreshTokenKey = 'keycloak_refresh_token_v2';
  final _appAuth = FlutterAppAuth();
  final _localAuthentication = LocalAuthentication();
  String? _accessToken;
  String? _refreshToken;
  Future<void>? _refreshAttempt;
  final _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  Future<bool> restoreSession() async {
    if (!await _storage.containsKey(key: _refreshTokenKey)) return false;

    final unlocked = await _localAuthentication.authenticate(
      localizedReason: 'Unlock RallyMaster',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!unlocked) {
      throw BiometricAuthenticationCancelledException();
    }

    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;
    _refreshToken = refreshToken;
    await _refreshAccessToken();
    return true;
  }

  Future<void> signIn() async {
    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _keycloakClientId,
        _redirectUrl,
        issuer: _keycloakIssuer,
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
    final refreshToken = response.refreshToken;
    if (refreshToken == null || response.accessToken == null) {
      throw StateError(
        'Keycloak did not return a refresh token. Enable offline_access for the mobile client.',
      );
    }
    _accessToken = response.accessToken;
    _refreshToken = refreshToken;
    await _storeRefreshToken(refreshToken);
  }

  Future<String> getAccessToken() async {
    var token = _accessToken;
    if (token == null) {
      throw StateError('No authenticated API session is available.');
    }
    if (_isExpiring(token)) {
      await _refreshAccessToken();
      token = _accessToken;
      if (token == null) {
        throw StateError('Unable to refresh the authenticated API session.');
      }
    }
    return token;
  }

  /// Refreshes once for all concurrent API calls. The refresh token is already
  /// loaded into memory after the startup biometric unlock, so this does not
  /// prompt the user again while the app is active.
  Future<void> _refreshAccessToken() {
    final inFlight = _refreshAttempt;
    if (inFlight != null) return inFlight;
    return _refreshAttempt = _refreshAccessTokenInternal().whenComplete(
      () => _refreshAttempt = null,
    );
  }

  Future<void> _refreshAccessTokenInternal() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      throw StateError('No refresh token is available for this session.');
    }
    final response = await _appAuth.token(
      TokenRequest(
        _keycloakClientId,
        _redirectUrl,
        issuer: _keycloakIssuer,
        refreshToken: refreshToken,
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
    final accessToken = response.accessToken;
    if (accessToken == null) {
      throw StateError('Keycloak did not return an access token on refresh.');
    }
    _accessToken = accessToken;
    _refreshToken = response.refreshToken ?? refreshToken;
    await _storeRefreshToken(_refreshToken!);
  }

  /// Refresh a minute before expiry so the request itself never starts with a
  /// token that Keycloak could reject in flight.
  bool _isExpiring(String token) {
    try {
      final sections = token.split('.');
      if (sections.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(sections[1]))),
      ) as Map<String, dynamic>;
      final expiration = payload['exp'];
      if (expiration is! num) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiration.toInt() * 1000,
      );
      return !expiresAt.isAfter(
        DateTime.now().add(const Duration(minutes: 1)),
      );
    } catch (_) {
      return true;
    }
  }

  Future<void> _storeRefreshToken(String value) =>
      _storage.write(key: _refreshTokenKey, value: value);
}

class BiometricAuthenticationCancelledException implements Exception {}
