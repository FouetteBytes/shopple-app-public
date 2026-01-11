# 🔥 Firebase Remote Config - Simple Setup Guide

## 📋 What is Remote Config?

Firebase Remote Config lets you **control AI features remotely** without releasing app updates:
- ✅ Turn features ON/OFF instantly
- ✅ Test with specific users
- ✅ Gradual rollouts (5% → 25% → 50% → 100%)
- ✅ A/B testing different features

**When features are disabled, users see a beautiful "Coming Soon" animation! 🚀**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project: **shopple-7a67b**
3. Click **"Remote Config"** in the left sidebar (under "Engage")

### Step 2: Add These 5 Parameters

Click **"Add parameter"** button, then add each one below:

---

## 🤖 AI Feature Flags (Add These 5)

### 1️⃣ AI Shopping Agent (Main Feature)
```
Parameter key: ai_shopping_agent_enabled
Data type: Boolean
Default value: true
Description: Main AI chat assistant for product suggestions
```
**What it does**: The floating AI assistant that helps users find products

---

### 2️⃣ AI Voice Assistant
```
Parameter key: ai_voice_assistant_enabled
Data type: Boolean
Default value: false
Description: Voice commands and speech-to-text shopping
```
**What it does**: Voice-activated shopping (say "Add milk to my list")

---

### 3️⃣ AI Price Predictor
```
Parameter key: ai_price_predictor_enabled
Data type: Boolean
Default value: false
Description: ML-powered price predictions and best time to buy alerts
```
**What it does**: Shows price trends and predicts when to buy

---

### 4️⃣ AI Smart Categorization
```
Parameter key: ai_smart_categorization_enabled
Data type: Boolean
Default value: false
Description: Auto-categorize products using machine learning
```
**What it does**: Automatically sorts products into categories

---

### 5️⃣ AI Recipe Suggestions
```
Parameter key: ai_recipe_suggestions_enabled
Data type: Boolean
Default value: false
Description: Recipe-based meal planning and ingredient lists
```
**What it does**: Suggests recipes and generates shopping lists from them

---

## ✅ Step 3: Publish Changes

1. After adding all 5 parameters, click **"Publish changes"** at the top
2. Confirm the publish
3. Done! 🎉

---

## 🎨 How to Add a Parameter (Detailed)

1. In Firebase Console → Remote Config
2. Click **"Add parameter"**
3. Fill in:
   - **Parameter key**: Copy exactly from above (e.g., `ai_shopping_agent_enabled`)
   - **Data type**: Select "Boolean"
   - **Default value**: Choose `true` or `false`
   - **Description**: Copy from above (optional but helpful)
4. Click **"Add parameter"**
5. Repeat for all 5 parameters

---

## 🎯 Advanced: Gradual Rollout (Optional)

Want to test a feature with 10% of users first? Here's how:

### Enable for 10% of Users:
1. In Firebase Console → Remote Config
2. Click on a parameter (e.g., `ai_voice_assistant_enabled`)
3. Click **"Add value for condition"**
4. Click **"Define new condition"**
5. Set:
   - Name: `10_percent_rollout`
   - Applies if: **"User in random percentile" <= 10**
6. Set value to `true`
7. Publish changes

Now 10% of users will see the feature enabled!

### Increase to 50% Later:
- Edit the condition
- Change `<= 10` to `<= 50`
- Publish

---

## 💻 Already Integrated in Your App!

The code is already in your app! Here's how to use it:

### How to Check if a Feature is Enabled

```dart
import 'package:shopple/services/feature_flags/remote_config_service.dart';
import 'package:shopple/widgets/ai/ai_feature_coming_soon.dart';

class AIFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigService();
    
    // Check if AI Voice is enabled
    if (!config.aiVoiceAssistantEnabled) {
      // Show "Coming Soon" animation
      return AIFeatureComingSoon(
        featureName: 'AI Voice Assistant',
        description: 'Voice-activated shopping is coming soon!',
        icon: Icons.mic,
      );
    }
    
    // Feature is enabled - show the actual feature
    return AIVoiceAssistantWidget();
  }
}
```

### All Available Feature Checks

```dart
final config = RemoteConfigService();

// Check each feature
if (config.aiShoppingAgentEnabled) { /* Main AI assistant */ }
if (config.aiVoiceAssistantEnabled) { /* Voice commands */ }
if (config.aiPricePredictorEnabled) { /* Price predictions */ }
if (config.aiSmartCategorizationEnabled) { /* Auto-categorize */ }
if (config.aiRecipeSuggestionsEnabled) { /* Recipe planning */ }
```

---

## 🎬 What Happens When a Feature is Disabled?

When you set a feature flag to `false` in Firebase:

1. **App detects it's disabled** (automatic)
2. **Shows beautiful "Coming Soon" screen** with:
   - ✨ Animated icon
   - 🚀 "COMING SOON" badge with pulse animation
   - 📝 Feature name and description
   - ⭐ Sparkle effects

**No app update needed!** Changes appear within 1 minute in debug mode, 1 hour in production.

---

## 📱 Budget Setting Location (Answered!)

You asked where users can set budgets - here it is:

### Option 1: When Creating a New List
1. Go to **Shopping Lists** screen
2. Tap **"+"** button (Create New List)
3. You'll see **Budget section** with:
   - Budget amount input
   - Cadence chips (One-time, Weekly, Monthly)
   - Period preview

### Option 2: Edit Existing List
1. Open any **Shopping List**
2. Tap **⚙️ Settings** icon (top right)
3. Select **"Edit List Details"**
4. Modify budget amount and cadence

**Files**:
- `lib/widgets/shopping_lists/create_shopping_list_sheet.dart`
- `lib/Screens/shopping_lists/list_detail_screen.dart`

✅ **Budget panel is there and working!**

---

## 🧪 Testing Your Changes

### In Debug Mode:
- Changes appear in **~1 minute**
- Perfect for testing!

### Force Refresh:
```dart
final config = RemoteConfigService();
await config.fetchAndActivate();
```

### Check Current Values:
```dart
final config = RemoteConfigService();
print('Voice enabled: ${config.aiVoiceAssistantEnabled}');
```

---

## 🎯 Best Practices

✅ **DO:**
- Start with features disabled (`false`)
- Test with 10% of users first
- Monitor analytics after enabling
- Use descriptive parameter names

❌ **DON'T:**
- Store secrets in Remote Config (it's public!)
- Change values too frequently
- Enable all features at once
- Forget to publish changes

---

## � Quick Reference

### Feature Flag Names (copy-paste):
```
ai_shopping_agent_enabled
ai_voice_assistant_enabled
ai_price_predictor_enabled
ai_smart_categorization_enabled
ai_recipe_suggestions_enabled
```

### Firebase Console URL:
https://console.firebase.google.com/project/shopple-7a67b/config

---

## 🆘 Need Help?

- **Firebase Docs**: https://firebase.google.com/docs/remote-config
- **Can't find Remote Config?**: Look in sidebar under "Engage" section
- **Changes not appearing?**: Wait 1 min (debug) or 1 hour (production), or force fetch

---

**✅ Setup Complete! Now configure these 5 parameters in Firebase Console.**

**Last Updated**: November 10, 2025
