# Service Testability Implementation Guide

This document explains the testability patterns implemented for Firebase-dependent services in the Shopple app.

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution: Lazy Loading Pattern](#solution-lazy-loading-pattern)
3. [Implementation Examples](#implementation-examples)
4. [Test Helper Infrastructure](#test-helper-infrastructure)
5. [Best Practices](#best-practices)

---

## Problem Statement

### The Challenge

Firebase services in Flutter typically use singleton patterns like `FirebaseFirestore.instance`. When these are hard-coded in service constructors, tests fail because:

1. Firebase isn't initialized in test environments
2. No way to inject fake/mock instances
3. Tests hit real Firebase (slow, unreliable, side effects)

```mermaid
flowchart TD
    subgraph "Production Code Problem"
        A[Service Constructor] --> B[FirebaseFirestore.instance]
        B --> C[Requires Real Firebase]
    end
    
    subgraph "Test Environment"
        D[Unit Test] --> E[Tries to Create Service]
        E --> F[❌ Firebase Not Initialized]
    end
    
    C -.-> |Blocks| D
```

### Symptoms

```dart
// This pattern breaks tests
class MyService {
  final _firestore = FirebaseFirestore.instance; // ❌ Called at construction
  
  MyService() {
    // Firebase must be initialized before this line
  }
}
```

Test error:
```
No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

---

## Solution: Lazy Loading Pattern

### Core Concept

Defer Firebase instance access until first use, allowing test injection before any Firebase calls.

```mermaid
sequenceDiagram
    participant Code
    participant Service
    participant LazyGetter
    participant Firebase
    
    Note over Code, Firebase: Production Flow
    Code->>Service: Create instance
    Service->>Service: Constructor (no Firebase access)
    Code->>Service: Call method
    Service->>LazyGetter: Get _firestore
    LazyGetter->>Firebase: FirebaseFirestore.instance
    Firebase-->>Service: Real instance
    
    Note over Code, Firebase: Test Flow
    Code->>Service: Create instance
    Code->>Service: Set _firestoreInstance = fake
    Code->>Service: Call method
    Service->>LazyGetter: Get _firestore
    LazyGetter-->>Service: Return injected fake
```

### Pattern Structure

```mermaid
classDiagram
    class TestableService {
        -FirebaseFirestore? _firestoreInstance
        -FirebaseAuth? _authInstance
        +FirebaseFirestore _firestore
        +FirebaseAuth _auth
        +businessMethod()
    }
    
    note for TestableService "Lazy getters return:\n1. Injected instance (testing)\n2. Default instance (production)"
```

---

## Implementation Examples

### PrivacySettingsService

#### Before (Untestable)

```dart
class PrivacySettingsService {
  static final PrivacySettingsService _instance = PrivacySettingsService._internal();
  static PrivacySettingsService get instance => _instance;
  
  final _firestore = FirebaseFirestore.instance; // ❌ Hard-coded
  final _auth = FirebaseAuth.instance; // ❌ Hard-coded
  
  PrivacySettingsService._internal();
  
  Future<UserPrivacySettings?> getPrivacySettings(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('privacy')
        .get();
    // ...
  }
}
```

#### After (Testable)

```dart
class PrivacySettingsService {
  static PrivacySettingsService? _instance;
  static PrivacySettingsService get instance => _instance ??= PrivacySettingsService._internal();
  static set instance(PrivacySettingsService? value) => _instance = value;
  
  // Lazy loading for Firestore
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  set firestoreInstance(FirebaseFirestore? value) => _firestoreInstance = value;
  
  // Lazy loading for Auth
  FirebaseAuth? _authInstance;
  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  set authInstance(FirebaseAuth? value) => _authInstance = value;
  
  PrivacySettingsService._internal();
  
  Future<UserPrivacySettings?> getPrivacySettings(String userId) async {
    final doc = await _firestore // Uses lazy getter
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('privacy')
        .get();
    // ...
  }
}
```

### Flow Diagram

```mermaid
flowchart TB
    subgraph "Getter Logic"
        A[Access _firestore] --> B{_firestoreInstance\nis null?}
        B -->|Yes| C[Return FirebaseFirestore.instance]
        B -->|No| D[Return _firestoreInstance]
    end
    
    subgraph "Production"
        P1[App starts] --> P2[Service created]
        P2 --> P3[Method called]
        P3 --> A
        A --> C
    end
    
    subgraph "Testing"
        T1[Test starts] --> T2[Service created]
        T2 --> T3[Inject fake instance]
        T3 --> T4[Method called]
        T4 --> A
        A --> D
    end
```

---

## Test Helper Infrastructure

### FirebaseTestHelper

Central helper class for setting up Firebase mocks across all tests.

```mermaid
graph TB
    subgraph "FirebaseTestHelper"
        Init[initialize]
        Setup[setupForTest]
        Seed[seedData]
        Reset[resetServices]
    end
    
    subgraph "Fake Firebase"
        FFS[FakeFirebaseFirestore]
        MFA[MockFirebaseAuth]
        MFU[MockUser]
    end
    
    subgraph "Services"
        PPS[PrivacySettingsService]
        AS[AuthService]
        SLS[ShoppingListService]
    end
    
    Init --> FFS
    Init --> MFA
    Init --> MFU
    
    Setup --> PPS
    Setup --> AS
    Setup --> SLS
    
    FFS --> PPS
    MFA --> PPS
```

### Test Setup Sequence

```mermaid
sequenceDiagram
    participant Test
    participant Helper as FirebaseTestHelper
    participant FakeFS as FakeFirebaseFirestore
    participant Service as PrivacySettingsService
    
    Note over Test: setUpAll()
    Test->>Helper: initialize()
    Helper->>FakeFS: Create instance
    Helper->>Helper: Create MockAuth
    
    Note over Test: setUp() - before each test
    Test->>Helper: setupForTest()
    Helper->>FakeFS: Clear collections
    Helper->>Service: firestoreInstance = fakeFirestore
    Helper->>Service: authInstance = mockAuth
    
    Note over Test: Test execution
    Test->>Service: getPrivacySettings('user-1')
    Service->>FakeFS: Query document
    FakeFS-->>Service: Return seeded data
    Service-->>Test: Return settings
    
    Note over Test: tearDown()
    Test->>Service: Reset instance
```

### Code Example

```dart
class FirebaseTestHelper {
  static late FakeFirebaseFirestore fakeFirestore;
  static late MockFirebaseAuth mockAuth;
  static late MockUser mockUser;
  
  static Future<void> initialize() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  }
  
  static void setupPrivacySettingsService() {
    final service = PrivacySettingsService.instance;
    service.firestoreInstance = fakeFirestore;
    service.authInstance = mockAuth;
  }
  
  static Future<void> seedPrivacySettings(List<String> userIds) async {
    for (final userId in userIds) {
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .set({
            'profileVisibility': 'friends',
            'showOnlineStatus': true,
            'allowFriendRequests': true,
            'showActivityStatus': true,
            'showLastSeen': true,
          });
    }
  }
  
  static void tearDown() {
    PrivacySettingsService.instance = null;
  }
}
```

---

## Best Practices

### 1. Singleton with Reset Capability

```mermaid
classDiagram
    class SingletonService {
        -static _instance: SingletonService?
        +static instance: SingletonService
        +static resetInstance()
    }
    
    note for SingletonService "Nullable static allows\ntest reset between runs"
```

```dart
class MyService {
  static MyService? _instance;
  static MyService get instance => _instance ??= MyService._internal();
  static set instance(MyService? value) => _instance = value; // For testing
  
  MyService._internal();
}
```

### 2. All Firebase Dependencies Lazy

```dart
class CompleteService {
  // ✅ All Firebase dependencies use lazy pattern
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  
  FirebaseAuth? _authInstance;
  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  
  FirebaseDatabase? _databaseInstance;
  FirebaseDatabase get _database => _databaseInstance ?? FirebaseDatabase.instance;
  
  FirebaseStorage? _storageInstance;
  FirebaseStorage get _storage => _storageInstance ?? FirebaseStorage.instance;
}
```

### 3. Test Isolation

```mermaid
flowchart TD
    subgraph "Test 1"
        T1A[setUp] --> T1B[Inject mocks]
        T1B --> T1C[Run test]
        T1C --> T1D[tearDown]
        T1D --> T1E[Reset instances]
    end
    
    subgraph "Test 2"
        T2A[setUp] --> T2B[Fresh mocks]
        T2B --> T2C[Run test]
        T2C --> T2D[tearDown]
        T2D --> T2E[Reset instances]
    end
    
    T1E --> T2A
    
    style T1E fill:#f96
    style T2B fill:#9f6
```

### 4. Consistent Teardown

```dart
tearDown(() {
  // Reset ALL services that were mocked
  PrivacySettingsService.instance = null;
  AuthService.instance = null;
  PresenceService.instance = null;
  
  // Clear any cached data
  fakeFirestore.clearPersistence();
});
```

---

## Migration Checklist

When making a service testable, follow this checklist:

```mermaid
flowchart TD
    A[Identify Service] --> B{Uses Firebase\ndirectly?}
    B -->|No| C[Already testable]
    B -->|Yes| D[List all Firebase deps]
    D --> E[Add nullable instance vars]
    E --> F[Create lazy getters]
    F --> G[Add setters for testing]
    G --> H[Make singleton resettable]
    H --> I[Update FirebaseTestHelper]
    I --> J[Write tests]
    J --> K[Verify tests pass]
```

### Step-by-Step

1. **Identify Firebase dependencies**
   ```dart
   // Find all uses of:
   FirebaseFirestore.instance
   FirebaseAuth.instance
   FirebaseDatabase.instance
   FirebaseStorage.instance
   ```

2. **Add nullable instance variables**
   ```dart
   FirebaseFirestore? _firestoreInstance;
   ```

3. **Create lazy getters**
   ```dart
   FirebaseFirestore get _firestore => 
       _firestoreInstance ?? FirebaseFirestore.instance;
   ```

4. **Add setters (for test injection)**
   ```dart
   set firestoreInstance(FirebaseFirestore? value) => 
       _firestoreInstance = value;
   ```

5. **Make singleton resettable**
   ```dart
   static MyService? _instance;
   static set instance(MyService? value) => _instance = value;
   ```

6. **Update test helper**
   ```dart
   static void setupMyService() {
     MyService.instance.firestoreInstance = fakeFirestore;
   }
   ```

---

## Conclusion

The lazy loading pattern enables:

- ✅ Production code unchanged in behavior
- ✅ Full test isolation
- ✅ No Firebase initialization in tests
- ✅ Fast, reliable unit tests
- ✅ Easy mock injection

This pattern should be applied to all services that depend on Firebase or other external services that are difficult to mock directly.
