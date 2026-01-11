# Self-Healing Chat User Mechanism

## Overview
This document describes the "Self-Healing" mechanism implemented to resolve issues where users exist in Firebase Auth/Firestore but are missing from the Stream Chat backend, causing crashes when attempting to start a chat.

## The Problem
Previously, if a user was created in Firebase but failed to sync to Stream Chat (due to network issues, timeouts, or legacy data), any attempt to start a chat with them would fail. This often resulted in:
- App crashes when opening a chat channel.
- "User not found" errors.
- Inability to message specific friends.

## The Solution
We implemented a robust, two-layer solution to ensure Stream Chat users are always available when needed.

### 1. Cloud Functions (Server-Side)
We added two new Cloud Functions in `functions/index.js` (deployed to `asia-south1`):

*   **`createStreamUser` (Trigger)**:
    *   **Type**: `onUserCreated` (Auth Trigger).
    *   **Action**: Automatically creates a Stream Chat user whenever a new user signs up via Firebase Auth.
    *   **Benefit**: Prevents the issue for all new users going forward.

*   **`ensureStreamUser` (Callable)**:
    *   **Type**: `onCall` (Callable Function).
    *   **Action**: Accepts a `userId`, fetches their profile securely from Firestore, and upserts them into Stream Chat.
    *   **Benefit**: Acts as a repair tool for existing users who are missing from Stream Chat.

### 2. App Integration (Client-Side)
We updated `ChatRepository` in `lib/services/chat/chat_repository.dart` to use these functions intelligently.

*   **`_ensureUserExists(String userId)`**:
    *   Before creating or accessing a chat channel, the app checks if the target user exists in Stream Chat.
    *   **If missing**: It calls the `ensureStreamUser` Cloud Function.
    *   **Result**: The user is "repaired" on the fly, and the chat opens successfully without the user noticing any error.

### 3. Configuration
The Cloud Functions require Stream Chat credentials to be set in the environment.
*   **File**: `functions/.env`
*   **Variables**:
    *   `STREAM_API_KEY`
    *   `STREAM_API_SECRET`

## Implementation Details

### Cloud Function (`functions/index.js`)
```javascript
export const ensureStreamUser = onCall({ region: "asia-south1" }, async (request) => {
    // 1. Validate Auth & Inputs
    // 2. Fetch User Profile from Firestore
    // 3. Upsert User to Stream Chat using Server SDK
    // 4. Return Success
});
```

### Flutter Repository (`ChatRepository`)
```dart
Future<bool> _ensureUserExists(String userId) async {
  // 1. Check local/client-side if user exists
  // 2. If not, call Cloud Function
  await FirebaseFunctions.instanceFor(region: 'asia-south1')
      .httpsCallable('ensureStreamUser')
      .call({'userId': userId});
  return true;
}
```

## Verification
To verify the fix works:
1.  Identify a user who is missing from Stream Chat (or use a test account).
2.  Attempt to open a chat with them in the app.
3.  Observe the logs:
    *   `User ... not found in Stream Chat, attempting to create...`
    *   `Successfully repaired/created user ... via Cloud Function`
4.  The chat screen should open normally.
