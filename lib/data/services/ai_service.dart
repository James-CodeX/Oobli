import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/ai_models.dart';
import '../models/category.dart';
import '../models/plan.dart';
import 'sms_parser.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService(ref.watch(functionsProvider)));

/// Result of AI categorisation for one transaction.
class AiCategory {
  const AiCategory({required this.category, required this.merchant, required this.confidence});

  final TxCategory category;
  final String merchant;
  final double confidence;
}

/// Client for the `oobli-ai` Appwrite Function, which holds the Gemini key
/// server-side. The app never talks to Gemini directly.
class AiService {
  AiService(this._functions);

  final Functions _functions;

  static const _unavailable =
      'Oobli could not reach the AI service right now. Please try again in a moment.';

  Future<Map<String, dynamic>> _call(String path, Map<String, dynamic> body) async {
    try {
      final execution = await _functions.createExecution(
        functionId: AppConfig.aiFunctionId,
        path: path,
        method: enums.ExecutionMethod.pOST,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = execution.responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(execution.responseBody) as Map<String, dynamic>;
      if (execution.responseStatusCode != 200) {
        final message = execution.responseStatusCode == 400
            ? decoded['error'] as String? ?? _unavailable
            : _unavailable;
        throw AppFailure(message, code: execution.responseStatusCode);
      }
      return decoded;
    } on FormatException catch (e) {
      throw AppFailure(_unavailable, cause: e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Categorises up to 60 transactions per call. Keys of [items] are opaque ids.
  Future<Map<String, AiCategory>> categorize(
    List<Map<String, dynamic>> items, {
    Map<String, TxCategory> rules = const {},
  }) async {
    final out = <String, AiCategory>{};
    final ruleList = rules.entries
        .take(40)
        .map((e) => {'merchant': e.key, 'category': e.value.key})
        .toList();
    for (var i = 0; i < items.length; i += 60) {
      final res = await _call('/categorize', {
        'items': items.sublist(i, (i + 60).clamp(0, items.length)),
        'rules': ruleList,
      });
      for (final r in (res['results'] as List? ?? []).cast<Map<String, dynamic>>()) {
        out[r['id'] as String] = AiCategory(
          category: TxCategory.fromKey(r['category'] as String?),
          merchant: r['merchant'] as String? ?? '',
          confidence: (r['confidence'] as num? ?? 0.5).toDouble(),
        );
      }
    }
    return out;
  }

  /// Extracts transactions from SMS the on-device parser could not handle
  /// (bank alerts, unusual M-Pesa formats). Returns raw maps keyed by SMS id.
  Future<Map<String, Map<String, dynamic>>> parseSms(List<SmsMessage> messages) async {
    final out = <String, Map<String, dynamic>>{};
    for (var i = 0; i < messages.length; i += 40) {
      final chunk = messages.sublist(i, (i + 40).clamp(0, messages.length));
      final res = await _call('/parse-sms', {
        'messages': [
          for (final m in chunk)
            {
              'id': m.id,
              'sender': m.sender,
              'body': m.body,
              'receivedAt': m.receivedAt.toIso8601String(),
            },
        ],
      });
      for (final t in (res['transactions'] as List? ?? []).cast<Map<String, dynamic>>()) {
        if (t['isTransaction'] == true) out[t['id'] as String] = t;
      }
    }
    return out;
  }

  Future<AiInsights> insights(Map<String, dynamic> stats) async =>
      AiInsights.fromJson(await _call('/insights', {'stats': stats}));

  Future<({String summary, List<PlanAllocation> allocations})> plan({
    required double income,
    required String goal,
    required String focus,
    required String month,
    required Map<String, dynamic> history,
  }) async {
    final res = await _call('/plan', {
      'income': income,
      'goal': goal,
      'focus': focus,
      'month': month,
      'history': history,
    });
    return (
      summary: res['summary'] as String? ?? '',
      allocations: (res['allocations'] as List)
          .map((a) => PlanAllocation.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<WrappedStory> wrapped(Map<String, dynamic> stats) async =>
      WrappedStory.fromJson(await _call('/wrapped', {'stats': stats}));

  Future<String> chat(List<ChatMessage> messages, Map<String, dynamic> context) async {
    final res = await _call('/chat', {
      'messages': messages.map((m) => m.toJson()).toList(),
      'context': context,
    });
    return res['reply'] as String? ?? '';
  }
}
