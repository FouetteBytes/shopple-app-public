import 'package:flutter/material.dart';

class OnboardingSlide {
  final String name;
  final String title;
  final String description;
  final Color color;

  OnboardingSlide({
    required this.name,
    required this.title,
    required this.description,
    required this.color,
  });
}

class OnboardingData {
  static List<OnboardingSlide> slides = [
    OnboardingSlide(
      name: 'Pisa',
      title: 'Shop, Without, Limits',
      description:
          'Discover endless possibilities with our smart shopping platform',
      color: Color(0xffdee5cf), // Matches original Pisa color
    ),
    OnboardingSlide(
      name: 'Budapest',
      title: 'Smart Decisions With AI',
      description: 'Let AI guide your shopping decisions for the best outcomes',
      color: Color(0xffdaf3f7), // Matches original Budapest color
    ),
    OnboardingSlide(
      name: 'London',
      title: 'Collaborate, Adjust, Efficiently',
      description: 'Work together seamlessly with friends and family',
      color: Color(0xfff9d9e2), // Matches original London color
    ),
  ];
}
