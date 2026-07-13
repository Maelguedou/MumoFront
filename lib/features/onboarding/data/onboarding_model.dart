class OnboardingModel {
  final String title;
  final String description;
  final String image;
  
  OnboardingModel({
  required this.title,
  required this.description,
  required this.image
    });
}

final List<OnboardingModel> onboardingPages = [
  OnboardingModel(
    title: "Une gestion multi cabines",
    description: "Centraliser toutes vos cabines Mobile Money en un seul tableau de bord.Pilotez votre réseau d'agents avec clarté et efficacité.",
    image: "assets/boarding1.png",
  ),
  OnboardingModel(
    title: "Transactions en temps réel",
    description: "Suivez chaque dépôt, retrait et transfert à l'instant T.Votre solde global et vos statistiques toujours à portée",
    image: "assets/onboarding2.png",
  ),
  OnboardingModel(
    title: "Bâtissez une large communauté",
    description: "Démarrez gratuitement et boostez votre activité Mobile Money. La croissance commence ici.",
    image: "assets/onboarding3.png",
  ),
];