import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/onboarding/labelled_option.dart';

class ProjectDetailBottomSheet extends StatelessWidget {
  const ProjectDetailBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSpaces.verticalSpace10,
        AppSpaces.verticalSpace10,
        ListTile(
          title: Text(
            "PROJECT SETTINGS",
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppColors.primaryText30,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              LabelledOption(label: 'Share Project', icon: Icons.share),
              LabelledOption(
                label: 'Mark all completed',
                icon: Icons.check_circle,
              ),
              LabelledOption(
                label: 'Copy',
                icon: Icons.tag,
                link: "shopple.io/6734aw",
              ),
              LabelledOption(
                label: 'Duplicate Project',
                icon: Icons.fiber_smart_record,
              ),
              LabelledOption(
                label: 'Set Color',
                icon: Icons.color_lens,
                boxColor: "FFDE72",
              ),
              LabelledOption(
                label: 'Archive Project',
                icon: Icons.archive,
                color: HexColor.fromHex("C55FFF"),
              ),
              LabelledOption(
                label: 'Delect Project',
                icon: FeatherIcons.trash,
                color: HexColor.fromHex("FC958E"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
