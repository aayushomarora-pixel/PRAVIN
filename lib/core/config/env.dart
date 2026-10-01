import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file.
/// Usage:
///   await Env.load();
///   final apiKey = Env.kimiApiKey;
class Env {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  /// Kimi K3 API key (required for AI features in Phase 3+)
  /// Source: Moonshot AI (Kimi) - OpenAI-compatible endpoint
  static String get kimiApiKey => dotenv.env['KIMI_API_KEY'] ?? '';

  /// Google OAuth 2.0 Client ID (required for Google Calendar/Tasks sync)
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  /// Google OAuth 2.0 Client Secret (required for server-side OAuth flow)
  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';

  /// Application name
  static String get appName => dotenv.env['APP_NAME'] ?? 'PRAVIN';

  /// Kimi K3 model name (OpenAI-compatible endpoint)
  static String get kimiModel => dotenv.env['KIMI_MODEL'] ?? 'kimi-k3-20260915-tiny';

  /// Check if required API keys are present
  static bool get hasRequiredKeys => kimiApiKey.isNotEmpty;

  /// Check if Google credentials are present
  static bool get hasGoogleCredentials =>
      googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;
}