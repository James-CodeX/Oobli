import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../state/auth_controller.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/tiles.dart';

/// Email + password sign up / log in (Appwrite Account).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startWithLogin = false});

  final bool startWithLogin;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _login = widget.startWithLogin;
  bool _busy = false;
  String? _error;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_login) {
        await auth.login(email: _email.text, password: _password.text);
      } else {
        await auth.register(name: _name.text, email: _email.text, password: _password.text);
      }
      // The router redirects to onboarding or home once the session exists.
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OobliIconButton(
                  icon: Icons.close_rounded,
                  color: c.secondaryText,
                  tooltip: 'Close',
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.welcome),
                ),
              ),
              const SizedBox(height: Sp.md),
              Center(child: OobliMascot(size: 96, mood: _login ? MascotMood.joy : MascotMood.happy)),
              const SizedBox(height: Sp.lg),
              OobliSaysCard(
                centered: true,
                message: _login
                    ? 'Welcome back! Log in to see what your money did while you were away.'
                    : "Let's create your account so your plans and goals follow you everywhere.",
                messageStyle: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Sp.xl),
              AnimatedSize(
                duration: Motion.medium,
                curve: Curves.easeOutCubic,
                child: _login
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: Sp.md),
                        child: OobliTextField(
                          label: 'Your name',
                          hint: 'Jared Waweru',
                          icon: Icons.person_rounded,
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (v) =>
                              !_login && (v == null || v.trim().length < 2) ? 'Tell Oobli your name' : null,
                        ),
                      ),
              ),
              OobliTextField(
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.mail_rounded,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) => _emailPattern.hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: Sp.md),
              OobliTextField(
                label: 'Password',
                hint: _login ? 'Your password' : 'At least 8 characters',
                icon: Icons.lock_rounded,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: [_login ? AutofillHints.password : AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').length < 8 ? 'Use at least 8 characters' : null,
              ),
              AnimatedSwitcher(
                duration: Motion.medium,
                child: _error == null
                    ? const SizedBox(height: Sp.lg)
                    : Padding(
                        key: ValueKey(_error),
                        padding: const EdgeInsets.symmetric(vertical: Sp.md),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: c.error, size: 20),
                            const SizedBox(width: Sp.sm),
                            Expanded(child: Text(_error!, style: t.bodySmall.copyWith(color: c.error))),
                          ],
                        ),
                      ),
              ),
              OobliButton(
                label: _login ? 'Log In' : 'Create Account',
                fullWidth: true,
                loading: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: Sp.md),
              OobliButton(
                label: _login ? 'New here? Create an account' : 'I already have an account',
                variant: OobliButtonVariant.ghost,
                size: OobliButtonSize.medium,
                fullWidth: true,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _login = !_login;
                          _error = null;
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
