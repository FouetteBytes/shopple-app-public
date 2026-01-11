import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/values/values.dart';

class AddItemForm extends StatelessWidget {
  final ListDetailController controller;
  final GlobalKey<FormState> formKey;

  const AddItemForm({
    super.key,
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Form(
        key: formKey,
        child: Row(
          children: [
            Expanded(
              child: _modernField(
                controller: controller.itemNameController,
                hint: 'Add item (e.g. 2x milk 500)',
                onChanged: (_) {},
                validator: (v) {
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            _MiniStepper(controller: controller),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: _modernField(
                controller: controller.priceController,
                hint: 'Price',
                keyboard: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.itemNameController,
              builder: (context, value, child) {
                final isTextEmpty = value.text.trim().isEmpty;
                return _AddButton(
                  disabled: isTextEmpty || controller.adding,
                  loading: controller.adding,
                  onPressed: controller.addItem,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.lato(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: HexColor.fromHex('1E2026'),
        hintStyle: GoogleFonts.lato(
          color: Colors.white30,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryAccentColor, width: 1.4),
        ),
      ),
    );
  }
}

class _MiniStepper extends StatefulWidget {
  final ListDetailController controller;

  const _MiniStepper({required this.controller});

  @override
  State<_MiniStepper> createState() => _MiniStepperState();
}

class _MiniStepperState extends State<_MiniStepper> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryAccentColor.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccentColor.withValues(alpha: .5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleBtn(Icons.remove, () {
            final v = int.tryParse(widget.controller.quantityController.text.trim()) ?? 1;
            if (v > 1) {
              widget.controller.quantityController.text = (v - 1).toString();
              setState(() {});
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              widget.controller.quantityController.text,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _circleBtn(Icons.add, () {
            final v = int.tryParse(widget.controller.quantityController.text.trim()) ?? 1;
            widget.controller.quantityController.text = (v + 1).toString();
            setState(() {});
          }),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryAccentColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool disabled;
  final bool loading;
  final VoidCallback onPressed;

  const _AddButton({
    required this.disabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: loading || disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccentColor,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
}
