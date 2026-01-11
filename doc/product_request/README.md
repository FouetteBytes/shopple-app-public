# Product Request System Documentation

## 📖 Overview

The Product Request System is a comprehensive crowdsourcing feature that allows Shopple users to contribute to the product catalog by requesting new products, reporting errors, suggesting updates, and submitting price corrections.

## 🎯 Quick Navigation

### For Admin Board Developers
**START HERE**: [**Admin Board Integration Guide**](./ADMIN_BOARD_INTEGRATION_GUIDE.md)

This comprehensive guide includes:
- ✅ Complete Firebase integration details
- ✅ All four request types documented (newProduct, updateProduct, reportError, priceUpdate)
- ✅ Firestore collection structure and fields
- ✅ Firebase Storage paths and structure
- ✅ Security rules configuration
- ✅ Required admin board features
- ✅ Database access patterns and queries
- ✅ API integration examples
- ✅ Implementation checklist
- ✅ Testing guidelines

### For Mobile Developers
- [Firebase Integration Complete](./PRODUCT_REQUEST_FIREBASE_COMPLETE.md) - Mobile app Firebase integration
- [Flutter Integration](./PRODUCT_REQUEST_FLUTTER_INTEGRATION.md) - UI components and widgets
- [Implementation Summary](./PRODUCT_REQUEST_IMPLEMENTATION_SUMMARY.md) - Quick reference

### Architecture & Design
- [System Architecture](./PRODUCT_REQUEST_ARCHITECTURE.md) - System overview and flow diagrams
- [System Design](./PRODUCT_REQUEST_SYSTEM_DESIGN.md) - Detailed technical design
- [Enhancements Complete](./PRODUCT_REQUEST_ENHANCEMENTS_COMPLETE.md) - Feature enhancements log

### Reference
- [Implementation](./PRODUCT_REQUEST_IMPLEMENTATION.md) - Implementation details
- [Next Steps](./PRODUCT_REQUEST_NEXT_STEPS.md) - Future roadmap

## 🔑 Key Features

### Four Request Types

1. **🆕 New Product Request**
   - Add completely new products to the catalog
   - Include photos, brand, size, store location
   - User-submitted priority levels

2. **🔄 Update Product Request**
   - Suggest updates to existing product information
   - Tag existing products for reference
   - Select specific issues (name, price, size, brand, image)
   - Provide incorrect vs. correct values

3. **🚨 Report Error**
   - Report critical errors in product data
   - Same fields as update request
   - Indicates higher urgency

4. **💰 Price Update Request**
   - Report price changes at specific stores
   - Include old and new prices
   - Attach receipt or shelf photos

## 🔥 Firebase Integration

### Firestore Collection
- **Collection**: `product_requests`
- **Security**: Users read/write own requests, admins read/write all
- **Indexes**: Required for filtering by status, type, priority

### Firebase Storage
- **Path**: `product-requests/{requestId}/`
- **Files**: Up to 5 photos per request
- **Format**: `photo_{timestamp}_{index}.jpg`
- **Size Limit**: 5MB per photo

## 🎨 Admin Board Features

### Required Features
- ✅ Request listing with filters (status, type, priority, date)
- ✅ Real-time updates via Firestore snapshots
- ✅ Detailed request view with all fields
- ✅ Photo gallery with zoom/download
- ✅ Status management workflow
- ✅ Admin notes and comments
- ✅ Assign to admin functionality
- ✅ Labels/tags system
- ✅ Dashboard statistics
- ✅ Bulk actions support

### Status Workflow
```
pending → inReview → approved → completed
            ↓
        rejected
```

## 📊 Data Model Summary

### Core Fields
- `requestType`: newProduct | updateProduct | reportError | priceUpdate
- `status`: pending | inReview | approved | completed | rejected
- `priority`: low | normal | high
- `productName`: Required product name
- `taggedProductId`: For corrections, reference to existing product
- `issue`: Issue details with incorrect/correct values
- `photoUrls`: Array of Firebase Storage URLs
- `submittedBy`: User information
- `adminNotes`: Admin comments array
- `createdAt`, `updatedAt`: Timestamps

## 🔐 Security

### Current Rules
- Users can read/write their own requests
- Authenticated users only

### Required Admin Rules
- Admins need read/write access to all requests
- Admin custom claim: `request.auth.token.admin == true`
- Storage rules need to be added for `product-requests/` path

## 🚀 Getting Started (Admin Board)

1. **Read**: [Admin Board Integration Guide](./ADMIN_BOARD_INTEGRATION_GUIDE.md)
2. **Setup**: Configure Firebase Admin SDK
3. **Implement**: Follow the implementation checklist
4. **Test**: Use the testing guidelines
5. **Deploy**: Update security rules in Firebase Console

## 📱 Mobile App Access Points

Users can submit product requests from:
1. **Dashboard** → Add button → "Request a Product"
2. **Product Details** → "Report Issue" floating button
3. **Request Center** → View and edit their own requests

## 🔗 Related Systems

- **Product Search**: Used for product tagging in correction requests
- **User Management**: Tracks submitter information
- **Analytics**: Tracks request patterns and user contributions

## 📞 Support

For questions or clarification:
- Review the [Admin Board Integration Guide](./ADMIN_BOARD_INTEGRATION_GUIDE.md)
- Check mobile app code for implementation reference
- Test queries in Firebase Console first

---

**Last Updated**: November 2025  
**Maintained By**: Shopple Development Team
