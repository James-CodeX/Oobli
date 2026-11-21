import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../data/models/ai_models.dart';
import '../data/services/ai_service.dart';
import 'auth_controller.dart';
import 'goals_controller.dart';
import 'plan_controller.dart';
import 'transactions_controller.dart';

@immutable
class ChatState {
  const ChatState({this.messages = const [], this.sending = false, this.error});

  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending, String? error}) =>
      ChatState(messages: messages ?? this.messages, sending: sending ?? this.sending, error: error);
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

/// "Ask Oobli": a short conversation grounded in the user's own numbers.
class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    ref.watch(currentUserIdProvider);
    return const ChatState();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    final history = [...state.messages, ChatMessage(fromUser: true, text: trimmed)];
    state = state.copyWith(messages: history, sending: true);
    try {
      final context = ref.read(statsProvider).aiSummary(
            primaryGoal: ref.read(primaryGoalProvider),
            plan: ref.read(planProvider).value,
            firstName: ref.read(authControllerProvider).value?.firstName,
          );
      final recent = history.length > 20 ? history.sublist(history.length - 20) : history;
      final reply = await ref.read(aiServiceProvider).chat(recent, context);
      state = state.copyWith(
        messages: [...history, ChatMessage(fromUser: false, text: reply)],
        sending: false,
      );
    } catch (e) {
      state = state.copyWith(sending: false, error: AppFailure.from(e).message);
    }
  }

  void clear() => state = const ChatState();
}
