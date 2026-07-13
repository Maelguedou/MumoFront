/// Message SMS normalise pour eviter que le reste de l'application depende
/// directement du modele fourni par un package SMS concret.
class IncomingSmsMessage {
  const IncomingSmsMessage({
    required this.body,
    required this.sender,
    required this.receivedAt,
  });

  final String? body;
  final String sender;
  final DateTime receivedAt;
}
