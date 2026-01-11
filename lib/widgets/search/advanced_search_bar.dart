import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/ml/teachable_machine_service.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class AdvancedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final Function(String) onSuggestionTapped;
  final VoidCallback? onFilterTapped;
  final bool showFilterButton;
  final String placeholder;

  const AdvancedSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.onSuggestionTapped,
    this.onFilterTapped,
    this.showFilterButton = false,
    this.placeholder = 'Search products...',
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _suggestionsAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _suggestionsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AdvancedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestions.isNotEmpty && oldWidget.suggestions.isEmpty) {
      _animationController.forward();
    } else if (widget.suggestions.isEmpty && oldWidget.suggestions.isNotEmpty) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input with Liquid Glass styling
        LiquidTextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          hintText: widget.placeholder,
          borderRadius: 16,
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Icon(
              Icons.search,
              color: Colors.white70,
              size: 20,
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera Button
              IconButton(
                onPressed: _handleCameraSearch,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),

              // Clear Button
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    widget.focusNode.unfocus();
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),

              // Filter Button
              if (widget.showFilterButton && widget.onFilterTapped != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: widget.onFilterTapped,
                    icon: Icon(
                      Icons.filter_list,
                      color: AppColors.primaryAccentColor,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Suggestions Dropdown
        SizeTransition(
          sizeFactor: _suggestionsAnimation,
          child: widget.suggestions.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inactive),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      color: AppColors.inactive,
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = widget.suggestions[index];
                      return ListTile(
                        leading: Icon(
                          Icons.search,
                          color: AppColors.primaryText70,
                          size: 18,
                        ),
                        title: Text(
                          suggestion,
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText,
                            fontSize: 14,
                          ),
                        ),
                        dense: true,
                        onTap: () => widget.onSuggestionTapped(suggestion),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _handleCameraSearch() async {
    final service = TeachableMachineService();

    // Load model if not initialized
    if (!service.isModelLoaded) {
      // TODO: Configure production model URLs
      const modelUrl =
          'https://storage.googleapis.com/tm-model/YOUR_MODEL_ID/model.tflite';
      const labelsUrl =
          'https://storage.googleapis.com/tm-model/YOUR_MODEL_ID/labels.txt';

      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading AI model...')),
          );
        }

        await service.loadModel(modelUrl: modelUrl, labelsUrl: labelsUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Model not configured. Please set up Teachable Machine model.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Analyzing image...')));
        }

        final File imageFile = File(image.path);
        final String? label = await service.classifyImage(imageFile);

        if (label != null && mounted) {
          widget.controller.text = label;
          // Parent widget observes controller changes
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not recognize item.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
