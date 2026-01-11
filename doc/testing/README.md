# 🧪 Testing Documentation

This directory contains detailed documentation for the automated tests in the Shopple app.

## 📂 Test Categories

### 📱 UI Tests
Tests that verify the rendering and interaction of UI components.

- **[Chat Conversation Screen](CHAT_CONVERSATION_SCREEN_TESTS.md)**
  - **File**: `test/ui/chat_conversation_screen_test.dart`
  - **Coverage**: 
    - Rendering of chat messages, headers, and input fields.
    - Message sending functionality.
    - Integration with Stream Chat SDK mocks.
    - Handling of async timers (e.g., audio recorder).

- **[Modern Chat Screen](MODERN_CHAT_SCREEN_TESTS.md)**
  - **File**: `test/ui/modern_chat_screen_test.dart`
  - **Coverage**:
    - Rendering of channel list.
    - Empty state handling.
    - Navigation to new chat and conversation screens.
    - Integration with `ChatManagementController`.

- **[New Chat Screen](NEW_CHAT_SCREEN_TESTS.md)**
  - **File**: `test/ui/new_chat_screen_test.dart`
  - **Coverage**:
    - UI rendering and empty states.
    - Friend list display and search results.
    - Navigation to chat conversation.
    - Integration with `ChatManagementController` and `PresenceService`.

- **[Additional UI Tests](ADDITIONAL_UI_TESTS.md)**
  - **Files**: 
    - `test/ui/friends_screen_test.dart`
    - `test/ui/dashboard_nav_test.dart`
    - `test/ui/splash_screen_test.dart`
  - **Coverage**:
    - Friends list rendering.
    - Dashboard header and navigation.
    - Splash screen animation and transition logic.

### ⚙️ Unit & Service Tests
Tests for business logic, data models, and backend integrations.

- **[Unit and Service Tests](UNIT_AND_SERVICE_TESTS.md)**
  - **Files**:
    - `test/agent_parser_test.dart`
    - `test/llm_parse_gate_test.dart`
    - `test/pii_sanitizer_test.dart`
    - `test/shopping_lists/models_test.dart`
    - `test/services/chat/chat_repository_test.dart`
  - **Coverage**:
    - AI Agent command parsing and intent extraction.
    - PII sanitization logic.
    - Feature flag gating for LLM.
    - Shopping list model logic (completion %, totals).
    - Chat repository authentication flows.

## 🛠 Testing Strategy

We use a combination of tools to ensure robust testing:

1.  **Flutter Test**: The core framework for widget and unit tests.
2.  **Mockito**: For mocking external dependencies like Stream Chat Client and GetX Controllers.
3.  **FakeAsync**: Implicitly used by `tester.pump` but explicitly managed via `tester.runAsync` for complex timers.
4.  **NetworkImageMock**: To handle network images in widget tests without making real network calls.

## 🏃‍♂️ Running Tests

To run all tests:
```bash
flutter test
```

To run specific test files:
```bash
flutter test test/ui/chat_conversation_screen_test.dart
flutter test test/ui/modern_chat_screen_test.dart
flutter test test/ui/new_chat_screen_test.dart
```
