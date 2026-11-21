import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../state/auth_controller.dart';
import '../../ui/widgets/feedback.dart';

/// Shown while the session is restored; the router moves on automatically.
/// It mirrors the native launch screen (same background and logo size per
/// theme) so the hand-off from Android's splash is seamless.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  /// Matches the logo size the native splash renders (180dp).
  static const logoSize = 180.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: auth.hasError && !auth.hasValue
          ? SafeArea(
              child: Center(
                child: ErrorRetry(error: auth.error!, onRetry: () => ref.invalidate(authControllerProvider)),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.asset('assets/branding/logo.png', width: logoSize, height: logoSize, semanticLabel: 'Oobli'),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + Sp.xxl,
                  child: const Center(child: _LoadingDots()),
                ),
              ],
            ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: ((_c.value * 3 - i) % 3) < 1 ? 1 : 0.3),
              ),
            ),
        ],
      ),
    );
  }
}
