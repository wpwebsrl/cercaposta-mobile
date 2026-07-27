import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../shared/models/chat.dart';
import 'citation_fold.dart';

/// Le citazioni di un turno, pieghevoli — con la variante del telefono.
///
/// Regola comune alle tre superfici: il turno che si sta leggendo resta aperto (per un turno
/// d'elenco la lista È la risposta), i turni precedenti si chiudono in una riga sola col
/// conteggio e i primi mittenti. In più, qui, l'elenco aperto si ferma a [kCitationsMaxVisible]
/// con «mostra tutte»: su uno schermo di telefono trenta righe sono quattro schermate.
class CitationBlock extends StatefulWidget {
  const CitationBlock({
    required this.citations,
    required this.isLastAssistant,
    super.key,
  });

  final List<Citation> citations;
  final bool isLastAssistant;

  @override
  State<CitationBlock> createState() => _CitationBlockState();
}

class _CitationBlockState extends State<CitationBlock> {
  /// La scelta esplicita dell'utente: quando c'è, vince sul comportamento automatico.
  bool? _manual;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final all = widget.citations;
    final folded = citationsFolded(
      all.length,
      widget.isLastAssistant,
      manual: _manual,
    );
    final foldable = all.length >= kCitationsFoldMin;
    final visible = folded
        ? const <Citation>[]
        : all.take(citationsVisible(all.length, showAll: _showAll)).toList();
    final hidden = all.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (foldable)
          InkWell(
            onTap: () => setState(() => _manual = !folded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    folded ? Icons.chevron_right : Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      folded
                          ? '${l.chatCitationsCount(all.length)} · '
                                '${_who(l, all)}'
                          : l.chatCitationsCount(all.length),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (visible.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: visible
                .map(
                  // Letta e non usata: stessa scheda, stesso tocco, solo smorzata. Toglierla
                  // farebbe «saltare» il suo numero, che nella risposta invece si legge.
                  (c) => Opacity(
                    opacity: c.used ? 1 : 0.55,
                    child: ActionChip(
                      label: Text(
                        '[${c.n}] ${c.subject.isEmpty ? c.fromLabel : c.subject}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/message/${c.id}'),
                    ),
                  ),
                )
                .toList(),
          ),
        // La legenda solo quando c'è qualcosa da spiegare: una scheda grigia senza spiegazione
        // è un enigma, la stessa spiegata è un'informazione.
        if (visible.any((c) => !c.used))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l.chatCitationsUnusedLegend,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ),
        // Aperto ma troncato: dire quante ne restano, e offrirle. Un elenco tagliato in
        // silenzio si legge come un elenco completo.
        if (!folded && hidden > 0)
          TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: Text(l.chatCitationsShowAll(hidden)),
          ),
      ],
    );
  }

  String _who(AppLocalizations l, List<Citation> all) {
    final names = citationNames(all);
    final others = all.length - names.length;
    final who = names.join(', ');
    return others > 0 ? '$who ${l.chatCitationsOthers(others)}' : who;
  }
}
