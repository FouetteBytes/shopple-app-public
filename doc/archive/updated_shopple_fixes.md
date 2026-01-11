# 🔧 Shopple Critical Fixes - Updated Implementation Guide

## 🎯 **CRITICAL ISSUES IDENTIFIED FROM CURRENT APP STATE**

Based on current app analysis and user testing, here are the specific problems that need immediate fixing:

---

## 🔧 **ISSUE 1: Login Page Layout & Button Styling**

### **Problems Identified:**
- Login buttons require scrolling to access (poor UX)
- Top image takes too much screen space
- Buttons don't follow modern app theme and UI standards
- Button styling inconsistent with app design language

### **Solution:**
**Reduce image size and implement modern button theming**

#### **Step 1.1: Fix Layout Proportions**
```dart
// In lib/Screens/Auth/login_selection.dart
class LoginSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaHeight = screenHeight - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // Use existing theme
      body: SafeArea(
        child: Column(
          children: [
            // REDUCED IMAGE SECTION - Only 45% of screen instead of 60%
            Expanded(
              flex: 45, // Reduced from 60
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration image - SMALLER
                    Flexible(
                      child: Image.asset(
                        'assets/images/login_illustration.png',
                        fit: BoxFit.contain,
                        height: safeAreaHeight * 0.35, // Limited height
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Title with proper spacing
                    Text(
                      "Shop, Without, Limits",
                      style: AppTheme.headlineLarge?.copyWith( // Use existing theme
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your personal shopping assistant",
                      style: AppTheme.bodyMedium?.copyWith( // Use existing theme
                        color: AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // FIXED BUTTONS SECTION - 55% of screen, NON-SCROLLABLE
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor, // Use existing theme
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadiusLarge), // Use existing theme
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Top row: Google + Phone side by side
                    Row(
                      children: [
                        // Google Button - MODERN STYLING
                        Expanded(
                          child: CustomButton( // Use existing custom button widget
                            onPressed: () => _signInWithGoogle(),
                            buttonType: ButtonType.secondary, // Use existing button types
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.google,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Google",
                                  style: AppTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFFDB4437), // Google red
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // Phone Button - MODERN STYLING
                        Expanded(
                          child: CustomButton( // Use existing custom button widget
                            onPressed: () => _continueWithPhone(),
                            buttonType: ButtonType.primary, // Use existing button types
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Phone",
                                  style: AppTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Email Button - FULL WIDTH, MODERN STYLING
                    CustomButton( // Use existing custom button widget
                      onPressed: () => _continueWithEmail(),
                      buttonType: ButtonType.primary,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Continue with Email",
                            style: AppTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Existing user login - MODERN TEXT BUTTON
                    TextButton(
                      onPressed: () => _showExistingUserLogin(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                      child: Text(
                        "Already have an account? Login using email",
                        style: AppTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Terms and Privacy - Small text
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "By continuing you agree to Shopple's Terms of Service & Privacy Policy",
                        style: AppTheme.bodySmall?.copyWith(
                          color: AppTheme.tertiaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### **🎨 CRITICAL: Study Existing Button Components**

**BEFORE implementing buttons, MUST study these files in shopple_previous_build:**

1. **Find Custom Button Widget:**
   ```
   shopple_previous_build/lib/widgets/custom_button.dart
   shopple_previous_build/lib/components/buttons/
   ```

2. **Study Theme Implementation:**
   ```
   shopple_previous_build/lib/theme/app_theme.dart
   shopple_previous_build/lib/constants/app_colors.dart
   shopple_previous_build/lib/constants/app_text_styles.dart
   ```

3. **Analyze Button Usage in Other Screens:**
   ```
   shopple_previous_build/lib/screens/ (all files)
   ```

**Use EXACT same button styling, colors, animations, and elevation patterns found in existing codebase.**

---

## 🔧 **ISSUE 2: Profile Completion - Dynamic Progress & DOB Collection**

### **Problems Identified:**
- Progress bar doesn't update dynamically as user fills fields
- Age input is basic - should collect Date of Birth in cool way
- Two redundant headers showing
- Doesn't follow app's UI theme properly

### **Solution:**
**Implement dynamic progress tracking and modern DOB picker**

#### **Step 2.1: Enhanced Profile Completion with Dynamic Progress**
```dart
// In lib/Screens/Auth/data_collection_screen.dart
class DataCollectionScreen extends StatefulWidget {
  final Map<String, dynamic>? prefilledData;
  final List<String>? fieldsToCollect;
  
  const DataCollectionScreen({
    Key? key,
    this.prefilledData,
    this.fieldsToCollect,
  }) : super(key: key);

  @override
  _DataCollectionScreenState createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  
  // Progress tracking
  double _currentProgress = 0.5; // Start at 50% (account created)
  int _completedFields = 0;
  final int _totalFields = 4; // firstName, lastName, DOB, gender
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Add listeners to track progress
    _firstNameController.addListener(_updateProgress);
    _lastNameController.addListener(_updateProgress);
  }
  
  void _updateProgress() {
    int completed = 0;
    
    if (_firstNameController.text.trim().isNotEmpty) completed++;
    if (_lastNameController.text.trim().isNotEmpty) completed++;
    if (_selectedDate != null) completed++;
    if (_selectedGender != null) completed++;
    
    setState(() {
      _completedFields = completed;
      double newProgress = 0.5 + (completed / _totalFields) * 0.5; // 50% to 100%
      
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      
      _currentProgress = newProgress;
      _progressController.forward(from: 0);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // REMOVE REDUNDANT HEADER - Only keep AppBar
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryTextColor,
          ),
        ),
        title: Text(
          "Complete Your Profile",
          style: AppTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _skipProfileCompletion(),
            child: Text(
              "Skip for now",
              style: AppTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // DYNAMIC PROGRESS INDICATOR
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Profile Completion",
                            style: AppTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Text(
                                "${(_progressAnimation.value * 100).round()}%",
                                style: AppTheme.labelLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: AppTheme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                            minHeight: 6,
                          );
                        },
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Account created ✓ • Profile details needed",
                        style: AppTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                Text(
                  "Just a few more details...",
                  style: AppTheme.headlineLarge?.copyWith(
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Help us personalize your shopping experience",
                  style: AppTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // First Name - Use existing text field styling
                CustomTextField( // Use existing custom text field widget
                  controller: _firstNameController,
                  labelText: "First Name",
                  hintText: "Enter your first name",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "First name is required";
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Last Name - Use existing text field styling
                CustomTextField( // Use existing custom text field widget
                  controller: _lastNameController,
                  labelText: "Last Name",
                  hintText: "Enter your last name",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Last name is required";
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // COOL DATE OF BIRTH PICKER
                _buildDOBSelector(),
                
                SizedBox(height: 16),
                
                // Gender Selection - Modern styling
                _buildGenderSelector(),
                
                SizedBox(height: 32),
                
                // Complete Profile Button - Use existing button styling
                CustomButton( // Use existing custom button widget
                  onPressed: _isFormValid() ? () => _saveProfile() : null,
                  buttonType: ButtonType.primary,
                  width: double.infinity,
                  child: Text(
                    "Complete Profile",
                    style: AppTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Skip Button
                TextButton(
                  onPressed: () => _skipProfileCompletion(),
                  child: Text(
                    "I'll complete this later",
                    style: AppTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // COOL DATE OF BIRTH PICKER
  Widget _buildDOBSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: _selectedDate != null 
            ? AppTheme.primaryColor 
            : AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectDateOfBirth(),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.cake_outlined,
                color: _selectedDate != null 
                  ? AppTheme.primaryColor 
                  : AppTheme.secondaryTextColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date of Birth",
                      style: AppTheme.labelMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : "Select your birth date",
                      style: AppTheme.bodyLarge?.copyWith(
                        color: _selectedDate != null
                          ? AppTheme.primaryTextColor
                          : AppTheme.tertiaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedDate != null)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Modern Gender Selector
  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: _selectedGender != null 
            ? AppTheme.primaryColor 
            : AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: _selectedGender != null 
                    ? AppTheme.primaryColor 
                    : AppTheme.secondaryTextColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Gender",
                  style: AppTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                if (_selectedGender != null)
                  Spacer(),
                if (_selectedGender != null)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption("Male"),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildGenderOption("Female"),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildGenderOption("Other"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGenderOption(String gender) {
    bool isSelected = _selectedGender == gender;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
        _updateProgress();
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(
            color: isSelected 
              ? AppTheme.primaryColor 
              : AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          gender,
          style: AppTheme.bodyMedium?.copyWith(
            color: isSelected 
              ? AppTheme.primaryColor 
              : AppTheme.primaryTextColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 25)), // 25 years ago
      firstDate: DateTime.now().subtract(Duration(days: 365 * 100)), // 100 years ago
      lastDate: DateTime.now().subtract(Duration(days: 365 * 13)), // 13 years ago (minimum age)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.primaryTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateProgress();
    }
  }
  
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
  
  bool _isFormValid() {
    return _firstNameController.text.trim().isNotEmpty &&
           _lastNameController.text.trim().isNotEmpty &&
           _selectedDate != null &&
           _selectedGender != null;
  }
}
```

---

## 🔧 **ISSUE 3: Profile Page Data Loading & Display**

### **Problems Identified:**
- Profile page not updating once user is created
- Name, email/phone not showing properly
- Edit section not loading data correctly

### **Solution:**
**Implement proper profile data fetching and real-time updates**

#### **Step 3.1: Enhanced Profile Screen with Real-time Data**
```dart
// In lib/Screens/profile_screen.dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  late StreamSubscription<DocumentSnapshot> _userSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeUserData();
  }
  
  // REAL-TIME USER DATA LISTENING
  void _setupRealtimeUserData() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists && mounted) {
              setState(() {
                _userData = UserModel.fromFirestore(
                  snapshot.data() as Map<String, dynamic>
                );
                _isLoading = false;
                _isRefreshing = false;
              });
            } else if (mounted) {
              setState(() {
                _isLoading = false;
                _isRefreshing = false;
              });
            }
          },
          onError: (error) {
            print('Error listening to user data: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isRefreshing = false;
              });
            }
          },
        );
    }
  }
  
  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Profile",
          style: AppTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _editProfile(),
            icon: Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Picture with edit option
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor,
                          backgroundImage: _userData?.photoURL != null 
                            ? NetworkImage(_userData!.photoURL!)
                            : null,
                          child: _userData?.photoURL == null
                            ? Text(
                                _getUserInitial(),
                                style: AppTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.surfaceColor,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => _changeProfilePicture(),
                              icon: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // User Name - PROPERLY LOADED
                    Text(
                      _getDisplayName(),
                      style: AppTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Primary Contact - BASED ON SIGN-IN METHOD
                    Text(
                      _getPrimaryContact(),
                      style: AppTheme.bodyLarge?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Edit Profile Button
                    CustomButton( // Use existing custom button widget
                      onPressed: () => _editProfile(),
                      buttonType: ButtonType.outline,
                      child: Text(
                        "Edit Profile",
                        style: AppTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Profile Details Section
              if (_userData != null) ...[
                _buildProfileDetailsCard(),
                SizedBox(height: 24),
              ],
              
              // Complete Profile Card (if incomplete)
              if (_userData?.isProfileComplete == false) ...[
                _buildCompleteProfileCard(),
                SizedBox(height: 24),
              ],
              
              // Profile Options
              _buildProfileOptions(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get display name with fallbacks
  String _getDisplayName() {
    if (_userData?.displayName != null && _userData!.displayName!.isNotEmpty) {
      return _userData!.displayName!;
    }
    
    // Try to construct from first/last name
    String firstName = _userData?.firstName ?? "";
    String lastName = _userData?.lastName ?? "";
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return "$firstName $lastName".trim();
    }
    
    // Fallback to email/phone based name
    if (_userData?.email != null) {
      return _userData!.email!.split('@')[0].capitalize();
    }
    
    return "User";
  }
  
  // Get user initial for avatar
  String _getUserInitial() {
    String displayName = _getDisplayName();
    if (displayName.isNotEmpty && displayName != "User") {
      return displayName[0].toUpperCase();
    }
    return "U";
  }
  
  // Get primary contact based on sign-in method - PROPERLY IMPLEMENTED
  String _getPrimaryContact() {
    switch (_userData?.signInMethod) {
      case 'google':
        return _userData?.email ?? "No email available";
      case 'email':
        return _userData?.email ?? "No email available";
      case 'phone':
        return _userData?.phoneNumber ?? "No phone available";
      default:
        // Fallback: show whatever is available
        if (_userData?.email != null) return _userData!.email!;
        if (_userData?.phoneNumber != null) return _userData!.phoneNumber!;
        return "No contact info available";
    }
  }
  
  // Profile details card
  Widget _buildProfileDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Profile Details",
            style: AppTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Show all available details
          if (_userData?.email != null)
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: "Email",
              value: _userData!.email!,
            ),
          
          if (_userData?.phoneNumber != null)
            _buildDetailRow(
              icon: Icons.phone_outlined,
              label: "Phone",
              value: _userData!.phoneNumber!,
            ),
          
          if (_userData?.dateOfBirth != null)
            _buildDetailRow(
              icon: Icons.cake_outlined,
              label: "Date of Birth",
              value: _formatDate(_userData!.dateOfBirth!),
            ),
          
          if (_userData?.gender != null)
            _buildDetailRow(
              icon: Icons.person_outline,
              label: "Gender",
              value: _userData!.gender!,
            ),
          
          _buildDetailRow(
            icon: Icons.login_outlined,
            label: "Sign-in Method",
            value: _getSignInMethodDisplay(),
          ),
          
          _buildDetailRow(
            icon: Icons.date_range_outlined,
            label: "Member Since",
            value: _userData?.createdAt != null 
              ? _formatDate(_userData!.createdAt!)
              : "Unknown",
          ),
        ],
      ),
    );
  }
  
  // Build detail row widget
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Get sign-in method display name
  String _getSignInMethodDisplay() {
    switch (_userData?.signInMethod) {
      case 'google':
        return "Google Account";
      case 'email':
        return "Email & Password";
      case 'phone':
        return "Phone Number";
      default:
        return "Unknown";
    }
  }
  
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
  
  // Refresh profile data
  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // The real-time listener will automatically update the data
    // Just wait a moment for any pending updates
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  
  void _editProfile() {
    // Navigate to edit profile screen with current data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );
  }
}
```

---

## 🔧 **ISSUE 4: State Management - Already Authenticated Users**

### **Problems Identified:**
- Already authenticated users are shown onboarding screens again
- App doesn't remember user login state properly
- This affects phone, email, and Google login users

### **Solution:**
**Implement proper authentication state management**

#### **Step 4.1: Authentication State Handler**
```dart
// In lib/Services/auth_state_service.dart
class AuthStateService {
  static Future<Widget> determineInitialRoute() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        // No user logged in - show onboarding
        return OnboardingScreen();
      }
      
      // User is logged in - check their profile completion status
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
      
      if (!userDoc.exists) {
        // User document doesn't exist - need to create profile
        return DataCollectionScreen();
      }
      
      UserModel userData = UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>
      );
      
      // Check profile completion status
      if (!userData.isProfileComplete && !userData.profileSkipped) {
        // Profile not complete and not skipped - show profile completion
        return DataCollectionScreen(prefilledData: userData.toMap());
      }
      
      if (!userData.hasCompletedOnboarding) {
        // First time after profile completion - show app onboarding
        return AppOnboardingScreen(); // Different from auth onboarding
      }
      
      // User is fully set up - go to main app
      return MainScreen(); // Your main app screen with bottom navigation
      
    } catch (e) {
      print('Error determining initial route: $e');
      // On error, default to onboarding
      return OnboardingScreen();
    }
  }
  
  // Update user's last login and onboarding status
  static Future<void> updateUserLoginState({
    required String uid,
    bool? hasCompletedOnboarding,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (hasCompletedOnboarding != null) {
        updateData['hasCompletedOnboarding'] = hasCompletedOnboarding;
      }
      
      await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updateData);
        
    } catch (e) {
      print('Error updating user login state: $e');
    }
  }
}
```

#### **Step 4.2: Update Main App Entry Point**
```dart
// In lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopple',
      theme: AppTheme.lightTheme, // Use existing theme
      home: AuthenticationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  Widget? _initialRoute;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }
  
  Future<void> _determineInitialRoute() async {
    // Wait for Firebase to initialize
    await Firebase.initializeApp();
    
    // Determine the correct initial route
    Widget initialRoute = await AuthStateService.determineInitialRoute();
    
    if (mounted) {
      setState(() {
        _initialRoute = initialRoute;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or splash content
              Image.asset(
                'assets/images/app_logo.png',
                height: 120,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                "Loading...",
                style: AppTheme.bodyLarge?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _initialRoute ?? OnboardingScreen();
  }
}
```

#### **Step 4.3: Update Login Success Handlers**
```dart
// In all login methods (Google, Email, Phone)
Future<void> _handleLoginSuccess(User user, String signInMethod) async {
  try {
    // Check if user document exists
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
    
    if (userDoc.exists) {
      // EXISTING USER - Update login time and navigate appropriately
      UserModel userData = UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>
      );
      
      // Update last login
      await AuthStateService.updateUserLoginState(uid: user.uid);
      
      // Navigate based on user's completion status
      if (!userData.isProfileComplete && !userData.profileSkipped) {
        // Profile incomplete - go to profile completion
        Get.offAll(() => DataCollectionScreen(
          prefilledData: userData.toMap(),
        ));
      } else if (!userData.hasCompletedOnboarding) {
        // Profile complete but hasn't seen app onboarding
        Get.offAll(() => AppOnboardingScreen());
      } else {
        // Fully set up user - go directly to main app
        Get.offAll(() => MainScreen());
      }
      
    } else {
      // NEW USER - Create user document and go to profile completion
      UserModel newUser = UserModel(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        photoURL: user.photoURL,
        signInMethod: signInMethod,
        isProfileComplete: false,
        hasCompletedOnboarding: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save new user to Firestore
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(newUser.toMap());
      
      // Navigate to profile completion
      Get.offAll(() => DataCollectionScreen(
        prefilledData: newUser.toMap(),
      ));
    }
    
  } catch (e) {
    print('Error handling login success: $e');
    // On error, show profile completion to be safe
    Get.offAll(() => DataCollectionScreen());
  }
}
```

---

## 📋 **Implementation Priority & Testing:**

### **Phase 1: Login Page Layout (Day 1)**
- ✅ Reduce image size to 45% of screen
- ✅ Fix button layout and accessibility
- ✅ Study and implement existing app theme for buttons
- ✅ Test on multiple screen sizes

### **Phase 2: Profile Completion Enhancement (Day 2)**
- ✅ Remove redundant header
- ✅ Implement dynamic progress bar
- ✅ Replace age with cool DOB picker
- ✅ Use existing app theme and components

### **Phase 3: Profile Page Data Loading (Day 3)**
- ✅ Implement real-time data fetching
- ✅ Fix name and contact display
- ✅ Proper edit functionality with data loading

### **Phase 4: Authentication State Management (Day 4)**
- ✅ Fix existing user login flow
- ✅ Prevent redundant onboarding for authenticated users
- ✅ Proper state management for all sign-in methods

### **Comprehensive Testing Checklist:**
- [ ] Login buttons accessible without scrolling (all screen sizes)
- [ ] Modern button styling matches existing app theme
- [ ] Progress bar updates dynamically in profile completion
- [ ] DOB picker works smoothly and looks modern
- [ ] Only one header in profile completion screen
- [ ] Profile page shows correct user data immediately
- [ ] Edit profile loads existing data properly
- [ ] Already authenticated users go directly to main app
- [ ] No redundant onboarding for existing users
- [ ] All sign-in methods (Google, Email, Phone) work correctly
- [ ] Real-time profile updates work
- [ ] App remembers user state across app restarts