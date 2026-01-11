# 🚨 Deprecated Profile Widgets - Migration Guide

**Date: July 27, 2025**

## Overview

The following profile picture widgets have been **deprecated** and replaced with a single unified component that provides all functionality with improved performance, caching, and consistency.

## Deprecated Widgets (DO NOT USE)

### 1. ❌ ProfileAvatar
- **File**: `lib/widgets/profile_avatar.dart`
- **Status**: DEPRECATED & COMMENTED OUT
- **Original Use**: Basic profile pictures in dashboard

### 2. ❌ RealtimeProfilePictureWidget  
- **File**: `lib/widgets/realtime_profile_picture_widget.dart`
- **Status**: DEPRECATED & COMMENTED OUT
- **Original Use**: Real-time profile pictures with advanced features

### 3. ❌ EnhancedProfilePictureWidget
- **File**: `lib/widgets/enhanced_profile_picture_widget.dart` 
- **Status**: DEPRECATED & COMMENTED OUT
- **Original Use**: Profile editing with upload capabilities

## ✅ New Unified Solution

### UnifiedProfileAvatar
- **File**: `lib/widgets/unified_profile_avatar.dart`
- **Status**: ACTIVE - Use this for all profile picture needs

## Migration Instructions

### Replace ProfileAvatar with:
```dart
// OLD (deprecated)
ProfileAvatar(
  radius: 25,
  showBorder: true,
  onTap: () => {},
)

// NEW (unified)
UnifiedProfileAvatar(
  radius: 25,
  showBorder: true,
  onTap: () => {},
)
```

### Replace RealtimeProfilePictureWidget with:
```dart
// OLD (deprecated)
RealtimeProfilePictureWidget(
  size: 50,
  isEditable: false,
  borderRadius: BorderRadius.circular(10),
)

// NEW (unified)
UnifiedProfileAvatar(
  radius: 25, // size / 2
  isEditable: false,
  borderRadius: BorderRadius.circular(10),
)
```

### Replace EnhancedProfilePictureWidget with:
```dart
// OLD (deprecated)
EnhancedProfilePictureWidget(
  size: 120,
  isEditable: true,
  onImageUpdated: () => {},
)

// NEW (unified)
UnifiedProfileAvatar(
  radius: 60, // size / 2
  isEditable: true,
  onImageUpdated: () => {},
)
```

## Benefits of UnifiedProfileAvatar

✅ **Smart Caching** - 5-minute cache prevents flickering  
✅ **Consistent UI** - Same appearance across all screens  
✅ **Full Editing** - Camera, gallery, avatar selection, remove options  
✅ **Error Handling** - Robust error handling with fallbacks  
✅ **Performance** - Optimized for better performance  
✅ **Maintainability** - Single component to maintain  
✅ **Flexibility** - Supports all use cases from original widgets  

## Features Included

- ✅ Real-time Firebase updates
- ✅ Custom image uploads (camera/gallery)
- ✅ Default avatar selection with backgrounds  
- ✅ Profile picture removal
- ✅ Loading states with progress indicators
- ✅ Smart image URL resolution (5-tier priority system)
- ✅ Background pattern support
- ✅ Widget lifecycle management
- ✅ Flexible border and decoration options
- ✅ Parent notification callbacks

## Search & Replace Recommendations

When migrating your codebase:

1. **Find all imports**:
   - Search: `import.*profile_avatar.dart`
   - Replace: `import 'package:shopple/widgets/unified_profile_avatar.dart'`

2. **Find widget usage**:
   - Search: `ProfileAvatar\(` → Replace with `UnifiedProfileAvatar(`
   - Search: `RealtimeProfilePictureWidget\(` → Replace with `UnifiedProfileAvatar(`  
   - Search: `EnhancedProfilePictureWidget\(` → Replace with `UnifiedProfileAvatar(`

3. **Update parameter names**:
   - `size: X` → `radius: X/2` (divide size by 2)
   - All other parameters should work as-is

## Important Notes

⚠️ **Do not delete** the deprecated files yet - they are commented out for reference  
⚠️ **Test thoroughly** after migration to ensure all functionality works  
⚠️ **Update imports** in all files that reference the old widgets  
⚠️ **Check parameter mappings** especially size vs radius  

## Files Status

| File | Status | Action Needed |
|------|--------|---------------|
| `profile_avatar.dart` | 🔒 Commented Out | Update imports & usage |
| `realtime_profile_picture_widget.dart` | 🔒 Commented Out | Update imports & usage |  
| `enhanced_profile_picture_widget.dart` | 🔒 Commented Out | Update imports & usage |
| `unified_profile_avatar.dart` | ✅ Active | Use this going forward |

---

**Migration Complete**: All profile picture functionality is now consolidated into `UnifiedProfileAvatar` with enhanced features and better performance.
