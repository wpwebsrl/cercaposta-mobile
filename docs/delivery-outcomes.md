# Esiti dei solleciti

Il client mantiene un UUID per contenuto confermato e lo riusa nei retry HTTP. Il server
 registra sending/sent/failed/unknown in modo durevole e impedisce nuovi invii mentre un
 esito e incerto. Esiti degli invii nella preparazione del sollecito consente di consultare
 il riferimento, verificare il servizio di posta e registrare accettazione o mancato invio.
 La conferma non invia messaggi e non riarma l'invio automatico. Verificare che il tentativo
 non sia piu in esecuzione prima di confermare il mancato invio. Il destinatario rimane
 sempre risolto dal server dall'attesa; il client non lo accetta come parametro di invio.

Test: delivery_history_test.dart (UUID/retry, contratto API, conferma esplicita,
 impossibilita di risolvere un tentativo in corso), piu regressioni lista/notifiche.
 Nessuna consegna reale o prova su dispositivo fisico eseguita.
