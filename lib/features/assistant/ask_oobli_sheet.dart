import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/ai_models.dart';
import '../../state/chat_controller.dart';
import '../../ui/widgets/choice_card.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';

Future<void> showAskOobli(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.92, child: AskOobliSheet()),
    );

/// The extended "Ask Oobli" pill button.
class AskOobliButton extends StatelessWidget {
  const AskOobliButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: () => showAskOobli(context),
      semanticLabel: 'Ask Oobli',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(99),
          boxShadow: Shadows.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: c.onPrimary, size: 24),
            const SizedBox(width: Sp.sm),
            Text('Ask Oobli', style: context.text.bodyLarge.copyWith(color: c.onPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class AskOobliSheet extends ConsumerStatefulWidget {
  const AskOobliSheet({super.key});

  @override
  ConsumerState<AskOobliSheet> createState() => _AskOobliSheetState();
}

class _AskOobliSheetState extends ConsumerState<AskOobliSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'Where did my money go this week?',
    'How can I save KES 5,000 this month?',
    'Am I on track with my plan?',
    'Which subscriptions should I cancel?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(chatControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final chat = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.sending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.medium, curve: Curves.easeOut);
          }
        });
      }
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
            child: Row(
              children: [
                const OobliMascot(size: 40, glow: false, mood: MascotMood.working),
                const SizedBox(width: Sp.md),
                Expanded(child: Text('Ask Oobli', style: t.headlineSmall)),
                if (chat.messages.isNotEmpty)
                  OobliIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'New chat',
                    color: c.secondaryText,
                    onPressed: () => ref.read(chatControllerProvider.notifier).clear(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: chat.messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(Sp.lg),
                    children: [
                      const SizedBox(height: Sp.lg),
                      const Center(child: OobliMascot(size: 96, mood: MascotMood.working, interactive: true)),
                      const SizedBox(height: Sp.lg),
                      Text(
                        "Hi! I know your M-Pesa story. Ask me anything about your money.",
                        textAlign: TextAlign.center,
                        style: t.bodyLarge.copyWith(color: c.secondaryText),
                      ),
                      const SizedBox(height: Sp.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: Sp.sm,
                        runSpacing: Sp.sm,
                        children: [
                          for (final s in _suggestions) PillChoice(label: s, selected: false, onTap: () => _send(s)),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(Sp.lg),
                    itemCount: chat.messages.length + (chat.sending ? 1 : 0),
                    itemBuilder: (context, i) => i == chat.messages.length
                        ? const _TypingBubble()
                        : _Bubble(message: chat.messages[i]),
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
              child: Text(chat.error!, style: t.bodySmall.copyWith(color: c.error)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      style: t.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Ask about your spending…',
                        hintStyle: t.bodyLarge.copyWith(color: c.hint),
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                        border: OutlineInputBorder(borderRadius: Rad.all(Rad.xl), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Pressable(
                    onTap: chat.sending ? null : () => _send(_input.text),
                    semanticLabel: 'Send',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_upward_rounded, color: c.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.fromUser;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.medium,
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: Sp.md),
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          decoration: BoxDecoration(
            color: mine ? c.primary : c.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(Rad.lg),
              topRight: const Radius.circular(Rad.lg),
              bottomLeft: Radius.circular(mine ? Rad.lg : Rad.xs),
              bottomRight: Radius.circular(mine ? Rad.xs : Rad.lg),
            ),
            border: mine ? null : Border.all(color: c.divider),
          ),
          child: Text(
            message.text,
            style: context.text.bodyMedium.copyWith(color: mine ? c.onPrimary : c.primaryText),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 14),
        decoration: BoxDecoration(color: c.surface, borderRadius: Rad.all(Rad.lg)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.secondaryText.withValues(
                      alpha: 0.3 + 0.7 * (((_c.value * 3 - i) % 3) < 1 ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
