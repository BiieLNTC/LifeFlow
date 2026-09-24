abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const authCallbackUrl = 'br.com.lifeflow://auth-callback';

  static String? get validationError {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      return 'Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY para iniciar o LifeFlow.';
    }

    final uri = Uri.tryParse(supabaseUrl);
    final isLocalHttp =
        uri?.scheme == 'http' &&
        const {'127.0.0.1', 'localhost', '10.0.2.2'}.contains(uri?.host);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !isLocalHttp)) {
      return 'SUPABASE_URL deve usar HTTPS ou um endereço local permitido.';
    }

    return null;
  }
}
