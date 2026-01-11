part of 'values.dart';

class ButtonStyles {
  static final ButtonStyle primaryButton = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.primaryGreen),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
        side: BorderSide(color: AppColors.primaryGreen),
      ),
    ),
  );

  static final ButtonStyle secondaryButton = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(AppColors.surface),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
        side: BorderSide(color: AppColors.inactive, width: 1),
      ),
    ),
  );

  // Legacy styles for backward compatibility
  static final ButtonStyle blueRounded = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.primaryGreen),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
        side: BorderSide(color: AppColors.primaryGreen),
      ),
    ),
  );

  static final ButtonStyle imageRounded = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(AppColors.surface),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
        side: BorderSide(color: AppColors.inactive, width: 1),
      ),
    ),
  );

  static final ButtonStyle whiteRounded = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(AppColors.surface),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
        side: BorderSide(color: AppColors.inactive, width: 1),
      ),
    ),
  );
}
