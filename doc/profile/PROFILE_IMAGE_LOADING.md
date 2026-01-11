# Profile Image Loading & Caching

This document explains the unified profile image architecture used across Friends, Chats, and Shopping Lists to keep avatars fast, consistent, and cost‑efficient.

## Overview

We standardized on a single avatar widget and a centralized user profile stream/cache:

- UnifiedProfileAvatar: one widget for displaying user avatars everywhere
- UserProfileStreamService: one source of truth for user profile data (Firestore), with in‑memory deduplication and short‑TTL caching
- Optimized image bytes via CachedNetworkImage (behind the avatar widget)
- PresenceService integration for online indicators (optional)
- Targeted prefetch at screen entry points to avoid flicker and reduce network round‑trips

## Components

1) UnifiedProfileAvatar (lib/widgets/unified_profile_avatar.dart)
- Input: userId, radius, enableCache
- Fetches the user’s profile doc (name, photoUrl, fallback avatar + background pattern)
- Listens to UserProfileStreamService so multiple widgets for the same user reuse one stream
- Uses CachedNetworkImage internally; supports optimistic updates (e.g., after edit)

2) UserProfileStreamService (lib/services/user/user_profile_stream_service.dart)
- API
  - watchUser(String userId) → Stream<Map<String, dynamic>?>
  - prefetchUsers(Iterable<String> userIds)
  - clearUser(String userId), clearAll()
- Behavior
  - Single Firestore listener per user across the app (deduplicated)
  - Broadcasts to all listeners
  - 5‑minute in‑memory TTL cache to minimize reads while keeping data fresh

3) PresenceService (lib/services/presence/presence_service.dart)
- RTDB-driven presence with Firestore mirrors
- Avatars can render an optional green dot using PresenceService.getUserPresenceStream(userId)

## Where it’s used

- Friends
  - FriendTile shows UnifiedProfileAvatar with optional presence
  - Friends list prefetches visible user profiles on load
- Chat
  - ChatChannelTile: DM tiles use UnifiedProfileAvatar for the other participant; prefetches partner profile while listing
  - ChatConversationScreen: App bar and message avatars use UnifiedProfileAvatar; prefetch fired on open
  - NewChatScreen/ChatUserTile: search results and user rows use UnifiedProfileAvatar with presence; prefetch on results
- Shopping Lists
  - Owner/member avatars on list cards and in the assign-people grid use UnifiedProfileAvatar
  - Prefetch occurs for visible list cards and filtered users in the grid

## Usage tips

- Prefer UnifiedProfileAvatar everywhere you show a user image; pass userId and an appropriate radius
- For better UX, prefetch userIds you know will be shown imminently (e.g., visible rows)
- If switching accounts or doing profile edits, call clearUser/clearAll sparingly (only when needed)

## Benefits

- Consistent image behavior and UX (no flicker, unified fallbacks)
- Less network and fewer Firestore listeners (deduped stream + TTL cache)
- Instant updates propagate everywhere (edit avatar/background once)

## Troubleshooting

- No avatar showing: ensure the userId is correct and the profile doc includes either a valid photoUrl or fallback fields
- Slow avatar loading: verify prefetch is called at the screen’s list-building phase; check for missing network connectivity
- Presence dot not updating: confirm PresenceService is configured and you subscribe using the correct userId
