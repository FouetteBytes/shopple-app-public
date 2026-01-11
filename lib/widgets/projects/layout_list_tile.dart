import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class LayoutListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final ValueNotifier<int> notifier;
  final int index;

  const LayoutListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.notifier,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Utils.screenWidth - 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryText, size: 30),
                AppSpaces.horizontalSpace20,
                Text(
                  title,
                  style: GoogleFonts.lato(
                    color: AppColors.primaryText,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: notifier,
              builder: (BuildContext context, _, __) {
                return Theme(
                  data: ThemeData(
                    //here change to your color
                    unselectedWidgetColor: AppColors.primaryText,
                  ),
                  child: Radio(
                    // overlayColor:  unselectedWi,
                    value: notifier.value,
                    // ignore: deprecated_member_use
                    groupValue: index,
                    // ignore: deprecated_member_use
                    onChanged: ((value) {
                      notifier.value = index;
                    }),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
