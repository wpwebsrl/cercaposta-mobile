import 'dart:math' as math;

import '../../shared/models/chat.dart';

/// Quante citazioni servono perché valga la pena piegare l'elenco: sotto questa soglia
/// nascondere quattro righe non guadagna spazio e costa un tocco.
const int kCitationsFoldMin = 6;

/// Quante se ne mostrano al massimo con l'elenco aperto **sul telefono**.
///
/// È la differenza voluta rispetto a web e desktop (docs/mobile-apps.md): lì l'elenco lungo
/// resta intero perché per un turno d'elenco la lista È la risposta, e uno schermo grande la
/// regge. Qui trenta righe sono quattro schermate: non una risposta leggibile, un muro. Quindi
/// anche il turno che si sta leggendo si ferma a dieci, con «mostra tutte».
const int kCitationsMaxVisible = 10;

/// L'elenco di questo turno parte piegato?
///
/// «Il passato si piega, il presente no»: l'ultimo turno dell'assistente resta aperto — per un
/// turno d'elenco la lista È la risposta — mentre quelli precedenti diventano una riga sola.
/// [manual] è la scelta esplicita dell'utente e vince sempre.
bool citationsFolded(int count, bool isLast, {bool? manual}) {
  if (manual != null) return manual;
  return !isLast && count >= kCitationsFoldMin;
}

/// Quante righe disegnare davvero.
int citationsVisible(int count, {required bool showAll}) =>
    showAll ? count : math.min(count, kCitationsMaxVisible);

/// Fino a [limit] mittenti distinti, per la riga chiusa: «30 email» e basta costringerebbe ad
/// aprirla solo per capire se è quella giusta.
List<String> citationNames(List<Citation> citations, {int limit = 2}) {
  final names = <String>[];
  for (final c in citations) {
    final name = c.fromLabel.trim();
    if (name.isNotEmpty && !names.contains(name)) names.add(name);
    if (names.length >= limit) break;
  }
  return names;
}
