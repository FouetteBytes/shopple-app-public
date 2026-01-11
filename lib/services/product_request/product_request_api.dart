import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shopple/models/product_request_model.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Firebase service for product requests
/// Writes directly to Firestore and Storage - Admin board reads from same database
class ProductRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'product_requests';
  static const String _storageFolder = 'product-requests';
  static const Uuid _uuid = Uuid();

  /// Submit a product request directly to Firebase
  /// Photos are uploaded to Firebase Storage first, then URLs saved to Firestore
  static Future<ProductRequest> submitRequest(
    ProductRequest request, {
    List<File>? photos,
  }) async {
    try {
      AppLogger.d(
        'Submitting ${request.requestType.displayName}: ${request.productName}',
      );

      // 1. Upload photos to Firebase Storage if provided
      List<String> photoUrls = [];
      if (photos != null && photos.isNotEmpty) {
        if (photos.length > 5) {
          throw Exception('Maximum 5 photos allowed');
        }
        photoUrls = await _uploadPhotos(photos);
        AppLogger.d('Uploaded ${photoUrls.length} photos to Storage');
      }

      // 2. Create request with photo URLs
      final requestWithPhotos = ProductRequest(
        requestType: request.requestType,
        productName: request.productName,
        brand: request.brand,
        size: request.size,
        categoryHint: request.categoryHint,
        store: request.store,
        storeLocation: request.storeLocation,
        description: request.description,
        priority: request.priority,
        status: RequestStatus.pending,
        submittedBy: request.submittedBy,
        submissionSource: 'mobile',
        photoUrls: photoUrls,
        taggedProductId: request.taggedProductId,
        issue: request.issue,
        labels: request.labels,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save to Firestore
      final docRef = await _firestore
          .collection(_collectionName)
          .add(requestWithPhotos.toFirestore());

      AppLogger.d('Product request saved to Firestore: ${docRef.id}');

      // 4. Return request with ID
      return ProductRequest(
        id: docRef.id,
        requestType: requestWithPhotos.requestType,
        productName: requestWithPhotos.productName,
        brand: requestWithPhotos.brand,
        size: requestWithPhotos.size,
        categoryHint: requestWithPhotos.categoryHint,
        store: requestWithPhotos.store,
        storeLocation: requestWithPhotos.storeLocation,
        description: requestWithPhotos.description,
        priority: requestWithPhotos.priority,
        status: requestWithPhotos.status,
        submittedBy: requestWithPhotos.submittedBy,
        submissionSource: requestWithPhotos.submissionSource,
        photoUrls: requestWithPhotos.photoUrls,
        taggedProductId: requestWithPhotos.taggedProductId,
        issue: requestWithPhotos.issue,
        labels: requestWithPhotos.labels,
        createdAt: requestWithPhotos.createdAt,
        updatedAt: requestWithPhotos.updatedAt,
      );
    } catch (e) {
      AppLogger.e('Error submitting product request to Firebase', error: e);
      rethrow;
    }
  }

  /// Update an existing product request. Only pending requests can be edited by shoppers.
  static Future<ProductRequest> updateRequest(
    ProductRequest request, {
    List<File>? newPhotos,
  }) async {
    if (request.id == null) {
      throw Exception('Cannot update product request without an ID');
    }

    final docRef = _firestore.collection(_collectionName).doc(request.id);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Product request ${request.id} does not exist');
    }

    final current = ProductRequest.fromFirestore(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
    if (current.status != RequestStatus.pending) {
      throw Exception('Only pending requests can be updated');
    }

    var updatedPhotoUrls = List<String>.from(request.photoUrls);
    if (newPhotos != null && newPhotos.isNotEmpty) {
      final uploaded = await _uploadPhotos(newPhotos);
      updatedPhotoUrls = [...updatedPhotoUrls, ...uploaded];
    }

    final updateData = <String, dynamic>{
      'requestType': request.requestType.name,
      'productName': request.productName,
      'priority': request.priority.name,
      'photoUrls': updatedPhotoUrls,
      'labels': request.labels,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    void setString(String key, String? value) {
      updateData[key] = (value != null && value.isNotEmpty)
          ? value
          : FieldValue.delete();
    }

    setString('brand', request.brand);
    setString('size', request.size);
    setString('categoryHint', request.categoryHint);
    setString('store', request.store);
    setString('description', request.description);
    setString('taggedProductId', request.taggedProductId);

    if (request.storeLocation != null) {
      updateData['storeLocation'] = request.storeLocation!.toJson();
    } else {
      updateData['storeLocation'] = FieldValue.delete();
    }

    if (request.issue != null) {
      updateData['issue'] = request.issue!.toJson();
    } else {
      updateData['issue'] = FieldValue.delete();
    }

    await docRef.update(updateData);

    final updatedSnapshot = await docRef.get();
    return ProductRequest.fromFirestore(
      updatedSnapshot.data() as Map<String, dynamic>,
      updatedSnapshot.id,
    );
  }

  /// Upload photos to Firebase Storage
  static Future<List<String>> _uploadPhotos(List<File> photos) async {
    final List<String> uploadedUrls = [];
    final requestId = _uuid.v4(); // Unique ID for this request's photos

    for (int i = 0; i < photos.length; i++) {
      try {
        final file = photos[i];
        final fileName =
            'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child(
          '$_storageFolder/$requestId/$fileName',
        );

        // Upload file
        final uploadTask = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Get download URL
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);

        AppLogger.d('Uploaded photo ${i + 1}/${photos.length}: $fileName');
      } catch (e) {
        AppLogger.e('Error uploading photo ${i + 1}', error: e);
        // Continue with other photos even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Get a specific product request by ID from Firestore
  static Future<ProductRequest?> getRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ProductRequest.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      AppLogger.e('Error fetching product request from Firestore', error: e);
      rethrow;
    }
  }

  /// List product requests from Firestore with optional filters
  static Future<List<ProductRequest>> listRequests({
    RequestStatus? status,
    RequestType? requestType,
    Priority? priority,
    String? userId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (requestType != null) {
        query = query.where('requestType', isEqualTo: requestType.name);
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }
      if (userId != null) {
        query = query.where('submittedBy.id', isEqualTo: userId);
      }

      // Order by creation date and limit
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => ProductRequest.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.e('Error listing product requests from Firestore', error: e);
      rethrow;
    }
  }

  /// Stream of user's product requests (real-time updates)
  static Stream<List<ProductRequest>> streamUserRequests(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('submittedBy.id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductRequest.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Delete a product request (soft delete by updating status)
  static Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collectionName).doc(requestId).update({
        'status': RequestStatus.rejected.name,
        'updatedAt': DateTime.now(),
      });
      AppLogger.d('Product request marked as rejected: $requestId');
    } catch (e) {
      AppLogger.e('Error deleting product request', error: e);
      rethrow;
    }
  }
}
