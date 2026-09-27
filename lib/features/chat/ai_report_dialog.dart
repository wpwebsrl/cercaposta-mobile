import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

Future<void> showAiReportDialog(
  BuildContext context,
  WidgetRef ref,
  String messageId,
) async {
  final rootContext = context;
  final l = AppLocalizations.of(context)!;
  final comment = TextEditingController();
  var reason = 'misleading';
  var sending = false;
  await showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.aiReportTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l.aiReportIntro),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: InputDecoration(labelText: l.aiReportReason),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'misleading',
                    child: Text(l.aiReportReasonMisleading),
                  ),
                  DropdownMenuItem(
                    value: 'harmful',
                    child: Text(l.aiReportReasonHarmful),
                  ),
                  DropdownMenuItem(
                    value: 'illegal',
                    child: Text(l.aiReportReasonIllegal),
                  ),
                  DropdownMenuItem(
                    value: 'privacy',
                    child: Text(l.aiReportReasonPrivacy),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(l.aiReportReasonOther),
                  ),
                ],
                onChanged: sending
                    ? null
                    : (value) => setState(() => reason = value ?? reason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comment,
                enabled: !sending,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l.aiReportComment,
                  hintText: l.aiReportCommentHint,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: sending ? null : () => Navigator.of(context).pop(),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: sending
                ? null
                : () async {
                    setState(() => sending = true);
                    try {
                      final created = await ref
                          .read(aiReportApiProvider)
                          .create(
                            messageId: messageId,
                            reason: reason,
                            comment: comment.text,
                          );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      showSnack(
                        rootContext,
                        created ? l.aiReportSent : l.aiReportAlreadySent,
                      );
                    } on Object catch (error) {
                      if (!context.mounted) return;
                      setState(() => sending = false);
                      showSnack(
                        context,
                        localizeApiError(l, error),
                        error: true,
                      );
                    }
                  },
            child: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.aiReportSend),
          ),
        ],
      ),
    ),
  );
  comment.dispose();
}
