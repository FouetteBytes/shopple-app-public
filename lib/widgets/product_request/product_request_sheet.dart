import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product_request/product_request_api.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/widgets/product_request/product_search_sheet.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:google_fonts/google_fonts.dart';

/// Intelligent product request form that adapts based on request type
/// Syncs directly to Firebase - no backend API calls
class ProductRequestSheet extends StatefulWidget {
  final String? initialRequestType;
  final Product? preTaggedProduct;
  final ProductRequest? existingRequest;

  const ProductRequestSheet({
    super.key,
    this.initialRequestType,
    this.preTaggedProduct,
    this.existingRequest,
  });

  @override
  State<ProductRequestSheet> createState() => _ProductRequestSheetState();
}

class _ProductRequestSheetState extends State<ProductRequestSheet> {
  late RequestType _selectedType;
  late bool _showTypeSelector;

  bool get _isEditing => widget.existingRequest != null;

  @override
  void initState() {
    super.initState();

    // Initialize based on parameters
    if (widget.existingRequest != null) {
      _selectedType = widget.existingRequest!.requestType;
      _showTypeSelector = false;
    } else if (widget.initialRequestType != null) {
      // Map string to RequestType
      _selectedType = _mapStringToRequestType(widget.initialRequestType!);
      _showTypeSelector = false; // Skip type selector if type is provided
    } else {
      _selectedType = RequestType.newProduct;
      _showTypeSelector = true;
    }
  }

  RequestType _mapStringToRequestType(String type) {
    switch (type) {
      case 'Report Error':
        return RequestType.reportError;
      case 'Update Information':
        return RequestType.updateProduct;
      case 'Price Update':
        return RequestType.priceUpdate;
      case 'New Product':
        return RequestType.newProduct;
      default:
        return RequestType.newProduct;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          if (_showTypeSelector)
            _RequestTypeSelector(
              onTypeSelected: (type) {
                setState(() {
                  _selectedType = type;
                  _showTypeSelector = false;
                });
              },
            )
          else
            Flexible(
              child: _RequestForm(
                requestType: _selectedType,
                preTaggedProduct: widget.preTaggedProduct,
                existingRequest: widget.existingRequest,
                isEditing: _isEditing,
                onBack: _isEditing
                    ? null
                    : () {
                        setState(() {
                          _showTypeSelector = true;
                        });
                      },
              ),
            ),
        ],
      ),
    );
  }
}

/// Request type selector - first step
class _RequestTypeSelector extends StatelessWidget {
  final Function(RequestType) onTypeSelected;

  const _RequestTypeSelector({required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What can we help with?',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Choose the type of request',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...RequestType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TypeOptionCard(
                type: type,
                onTap: () => onTypeSelected(type),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Type option card
class _TypeOptionCard extends StatelessWidget {
  final RequestType type;
  final VoidCallback onTap;

  const _TypeOptionCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type.icon, color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

/// Main request form - adapts based on request type
class _RequestForm extends StatefulWidget {
  final RequestType requestType;
  final VoidCallback? onBack;
  final Product? preTaggedProduct;
  final ProductRequest? existingRequest;
  final bool isEditing;

  const _RequestForm({
    required this.requestType,
    this.onBack,
    this.preTaggedProduct,
    this.existingRequest,
    this.isEditing = false,
  });

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _storeController = TextEditingController();
  final _branchController = TextEditingController();
  final _descriptionController = TextEditingController();

  // For corrections
  final _incorrectNameController = TextEditingController();
  final _correctNameController = TextEditingController();
  final _incorrectPriceController = TextEditingController();
  final _correctPriceController = TextEditingController();
  final _incorrectSizeController = TextEditingController();
  final _correctSizeController = TextEditingController();
  final List<String> _existingPhotoUrls = [];
  final _incorrectBrandController = TextEditingController();
  final _correctBrandController = TextEditingController();

  Priority _priority = Priority.normal;
  final List<File> _selectedPhotos = [];
  final List<IssueType> _selectedIssues = [];
  bool _isSubmitting = false;

  // For tagging existing product (corrections)
  String? _taggedProductId;
  String? _taggedProductName;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final existing = widget.existingRequest;
    if (existing != null) {
      _productNameController.text = existing.productName;
      _brandController.text = existing.brand ?? '';
      _sizeController.text = existing.size ?? '';
      _storeController.text = existing.store ?? '';
      _branchController.text = existing.storeLocation?.branch ?? '';
      _descriptionController.text = existing.description ?? '';
      _priority = existing.priority;
      _taggedProductId = existing.taggedProductId;
      _taggedProductName = existing.taggedProductId != null
          ? existing.productName
          : existing.productName;
      if (existing.issue != null) {
        final issue = existing.issue!;
        _selectedIssues.addAll(issue.issueTypes);
        _incorrectNameController.text = issue.incorrectName ?? '';
        _correctNameController.text = issue.correctName ?? '';
        _incorrectPriceController.text = issue.incorrectPrice ?? '';
        _correctPriceController.text = issue.correctPrice ?? '';
        _incorrectSizeController.text = issue.incorrectSize ?? '';
        _correctSizeController.text = issue.correctSize ?? '';
        _incorrectBrandController.text = issue.incorrectBrand ?? '';
        _correctBrandController.text = issue.correctBrand ?? '';
      }
      _existingPhotoUrls.addAll(existing.photoUrls);
    }

    // Pre-fill form if product is tagged
    if (widget.preTaggedProduct != null) {
      final product = widget.preTaggedProduct!;
      _taggedProductId = product.id;
      _taggedProductName = product.name;

      // Pre-fill incorrect values for correction types
      if (widget.requestType == RequestType.reportError ||
          widget.requestType == RequestType.updateProduct ||
          widget.requestType == RequestType.priceUpdate) {
        _incorrectNameController.text = product.name;
        _incorrectBrandController.text = product.brandName;
        _incorrectSizeController.text = '${product.size} ${product.sizeUnit}';
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _storeController.dispose();
    _branchController.dispose();
    _descriptionController.dispose();
    _incorrectNameController.dispose();
    _correctNameController.dispose();
    _incorrectPriceController.dispose();
    _correctPriceController.dispose();
    _incorrectSizeController.dispose();
    _correctSizeController.dispose();
    _incorrectBrandController.dispose();
    _correctBrandController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remainingSlots = _remainingPhotoSlots();
    if (remainingSlots <= 0) {
      _showPhotoLimitSnackbar();
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1280,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (var i = 0; i < images.length && i < remainingSlots; i++) {
            _selectedPhotos.add(File(images[i].path));
          }
        });
      }
    } catch (e) {
      AppLogger.e('Error picking images', error: e);
    }
  }

  Future<void> _takePicture() async {
    if (_remainingPhotoSlots() <= 0) {
      _showPhotoLimitSnackbar();
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedPhotos.add(File(photo.path));
        });
      }
    } catch (e) {
      AppLogger.e('Error taking picture', error: e);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _toggleIssue(IssueType issue) {
    setState(() {
      if (_selectedIssues.contains(issue)) {
        _selectedIssues.remove(issue);
      } else {
        _selectedIssues.add(issue);
      }
    });
  }

  Future<void> _searchAndTagProduct() async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductSearchSheet(),
    );

    if (result != null) {
      setState(() {
        _taggedProductId = result.id;
        _taggedProductName = result.name;
        // Pre-fill product name if empty (for convenience)
        if (_productNameController.text.isEmpty) {
          _productNameController.text = result.name;
        }
        if (_brandController.text.isEmpty && result.brandName.isNotEmpty) {
          _brandController.text = result.brandName;
        }
        if (_sizeController.text.isEmpty) {
          _sizeController.text = '${result.size} ${result.sizeUnit}';
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation based on the request type
    if (widget.requestType == RequestType.reportError ||
        widget.requestType == RequestType.updateProduct) {
      if (_taggedProductId == null) {
        LiquidSnack.show(
          title: 'Product Required',
          message: 'Please tag the product you want to report/update',
          accentColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
      if (_selectedIssues.isEmpty) {
        LiquidSnack.show(
          title: 'Issue Required',
          message: 'Please select at least one issue type',
          accentColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userController = Get.find<UserController>();
      final submittedBy = SubmittedBy(
        userId: userController.user?.uid,
        displayName: userController.userName,
        email: userController.userEmail,
      );

      final existing = widget.existingRequest;
      final effectiveSubmittedBy = widget.isEditing
          ? existing?.submittedBy ?? submittedBy
          : submittedBy;

      StoreLocation? storeLocation;
      if (_branchController.text.isNotEmpty) {
        storeLocation = StoreLocation(branch: _branchController.text);
      }

      ProductIssue? issue;
      if (_selectedIssues.isNotEmpty) {
        issue = ProductIssue(
          issueTypes: _selectedIssues,
          incorrectName: _incorrectNameController.text.trim().isEmpty
              ? null
              : _incorrectNameController.text.trim(),
          correctName: _correctNameController.text.trim().isEmpty
              ? null
              : _correctNameController.text.trim(),
          incorrectPrice: _incorrectPriceController.text.trim().isEmpty
              ? null
              : _incorrectPriceController.text.trim(),
          correctPrice: _correctPriceController.text.trim().isEmpty
              ? null
              : _correctPriceController.text.trim(),
          incorrectSize: _incorrectSizeController.text.trim().isEmpty
              ? null
              : _incorrectSizeController.text.trim(),
          correctSize: _correctSizeController.text.trim().isEmpty
              ? null
              : _correctSizeController.text.trim(),
          incorrectBrand: _incorrectBrandController.text.trim().isEmpty
              ? null
              : _incorrectBrandController.text.trim(),
          correctBrand: _correctBrandController.text.trim().isEmpty
              ? null
              : _correctBrandController.text.trim(),
          additionalDetails: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }

      final request = ProductRequest(
        id: existing?.id,
        requestType: widget.requestType,
        productName: _productNameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        size: _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim(),
        store: _storeController.text.trim().isEmpty
            ? null
            : _storeController.text.trim(),
        storeLocation: storeLocation,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        status: existing?.status ?? RequestStatus.pending,
        submittedBy: effectiveSubmittedBy,
        submissionSource: existing?.submissionSource ?? 'mobile',
        photoUrls: widget.isEditing
            ? List<String>.from(_existingPhotoUrls)
            : const [],
        taggedProductId: _taggedProductId,
        issue: issue,
        labels: existing?.labels ?? const [],
        createdAt: existing?.createdAt,
        updatedAt: existing?.updatedAt,
        adminNotes: existing?.adminNotes ?? const [],
        categoryHint: existing?.categoryHint,
      );

      if (widget.isEditing) {
        await ProductRequestService.updateRequest(
          request,
          newPhotos: _selectedPhotos.isEmpty ? null : _selectedPhotos,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        LiquidSnack.show(
          title: 'Request Updated',
          message: 'We saved your changes and will review them shortly.',
          accentColor: AppColors.primaryGreen,
          icon: Icons.check_circle_outline,
        );
      } else {
        final result = await ProductRequestService.submitRequest(
          request,
          photos: _selectedPhotos.isEmpty ? null : _selectedPhotos,
        );

        // Success!
        if (!mounted) return;
        Get.back(); // Close form
        _showSuccessDialog(result);
      }
    } catch (e) {
      AppLogger.e('Error submitting product request', error: e);
      LiquidSnack.show(
        title: 'Submission Failed',
        message: e.toString().replaceAll('Exception: ', ''),
        accentColor: Colors.red,
        icon: Icons.error_outline,
        durationSeconds: 5,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(ProductRequest result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LiquidGlass(
          enableBlur: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Request Submitted!',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getSuccessMessage(),
                style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSuccessMessage() {
    switch (widget.requestType) {
      case RequestType.newProduct:
        return 'We\'ll review your product request and add it to our catalogue soon.';
      case RequestType.updateProduct:
        return 'Product information will be updated after review.';
      case RequestType.reportError:
        return 'Thank you for helping us maintain accurate information!';
      case RequestType.priceUpdate:
        return 'Price will be verified and updated shortly.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBackButton = widget.onBack != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Row(
              children: [
                GestureDetector(
                  onTap: showBackButton
                      ? widget.onBack
                      : () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      showBackButton ? Icons.arrow_back : Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreen.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.requestType.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.requestType.displayName,
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.requestType.description,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Conditional fields based on request type
            if (widget.requestType == RequestType.reportError ||
                widget.requestType == RequestType.updateProduct) ...[
              _buildLabel('Tagged Product *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _searchAndTagProduct,
                child: LiquidGlass(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _taggedProductName ?? 'Search and tag product',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: _taggedProductName != null
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                      ),
                      if (_taggedProductName != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _taggedProductId = null;
                              _taggedProductName = null;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Issue Type *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IssueType.values.map((issue) {
                  final isSelected = _selectedIssues.contains(issue);
                  return GestureDetector(
                    onTap: () => _toggleIssue(issue),
                    child: LiquidGlass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      gradientColors: isSelected
                          ? [
                              AppColors.primaryGreen.withValues(alpha: 0.3),
                              AppColors.primaryGreen.withValues(alpha: 0.15),
                            ]
                          : null,
                      borderColor: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.5)
                          : null,
                      child: Text(
                        issue.displayName,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Show correction fields based on selected issues
              if (_selectedIssues.contains(IssueType.incorrectName)) ...[
                _buildCorrectionFields(
                  'Product Name',
                  _incorrectNameController,
                  _correctNameController,
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedIssues.contains(IssueType.incorrectPrice)) ...[
                _buildCorrectionFields(
                  'Price',
                  _incorrectPriceController,
                  _correctPriceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedIssues.contains(IssueType.incorrectSize)) ...[
                _buildCorrectionFields(
                  'Size',
                  _incorrectSizeController,
                  _correctSizeController,
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedIssues.contains(IssueType.incorrectBrand)) ...[
                _buildCorrectionFields(
                  'Brand',
                  _incorrectBrandController,
                  _correctBrandController,
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Fields for new product
            if (widget.requestType == RequestType.newProduct) ...[
              _buildLabel('Product Name *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _productNameController,
                hint: 'e.g., Organic Coconut Milk',
                icon: Icons.shopping_bag_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Brand'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _brandController,
                          hint: 'e.g., Anchor',
                          icon: Icons.business_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Size'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _sizeController,
                          hint: 'e.g., 400ml',
                          icon: Icons.straighten_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Store'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _storeController,
                hint: 'e.g., Keells, Cargills',
                icon: Icons.store_outlined,
              ),
              const SizedBox(height: 16),

              _buildLabel('Branch'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _branchController,
                hint: 'e.g., Union Place',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
            ],

            // Priority
            _buildLabel('Priority'),
            const SizedBox(height: 8),
            Row(
              children: Priority.values.map((priority) {
                final isSelected = _priority == priority;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _priority = priority;
                        });
                      },
                      child: LiquidGlass(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        gradientColors: isSelected
                            ? [
                                AppColors.primaryGreen.withValues(alpha: 0.3),
                                AppColors.primaryGreen.withValues(alpha: 0.15),
                              ]
                            : null,
                        borderColor: isSelected
                            ? AppColors.primaryGreen.withValues(alpha: 0.5)
                            : null,
                        child: Text(
                          priority.displayName,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Description
            _buildLabel('Additional Details'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Any additional information',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Photos
            _buildLabel('Photos (Up to 5)'),
            const SizedBox(height: 8),
            if (widget.isEditing && _existingPhotoUrls.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingPhotoUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _existingPhotoUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedPhotos.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedPhotos[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    onTap: _pickImages,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Camera',
                    icon: Icons.camera_alt_outlined,
                    onTap: _takePicture,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isEditing
                                ? Icons.save_outlined
                                : Icons.send_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isEditing
                                ? 'Save Changes'
                                : 'Submit Request',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  int _remainingPhotoSlots() {
    const maxPhotos = 5;
    final remaining =
        maxPhotos - (_existingPhotoUrls.length + _selectedPhotos.length);
    return remaining > 0 ? remaining : 0;
  }

  void _showPhotoLimitSnackbar() {
    LiquidSnack.show(
      title: 'Maximum Reached',
      message: 'You can only upload up to 5 photos per request',
      accentColor: Colors.orange,
      icon: Icons.photo_library_outlined,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.lato(fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lato(fontSize: 14, color: Colors.white38),
          prefixIcon: Icon(icon, size: 20, color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCorrectionFields(
    String label,
    TextEditingController incorrectController,
    TextEditingController correctController, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('$label Correction'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current (Incorrect)',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTextField(
                    controller: incorrectController,
                    hint: 'Current value',
                    icon: Icons.close,
                    keyboardType: keyboardType,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 20, color: Colors.white38),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Correct Value',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.primaryGreen.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTextField(
                    controller: correctController,
                    hint: 'Correct value',
                    icon: Icons.check,
                    keyboardType: keyboardType,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
