# Product Request System Architecture

> **📌 For Admin Board Developers**: See [ADMIN_BOARD_INTEGRATION_GUIDE.md](./ADMIN_BOARD_INTEGRATION_GUIDE.md) for complete integration documentation.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         SHOPPLE APP                              │
│                      (Flutter / Dart)                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   Dashboard   │   │  Data Models  │   │  UI Widgets   │
│   Add Sheet   │   │               │   │               │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        │ User taps         │ ProductRequest    │ ProductRequest
        │ "Request          │ RequestType       │ Sheet
        │  Product"         │ ProductIssue      │
        │                   │ IssueType         │
        ▼                   ▼                   ▼
┌───────────────────────────────────────────────────────────┐
│              Product Request Type Selector                 │
│                                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │   New    │  │  Update  │  │  Report  │  │  Price   │ │
│  │ Product  │  │ Product  │  │  Error   │  │  Update  │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ User selects type
                        ▼
┌───────────────────────────────────────────────────────────┐
│              Intelligent Request Form                      │
│             (Adapts based on type)                        │
│                                                            │
│  If NEW PRODUCT:                                          │
│    • Product Name (required)                              │
│    • Brand, Size                                          │
│    • Store, Branch                                        │
│    • Priority, Photos                                     │
│                                                            │
│  If UPDATE/REPORT/PRICE:                                  │
│    • Search & Tag Product (required)                      │
│    • Select Issue Types (required)                        │
│    • Correction Fields (dynamic)                          │
│    • Priority, Photos                                     │
│                                                            │
│  ┌─────────────────────────────────────────┐             │
│  │        Submit Button                     │             │
│  └─────────────────────────────────────────┘             │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ User submits
                        ▼
┌───────────────────────────────────────────────────────────┐
│            ProductRequestService                           │
│         (Firebase Integration Layer)                       │
│                                                            │
│  submitRequest(request, photos):                          │
│    1. Generate requestId (UUID)                           │
│    2. Upload photos to Firebase Storage                   │
│    3. Get photo download URLs                             │
│    4. Create Firestore document                           │
│    5. Return ProductRequest                               │
└───────────┬───────────────────┬───────────────────────────┘
            │                   │
            │ Photos            │ Metadata
            ▼                   ▼
┌───────────────────┐   ┌───────────────────┐
│ Firebase Storage  │   │    Firestore      │
│                   │   │    Database       │
│ product-requests/ │   │  product_requests │
│   {requestId}/    │   │    collection     │
│     photo_0.jpg   │   │                   │
│     photo_1.jpg   │   │  {requestId}/     │
│     ...           │   │    - requestType  │
└───────────────────┘   │    - productName  │
                        │    - photoUrls[]  │
                        │    - issue        │
                        │    - status       │
                        │    - createdAt    │
                        └───────────┬───────┘
                                    │
                                    │ Real-time sync
                                    │ (onSnapshot)
                                    ▼
                        ┌───────────────────┐
                        │   Admin Board     │
                        │   (Next.js)       │
                        │                   │
                        │  • View Requests  │
                        │  • Update Status  │
                        │  • Add Comments   │
                        │  • Approve/Reject │
                        └───────────────────┘
```

## Request Type Flow

### 1. New Product Request
```
User → Type Selector → NEW PRODUCT
                          ↓
              ┌───────────────────────┐
              │  Product Name*        │
              │  Brand                │
              │  Size                 │
              │  Store                │
              │  Branch               │
              │  Priority             │
              │  Photos (0-5)         │
              │  Description          │
              └───────────┬───────────┘
                          ↓
                     Submit to Firebase
                          ↓
                  ┌───────────────┐
                  │  Firestore:   │
                  │  requestType: │
                  │  "newProduct" │
                  └───────────────┘
```

### 2. Update Product Request
```
User → Type Selector → UPDATE PRODUCT
                          ↓
              ┌───────────────────────┐
              │  Search Product*      │ ← Product tagging
              │  Tag Product*         │
              └───────────┬───────────┘
                          ↓
              ┌───────────────────────┐
              │  Select Issues*:      │
              │  □ Incorrect Name     │
              │  □ Incorrect Price    │
              │  □ Incorrect Size     │
              │  □ Incorrect Brand    │
              │  □ Incorrect Image    │
              │  □ Other              │
              └───────────┬───────────┘
                          ↓
              ┌───────────────────────┐
              │  Correction Fields:   │
              │  Current: [____]      │ ← Dynamic
              │  Correct: [____]      │ ← Based on
              │                       │   selected issues
              │  Priority             │
              │  Photos (0-5)         │
              │  Description          │
              └───────────┬───────────┘
                          ↓
                     Submit to Firebase
                          ↓
                  ┌───────────────┐
                  │  Firestore:   │
                  │  requestType: │
                  │  "updateProd" │
                  │  taggedId:    │
                  │  "prod_123"   │
                  │  issue: {...} │
                  └───────────────┘
```

### 3. Report Error Request
```
User → Type Selector → REPORT ERROR
                          ↓
              ┌───────────────────────┐
              │  Search Product*      │
              │  Tag Product*         │
              └───────────┬───────────┘
                          ↓
              ┌───────────────────────┐
              │  Select Issues*       │
              │  (checkboxes)         │
              └───────────┬───────────┘
                          ↓
              ┌───────────────────────┐
              │  Correction Fields    │
              │  (for each issue)     │
              │                       │
              │  Priority             │
              │  Photos (0-5)         │
              │  Description          │
              └───────────┬───────────┘
                          ↓
                     Submit to Firebase
                          ↓
                  ┌───────────────┐
                  │  Firestore:   │
                  │  requestType: │
                  │  "reportError"│
                  │  taggedId:    │
                  │  "prod_456"   │
                  │  issue: {...} │
                  └───────────────┘
```

### 4. Price Update Request
```
User → Type Selector → PRICE UPDATE
                          ↓
              ┌───────────────────────┐
              │  Search Product*      │
              │  Tag Product*         │
              └───────────┬───────────┘
                          ↓
              ┌───────────────────────┐
              │  Current Price*       │
              │  New Price*           │
              │  Store                │
              │  Branch               │
              │  Priority             │
              │  Photos (receipt)     │
              │  Description          │
              └───────────┬───────────┘
                          ↓
                     Submit to Firebase
                          ↓
                  ┌───────────────┐
                  │  Firestore:   │
                  │  requestType: │
                  │  "priceUpdate"│
                  │  taggedId:    │
                  │  "prod_789"   │
                  │  issue: {     │
                  │    incorrect: │
                  │    "Rs.500",  │
                  │    correct:   │
                  │    "Rs.450"   │
                  │  }            │
                  └───────────────┘
```

## Data Flow Architecture

### Write Path (App → Firebase)
```
1. User Input
   └─→ Form Validation
       └─→ Image Picker (if photos selected)
           └─→ ProductRequestService.submitRequest()
               ├─→ Generate UUID requestId
               ├─→ _uploadPhotos() to Firebase Storage
               │   ├─→ Upload photo_0.jpg
               │   ├─→ Upload photo_1.jpg
               │   ├─→ ...
               │   └─→ Return download URLs
               │
               └─→ Firestore.collection('product_requests').doc(requestId).set()
                   └─→ Success → Show success dialog
                   └─→ Error → Show error message
```

### Read Path (Firebase → Admin Board)
```
1. Admin Board loads
   └─→ Firestore.collection('product_requests')
       .where('status', '==', 'pending')
       .onSnapshot()
       └─→ Real-time updates
           └─→ Display requests in table
               ├─→ Load photos from Storage URLs
               ├─→ Show request details
               └─→ Allow status updates
```

## Component Architecture

### Frontend (Flutter App)
```
lib/
├── models/
│   └── product_request_model.dart
│       ├── ProductRequest
│       ├── RequestType
│       ├── ProductIssue
│       ├── IssueType
│       ├── Priority
│       └── RequestStatus
│
├── services/
│   └── product_request/
│       └── product_request_api.dart
│           └── ProductRequestService
│               ├── submitRequest()
│               ├── _uploadPhotos()
│               ├── getRequest()
│               ├── listRequests()
│               ├── streamUserRequests()
│               └── deleteRequest()
│
└── widgets/
    ├── Dashboard/
    │   └── dashboard_add_sheet.dart
    │       └── "Request a Product" option
    │
    └── product_request/
        └── product_request_sheet.dart
            ├── ProductRequestSheet (main)
            ├── _RequestTypeSelector
            ├── _RequestForm
            └── Helper widgets
```

### Backend (Firebase)
```
Firebase Project
├── Firestore Database
│   └── product_requests (collection)
│       └── {requestId} (document)
│           ├── requestId: string
│           ├── requestType: string
│           ├── productName: string
│           ├── taggedProductId: string?
│           ├── issue: object?
│           ├── photoUrls: array
│           ├── priority: string
│           ├── status: string
│           ├── submittedBy: object
│           ├── createdAt: timestamp
│           └── updatedAt: timestamp?
│
└── Storage
    └── product-requests/
        └── {requestId}/
            ├── photo_0.jpg
            ├── photo_1.jpg
            └── ...
```

### Admin Dashboard (Next.js)
```
admin-board/
├── pages/
│   ├── requests/
│   │   ├── index.tsx (list all)
│   │   └── [id].tsx (detail view)
│   │
│   └── api/
│       └── requests/
│           ├── list.ts (fetch pending)
│           └── update.ts (change status)
│
├── components/
│   ├── RequestTable.tsx
│   ├── RequestDetail.tsx
│   └── StatusUpdater.tsx
│
└── lib/
    └── firebase-admin.ts (server-side SDK)
```

## State Management

### UI State
```
_RequestFormState
├── _formKey (validation)
├── Text Controllers (12 controllers)
│   ├── _productNameController
│   ├── _brandController
│   ├── _sizeController
│   ├── _storeController
│   ├── _branchController
│   ├── _descriptionController
│   ├── _incorrectNameController
│   ├── _correctNameController
│   ├── _incorrectPriceController
│   ├── _correctPriceController
│   ├── _incorrectSizeController
│   ├── _correctSizeController
│   ├── _incorrectBrandController
│   └── _correctBrandController
│
├── Selection State
│   ├── _priority (enum)
│   ├── _selectedPhotos (List<File>)
│   ├── _selectedIssues (List<IssueType>)
│   ├── _taggedProductId (String?)
│   └── _taggedProductName (String?)
│
└── Loading State
    └── _isSubmitting (bool)
```

### Request State Machine
```
                    ┌─────────┐
                    │ Initial │
                    └────┬────┘
                         │
         User fills form │
                         ▼
                    ┌─────────┐
                    │Validated│
                    └────┬────┘
                         │
       User taps submit  │
                         ▼
                    ┌─────────┐
                    │Uploading│
                    │ Photos  │
                    └────┬────┘
                         │
         Upload complete │
                         ▼
                    ┌─────────┐
                    │ Writing │
                    │Firestore│
                    └────┬────┘
                         │
        Write successful │
                         ▼
                    ┌─────────┐
                    │ Success │
                    └─────────┘
                         
    (Any error) → ┌─────────┐
                  │  Error  │
                  └─────────┘
```

## Firebase SDK Usage

### Firestore Operations
```dart
// Write
await FirebaseFirestore.instance
    .collection('product_requests')
    .doc(requestId)
    .set(request.toFirestore());

// Read
final doc = await FirebaseFirestore.instance
    .collection('product_requests')
    .doc(requestId)
    .get();

// Query
final snapshot = await FirebaseFirestore.instance
    .collection('product_requests')
    .where('status', isEqualTo: 'pending')
    .orderBy('createdAt', descending: true)
    .get();

// Stream (real-time)
FirebaseFirestore.instance
    .collection('product_requests')
    .where('submittedBy.userId', isEqualTo: userId)
    .snapshots()
```

### Storage Operations
```dart
// Upload
final ref = FirebaseStorage.instance
    .ref()
    .child('product-requests')
    .child(requestId)
    .child('photo_$i.jpg');

await ref.putFile(file);

// Get URL
final url = await ref.getDownloadURL();

// Delete
await ref.delete();
```

## Security Model

### Authentication Required
```
All operations require:
- User authenticated via Firebase Auth
- Valid user ID (UID)
- User info in submittedBy field
```

### Authorization Rules
```
Users can:
✓ Create their own requests
✓ Read their own requests
✗ Modify existing requests
✗ Delete requests
✗ Read other users' requests

Admins can:
✓ Read all requests
✓ Update request status
✓ Add comments
✗ Delete requests (soft delete only)
```

## Performance Optimizations

### Client-Side
- Image compression (85% quality)
- Image resizing (1280px max)
- Pagination (20 requests per page)
- Lazy loading photos
- Form validation before submission

### Firebase-Side
- Composite indexes for queries
- Photo size limits (5MB)
- Firestore offline persistence
- Batch writes for multiple operations

## Monitoring & Analytics

### Track These Events
```dart
// User actions
analytics.logEvent('product_request_started', {
  'request_type': requestType.name,
});

analytics.logEvent('product_request_submitted', {
  'request_type': requestType.name,
  'has_photos': photos.isNotEmpty,
  'issue_count': selectedIssues.length,
});

analytics.logEvent('product_request_failed', {
  'request_type': requestType.name,
  'error': error.toString(),
});
```

### Monitor These Metrics
- Request submission success rate
- Average submission time
- Photo upload success rate
- Request type distribution
- Issue type distribution
- Admin response time
- Request approval rate

---

**Status:** ✅ Architecture implemented and documented  
**Next Steps:** Product search implementation, Firebase rules, testing
