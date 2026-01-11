# Flutter Product Request Integration Guide

This guide walks Flutter engineers through integrating the new product-request workflow with the Flask backend. It covers required endpoints, payload shapes, attachment handling, and recommended UX patterns so shoppers can submit missing-product requests straight from the mobile app.

---

## 1. Architecture Overview

- **Frontend (Flutter):** Captures shopper input (product name, brand, size, store, optional photos) and posts it to the backend.
- **Backend (Flask):** Receives the submission on `/api/product-requests`, stores metadata in Firestore, uploads attachments to Firebase Storage, and immediately runs the *Intelligent Product Matcher* to suggest catalogue matches.
- **Admin Console (Next.js):** Displays the AI verdict, match list, and activity feed so admins can triage quickly.

### Auto-analysis recap

Every submission triggers an AI pass powered by the `IntelligentProductMatcher`. It:

1. Normalizes the incoming product description.
2. Searches the cached product catalogue with fuzzy/Levenshtein scoring (`fuzzywuzzy`, `python-Levenshtein`, difflib fallback).
3. Returns top matches with similarity percentages and reasoning.
4. Classifies the request into one of four recommendations: `already_exists`, `likely_duplicate`, `needs_manual_review`, or `create_new`.

The AI output is stored on the request record (`aiAnalysis`) and surfaces instantly in the admin UI.

---

## 2. Endpoint Reference

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/product-requests` | `POST` | Create a new request (JSON or multipart). Triggers AI analysis automatically. |
| `/api/product-requests/{id}` | `GET` | Fetch a specific request (includes activity + signed URLs). |
| `/api/product-requests?…` | `GET` | List requests with filters/pagination (mostly for admin dashboards). |
| `/api/product-requests/{id}/notes` | `POST` | Admin-only: add internal note (not needed in mobile flow). |
| `/api/product-requests/{id}/acknowledge` | `POST` | Admin endpoint to claim requests. |

Only the `POST /api/product-requests` endpoint is required for the shopper app; the others are provided for completeness.

### Base URL

- Local development: `http://localhost:5000`
- Staging/production: configure via environment (e.g., `https://api.shopple.example`)

All endpoints expect and return JSON unless you upload images; attachments require `multipart/form-data`.

---

## 3. Request Schema

### Minimum fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `productName` | string | ✅ | Shopper-entered name. |
| `store` | string | ✅ | Store identifier (e.g., `keells`, `cargills`). |
| `priority` | string | Optional | `low`, `normal` (default), or `high`. |
| `brand` | string | Optional | Shopper-provided brand. |
| `size` | string | Optional | Text such as `400g` or `4 pack`. |
| `categoryHint` | string | Optional | Shopper hint for category/aisle. |
| `description` | string | Optional | Free-form notes. |
| `labels` | string[] | Optional | Additional tags; helpful for segmentation. |
| `storeLocation` | object | Optional | Structured location info (e.g., aisle, GPS). |
| `submittedBy` | object | Optional | Shopper metadata: `{ id, name, email }` or similar. |
| `submissionSource` | string | Optional | Defaults to `mobile`. Use to distinguish between app/web. |
| `attachments` | array | Optional | Up to five files or base64 blobs. |

### JSON payload example

```json
{
  "productName": "Organic Coconut Milk",
  "brand": "Shopple Farms",
  "size": "400ml can",
  "store": "keells",
  "categoryHint": "Dairy substitutes",
  "description": "Need a lactose-free option",
  "priority": "high",
  "labels": ["vegan", "lactose-free"],
  "storeLocation": {
    "city": "Colombo",
    "branch": "Union Place"
  },
  "submittedBy": {
    "id": "user_123",
    "name": "Jane Doe",
    "email": "jane@example.com"
  }
}
```

### Multipart example

When sending photos, use `multipart/form-data`. Each attachment should be named `attachments` and include the file’s MIME type.

```
Content-Disposition: form-data; name="productName"
Organic Coconut Milk

Content-Disposition: form-data; name="store"
keells

Content-Disposition: form-data; name="attachments"; filename="shelf.jpg"
Content-Type: image/jpeg
(binary data)
```

The backend downscales images to ~1280px max edge and stores them in Firebase Storage automatically.

---

## 4. Response Structure

Successful creation returns HTTP 201 with:

```json
{
  "success": true,
  "request": {
    "id": "req_1695972390_ab12cd",
    "productName": "Organic Coconut Milk",
    "status": "submitted",
    "priority": "high",
    "aiAnalysis": {
      "status": "complete",
      "recommendation": "needs_manual_review",
      "confidence": 0.82,
      "summary": "Review recommended (confidence 82%)",
      "matches": [
        {
          "productId": "prod_001",
          "name": "Coconut Milk Classic",
          "brand": "Farm Fresh",
          "size": "400ml",
          "similarity": 0.87,
          "reasons": ["High fuzzy name match (0.94)", "Size match"],
          "isDuplicate": false
        }
      ]
    },
    "attachments": [
      {
        "filename": "shelf.jpg",
        "storagePath": "product-requests/req_1695972390_ab12cd/…",
        "contentType": "image/jpeg",
        "size": 204800
      }
    ],
    "createdAt": "2025-09-25T08:12:03Z"
  }
}
```

Errors return HTTP 4xx/5xx with `{ "success": false, "error": "…" }`.

---

## 5. Flutter Implementation Blueprint

### Recommended packages

- [`http`](https://pub.dev/packages/http) for REST calls.
- [`image_picker`](https://pub.dev/packages/image_picker) for capturing attachments.
- [`mime`](https://pub.dev/packages/mime) for inferring MIME types.
- Optional: [`dio`](https://pub.dev/packages/dio) if you prefer advanced networking features (progress, interceptors).

### Posting JSON (no attachments)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductRequestApi {
  static const _baseUrl = String.fromEnvironment(
    'PRODUCT_API_BASE',
    defaultValue: 'https://api.shopple.example',
  );

  static Future<Map<String, dynamic>> submitRequest({
    required String productName,
    required String store,
    String? brand,
    String? size,
    String? description,
    Map<String, dynamic>? submittedBy,
    String priority = 'normal',
  }) async {
    final payload = {
      'productName': productName,
      'store': store,
      'priority': priority,
      if (brand != null) 'brand': brand,
      if (size != null) 'size': size,
      if (description != null) 'description': description,
      if (submittedBy != null) 'submittedBy': submittedBy,
      'submissionSource': 'mobile',
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/product-requests'),
      headers: {
        'Content-Type': 'application/json',
        // Include auth header if your backend requires it
        // 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      final message = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Submission failed: $message');
    }

    return jsonDecode(response.body)['request'] as Map<String, dynamic>;
  }
}
```

### Posting with attachments (multipart)

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

Future<Map<String, dynamic>> submitRequestWithPhotos({
  required String productName,
  required String store,
  required List<File> photos,
}) async {
  final uri = Uri.parse('$_baseUrl/api/product-requests');
  final request = http.MultipartRequest('POST', uri)
    ..fields['productName'] = productName
    ..fields['store'] = store
    ..fields['priority'] = 'normal'
    ..fields['submissionSource'] = 'mobile';

  for (final file in photos.take(5)) {
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'attachments',
      bytes,
      filename: file.uri.pathSegments.last,
      contentType: MediaType.parse(mimeType),
    ));
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode != 201) {
    throw Exception('Submission failed: ${response.body}');
  }

  return jsonDecode(response.body)['request'];
}
```

### UX checklist

- **Progress indicators:** Show upload progress for large photos.
- **Retry support:** Cache requests locally when offline and sync later.
- **Validation:** Require `productName` + `store` before allowing submission.
- **Success confirmation:** Display the AI summary so shoppers see that the request is being actioned.

---

## 6. Handling AI Feedback (Optional Display)

Although the admin console is the primary consumer, you can surface AI insights back to shoppers (if desired):

- `aiAnalysis.summary`: One-line explanation of what the system found.
- `aiAnalysis.recommendation`: Use to show status chips (e.g., “We already have this product”).
- `aiAnalysis.matches`: Provide a carousel of near matches and let users confirm duplicates.

This is optional, but exposing it creates a feedback loop that improves data quality.

---

## 7. Error Handling & Monitoring

- **400 Bad Request:** Validation issues (`productName` missing, payload malformed). Surface the `error` message to the user.
- **500 Internal Server Error:** Retry with exponential backoff. Log incidents with request ID, payload summary, and attachments count.
- **Attachment failures:** The backend skips unreadable files silently; send clean images (JPEG/PNG/WebP).

### Observability hooks

- Include a `X-Request-Id` header if your network stack supports it for easier tracing in backend logs.
- Track submission analytics (success/failure) using your analytics provider.

---

## 8. Launch Checklist

1. ✅ Configure `PRODUCT_API_BASE` per environment.
2. ✅ Ensure Firebase service account & Storage bucket are accessible from the backend.
3. ✅ Limit attachments to ≤5 images; resize to 1280px client-side if bandwidth is a concern.
4. ✅ QA end-to-end with sample products and confirm AI recommendations appear in the admin UI.
5. ✅ Coordinate with backend to enable authentication if production requires user verification.

For questions or updates, reach out to the backend team maintaining `product_request_service.py`.
