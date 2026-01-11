import 'package:flutter/material.dart';

/// Product request model for Firebase Firestore
/// Syncs directly to Firestore, admin board reads from same database
class ProductRequest {
  final String? id;
  final RequestType requestType; // NEW: Type of request
  final String productName;
  final String? brand;
  final String? size;
  final String? categoryHint;
  final String? store;
  final StoreLocation? storeLocation;
  final String? description;
  final Priority priority;
  final RequestStatus status;
  final SubmittedBy? submittedBy;
  final String submissionSource;
  final List<String> photoUrls; // Firebase Storage URLs
  final String?
  taggedProductId; // For corrections - reference to existing product
  final ProductIssue? issue; // NEW: What's wrong with existing product
  final List<String> labels;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AdminNote> adminNotes;

  ProductRequest({
    this.id,
    this.requestType = RequestType.newProduct,
    required this.productName,
    this.brand,
    this.size,
    this.categoryHint,
    this.store,
    this.storeLocation,
    this.description,
    this.priority = Priority.normal,
    this.status = RequestStatus.pending,
    this.submittedBy,
    this.submissionSource = 'mobile',
    this.photoUrls = const [],
    this.taggedProductId,
    this.issue,
    this.labels = const [],
    this.createdAt,
    this.updatedAt,
    this.adminNotes = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'requestType': requestType.name,
      'productName': productName,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (size != null && size!.isNotEmpty) 'size': size,
      if (categoryHint != null && categoryHint!.isNotEmpty)
        'categoryHint': categoryHint,
      if (store != null && store!.isNotEmpty) 'store': store,
      if (storeLocation != null) 'storeLocation': storeLocation!.toJson(),
      if (description != null && description!.isNotEmpty)
        'description': description,
      'priority': priority.name,
      'status': status.name,
      if (submittedBy != null) 'submittedBy': submittedBy!.toJson(),
      'submissionSource': submissionSource,
      'photoUrls': photoUrls,
      if (taggedProductId != null) 'taggedProductId': taggedProductId,
      if (issue != null) 'issue': issue!.toJson(),
      'labels': labels,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  factory ProductRequest.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ProductRequest(
      id: docId,
      requestType: RequestType.values.firstWhere(
        (e) => e.name == data['requestType'],
        orElse: () => RequestType.newProduct,
      ),
      productName: data['productName'] as String,
      brand: data['brand'] as String?,
      size: data['size'] as String?,
      categoryHint: data['categoryHint'] as String?,
      store: data['store'] as String?,
      storeLocation: data['storeLocation'] != null
          ? StoreLocation.fromJson(data['storeLocation'])
          : null,
      description: data['description'] as String?,
      priority: Priority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => Priority.normal,
      ),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      submittedBy: data['submittedBy'] != null
          ? SubmittedBy.fromJson(data['submittedBy'])
          : null,
      submissionSource: data['submissionSource'] as String? ?? 'mobile',
      photoUrls: (data['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      taggedProductId: data['taggedProductId'] as String?,
      issue: data['issue'] != null
          ? ProductIssue.fromJson(data['issue'])
          : null,
      labels: (data['labels'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
      adminNotes: (data['adminNotes'] as List<dynamic>? ?? const [])
          .map(
            (note) =>
                AdminNote.fromJson(Map<String, dynamic>.from(note as Map)),
          )
          .toList(growable: false),
    );
  }
}

/// Store location details
class StoreLocation {
  final String? city;
  final String? branch;
  final String? aisle;
  final String? shelf;

  StoreLocation({this.city, this.branch, this.aisle, this.shelf});

  Map<String, dynamic> toJson() {
    return {
      if (city != null) 'city': city,
      if (branch != null) 'branch': branch,
      if (aisle != null) 'aisle': aisle,
      if (shelf != null) 'shelf': shelf,
    };
  }

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      city: json['city'] as String?,
      branch: json['branch'] as String?,
      aisle: json['aisle'] as String?,
      shelf: json['shelf'] as String?,
    );
  }
}

/// Submitter information
class SubmittedBy {
  final String? userId;
  final String? displayName;
  final String? email;
  final String? phone;

  SubmittedBy({this.userId, this.displayName, this.email, this.phone});

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'id': userId,
      if (displayName != null) 'name': displayName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  factory SubmittedBy.fromJson(Map<String, dynamic> json) {
    return SubmittedBy(
      userId: json['id'] as String?,
      displayName: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

/// Type of product request
enum RequestType {
  newProduct, // Request to add a new product to catalogue
  updateProduct, // Request to update existing product info
  reportError, // Report incorrect information (price, name, size)
  priceUpdate; // Specifically for price corrections

  String get displayName {
    switch (this) {
      case RequestType.newProduct:
        return 'New Product Request';
      case RequestType.updateProduct:
        return 'Update Product';
      case RequestType.reportError:
        return 'Report Error';
      case RequestType.priceUpdate:
        return 'Price Update';
    }
  }

  String get description {
    switch (this) {
      case RequestType.newProduct:
        return 'Product not in catalogue';
      case RequestType.updateProduct:
        return 'Update product details';
      case RequestType.reportError:
        return 'Incorrect information';
      case RequestType.priceUpdate:
        return 'Price needs correction';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestType.newProduct:
        return Icons.add_shopping_cart;
      case RequestType.updateProduct:
        return Icons.edit_outlined;
      case RequestType.reportError:
        return Icons.error_outline;
      case RequestType.priceUpdate:
        return Icons.attach_money_outlined;
    }
  }
}

/// Issue with existing product
class ProductIssue {
  final List<IssueType> issueTypes;
  final String? incorrectName;
  final String? correctName;
  final String? incorrectPrice;
  final String? correctPrice;
  final String? incorrectSize;
  final String? correctSize;
  final String? incorrectBrand;
  final String? correctBrand;
  final String? additionalDetails;

  ProductIssue({
    required this.issueTypes,
    this.incorrectName,
    this.correctName,
    this.incorrectPrice,
    this.correctPrice,
    this.incorrectSize,
    this.correctSize,
    this.incorrectBrand,
    this.correctBrand,
    this.additionalDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'issueTypes': issueTypes.map((e) => e.name).toList(),
      if (incorrectName != null) 'incorrectName': incorrectName,
      if (correctName != null) 'correctName': correctName,
      if (incorrectPrice != null) 'incorrectPrice': incorrectPrice,
      if (correctPrice != null) 'correctPrice': correctPrice,
      if (incorrectSize != null) 'incorrectSize': incorrectSize,
      if (correctSize != null) 'correctSize': correctSize,
      if (incorrectBrand != null) 'incorrectBrand': incorrectBrand,
      if (correctBrand != null) 'correctBrand': correctBrand,
      if (additionalDetails != null) 'additionalDetails': additionalDetails,
    };
  }

  factory ProductIssue.fromJson(Map<String, dynamic> json) {
    return ProductIssue(
      issueTypes: (json['issueTypes'] as List<dynamic>)
          .map((e) => IssueType.values.firstWhere((t) => t.name == e))
          .toList(),
      incorrectName: json['incorrectName'] as String?,
      correctName: json['correctName'] as String?,
      incorrectPrice: json['incorrectPrice'] as String?,
      correctPrice: json['correctPrice'] as String?,
      incorrectSize: json['incorrectSize'] as String?,
      correctSize: json['correctSize'] as String?,
      incorrectBrand: json['incorrectBrand'] as String?,
      correctBrand: json['correctBrand'] as String?,
      additionalDetails: json['additionalDetails'] as String?,
    );
  }
}

/// Types of issues with products
enum IssueType {
  incorrectName,
  incorrectPrice,
  incorrectSize,
  incorrectBrand,
  incorrectImage,
  other;

  String get displayName {
    switch (this) {
      case IssueType.incorrectName:
        return 'Wrong Name';
      case IssueType.incorrectPrice:
        return 'Wrong Price';
      case IssueType.incorrectSize:
        return 'Wrong Size';
      case IssueType.incorrectBrand:
        return 'Wrong Brand';
      case IssueType.incorrectImage:
        return 'Wrong Image';
      case IssueType.other:
        return 'Other Issue';
    }
  }
}

/// Request priority levels
enum Priority {
  low,
  normal,
  high;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
    }
  }
}

/// Request status
enum RequestStatus {
  pending,
  inReview,
  approved,
  completed,
  rejected;

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.inReview:
        return 'In Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
}

class AdminNote {
  final String id;
  final String? authorId;
  final String? authorName;
  final String note;
  final bool isPrivate;
  final DateTime? createdAt;

  const AdminNote({
    required this.id,
    this.authorId,
    this.authorName,
    required this.note,
    this.isPrivate = false,
    this.createdAt,
  });

  factory AdminNote.fromJson(Map<String, dynamic> json) {
    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      try {
        // Handles Firestore Timestamp with toDate()
        final toDate = value as dynamic;
        return toDate.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return AdminNote(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString(),
      authorName: json['authorName']?.toString(),
      note: json['note']?.toString() ?? '',
      isPrivate: json['visibility']?.toString() == 'internal',
      createdAt: toDate(json['createdAt']),
    );
  }
}
