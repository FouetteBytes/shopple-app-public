import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/rect_primary_button.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import '../../widgets/pickers/icon_picker_widget.dart';
import '../../widgets/pickers/color_picker_widget.dart';
import '../../services/shopping_lists/shopping_list_service.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  String _iconId = 'shopping_cart';
  // stored with leading '#'
  String _colorHex = '#4CAF50';
  bool _submitting = false;
  final ValueNotifier<int> _layoutTrigger = ValueNotifier(0);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ShoppingListService.createShoppingList(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconId: _iconId,
        colorTheme: _colorHex,
        budgetLimit: double.tryParse(_budgetController.text.trim()) ?? 0.0,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  IconData _iconFromId(String id) {
    return IconPickerWidget.shoppingListIcons[id] ?? Icons.shopping_cart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          // header blur
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 20),
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Create List',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 110,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpaces.verticalSpace20,
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                HexColor.fromHex(
                                  _colorHex.replaceFirst('#', ''),
                                ),
                                darken(
                                  HexColor.fromHex(
                                    _colorHex.replaceFirst('#', ''),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Icon(
                            _iconFromId(_iconId),
                            color: Colors.white,
                          ),
                        ),
                        AppSpaces.horizontalSpace20,
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'List Name ...',
                              hintStyle: GoogleFonts.lato(
                                color: HexColor.fromHex('626677'),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: HexColor.fromHex('343840'),
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: HexColor.fromHex(
                                    _colorHex.replaceFirst('#', ''),
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    AppSpaces.verticalSpace20,
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: GoogleFonts.lato(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        hintStyle: GoogleFonts.lato(
                          color: HexColor.fromHex('626677'),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: HexColor.fromHex('343840'),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: HexColor.fromHex(
                              _colorHex.replaceFirst('#', ''),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppSpaces.verticalSpace20,
                    Text(
                      'BUDGET (OPTIONAL)',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpaces.verticalSpace10,
                    Container(
                      decoration: BoxDecoration(
                        color: HexColor.fromHex('181A1F'),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HexColor.fromHex('343840')),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.lato(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter budget limit (Rs)',
                          hintStyle: GoogleFonts.lato(
                            color: HexColor.fromHex('626677'),
                          ),
                          icon: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: HexColor.fromHex(
                              _colorHex.replaceFirst('#', ''),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppSpaces.verticalSpace20,
                    Text(
                      'SELECT LAYOUT',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpaces.verticalSpace10,
                    Container(
                      width: double.infinity,
                      height: 60,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor.fromHex("181A1F"),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RectPrimaryButtonWithIcon(
                              buttonText: 'Grid',
                              icon: Icons.grid_view,
                              itemIndex: 0,
                              notifier: _layoutTrigger,
                            ),
                          ),
                          Expanded(
                            child: RectPrimaryButtonWithIcon(
                              buttonText: 'List',
                              icon: Icons.view_agenda,
                              itemIndex: 1,
                              notifier: _layoutTrigger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpaces.verticalSpace20,
                    Text(
                      'COLOR THEME',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpaces.verticalSpace10,
                    ColorPickerWidget(
                      selectedColor: _colorHex,
                      onColorSelected: (hex) => setState(() => _colorHex = hex),
                    ),
                    AppSpaces.verticalSpace20,
                    Text(
                      'ICON',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpaces.verticalSpace10,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HexColor.fromHex('181A1F'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconPickerWidget(
                        selectedIconId: _iconId,
                        onIconSelected: (id) => setState(() => _iconId = id),
                      ),
                    ),
                    AppSpaces.verticalSpace40,
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor.fromHex(
                            _colorHex.replaceFirst('#', ''),
                          ),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create List',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    AppSpaces.verticalSpace20,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
