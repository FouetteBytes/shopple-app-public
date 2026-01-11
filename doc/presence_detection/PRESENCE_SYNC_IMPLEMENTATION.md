# Presence Sync Implementation Guide

## 🎯 Problem Solved

**Issue**: Firestore was showing stale presence data (users showing as online when they're actually offline) because it wasn't syncing with the real-time updates from Firebase Realtime Database.

**Solution**: Cloud Functions that automatically sync presence changes from RTDB to Firestore in real-time.

---

## 🏗️ Architecture

```
User Device
    ↓
Firebase Realtime Database
    /status/{uid} { state: 'online'/'offline' }
    ↓
Cloud Function: syncPresenceToFirestore ⚡ [TRIGGERS INSTANTLY]
    ↓
Firestore Updates (batched)
    ├── status/{uid} collection
    └── users/{uid}.presence field
    ↓
Your Flutter App (All Screens)
    ├── Chat Conversation
    ├── Friends List
    ├── Shopping Lists
    └── Messaging
```

---

## 📦 What Was Implemented

### 1. **Cloud Function: syncPresenceToFirestore**
- **Trigger**: Firebase Realtime Database `/status/{uid}` changes
- **Action**: Syncs state to Firestore immediately
- **Updates**:
  - `status/{uid}` collection (primary presence doc)
  - `users/{uid}.presence` field (backward compatibility)

### 2. **Cloud Function: cleanupStalePresence**
- **Schedule**: Every 5 minutes
- **Action**: Safety net to catch any missed offline transitions
- **Process**: Compares RTDB vs Firestore and fixes discrepancies

### 3. **Realtime Database Security Rules**
- **File**: `database.rules.json`
- **Rules**:
  - Anyone authenticated can READ presence
  - Only the user can WRITE their own presence

---

## 🚀 Deployment Instructions

### Option 1: Use the PowerShell Script (Recommended)
```powershell
.\deploy-presence-sync.ps1
```

### Option 2: Manual Deployment
```bash
# Deploy database rules
firebase deploy --only database

# Deploy functions
firebase deploy --only functions:syncPresenceToFirestore,functions:cleanupStalePresence
```

### Option 3: Deploy All Functions
```bash
npm --prefix functions run deploy
```

---

## 📋 Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `functions/index.js` | ✏️ Modified | Added 2 new functions at the end |
| `database.rules.json` | ✨ Created | RTDB security rules |
| `firebase.json` | ✏️ Modified | Added database rules config |
| `deploy-presence-sync.ps1` | ✨ Created | Deployment helper script |

---

## 🔍 How It Works

### Real-Time Sync Flow

1. **User Opens App**
   ```
   PresenceService.initialize() called
   → Sets up RTDB listener on .info/connected
   → Writes to /status/{uid} { state: 'online' }
   ```

2. **Cloud Function Triggers**
   ```
   syncPresenceToFirestore detects change
   → Reads RTDB data
   → Writes to Firestore batch:
      - status/{uid}.state = 'online'
      - users/{uid}.presence.state = 'online'
   ```

3. **User Goes Offline**
   ```
   RTDB onDisconnect() triggers
   → /status/{uid} { state: 'offline' }
   → Cloud Function syncs to Firestore
   → UI updates instantly (green dot → gray dot)
   ```

### Cleanup Process (Every 5 Minutes)

```
cleanupStalePresence runs
→ Queries Firestore for online users
→ Checks each against RTDB
→ If mismatch found:
   - Marks as offline in Firestore
   - Updates users document
```

---

## 🧪 Testing

### Before Deployment (Current Issue)
```
1. User A opens app → Shows online ✅
2. User A closes app → RTDB marks offline ✅
3. Firestore → Still shows online ❌
4. User B sees User A as "Online" (WRONG) ❌
```

### After Deployment (Fixed)
```
1. User A opens app → Shows online ✅
2. User A closes app → RTDB marks offline ✅
3. Cloud Function syncs → Firestore marks offline ✅
4. User B sees User A as "Offline" (CORRECT) ✅
5. Sync happens in < 1 second ⚡
```

### Manual Test Steps

1. **Deploy the functions**
   ```bash
   .\deploy-presence-sync.ps1
   ```

2. **Open Firebase Console**
   - Go to Realtime Database
   - Navigate to `/status/{your-uid}`

3. **Test in your app**
   - Open the app → Check RTDB shows "online"
   - Close the app → Check RTDB shows "offline"
   - Open Firestore Console
   - Check `status/{your-uid}` matches RTDB

4. **Test with 2 devices**
   - Device A: Login as User A
   - Device B: Login as User B
   - Device B: Open Friends or Chat
   - Device A: Close app
   - Device B: Should see User A go offline within 1-2 seconds

---

## 📊 Cost Estimation

### Cloud Function Invocations
- **syncPresenceToFirestore**: 2 invocations per user session
  - 1x on connect (online)
  - 1x on disconnect (offline)
- **cleanupStalePresence**: 12 invocations per hour
  - Scheduled every 5 minutes

### For 1000 Active Users/Day
```
syncPresenceToFirestore:
  1000 users × 2 sessions/day × 2 calls = 4,000 calls/day
  4,000 × 30 days = 120,000 calls/month

cleanupStalePresence:
  12 calls/hour × 24 hours × 30 days = 8,640 calls/month

Total: ~129,000 invocations/month
Free Tier: 2,000,000 invocations/month ✅
Cost: $0 (well within free tier)
```

### Firestore Writes
```
Each presence change = 2 writes (status + users doc)
1000 users × 2 sessions/day × 2 writes = 4,000 writes/day
4,000 × 30 = 120,000 writes/month

Free Tier: 20,000 writes/day
Cost: Minimal (few cents if any)
```

---

## 🛡️ Security

### Realtime Database Rules
```json
{
  "rules": {
    "status": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

**What this means**:
- ✅ Any authenticated user can READ presence
- ✅ Users can only WRITE their own presence
- ❌ Anonymous users cannot read/write
- ❌ Users cannot modify others' presence

---

## 🐛 Troubleshooting

### Function Not Triggering

**Check 1: Is function deployed?**
```bash
firebase functions:list
# Should show: syncPresenceToFirestore
```

**Check 2: Check function logs**
```bash
firebase functions:log --only syncPresenceToFirestore
```

**Check 3: Verify RTDB writes are happening**
```
Firebase Console → Realtime Database → /status/{uid}
Should update when user connects/disconnects
```

### Firestore Not Updating

**Check 1: Function permissions**
```
Functions should have admin access (default for Firebase Admin SDK)
```

**Check 2: Check for errors in logs**
```bash
firebase functions:log --only syncPresenceToFirestore --limit 50
```

**Check 3: Manual trigger test**
```
Firebase Console → Realtime Database
→ Manually edit /status/{uid}/state to 'offline'
→ Check Firestore updates within 1-2 seconds
```

---

## 🔄 Data Flow Diagram

```
┌─────────────────┐
│  Flutter App    │
│  (User Device)  │
└────────┬────────┘
         │
         │ PresenceService.initialize()
         ↓
┌────────────────────────┐
│ Firebase RTDB          │
│ /status/{uid}          │
│ { state: 'online' }    │ ← .info/connected listener
└────────┬───────────────┘
         │
         │ RTDB Trigger (instant)
         ↓
┌───────────────────────────────┐
│ Cloud Function                │
│ syncPresenceToFirestore       │
│ - Reads RTDB data             │
│ - Writes to Firestore batch   │
└────────┬──────────────────────┘
         │
         │ Batch Write
         ↓
┌────────────────────────────────┐
│ Firestore                      │
│ ├─ status/{uid}                │
│ │  { state: 'online' }         │
│ └─ users/{uid}.presence        │
│    { state: 'online' }         │
└────────┬───────────────────────┘
         │
         │ StreamBuilder listens
         ↓
┌─────────────────────────────────┐
│ Flutter UI (All Screens)        │
│ ├─ Chat: Green dot              │
│ ├─ Friends: "Online" text       │
│ └─ Shopping: Active indicator   │
└─────────────────────────────────┘
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] Functions deployed successfully
- [ ] Database rules deployed
- [ ] RTDB `/status/{uid}` updates on connect/disconnect
- [ ] Firestore `status/{uid}` syncs within 1-2 seconds
- [ ] Firestore `users/{uid}.presence` updates
- [ ] UI shows correct online/offline status
- [ ] Cleanup function runs (check logs after 5 minutes)
- [ ] No errors in function logs

---

## 📚 Additional Resources

- [Firebase Presence Documentation](https://firebase.google.com/docs/firestore/solutions/presence)
- [Firebase Functions Triggers](https://firebase.google.com/docs/functions/database-events)
- [Realtime Database Security Rules](https://firebase.google.com/docs/database/security)

---

## 🎉 Success Indicators

You'll know it's working when:

1. **Friends List**: Shows "Online" only for truly online users
2. **Chat Screen**: Green dot appears/disappears instantly
3. **User goes offline**: Status updates within 1-2 seconds
4. **No ghost "online" status**: Strivio won't show online when offline
5. **Function logs**: Show successful syncs

---

**Deployment Date**: November 8, 2025  
**Status**: Ready to Deploy  
**Next Step**: Run `.\deploy-presence-sync.ps1`
