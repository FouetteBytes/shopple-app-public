Firestore Rules Draft (Shopping Lists Foundation)
------------------------------------------------

High-level goals:
1. A user can fully manage (CRUD) only lists they created (createdBy == request.auth.uid).
2. Items subcollection inherits same ownership; no cross-user access.
3. Basic field validation for writes to prevent malformed docs.
4. Read access restricted to owner (no public lists yet in foundation).

Example rules snippet (merge into main firestore.rules):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function isOwner(data) { return isSignedIn() && data.createdBy == request.auth.uid; }

    // Shopping lists root
    match /shopping_lists/{listId} {
      allow read: if isOwner(resource.data);
      allow create: if isSignedIn() &&
        request.resource.data.createdBy == request.auth.uid &&
        request.resource.data.name is string &&
        request.resource.data.createdAt is timestamp &&
        request.resource.data.updatedAt is timestamp;
      allow update, delete: if isOwner(resource.data);

      // Items subcollection
      match /items/{itemId} {
        allow read: if isOwner(get(/databases/$(database)/documents/shopping_lists/$(listId)).data);
        allow create: if isOwner(get(/databases/$(database)/documents/shopping_lists/$(listId)).data) &&
          request.resource.data.listId == listId &&
          request.resource.data.name is string &&
          request.resource.data.addedAt is timestamp;
        allow update, delete: if isOwner(get(/databases/$(database)/documents/shopping_lists/$(listId)).data);
      }
    }
  }
}
```

Next steps:
- Integrate with existing rules file carefully (avoid overriding unrelated rules).
- Add composite indexes if Firestore suggests (for orderBy + where queries).
- Add rate limiting / doc size constraints in later collaboration phase.
