import 'package:dio/dio.dart';

import '../json.dart';

class BillingOverview {
  const BillingOverview({
    required this.hasSubscription,
    required this.planNameIt,
    required this.planNameEn,
    required this.status,
    required this.provider,
    required this.interval,
    required this.currency,
    required this.priceCents,
    required this.periodEnd,
    required this.graceUntil,
  });

  factory BillingOverview.fromJson(Map<String, dynamic> json) {
    final raw = json['subscription'];
    if (raw is! Map) {
      return const BillingOverview(
        hasSubscription: false,
        planNameIt: '',
        planNameEn: '',
        status: '',
        provider: '',
        interval: '',
        currency: 'EUR',
        priceCents: 0,
        periodEnd: null,
        graceUntil: null,
      );
    }
    final subscription = raw.cast<String, dynamic>();
    DateTime? date(String key) => DateTime.tryParse(
      subscription[key] is String ? subscription[key] as String : '',
    );
    return BillingOverview(
      hasSubscription: true,
      planNameIt: subscription['plan_name_it'] as String? ?? '',
      planNameEn: subscription['plan_name_en'] as String? ?? '',
      status: subscription['status'] as String? ?? '',
      provider: subscription['provider'] as String? ?? '',
      interval: subscription['billing_interval'] as String? ?? '',
      currency: subscription['currency'] as String? ?? 'EUR',
      priceCents: (subscription['price_cents'] as num?)?.toInt() ?? 0,
      periodEnd: date('period_end'),
      graceUntil: date('grace_until'),
    );
  }

  final bool hasSubscription;
  final String planNameIt;
  final String planNameEn;
  final String status;
  final String provider;
  final String interval;
  final String currency;
  final int priceCents;
  final DateTime? periodEnd;
  final DateTime? graceUntil;
}

class PlanChangeSummary {
  const PlanChangeSummary({
    required this.id,
    required this.targetNameIt,
    required this.targetNameEn,
    required this.status,
    required this.currency,
    required this.amountDueCents,
    required this.effectiveAt,
    required this.graceUntil,
  });

  factory PlanChangeSummary.fromJson(Map<String, dynamic> json) {
    final target = mapOf(json['target']);
    final quote = mapOf(json['quote']);
    DateTime? date(String key) =>
        DateTime.tryParse(json[key] is String ? json[key] as String : '');
    return PlanChangeSummary(
      id: json['id'] as String? ?? '',
      targetNameIt: target['name_it'] as String? ?? '',
      targetNameEn: target['name_en'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currency: json['currency'] as String? ?? 'EUR',
      amountDueCents: (quote['amount_due_cents'] as num?)?.toInt() ?? 0,
      effectiveAt: date('effective_at'),
      graceUntil: date('grace_until'),
    );
  }

  final String id;
  final String targetNameIt;
  final String targetNameEn;
  final String status;
  final String currency;
  final int amountDueCents;
  final DateTime? effectiveAt;
  final DateTime? graceUntil;
}

class BillingApi {
  BillingApi(this._dio);

  final Dio _dio;

  Future<BillingOverview> overview() async {
    final response = await _dio.get<dynamic>('/me/billing');
    return BillingOverview.fromJson(mapOf(response.data));
  }

  Future<List<PlanChangeSummary>> changes() async {
    final response = await _dio.get<dynamic>('/me/billing/plan-changes');
    final raw = response.data;
    if (raw is! List) return const <PlanChangeSummary>[];
    return raw
        .whereType<Map>()
        .map((item) => PlanChangeSummary.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
