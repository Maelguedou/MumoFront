import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/onboarding_model.dart';

class OnboardingController extends ChangeNotifier{
  final PageController pageController=PageController();
  int currentPage=0;

  void onPageChanged(int value){
    currentPage= value;
    notifyListeners();
  }

  // Logique du bouton Suivant / Commencer
  void handleNext(BuildContext context){
    if (currentPage == onboardingPages.length-1){
      context.go('/login');
    }else{
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  void handlePrevious(BuildContext context){
    if(currentPage > 0){
      pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }
}