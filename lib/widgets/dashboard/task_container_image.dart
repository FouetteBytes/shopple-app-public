import 'package:flutter/material.dart';

class TaskContainerImage extends StatelessWidget {
  final String imageUrl;
  final Color backgroundColor;
  const TaskContainerImage({
    super.key,
    required this.backgroundColor,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        color: backgroundColor,
      ),
      child: ClipRRect(
        child: Image(image: AssetImage(imageUrl), fit: BoxFit.scaleDown),
      ),
    );
  }
}
