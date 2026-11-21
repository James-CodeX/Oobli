import 'dart:async';
import 'dart:io';

/// Makes every `HttpClient` in the app (including the Appwrite SDK's) connect
/// IPv4-first with per-address fallback.
///
/// Why: Appwrite Cloud is served over both IPv4 and IPv6. Some mobile
/// networks hand phones an IPv6 path that connects but then drops during the
/// TLS handshake ("Software caused connection abort", errno 103). Browsers
/// silently fall back to IPv4; Dart's default connector does not. Here each
/// resolved address is tried in turn (IPv4 first) and an address only "wins"
/// once its TLS handshake has completed.
class ResilientHttpOverrides extends HttpOverrides {
  ResilientHttpOverrides({
    this.perAddressTimeout = const Duration(seconds: 10),
  });

  final Duration perAddressTimeout;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (proxyHost != null && proxyPort != null) {
        // Proxied requests keep the default behaviour (HttpClient tunnels TLS).
        return Socket.startConnect(proxyHost, proxyPort);
      }
      return _connect(uri, context);
    };
    return client;
  }

  Future<ConnectionTask<Socket>> _connect(Uri uri, SecurityContext? context) async {
    final secure = uri.isScheme('https');
    final port = uri.hasPort ? uri.port : (secure ? 443 : 80);
    final addresses = await orderedAddresses(uri.host);

    ConnectionTask<Socket>? current;
    var cancelled = false;

    Future<Socket> attempt() async {
      Object? lastError;
      for (final address in addresses) {
        if (cancelled) break;
        try {
          final ConnectionTask<Socket> task = secure
              // An address from lookup() keeps its hostname, so SNI and
              // certificate verification still use "sgp.cloud.appwrite.io".
              ? await SecureSocket.startConnect(address, port, context: context)
              : await Socket.startConnect(address, port);
          current = task;
          return await task.socket.timeout(perAddressTimeout, onTimeout: () {
            task.cancel();
            throw TimeoutException('Connecting to ${address.address} timed out', perAddressTimeout);
          });
        } catch (e) {
          lastError = e;
        }
      }
      throw lastError ?? SocketException('No addresses found for ${uri.host}');
    }

    return ConnectionTask.fromSocket(attempt(), () {
      cancelled = true;
      current?.cancel();
    });
  }

  /// Resolves [host] with IPv4 addresses ahead of IPv6 ones.
  static Future<List<InternetAddress>> orderedAddresses(String host) async {
    final literal = InternetAddress.tryParse(host);
    if (literal != null) return [literal];
    final all = await InternetAddress.lookup(host);
    return [
      ...all.where((a) => a.type == InternetAddressType.IPv4),
      ...all.where((a) => a.type != InternetAddressType.IPv4),
    ];
  }
}
