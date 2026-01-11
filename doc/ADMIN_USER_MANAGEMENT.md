# Admin Implementation Guide: User Management

This guide explains how to implement the backend logic in the Shopple Admin panel to manage user status (Ban, Block, Force Logout).

## Data Structure

The mobile app listens to the `users/{uid}` document in Firestore.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `isBanned` | boolean | Set to `true` to ban the user. |
| `banReason` | string | The reason for the ban (displayed to the user). |
| `banExpiresAt` | timestamp | (Optional) When the ban expires. |
| `forceLogoutAt` | timestamp | Update this timestamp to force the user to log out immediately. |

## Implementation Steps (Admin Panel)

### 1. Ban User

To ban a user, update their Firestore document:

```javascript
// Example using Firebase Admin SDK (Node.js)
await firestore.collection('users').doc(userId).update({
  isBanned: true,
  banReason: 'Violation of community guidelines',
  banExpiresAt: admin.firestore.Timestamp.fromDate(new Date('2024-12-31')), // Optional
});
```

### 2. Unban User

To unban a user:

```javascript
await firestore.collection('users').doc(userId).update({
  isBanned: false,
  banReason: admin.firestore.FieldValue.delete(),
  banExpiresAt: admin.firestore.FieldValue.delete(),
});
```

### 3. Force Logout

To force a user to log out (e.g., for security reasons), update the `forceLogoutAt` timestamp to the current time:

```javascript
await firestore.collection('users').doc(userId).update({
  forceLogoutAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

## App Behavior

- **Ban:** When `isBanned` becomes `true`, the app immediately signs the user out and displays a non-dismissible dialog with the ban reason and expiration. It also provides a "Contact Support" button.
- **Force Logout:** When `forceLogoutAt` changes, the app detects the change and signs the user out, displaying a snackbar message.

## Notes

- Ensure the Admin panel has the necessary permissions to write to the `users` collection.
- The app uses `UserStatusService` to listen for these changes in real-time.
