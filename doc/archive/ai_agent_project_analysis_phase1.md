# AI Agent Project Analysis Report (Phase 1)

> Scope: Exhaustive baseline documentation of existing Shopple app architecture prior to AI Agent + Genkit backend integration. Generated: 2025-08-30.

---
## 1. Frontend Architecture Overview

Directory roots (lib/):
- controllers/ : ChangeNotifier + ad‑hoc controllers (e.g., `ai_agent_controller.dart`).
- services/ : Core business logic (auth, product, lists, search, analytics, ai, caches).
- models/ : Data models (products, shopping lists/items, ai agent intent models, user models).
- Screens/ : Feature screens (Dashboard with `search_screen.dart`, list/project/timeline/etc.).
- widgets/ : Reusable UI components (search cards, bottom sheets, AI agent sheet, etc.).
- theme/ and Values/ : Design tokens (colors, text styles, spacing, decorations).
- config/ : Feature flags, firebase options.

State management pattern:
- Hybrid: Local widget state + ValueNotifier + ChangeNotifier classes (e.g., AI agent) + singleton service classes. GetX imported but not heavily used in analyzed sections (no pervasive observable wrappers). No Bloc/Riverpod/Redux present.

Navigation:
- Traditional Navigator API (need deeper inspection of `main.dart` for any GoRouter usage; not identified yet).

---
## 2. Product & Search Services

Primary search & product logic:
- `services/product/enhanced_product_service.dart`
  - getAllProducts(): Firestore fetch with SharedPreferences timestamp cache + in‑memory map.
  - getProductsByCategory(categoryId)
  - getCurrentPricesForProduct(productId) & getCurrentPricesForProducts(productIds[]) (batched, chunk size 10).
  - getProductById, getProductsByIds(ids)
  - getCategories()
  - searchProductsWithPrices(query): loads products (cached), fuzzy search, enrich with batched price map.
  - Cache clearing & helper name formatting.

Search engine core:
- `services/search/search_engine_service.dart` (AdvancedSearchEngine)
  - Levenshtein distance implementation.
  - performFuzzySearch(): isolates heavy work in compute isolate.
  - Multi-field weighted scoring (name > brand > variety > originalName > category > sizeRaw).
  - Additional helpers: soundex, spelling suggestions.

Supplemental search services (not fully parsed but present):
- autocomplete_service.dart, fast_product_search_service.dart (likely Cloud Function integration), recent_search_service.dart, cloud_recent_search_service.dart.

Caching:
- Product caches in memory + SharedPreferences.
- Price and product detail caches (files present: `product_details_cache.dart`, `product_image_cache.dart`, `current_price_cache.dart`).

---
## 3. Shopping List Services

`shopping_lists/shopping_list_service.dart` (683 lines):
- createShoppingList(): writes list doc + user nested ref doc; supports optional start/end dates, member roles, budget.
- addCustomItemToList(): adds arbitrary item (no productId) with optimistic aggregate updates via `ShoppingListCache`.
- addProductItemToList(): idempotent addition (increments quantity if same productId exists) with optimistic local aggregate updates.
- addProductToList(): alias wrapper.
- toggleItemCompletion(), updateShoppingList(), updateShoppingListMap(), updateItem(), deleteItem().
- Extensive use of batches + hydration marking for downstream smart hydration service(s).

`shopping_list_cache.dart` and hydration services maintain local snapshots (not detailed here yet—pending deeper review if needed for Phase 2 planning).

Models:
- `ShoppingList` (aggregates: totalItems, completedItems, estimatedTotal, distinctProducts, etc.).
- `ShoppingListItem` (productId optional, estimatedPrice, order, timestamps, completion state).

---
## 4. AI Agent Current State

Files:
- `controllers/ai_agent_controller.dart`: Orchestrates parse -> list creation -> sequential product additions. Features:
  - Multi-provider parsing chain (GeminiLLMParsingProvider, Heuristic fallback).
  - Streaming parse preview buffer (feature flag `streamingUIEnabled`).
  - Search attempt heuristics (token subset permutations, genericization, plural stripping, vowel removal, fuzzy library attempts, domain synonyms to cola/meat/beef/chicken).
  - Alternative smart suggestion engine integration (currently partially removed / to be re-inserted for alternatives logic—validated compile success).
  - History persistence (SharedPreferences) capped at 50 entries.
  - Lightweight analytics events (run start/complete/item added) via `AgentAnalytics`.
  - Cancellation support & item status tracking map.

- `services/ai/agent_parsing_providers.dart`: Abstraction for parsing; Gemini provider with streaming token JSON detection, heuristic provider.
- `services/ai/gemini_service.dart` (not yet re-read in this pass) presumably wraps Firebase AI or Gemini SDK.
- `services/ai/pii_sanitizer.dart`: (open in editor) removes PII from user input for LLM prompt (details not inspected yet—should verify patterns for false positives before production).
- Feature flags: `config/feature_flags_ai.dart` controlling llmParsing, streaming UI, function calling placeholder, suggestions, analytics.

Missing / Not Yet Implemented:
- Function-calling tool orchestration (flag present but no code).
- Backend Genkit flows (none in Cloud Functions yet).
- Central conversation memory beyond last parse history (no multi-turn chat context for agent logic; chat session may exist in Gemini service—pending check).

---
## 5. Authentication & User Services

`auth/auth_service.dart`:
- Email/password sign-up & login.
- Google Sign-In with Firestore user document creation or update last login.
- Email verification utilities.
- Uses `UserStateService` for initialization (not yet inspected for preference/profile logic).

User-related services directory includes contact sync, profile, search, state, tracking—foundation for personalized features later.

---
## 6. Analytics & Telemetry

- `services/analytics/agent_analytics.dart`: Print-based stub; ready for future expansion to Firestore or Analytics.
- Additional analytics service files present (`comprehensive_analytics_service.dart`, `enhanced_search_analytics_service.dart`), not yet parsed.
- Cloud Functions trimmed down; some analytics functions removed per header comments in index.js.

---
## 7. Cloud Functions Backend (Current)

`functions/index.js` (partial scan; ~1400 lines total):
- Initialized admin.
- Exports seen so far:
  - `hydrationOnItemWrite`: Firestore trigger (shopping list items) recalculates aggregates and writes both meta doc and parent doc (idempotent update check avoids unnecessary writes).
  - `getListHydrationBatch`: Callable batched retrieval of hydration meta for list IDs.
  - `backfillItemPrices`: Callable to populate missing estimatedPrice values from `current_prices` cheapest entry.
- Remaining functions (search endpoints, user search, fast product search) expected deeper in file—pending full enumeration in extended scan.
- No Genkit or AI model initialization present yet.

Security (Firestore rules):
- Public read-only for product/catalog collections.
- Strict per-user ownership for `/users/{userId}` tree.
- Shopping list write rules not explicitly listed (lists appear under `shopping_lists`; rules file currently denies everything else—implies writes rely on privileged environment? Need confirmation; may be missing rule conditions for shopping_lists path or trimmed for audit.) => ACTION: Re-verify actual deployed rules; current snapshot would block client writes to shopping_lists unless more rules exist elsewhere. Possibly partial rules file or lists managed via privileged Cloud Functions? In-app direct Firestore writes are present, so production rules must allow them—this mismatch needs resolution before rollout.

---
## 8. Design System

Colors (AppColors):
- primary background: #181A1F
- surface: #262A34
- accent primary: #246CFD
- accent secondary: #C395FC
- text primary: #FFFFFF, secondary: #C395FC
- error: redAccent, inactive: #666A7A

Typography (Poppins):
- heading1 48 bold
- heading2 34 bold
- bodyL 17 normal primary
- bodyM 15 normal secondary
- button 17 semi-bold

Patterns:
- Rounded pill chips, 32 radius containers (see search collapsed header)
- Glass / blurred surfaces via `LiquidGlass` bottom sheets
- Elevated surfaces use slightly lighter charcoal (#262A34)

Pending extraction: spacing tokens/radii from remaining Values part files.

---
## 9. Performance Patterns

- Fuzzy search heavy work dispatched to compute isolate to protect UI.
- Product cache TTL 15 minutes (SharedPreferences timestamp + in-memory)
- Batched Firestore price queries in chunks of 10 (within 'in' query limits) and for current_prices product queries.
- Hydration trigger consolidates list aggregates server-side reducing client aggregate recomputation cost.

Potential enhancements for AI integration:
- Warm search/product caches before agent run.
- Introduce incremental streaming UI beyond parse preview (for action progress logs).
- Add debounce or concurrency guard on multiple simultaneous agent runs (already prevented by `_running`).

---
## 10. Security & Privacy

- PIISanitizer present but unverified for coverage; should test edge cases (emails, phone numbers, addresses, names) for false positives.
- Firestore rules discrepancy for shopping lists must be resolved (see Section 7 note).
- No explicit encryption of locally cached data (SharedPreferences) – acceptable for non-sensitive aggregates; ensure no secrets stored.
- Feature flags allow disabling LLM parsing if compliance concerns.

---
## 11. Gaps vs. Target AI Agent Roadmap

Needed for Genkit + advanced agent:
1. Backend flows (intent parsing, action orchestration, alternatives tool) — absent.
2. Structured function/tool definitions (searchProducts, addToList, createList) — placeholders only in design docs.
3. Streaming conversation & multi-turn memory — partial (parse token streaming only). Need chat session & context summarization.
4. Robust fallback logic for alternative suggestions (controller currently simplified after cleanup; reintroduce suggestion path).
5. Telemetry persistence for agent runs (only console logging currently).
6. Remote config integration for feature flags & staged rollout.
7. Firestore rule verification and potential adjustments for any new collections (agent logs, conversations).

---
## 12. Risks & Considerations

- Rule mismatch could block list writes under stricter Firestore deployment (must audit before deploying AI that adds items automatically).
- Large Cloud Functions monolith complicates incremental Genkit introduction—recommend modular new `functions/src/ai/` directory with isolated exports, progressively integrated.
- Potential cost amplification from LLM usage; need caching and early-exit heuristics (already skip short prompts) + user quotas.
- PII sanitizer quality directly impacts compliance; requires tests.
- Lack of backend-side intent execution verification (currently all in client) could lead to trust issues for collaborative list modifications; backend authoritative flow recommended.

---
## 13. Immediate Action Items (Proposed)

| Priority | Action | Rationale |
|----------|--------|-----------|
| High | Firestore rules audit for shopping_lists write allowance | Ensure current client writes are valid before automation |
| High | Add agent alternative suggestion reintegration & tests | Restore feature completeness pre-expansion |
| High | Create PII sanitizer unit tests | Privacy assurance before streaming prompts |
| High | Implement agent run analytics persistence (Firestore document) | Observability & rollback metrics |
| Medium | Design Genkit flow skeleton + tools mapping to existing services | Backend orchestration foundation |
| Medium | Remote config fetch for AI feature flags | Controlled rollout |
| Medium | Multi-turn context summarization strategy | Future conversational improvements |
| Low | Additional search ranking telemetry (score distribution logging) | Optimize fuzzy matching thresholds |

---
## 14. Test Coverage Recommendations (Next)

Add tests for:
- Search attempts generation heuristics (edge cases: plurals, hyphenated, brand removal, vowel stripping).
- PII sanitizer patterns (emails, phone numbers, credit card-like sequences, addresses).
- Parsing providers: Gemini streaming early JSON extraction vs. heuristic fallback.
- Controller run scenarios: create list + add items, reuse existing list, cancellation mid-run, fallback to custom item, analytics events present.

---
## 15. Pending Clarifications for User

1. Confirm Firestore rules for `shopping_lists` (hidden snippet or separate rules include?).
2. Approve creation of `functions/src/ai/` for Genkit flows vs integrating into existing `index.js`.
3. Preferred deployment region for new AI functions (current region: `asia-south1`).
4. Budget/usage constraints for LLM calls (set internal throttling?).
5. Logging retention expectations for agent interactions (duration, redaction level).

---
## 16. Next Phase (Design) Preview

Upon approval:
- Produce concrete Genkit flow + tool mapping pseudo-code referencing existing product & list services.
- Define function calling schema interface aligning with future Gemini function calling (searchProducts, addToList, createList, listUserLists).
- Architect minimal conversation state store (Firestore collection `agent_sessions/{sessionId}/messages`) with redaction.

---
## 17. Summary

Existing foundation is strong: performant product retrieval, fuzzy search, robust list management, and an initial AI controller with streaming parse support. Key missing pieces for enterprise-grade AI agent: backend authoritative orchestration (Genkit), telemetry persistence, fuller privacy/testing, and structured tool/function abstractions ready for model function calling.

Prepared to proceed to Phase 2 once clarifications answered.

---
*End of Phase 1 Report*
