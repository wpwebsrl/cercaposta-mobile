import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/api/services/billing_api.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import '../../shared/format.dart';
import '../../shared/widgets/snack.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  BillingOverview? _overview;
  List<PlanChangeSummary> _changes = const <PlanChangeSummary>[];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(billingApiProvider);
      final values = await Future.wait<Object>(<Future<Object>>[
        api.overview(),
        api.changes(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = values[0] as BillingOverview;
        _changes = values[1] as List<PlanChangeSummary>;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openWebBilling() async {
    final l = AppLocalizations.of(context)!;
    final origin = ref.read(activeServerProvider);
    if (origin == null) return;
    final opened = await launchUrl(
      Uri.parse('$origin/billing'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) showSnack(context, l.errorGeneric, error: true);
  }

  String _money(int cents, String currency, String locale) => NumberFormat.currency(
    locale: locale,
    name: currency,
  ).format(cents / 100);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final italian = Localizations.localeOf(context).languageCode == 'it';
    return Scaffold(
      appBar: AppBar(title: Text(l.billingTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(localizeApiError(l, _error!)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: Text(l.actionRetry)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _currentPlan(context, l, locale, italian),
                  if (_changes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Text(
                      l.billingPendingChanges,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._changes.map(
                      (change) => _changeCard(context, l, change, locale, italian),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _openWebBilling,
                    icon: const Icon(Icons.open_in_browser),
                    label: Text(l.billingManageInBrowser),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.billingExternalCheckoutHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _currentPlan(
    BuildContext context,
    AppLocalizations l,
    String locale,
    bool italian,
  ) {
    final overview = _overview!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: overview.hasSubscription
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.billingCurrentPlan, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    italian ? overview.planNameIt : overview.planNameEn,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _line(l.billingStatus, _subscriptionStatus(l, overview.status)),
                  _line(l.billingPaymentMethod, _providerLabel(l, overview.provider)),
                  _line(
                    l.billingRecurringPrice,
                    _money(overview.priceCents, overview.currency, locale),
                  ),
                  if (overview.periodEnd != null)
                    _line(
                      l.billingPeriodEnd,
                      formatDateShort(overview.periodEnd!, locale),
                    ),
                  if (overview.graceUntil != null)
                    _line(
                      l.billingGraceUntil,
                      formatDateShort(overview.graceUntil!, locale),
                      warning: true,
                    ),
                ],
              )
            : Text(l.billingNoPlan),
      ),
    );
  }

  Widget _changeCard(
    BuildContext context,
    AppLocalizations l,
    PlanChangeSummary change,
    String locale,
    bool italian,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            italian ? change.targetNameIt : change.targetNameEn,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _line(l.billingStatus, _changeStatus(l, change.status)),
          if (change.effectiveAt != null)
            _line(
              l.billingEffectiveAt,
              formatDateShort(change.effectiveAt!, locale),
            ),
          _line(
            l.billingAmountDue,
            _money(change.amountDueCents, change.currency, locale),
          ),
          if (change.graceUntil != null)
            _line(
              l.billingGraceUntil,
              formatDateShort(change.graceUntil!, locale),
              warning: true,
            ),
        ],
      ),
    ),
  );

  Widget _line(String label, String value, {bool warning = false}) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: warning ? Colors.orange.shade800 : null,
            ),
          ),
        ),
      ],
    ),
  );

  String _subscriptionStatus(AppLocalizations l, String value) => switch (value) {
    'active' => l.billingStatusActive,
    'free' => l.billingStatusFree,
    'past_due' => l.billingStatusPastDue,
    'suspended' => l.billingStatusSuspended,
    'canceled' => l.billingStatusCanceled,
    _ => value.replaceAll('_', ' '),
  };

  String _changeStatus(AppLocalizations l, String value) => switch (value) {
    'pending_acceptance' => l.billingChangePendingAcceptance,
    'pending_payment' => l.billingChangePendingPayment,
    'scheduled' => l.billingChangeScheduled,
    'processing' => l.billingChangeProcessing,
    'payment_failed_grace' => l.billingChangePaymentGrace,
    'canceling' => l.billingChangeCanceling,
    'canceled' => l.billingStatusCanceled,
    _ => value.replaceAll('_', ' '),
  };

  String _providerLabel(AppLocalizations l, String value) => switch (value) {
    'free' => l.billingStatusFree,
    'manual' => l.billingProviderManual,
    'stripe' => 'Stripe',
    'paypal' => 'PayPal',
    _ => value,
  };
}
