class Failure {
  // Erreur normalisee a travers toute l'application.
  // message est ce que tu affiches a l'utilisateur.
  final String message;
  // statusCode est optionnel, pratique pour debug ou affichage avance.
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}