# Firebase Session Management

## How Sessions are Maintained

Firebase Authentication manages user sessions using **ID Tokens** and **Refresh Tokens**.

1.  **Login:** When a user signs in (Email/Password, Google, etc.), Firebase issues a short-lived **ID Token** (valid for 1 hour) and a long-lived **Refresh Token**.
2.  **Persistence:** The Firebase SDK automatically persists these tokens on the device (e.g., in Keychain on iOS, Keystore on Android).
3.  **Token Refresh:** The SDK automatically uses the Refresh Token to get a new ID Token whenever the current one expires (every hour). This happens in the background without user intervention.
4.  **Session Duration:** The session persists indefinitely until:
    *   The user explicitly signs out (`auth.signOut()`).
    *   The user is deleted or disabled in the Firebase Console.
    *   The Refresh Token is revoked (e.g., password change, or admin revocation).

## Gmail Auto-Logout Issue

The issue with Gmail auto-logout not syncing correctly upon re-login was likely due to the local `GoogleSignIn` instance retaining a stale session.

**Fix Implemented:**
We now force a local sign-out of the `GoogleSignIn` instance *before* initiating a new sign-in flow. This ensures that the user is prompted to select their account again, or at least that a fresh authentication token is retrieved from Google, preventing the app from using cached, potentially invalid credentials.

```dart
// In AuthService.signInWithGoogle
await _googleSignIn.signOut(); // Force clear local Google session
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
```
