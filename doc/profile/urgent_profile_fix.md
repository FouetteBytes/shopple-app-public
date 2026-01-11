# 🚨 URGENT: Profile Data Still Not Loading - Critical Fix Needed

## 📱 **CURRENT PROBLEM (From Screenshots)**

**The profile page is STILL showing:**
- **"User"** instead of the actual user's name  
- **"No email available"** instead of the phone number for phone users

**This means the previous implementation did NOT work. We need to fix the core data loading issue immediately.**

## 🔍 **ROOT CAUSE ANALYSIS REQUIRED**

**BEFORE writing any code, you MUST investigate:**

### **Step 1: Check if User Data Exists in Firestore**
1. **Open Firebase Console** → **Firestore Database**
2. **Navigate to `users` collection**
3. **Find the current user's document** (use their UID from Firebase Auth)
4. **Check what data is actually stored:**
   ```
   Expected for Phone Users:
   {
     "uid": "xxx",
     "firstName": "John",
     "lastName": "Doe", 
     "phoneNumber": "+1234567890",
     "signInMethod": "phone",
     "isProfileComplete": true
   }
   ```

### **Step 2: Verify Profile Screen Code**
1. **Find the profile screen file** (likely `lib/Screens/Profile/profile_screen.dart` or similar)
2. **Check if it's actually reading from Firestore**
3. **Look for StreamSubscription or StreamBuilder code**
4. **Verify the document path is correct**

### **Step 3: Check Console Logs**
1. **Run the app in debug mode**
2. **Navigate to profile screen**
3. **Look for any error messages in console**
4. **Check if Firestore queries are executing**

## 🔧 **IMMEDIATE FIX IMPLEMENTATION**

**If user data EXISTS in Firestore but profile shows generic data:**

### **Replace the entire profile screen with this working code:**

```dart
// File: lib/Screens/Profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a), // Dark background
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1a1a),
        title: Text("Profile", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error loading profile", style: TextStyle(color: Colors.red)),
                  Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No user data found", style: TextStyle(color: Colors.red)),
                  Text("Document path: users/${currentUser.uid}", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ElevatedButton(
                    onPressed: () {
                      // Create a basic user document
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .set({
                        'uid': currentUser.uid,
                        'email': currentUser.email,
                        'phoneNumber': currentUser.phoneNumber,
                        'displayName': currentUser.displayName,
                        'signInMethod': 'unknown',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    },
                    child: Text("Create Profile"),
                  ),
                ],
              ),
            );
          }

          // User data exists - display it
          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.cyan.shade300,
                  backgroundImage: userData['photoURL'] != null 
                      ? NetworkImage(userData['photoURL'])
                      : null,
                  child: userData['photoURL'] == null
                      ? Text(
                          _getUserInitial(userData),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                
                SizedBox(height: 20),
                
                // User Name
                Text(
                  _getDisplayName(userData),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Contact Info
                Text(
                  _getPrimaryContact(userData),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Edit Button
                OutlinedButton(
                  onPressed: () {
                    // Navigate to edit screen
                  },
                  child: Text("Edit", style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Debug Info (REMOVE AFTER TESTING)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DEBUG INFO:", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("UID: ${currentUser.uid}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Sign-in Method: ${userData['signInMethod'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("First Name: ${userData['firstName'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Last Name: ${userData['lastName'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Phone: ${userData['phoneNumber'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Email: ${userData['email'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Display Name: ${userData['displayName'] ?? 'not set'}", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Rest of your existing profile UI (Show me as away, My Projects, etc.)
                _buildProfileOptions(),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _getDisplayName(Map<String, dynamic> userData) {
    // For Google users
    if (userData['signInMethod'] == 'google' && userData['displayName'] != null) {
      return userData['displayName'];
    }
    
    // For phone/email users - use collected name
    String firstName = userData['firstName'] ?? '';
    String lastName = userData['lastName'] ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    if (firstName.isNotEmpty) return firstName;
    if (lastName.isNotEmpty) return lastName;
    
    // Fallback
    return userData['displayName'] ?? 'User';
  }
  
  String _getPrimaryContact(Map<String, dynamic> userData) {
    String? signInMethod = userData['signInMethod'];
    
    switch (signInMethod) {
      case 'phone':
        return userData['phoneNumber'] ?? 'No phone available';
      case 'google':
      case 'email':
        return userData['email'] ?? 'No email available';
      default:
        // Show whatever is available
        if (userData['phoneNumber'] != null) return userData['phoneNumber'];
        if (userData['email'] != null) return userData['email'];
        return 'No contact info';
    }
  }
  
  String _getUserInitial(Map<String, dynamic> userData) {
    String displayName = _getDisplayName(userData);
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }
  
  Widget _buildProfileOptions() {
    return Column(
      children: [
        _buildProfileOption(Icons.directions_walk, "Show me as away", true),
        _buildProfileOption(Icons.work, "My Projects", false),
        _buildProfileOption(Icons.group_add, "Join A Team", false),
        _buildProfileOption(Icons.share, "Share Profile", false),
        _buildProfileOption(Icons.assignment, "All My Task", false),
        Container(
          margin: EdgeInsets.only(top: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 12),
                  Text("Security Settings", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Auto Logout", style: TextStyle(color: Colors.white)),
                      Text("Logout when inactive for security", 
                           style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileOption(IconData icon, String title, bool hasToggle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          if (hasToggle)
            Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.blue,
            ),
        ],
      ),
    );
  }
}
```

## 🚨 **IF USER DATA DOESN'T EXIST IN FIRESTORE**

**This means the registration process isn't saving data properly. You need to:**

### **Find and Fix the Registration/Data Collection Code:**

1. **Find where user enters their name** (data collection screen)
2. **Check if the save/submit button actually saves to Firestore**
3. **Look for code like:**
   ```dart
   FirebaseFirestore.instance.collection('users').doc(uid).set({...})
   ```

### **Add Debug Logging to Registration:**
```dart
// Add this to your data collection save method
Future<void> _saveUserData() async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print("DEBUG: Saving user data for UID: ${currentUser.uid}");
      
      Map<String, dynamic> userData = {
        'uid': currentUser.uid,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phoneNumber': currentUser.phoneNumber,
        'email': currentUser.email,
        'signInMethod': 'phone', // or detect dynamically
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print("DEBUG: Data to save: $userData");
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(userData);
      
      print("DEBUG: Data saved successfully!");
      
    }
  } catch (e) {
    print("DEBUG: Error saving user data: $e");
  }
}
```

## 📋 **IMMEDIATE ACTION PLAN**

1. **Replace profile screen code** with the working version above
2. **Test the profile screen** - check if debug info shows user data
3. **If data is missing**, fix the registration/data collection process
4. **Remove debug info** once everything works
5. **Test with phone users specifically** to ensure phone numbers show

## 🎯 **SUCCESS CRITERIA**

- **Phone users see**: "John Doe" and "+1234567890" 
- **Email users see**: "Jane Smith" and "jane@example.com"
- **No more "User" or "No email available"**

**This is the core issue that MUST be fixed immediately. Focus only on getting the profile data to load correctly before moving to any other features.**