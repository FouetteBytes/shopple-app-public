part of 'values.dart';

class BoxDecorationStyles {
  static final BoxDecoration fadingGlory = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HexColor.fromHex("625B8B"), // subtle purple tint
        AppColors.surface,
        AppColors.background,
        AppColors.background,
      ],
    ),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
    //border: Border.all(color: Colors.red, width: 5)
  );

  static final BoxDecoration fadingInnerDecor = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
  );
}
