# Product Request System - Admin Board Integration Guide

## 📋 Table of Contents
- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Request Types](#request-types)
- [Firebase Integration](#firebase-integration)
- [Data Models & Fields](#data-models--fields)
- [Admin Board Requirements](#admin-board-requirements)
- [Database Access Patterns](#database-access-patterns)
- [API Integration](#api-integration)
- [Security & Permissions](#security--permissions)
- [Implementation Checklist](#implementation-checklist)
- [Testing Guidelines](#testing-guidelines)

---

## 📖 Overview

The **Product Request System** is a comprehensive crowdsourcing feature that enables Shopple mobile app users to contribute to the product catalog by:
- Requesting new products to be added
- Suggesting updates to existing product information
- Reporting errors or incorrect data
- Submitting price corrections

The system is **fully integrated with Firebase** (Firestore + Storage) and requires **no backend API** for request submission. The mobile app writes directly to Firebase, and the admin board reads from the same Firebase database.

### Key Features
✅ **Four distinct request types** with adaptive UI  
✅ **Direct Firebase integration** - no middleware API needed  
✅ **Photo upload support** - up to 5 photos per request  
✅ **Product tagging** - link corrections to existing products  
✅ **Priority levels** - user-submitted urgency indicators  
✅ **Real-time sync** - admin board sees requests instantly  
✅ **Comprehensive audit trail** - all changes tracked  

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SHOPPLE MOBILE APP                        │
│                      (Flutter/Dart)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Direct Write (No API)
                         ▼
            ┌────────────────────────────┐
            │      FIREBASE CLOUD        │
            │                            │
            │  ┌──────────────────────┐  │
            │  │   Firestore DB       │  │
            │  │ product_requests     │  │
            │  │   collection         │  │
            │  └──────────────────────┘  │
            │                            │
            │  ┌──────────────────────┐  │
            │  │  Firebase Storage    │  │
            │  │  product-requests/   │  │
            │  │    {requestId}/      │  │
            │  └──────────────────────┘  │
            └────────────┬───────────────┘
                         │
                         │ Real-time Read
                         ▼
            ┌────────────────────────────┐
            │      ADMIN BOARD           │
            │      (Next.js/React)       │
            │                            │
            │  - View Requests           │
            │  - Update Status           │
            │  - Add Comments            │
            │  - Approve/Reject          │
            │  - Assign Requests         │
            └────────────────────────────┘
```

### Data Flow
1. **Mobile App** → User fills form → Uploads photos to Storage → Writes document to Firestore
2. **Firestore** → Real-time sync with admin board
3. **Admin Board** → Reads requests → Updates status → Adds notes → Triggers actions

---

## 🎯 Request Types

The system supports **four distinct request types**, each with specific fields and validation rules:

### 1. 🆕 New Product Request
**Purpose**: User wants to add a completely new product to the catalog

**Use Cases**:
- Product not found during search
- New product in store not yet in catalog
- Regional/local products

**Required Fields**:
- ✅ `productName` (string) - Product name or description

**Optional Fields**:
- `brand` (string) - Brand name
- `size` (string) - Size/quantity with unit
- `store` (string) - Store name where product found
- `storeLocation.branch` (string) - Specific branch/location
- `storeLocation.city` (string) - City
- `description` (string) - Additional details
- `priority` (enum) - low | normal | high
- `photoUrls` (array) - Up to 5 product photos
- `categoryHint` (string) - Suggested category

**Example Use Case**:
> User sees a new "Organic Quinoa Chips - 150g" at Woolworths that's not in the app. They take photos, fill in the details, and submit a new product request.

---

### 2. 🔄 Update Product Request
**Purpose**: Suggest updates to existing product information

**Use Cases**:
- Product details need updating
- Multiple fields need correction
- Product rebranding or packaging change

**Required Fields**:
- ✅ `taggedProductId` (string) - Reference to existing product
- ✅ `issue.issueTypes` (array) - Selected issue types
- ✅ Correction fields based on selected issues

**Optional Fields**:
- `priority` (enum) - low | normal | high
- `photoUrls` (array) - Supporting photos
- `description` (string) - Additional context

**Issue Types** (user can select multiple):
```typescript
enum IssueType {
  incorrectName    // Product name is wrong
  incorrectPrice   // Price is outdated
  incorrectSize    // Size/quantity incorrect
  incorrectBrand   // Brand information wrong
  incorrectImage   // Product image needs updating
  other           // Other issues
}
```

**Correction Fields** (dynamic based on selected issues):
- `incorrectName` → `correctName`
- `incorrectPrice` → `correctPrice`
- `incorrectSize` → `correctSize`
- `incorrectBrand` → `correctBrand`
- `additionalDetails` - Explanation

**Example Use Case**:
> User notices "Cadbury Dairy Milk" shows 180g but it's actually 200g now. They tag the product, select "incorrectSize", enter current: "180g", correct: "200g", and submit.

---

### 3. 🚨 Report Error
**Purpose**: Report incorrect information on existing products

**Use Cases**:
- Critical errors in product data
- Price significantly wrong
- Wrong product image
- Misleading information

**Fields**: Same as Update Product Request
- ✅ `taggedProductId` (string)
- ✅ `issue.issueTypes` (array)
- ✅ Correction fields
- Optional: priority, photos, description

**Difference from Update**:
- Semantically indicates urgency (error vs. update)
- May trigger different admin workflows
- Higher priority in admin queue

**Example Use Case**:
> User finds that "Heinz Tomato Ketchup 500ml" is showing the image of mustard. They report the error, select "incorrectImage", attach correct photo, and submit.

---

### 4. 💰 Price Update Request
**Purpose**: Report price changes at specific stores

**Use Cases**:
- Price increased/decreased
- Sale price ended
- Store-specific pricing
- Outdated price information

**Required Fields**:
- ✅ `taggedProductId` (string) - Product reference
- ✅ `issue.incorrectPrice` (string) - Current shown price
- ✅ `issue.correctPrice` (string) - Actual price
- Optional: `store`, `storeLocation.branch`

**Optional Fields**:
- `priority` (enum)
- `photoUrls` (array) - Receipt or shelf photo
- `description` (string) - Context (e.g., "On sale this week")

**Example Use Case**:
> User shops at Coles and sees "Weetbix 1.2kg" is now $5.50, not $6.00 as shown in the app. They submit a price update with receipt photo.

---

## 🔥 Firebase Integration

### Firestore Collection Structure

**Collection**: `product_requests`  
**Document ID**: Auto-generated by Firestore

```
product_requests/
├── {docId1}/
├── {docId2}/
└── {docId3}/
```

### Firebase Storage Structure

**Bucket**: Default Firebase Storage bucket  
**Path**: `product-requests/{requestId}/`

```
product-requests/
├── abc123-def456/
│   ├── photo_1700000000000_0.jpg
│   ├── photo_1700000000001_1.jpg
│   └── photo_1700000000002_2.jpg
└── xyz789-uvw012/
    └── photo_1700000000003_0.jpg
```

**Photo Naming Convention**:
```
photo_{timestamp}_{index}.jpg
```

**Upload Process**:
1. User selects/captures photos
2. App uploads to Storage path: `product-requests/{requestId}/photo_{timestamp}_{index}.jpg`
3. Gets download URLs
4. Stores URLs in Firestore `photoUrls` array

---

## 📊 Data Models & Fields

### Core Document Structure

```typescript
interface ProductRequest {
  // Identity
  id?: string;                          // Document ID (generated by Firestore)
  
  // Request Classification
  requestType: RequestType;             // REQUIRED - Type of request
  
  // Product Information
  productName: string;                  // REQUIRED - Product name/description
  brand?: string;                       // Optional brand name
  size?: string;                        // Optional size/quantity
  categoryHint?: string;                // Optional category suggestion
  
  // Store Context
  store?: string;                       // Store name
  storeLocation?: StoreLocation;        // Detailed location
  
  // Description
  description?: string;                 // Free-text additional details
  
  // Priority & Status
  priority: Priority;                   // User-submitted priority
  status: RequestStatus;                // Current lifecycle status
  
  // Submitter Information
  submittedBy?: SubmittedBy;           // User who submitted
  submissionSource: string;             // 'mobile' | 'web' | 'admin'
  
  // Media Assets
  photoUrls: string[];                  // Firebase Storage download URLs
  
  // Product Tagging (for corrections)
  taggedProductId?: string;             // Reference to existing product
  
  // Issue Details (for corrections)
  issue?: ProductIssue;                 // What's wrong and corrections
  
  // Admin Management
  labels: string[];                     // Custom tags
  adminNotes: AdminNote[];              // Admin comments
  
  // Timestamps
  createdAt?: Timestamp;                // Submission time
  updatedAt?: Timestamp;                // Last modification time
}
```

### Enums

#### RequestType
```typescript
enum RequestType {
  newProduct      // Request to add new product to catalog
  updateProduct   // Request to update existing product info
  reportError     // Report incorrect/wrong information
  priceUpdate     // Report price change/correction
}
```

#### Priority
```typescript
enum Priority {
  low       // Can wait
  normal    // Standard priority (default)
  high      // Needs attention soon
}
```

#### RequestStatus
```typescript
enum RequestStatus {
  pending       // Just submitted, not reviewed
  inReview      // Admin is reviewing
  approved      // Approved, will be implemented
  completed     // Implemented/resolved
  rejected      // Rejected with reason
}
```

#### IssueType
```typescript
enum IssueType {
  incorrectName     // Product name is wrong
  incorrectPrice    // Price is incorrect
  incorrectSize     // Size/quantity wrong
  incorrectBrand    // Brand information incorrect
  incorrectImage    // Product image needs updating
  other            // Other issues
}
```

### Supporting Types

#### StoreLocation
```typescript
interface StoreLocation {
  city?: string;        // City name
  branch?: string;      // Branch/store location
  aisle?: string;       // Aisle number (future)
  shelf?: string;       // Shelf location (future)
}
```

#### SubmittedBy
```typescript
interface SubmittedBy {
  userId?: string;       // Firebase Auth UID
  displayName?: string;  // User's display name
  email?: string;        // User's email
  phone?: string;        // User's phone (optional)
}
```

#### ProductIssue
```typescript
interface ProductIssue {
  issueTypes: IssueType[];           // REQUIRED - List of issues
  
  // Name Corrections
  incorrectName?: string;            // Current wrong name
  correctName?: string;              // Proposed correct name
  
  // Price Corrections
  incorrectPrice?: string;           // Current wrong price
  correctPrice?: string;             // Proposed correct price
  
  // Size Corrections
  incorrectSize?: string;            // Current wrong size
  correctSize?: string;              // Proposed correct size
  
  // Brand Corrections
  incorrectBrand?: string;           // Current wrong brand
  correctBrand?: string;             // Proposed correct brand
  
  // Additional Context
  additionalDetails?: string;        // Extra explanation
}
```

#### AdminNote
```typescript
interface AdminNote {
  id: string;                // Note ID
  authorId?: string;         // Admin user ID
  authorName?: string;       // Admin display name
  note: string;              // Note content
  isPrivate: boolean;        // Internal note (not visible to user)
  createdAt?: Timestamp;     // When note was added
}
```

---

## 🔐 Security & Permissions

### Firestore Security Rules

```javascript
// Current rules at: firestore.rules line 104-119
match /product_requests/{requestId} {
  // Users can read their own requests
  allow read: if isSignedIn() && (
    resource.data.submittedBy.id == request.auth.uid
  );
  
  // Users can create requests (must match their UID)
  allow create: if isSignedIn() && 
    request.resource.data.submittedBy.id == request.auth.uid;
  
  // Users can update their own requests
  allow update: if isSignedIn() && (
    resource.data.submittedBy.id == request.auth.uid
  );
  
  // Users can delete their own requests
  allow delete: if isSignedIn() && 
    resource.data.submittedBy.id == request.auth.uid;
}
```

### Required Admin Rules (TO BE ADDED)

```javascript
match /product_requests/{requestId} {
  // Admin read access
  allow read: if isSignedIn() && (
    resource.data.submittedBy.id == request.auth.uid ||
    request.auth.token.admin == true  // Admin custom claim
  );
  
  // Admin update access (status, notes, etc.)
  allow update: if isSignedIn() && (
    resource.data.submittedBy.id == request.auth.uid ||
    request.auth.token.admin == true
  );
}
```

### Firebase Storage Rules

⚠️ **NEEDS TO BE CONFIGURED** - Currently no specific rules for product-requests folder

**Required Rules**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /product-requests/{requestId}/{photo} {
      // Allow authenticated users to upload photos
      allow write: if request.auth != null &&
                     request.resource.size < 5 * 1024 * 1024;  // Max 5MB per photo
      
      // Allow authenticated users and admins to read photos
      allow read: if request.auth != null;
      
      // Admins can delete photos
      allow delete: if request.auth != null &&
                      request.auth.token.admin == true;
    }
  }
}
```

---

## 🔧 Admin Board Requirements

### Essential Features

#### 1. Request Listing Page
**Route**: `/admin/product-requests`

**Features**:
- Table view of all product requests
- Real-time updates (Firestore snapshots)
- Filtering by:
  - Status (pending, inReview, approved, completed, rejected)
  - Request Type (newProduct, updateProduct, reportError, priceUpdate)
  - Priority (low, normal, high)
  - Date range
  - Store
  - User/submitter
- Sorting by:
  - Creation date
  - Priority
  - Status
  - Request type
- Pagination (20-50 per page)
- Bulk actions (approve multiple, assign to admin, etc.)

**Display Columns**:
| Column | Data | Format |
|--------|------|--------|
| ID | `id` | Short ID or badge |
| Type | `requestType` | Icon + label |
| Product | `productName` | Text with brand |
| Status | `status` | Colored badge |
| Priority | `priority` | Badge/icon |
| Store | `store` | Text |
| Submitter | `submittedBy.displayName` | Name + avatar |
| Created | `createdAt` | "2 hours ago" |
| Actions | - | View/Edit buttons |

---

#### 2. Request Detail View
**Route**: `/admin/product-requests/{requestId}`

**Sections**:

**A. Request Header**
- Request type badge
- Status badge
- Priority indicator
- Creation date
- Last updated date
- Request ID

**B. Product Information**
- Product name
- Brand
- Size
- Category hint
- Store + branch location

**C. Issue Details** (for correction types)
- Tagged product (if exists) with link
- Selected issue types
- Incorrect vs. Correct values comparison table:
  ```
  | Field  | Current Value | Proposed Value |
  |--------|---------------|----------------|
  | Name   | Heinz Mustard | Heinz Ketchup  |
  | Price  | $4.50         | $5.00          |
  ```

**D. Photos Gallery**
- Display all uploaded photos
- Lightbox/zoom functionality
- Download individual photos
- Download all photos as zip

**E. Submitter Information**
- Display name
- Email (if available)
- Phone (if available)
- User ID
- Submission source (mobile/web)

**F. Description**
- Free-text description from user
- Formatted display

**G. Admin Actions**
- Change status dropdown
- Assign to admin dropdown
- Add labels/tags
- Priority adjustment
- Add internal note
- Add public comment
- Approve/Reject buttons

**H. Activity Timeline**
- All status changes
- Admin notes
- System events
- Timestamps

---

#### 3. Quick Actions

**Status Transitions**:
```typescript
// Allowed status transitions
pending → inReview
pending → rejected
inReview → approved
inReview → rejected
approved → completed
approved → pending (revert)
```

**Action Buttons**:
- 🔍 **Review** - Change to inReview, assign to self
- ✅ **Approve** - Mark as approved, add note
- ❌ **Reject** - Mark as rejected, require reason
- ✔️ **Complete** - Mark as completed, require action taken
- 📝 **Add Note** - Add admin comment
- 🏷️ **Tag** - Add custom labels
- 👤 **Assign** - Assign to admin user

---

#### 4. Dashboard Statistics

**Metrics to Display**:
```typescript
interface RequestStatistics {
  // Counts by Status
  totalRequests: number;
  pendingCount: number;
  inReviewCount: number;
  approvedCount: number;
  completedCount: number;
  rejectedCount: number;
  
  // Counts by Type
  newProductCount: number;
  updateProductCount: number;
  reportErrorCount: number;
  priceUpdateCount: number;
  
  // Counts by Priority
  highPriorityCount: number;
  normalPriorityCount: number;
  lowPriorityCount: number;
  
  // Time-based Metrics
  avgResponseTime: number;        // Time to first admin action
  avgResolutionTime: number;      // Time to completion
  requestsToday: number;
  requestsThisWeek: number;
  requestsThisMonth: number;
  
  // Store Breakdown
  requestsByStore: Record<string, number>;
  
  // Recent Activity
  recentRequests: ProductRequest[];
  recentlyCompleted: ProductRequest[];
}
```

---

## 📡 Database Access Patterns

### Read Operations

#### 1. List All Requests (with filters)
```typescript
// Query with filters
const requestsQuery = firestore
  .collection('product_requests')
  .where('status', '==', 'pending')           // Filter by status
  .where('priority', '==', 'high')            // Filter by priority
  .orderBy('createdAt', 'desc')               // Sort by date
  .limit(50);                                 // Pagination

const snapshot = await requestsQuery.get();
const requests = snapshot.docs.map(doc => ({
  id: doc.id,
  ...doc.data()
}));
```

#### 2. Get Single Request
```typescript
const requestDoc = await firestore
  .collection('product_requests')
  .doc(requestId)
  .get();

if (!requestDoc.exists) {
  throw new Error('Request not found');
}

const request = {
  id: requestDoc.id,
  ...requestDoc.data()
};
```

#### 3. Real-time Subscription
```typescript
// Listen to all pending requests
const unsubscribe = firestore
  .collection('product_requests')
  .where('status', '==', 'pending')
  .onSnapshot(snapshot => {
    const requests = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    updateUI(requests);
  });

// Remember to unsubscribe when component unmounts
```

#### 4. Statistics Query
```typescript
// Count by status (requires aggregation or client-side counting)
const pendingSnapshot = await firestore
  .collection('product_requests')
  .where('status', '==', 'pending')
  .get();

const pendingCount = pendingSnapshot.size;
```

---

### Write Operations

#### 1. Update Request Status
```typescript
await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    status: 'inReview',
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 2. Add Admin Note
```typescript
const note: AdminNote = {
  id: generateId(),
  authorId: currentAdmin.uid,
  authorName: currentAdmin.displayName,
  note: noteContent,
  isPrivate: false,
  createdAt: FieldValue.serverTimestamp()
};

await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    adminNotes: FieldValue.arrayUnion(note),
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 3. Approve Request
```typescript
await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    status: 'approved',
    approvedBy: {
      adminId: currentAdmin.uid,
      adminName: currentAdmin.displayName,
      approvedAt: FieldValue.serverTimestamp()
    },
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 4. Reject Request with Reason
```typescript
const rejectionNote: AdminNote = {
  id: generateId(),
  authorId: currentAdmin.uid,
  authorName: currentAdmin.displayName,
  note: `Rejected: ${reason}`,
  isPrivate: false,
  createdAt: FieldValue.serverTimestamp()
};

await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    status: 'rejected',
    rejectionReason: reason,
    adminNotes: FieldValue.arrayUnion(rejectionNote),
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 5. Assign to Admin
```typescript
await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    assignedTo: {
      adminId: assignedAdmin.uid,
      adminName: assignedAdmin.displayName,
      assignedAt: FieldValue.serverTimestamp()
    },
    status: 'inReview',  // Auto-change to inReview
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 6. Add Labels/Tags
```typescript
await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    labels: FieldValue.arrayUnion('needs-photo', 'duplicate-check'),
    updatedAt: FieldValue.serverTimestamp()
  });
```

#### 7. Update Priority
```typescript
await firestore
  .collection('product_requests')
  .doc(requestId)
  .update({
    priority: 'high',
    updatedAt: FieldValue.serverTimestamp()
  });
```

---

### Complex Queries

#### 1. Get Requests by Multiple Criteria
```typescript
// Note: Firestore has limitations on compound queries
// May need to create composite indexes

// Query: All high-priority pending requests from last 7 days
const oneWeekAgo = new Date();
oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

const query = firestore
  .collection('product_requests')
  .where('status', '==', 'pending')
  .where('priority', '==', 'high')
  .where('createdAt', '>=', oneWeekAgo)
  .orderBy('createdAt', 'desc');

const snapshot = await query.get();
```

#### 2. Search Requests (Full-text search)
```typescript
// Option 1: Client-side filtering (for small datasets)
const allRequests = await firestore
  .collection('product_requests')
  .get();

const searchResults = allRequests.docs
  .filter(doc => {
    const data = doc.data();
    const searchText = searchQuery.toLowerCase();
    return (
      data.productName?.toLowerCase().includes(searchText) ||
      data.brand?.toLowerCase().includes(searchText) ||
      data.store?.toLowerCase().includes(searchText)
    );
  })
  .map(doc => ({ id: doc.id, ...doc.data() }));

// Option 2: Use Algolia/Meilisearch for full-text search
// (Requires setting up external search service)
```

#### 3. Get Statistics
```typescript
async function getStatistics() {
  const allRequests = await firestore
    .collection('product_requests')
    .get();
  
  const stats = {
    totalRequests: allRequests.size,
    pendingCount: 0,
    inReviewCount: 0,
    approvedCount: 0,
    completedCount: 0,
    rejectedCount: 0,
    newProductCount: 0,
    updateProductCount: 0,
    reportErrorCount: 0,
    priceUpdateCount: 0,
    highPriorityCount: 0,
    requestsByStore: {} as Record<string, number>
  };
  
  allRequests.forEach(doc => {
    const data = doc.data();
    
    // Count by status
    stats[`${data.status}Count`]++;
    
    // Count by type
    stats[`${data.requestType}Count`]++;
    
    // Count by priority
    if (data.priority === 'high') stats.highPriorityCount++;
    
    // Count by store
    if (data.store) {
      stats.requestsByStore[data.store] = 
        (stats.requestsByStore[data.store] || 0) + 1;
    }
  });
  
  return stats;
}
```

---

## 🔌 API Integration

### Firebase Admin SDK Setup

```typescript
// lib/firebase-admin.ts
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
    })
  });
}

export const firestore = admin.firestore();
export const storage = admin.storage();
export const auth = admin.auth();
```

### API Routes (Next.js Example)

#### GET /api/product-requests
```typescript
// pages/api/product-requests.ts
import { NextApiRequest, NextApiResponse } from 'next';
import { firestore } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/auth';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Verify admin authentication
  const admin = await verifyAdminAuth(req);
  if (!admin) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const {
    status,
    requestType,
    priority,
    page = 1,
    limit = 50
  } = req.query;
  
  let query = firestore.collection('product_requests');
  
  // Apply filters
  if (status) {
    query = query.where('status', '==', status);
  }
  if (requestType) {
    query = query.where('requestType', '==', requestType);
  }
  if (priority) {
    query = query.where('priority', '==', priority);
  }
  
  // Order and paginate
  query = query
    .orderBy('createdAt', 'desc')
    .limit(Number(limit))
    .offset((Number(page) - 1) * Number(limit));
  
  const snapshot = await query.get();
  const requests = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  
  res.json({
    requests,
    page: Number(page),
    limit: Number(limit),
    total: snapshot.size
  });
}
```

#### GET /api/product-requests/[id]
```typescript
// pages/api/product-requests/[id].ts
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const admin = await verifyAdminAuth(req);
  if (!admin) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const { id } = req.query;
  
  const doc = await firestore
    .collection('product_requests')
    .doc(id as string)
    .get();
  
  if (!doc.exists) {
    return res.status(404).json({ error: 'Request not found' });
  }
  
  const request = {
    id: doc.id,
    ...doc.data()
  };
  
  res.json(request);
}
```

#### PATCH /api/product-requests/[id]
```typescript
// pages/api/product-requests/[id].ts
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === 'PATCH') {
    const admin = await verifyAdminAuth(req);
    if (!admin) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const { id } = req.query;
    const updates = req.body;
    
    // Validate allowed fields
    const allowedFields = [
      'status',
      'priority',
      'labels',
      'assignedTo'
    ];
    
    const updateData = Object.keys(updates)
      .filter(key => allowedFields.includes(key))
      .reduce((obj, key) => {
        obj[key] = updates[key];
        return obj;
      }, {} as any);
    
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    
    await firestore
      .collection('product_requests')
      .doc(id as string)
      .update(updateData);
    
    res.json({ success: true });
  }
}
```

#### POST /api/product-requests/[id]/notes
```typescript
// pages/api/product-requests/[id]/notes.ts
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const currentAdmin = await verifyAdminAuth(req);
  if (!currentAdmin) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const { id } = req.query;
  const { note, isPrivate = false } = req.body;
  
  const adminNote = {
    id: generateId(),
    authorId: currentAdmin.uid,
    authorName: currentAdmin.displayName,
    note,
    isPrivate,
    createdAt: new Date()
  };
  
  await firestore
    .collection('product_requests')
    .doc(id as string)
    .update({
      adminNotes: admin.firestore.FieldValue.arrayUnion(adminNote),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  
  res.json({ success: true, note: adminNote });
}
```

---

## ✅ Implementation Checklist

### Phase 1: Setup & Configuration
- [ ] Set up Firebase Admin SDK in admin board
- [ ] Configure Firebase credentials (service account)
- [ ] Add Firebase Storage rules for `product-requests/` path
- [ ] Update Firestore rules for admin access
- [ ] Create Firestore indexes for common queries

### Phase 2: Core Features
- [ ] Implement request listing page with filters
- [ ] Implement request detail view
- [ ] Add status update functionality
- [ ] Add admin notes/comments feature
- [ ] Implement photo gallery with lightbox
- [ ] Add real-time updates (Firestore snapshots)

### Phase 3: Advanced Features
- [ ] Dashboard statistics and metrics
- [ ] Bulk actions (approve multiple, etc.)
- [ ] Search functionality
- [ ] Export to CSV/Excel
- [ ] Email notifications for status changes
- [ ] Activity log/audit trail

### Phase 4: Integration & Testing
- [ ] Test all CRUD operations
- [ ] Test real-time sync
- [ ] Test photo uploads/downloads
- [ ] Test different request types
- [ ] Test permission/security rules
- [ ] Performance testing with large datasets

---

## 🧪 Testing Guidelines

### Unit Tests

#### Test Firestore Queries
```typescript
describe('Product Request Queries', () => {
  it('should fetch pending requests', async () => {
    const requests = await getPendingRequests();
    expect(requests.every(r => r.status === 'pending')).toBe(true);
  });
  
  it('should filter by request type', async () => {
    const newProductRequests = await getRequestsByType('newProduct');
    expect(newProductRequests.every(r => r.requestType === 'newProduct'))
      .toBe(true);
  });
});
```

#### Test Status Transitions
```typescript
describe('Status Updates', () => {
  it('should update status from pending to inReview', async () => {
    await updateRequestStatus(requestId, 'inReview');
    const request = await getRequest(requestId);
    expect(request.status).toBe('inReview');
  });
  
  it('should prevent invalid status transitions', async () => {
    await expect(
      updateRequestStatus(requestId, 'completed')
    ).rejects.toThrow('Invalid status transition');
  });
});
```

### Integration Tests

#### Test Complete Workflow
```typescript
describe('Request Workflow', () => {
  it('should complete full approval workflow', async () => {
    // 1. Create test request
    const request = await createTestRequest();
    
    // 2. Assign to admin
    await assignRequest(request.id, adminId);
    expect((await getRequest(request.id)).status).toBe('inReview');
    
    // 3. Add note
    await addAdminNote(request.id, 'Looks good');
    
    // 4. Approve
    await approveRequest(request.id);
    expect((await getRequest(request.id)).status).toBe('approved');
    
    // 5. Mark complete
    await completeRequest(request.id);
    expect((await getRequest(request.id)).status).toBe('completed');
  });
});
```

### Manual Testing Checklist

#### Request Viewing
- [ ] View list of all requests
- [ ] Filter by status (pending, inReview, etc.)
- [ ] Filter by type (newProduct, updateProduct, etc.)
- [ ] Filter by priority
- [ ] Sort by date, priority, status
- [ ] Pagination works correctly
- [ ] Real-time updates when new request added

#### Request Details
- [ ] View all request fields correctly
- [ ] Photos display properly
- [ ] Photo zoom/lightbox works
- [ ] Tagged product link works (for corrections)
- [ ] Submitter information displays
- [ ] Issue details show correctly
- [ ] Admin notes display

#### Actions
- [ ] Change status dropdown works
- [ ] Assign to admin works
- [ ] Add admin note works
- [ ] Add labels/tags works
- [ ] Update priority works
- [ ] Approve button works
- [ ] Reject with reason works
- [ ] Complete request works

#### Edge Cases
- [ ] Handle missing photos
- [ ] Handle missing optional fields
- [ ] Handle very long product names
- [ ] Handle special characters
- [ ] Handle multiple admin notes
- [ ] Handle requests without submitter info

---

## 📚 Additional Resources

### Related Documentation
- [Product Request System Design](./PRODUCT_REQUEST_SYSTEM_DESIGN.md) - High-level system design
- [Product Request Architecture](./PRODUCT_REQUEST_ARCHITECTURE.md) - Technical architecture
- [Firebase Integration Guide](./PRODUCT_REQUEST_FIREBASE_COMPLETE.md) - Mobile app integration

### Code References
- **Models**: `lib/models/product_request_model.dart`
- **Service**: `lib/services/product_request/product_request_api.dart`
- **UI Widget**: `lib/widgets/product_request/product_request_sheet.dart`
- **Request Center**: `lib/Screens/requests/request_center_screen.dart`
- **Product Details**: `lib/Screens/modern_product_details_screen.dart`

### Firebase Console
- **Firestore**: `https://console.firebase.google.com/project/{project-id}/firestore`
- **Storage**: `https://console.firebase.google.com/project/{project-id}/storage`
- **Rules**: Configure in Firebase Console → Firestore/Storage → Rules tab

---

## 🆘 Support & Questions

For questions or issues regarding the product request system:
1. Review this documentation thoroughly
2. Check the mobile app implementation for reference
3. Test queries in Firebase Console first
4. Contact the mobile development team for clarification

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Maintained By**: Shopple Development Team
