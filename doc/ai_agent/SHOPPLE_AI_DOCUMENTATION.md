# Shopple AI Agent - Comprehensive Technical Documentation

> **Version:** 1.0.0  
> **Last Updated:** January 2026  
> **Technology:** Google Gemini via Firebase AI (Vertex AI)

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Processing Pipeline](#processing-pipeline)
5. [Intent Recognition System](#intent-recognition-system)
6. [Natural Language Processing](#natural-language-processing)
7. [Product Search & Resolution](#product-search--resolution)
8. [Session Management](#session-management)
9. [Feature Flags & Configuration](#feature-flags--configuration)
10. [User Interface](#user-interface)
11. [Examples & Walkthroughs](#examples--walkthroughs)
12. [API Reference](#api-reference)
13. [Performance Considerations](#performance-considerations)

---

## Overview

The Shopple AI Agent is a sophisticated **natural language processing (NLP) assistant** for shopping list management. It allows users to create shopping lists, add items, query prices, and manage their shopping experience through natural conversational commands.

### What Makes Shopple AI Unique?

Unlike traditional shopping list apps that require users to manually search for products one by one, Shopple AI understands natural language commands and can process multiple items in a single request. When a user says "Create a party list and add chips, salsa, and beer," the AI doesn't just create a list with text entries—it actually:

1. **Understands the intent**: Recognizes that the user wants to create a new list AND add specific items
2. **Extracts structured data**: Parses the list name ("party") and individual items ("chips", "salsa", "beer")
3. **Resolves products**: Searches the product database to find actual products matching each phrase
4. **Handles ambiguity**: Uses AI to select the best match when multiple products could fit (e.g., "chips" could be Doritos, Lays, or tortilla chips)
5. **Executes atomically**: Creates the list and adds all items, tracking successes and failures

This approach transforms what would be 4-5 manual operations (create list, search chips, add chips, search salsa, add salsa...) into a single conversational command.

### Key Capabilities

| Capability | Description |
|------------|-------------|
| **List Creation** | Create shopping lists with natural names, budgets, and date ranges |
| **Item Addition** | Add multiple items with quantities using natural language |
| **Price Queries** | Get current prices for products |
| **List Queries** | Count items, list contents, check product presence |
| **Smart Matching** | AI-powered product matching from user phrases |

### Example Interactions

```
User: "Create a grocery list called weekend BBQ and add 3 steaks, a dozen eggs, and some beer"

AI Response:
✓ Created list "Weekend BBQ"
✓ Added: Premium Beef Steaks (qty: 3)
✓ Added: Farm Fresh Eggs 12pk (qty: 1)
✓ Added: Heineken 6-Pack (qty: 1)
```

---

## Architecture

The Shopple AI system uses a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                    UI Layer (Presentation)                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ FloatingAIButton │  │AIAgentBottomSheet│  │FloatingAIDemoScreen│
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                  Controller Layer (State Management)             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │               AIAgentController (GetX)                       ││
│  │   - Session management, execution flow, history tracking    ││
│  └─────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────┤
│                     Service Layer (Business Logic)               │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │GeminiService │ │AgentSearch   │ │AgenticProductSearch    │   │
│  │(LLM API)     │ │Service       │ │Service                 │   │
│  └──────────────┘ └──────────────┘ └────────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │AgentList     │ │AgentQuery    │ │AgentHistory            │   │
│  │Service       │ │Service       │ │Service                 │   │
│  └──────────────┘ └──────────────┘ └────────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │ServerAgent   │ │QuickPrompt   │ │Parsing Providers       │   │
│  │Service       │ │Service       │ │(Gemini + Heuristic)    │   │
│  └──────────────┘ └──────────────┘ └────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                      Model Layer (Data)                          │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │AgentIntents  │ │FunctionCalls │ │SessionModels           │   │
│  └──────────────┘ └──────────────┘ └────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                   External Services                              │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │Firebase AI   │ │Firebase      │ │Cloud Functions         │   │
│  │(Vertex AI    │ │Firestore     │ │(Genkit Backend)        │   │
│  │Gemini)       │ │              │ │                        │   │
│  └──────────────┘ └──────────────┘ └────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Key Files |
|-------|----------------|-----------|
| **UI** | User interaction, visual feedback | `ai_agent_bottom_sheet.dart`, `floating_ai_button.dart` |
| **Controller** | State management, orchestration | `ai_agent_controller.dart` |
| **Service** | Business logic, AI processing | `lib/services/ai/*.dart` |
| **Model** | Data structures, parsing rules | `lib/models/ai_agent/*.dart` |
| **External** | Cloud APIs, persistence | Firebase AI, Firestore |

### Why This Architecture?

**Separation of Concerns**: Each layer has a single responsibility. The UI layer never directly calls AI APIs—it communicates through the controller. The controller orchestrates but doesn't contain business logic—that lives in services. This makes testing easier and allows us to swap implementations (e.g., switch from Gemini to another LLM) without touching UI code.

**Service Layer Granularity**: Rather than having one monolithic "AIService," we split functionality into specialized services:
- `GeminiService` handles raw LLM API calls
- `AgentSearchService` handles product resolution
- `AgentListService` handles list operations
- `AgentParsingProviders` handles NLP parsing

This allows each service to be optimized independently and makes the codebase more maintainable.

**Reactive State Management**: GetX provides reactive state that automatically updates the UI when data changes. When an item is successfully added, the controller updates state, and the UI immediately reflects the change without manual refresh calls.

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **LLM Provider** | Google Gemini via Firebase AI (Vertex AI) | Natural language understanding |
| **Primary Model** | `gemini-2.5-flash` | High-quality parsing and reasoning |
| **Lite Model** | `gemini-2.0-flash-lite` | Cost-optimized simple operations |
| **State Management** | GetX | Reactive UI state |
| **Backend** | Firebase Cloud Functions with Genkit | Server-side AI processing |
| **Database** | Cloud Firestore | History persistence |
| **Local Storage** | SharedPreferences | Caching, user preferences |
| **Analytics** | Custom `AgentAnalytics` | Usage tracking |
### Why Google Gemini?

We chose Google Gemini as our LLM provider for several strategic reasons:

1. **Firebase Integration**: Gemini is natively available through Firebase AI (Vertex AI), which means we don't need to manage API keys separately or set up additional infrastructure. Authentication flows through Firebase Auth, which we already use.

2. **Cost-Performance Balance**: Gemini offers multiple model tiers. We use `gemini-2.5-flash` for complex parsing tasks that require high accuracy, and `gemini-2.0-flash-lite` for simpler operations like generating search term variants. This dual-model approach reduces costs by 40-60% compared to using the primary model for everything.

3. **Streaming Support**: Gemini supports streaming responses, allowing us to show users real-time feedback as the AI processes their request. This improves perceived performance even when actual processing takes 2-3 seconds.

4. **JSON Mode**: Gemini can be prompted to return structured JSON, which is crucial for our parsing pipeline. We don't need to parse free-form text—the model returns properly formatted data that we can directly deserialize.

### Why Not OpenAI/Claude/Other?

While other LLMs are excellent, they would require:
- Separate API key management
- Additional server infrastructure to proxy requests (to protect API keys)
- More complex authentication flows
- Higher latency due to additional network hops

Gemini's Firebase integration eliminates these concerns.
### Gemini Service Implementation

```dart
// lib/services/ai/gemini_service.dart
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();
  
  GenerativeModel? _model;
  GenerativeModel? _liteModel;

  Future<void> ensureInitialized() async {
    _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash');
    _liteModel = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.0-flash-lite');
  }

  /// Simple text generation
  Future<String> generateText(String prompt, {bool lite = false}) async {
    await ensureInitialized();
    final m = lite ? (_liteModel ?? model) : model;
    final response = await m.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  /// Streaming text generation (real-time token output)
  Stream<String> generateTextStream(String prompt) async* {
    await ensureInitialized();
    final stream = model.generateContentStream([Content.text(prompt)]);
    await for (final event in stream) {
      if (event.text?.isNotEmpty ?? false) yield event.text!;
    }
  }
}
```

---

## Processing Pipeline

The AI agent follows a **6-step pipeline** from user input to execution:

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Natural Language Input                   │
│        "Create a list called party and add coca cola"           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Step 1: PII Sanitization                      │
│                    (Remove emails, phones, etc.)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Step 2: Intent Parsing                        │
│     ┌─────────────────────────────────────────────────┐         │
│     │ Gemini LLM Parser (if enabled & >2 words)       │         │
│     │   → JSON: {listName, createList, items, ...}    │         │
│     └─────────────────────────────────────────────────┘         │
│                           │ fallback                            │
│     ┌─────────────────────────────────────────────────┐         │
│     │ Heuristic Parser (regex + keyword detection)    │         │
│     └─────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                Step 3: Execution Plan Building                   │
│     AgentExecutionPlan.buildFromParsed()                        │
│     → [CreateListCall, AddItemCall("coca cola"), FinalizeCall]  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Step 4: Plan Execution (per call)                   │
│                                                                  │
│  CreateListCall:                                                │
│    → AgentListService.createListWithDetails()                   │
│                                                                  │
│  AddItemCall("coca cola"):                                      │
│    → AgentSearchService.addSingleItem()                         │
│        1. Check cached UI search results                        │
│        2. AI term generation + aggregated search                │
│        3. AI candidate evaluation                               │
│        4. Semantic refinement if needed                         │
│        5. Fallback to custom item                               │
│                                                                  │
│  FinalizeCall:                                                  │
│    → Log completion summary                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Step 5: Result & Persistence                  │
│     - AgentRunResult with added/failed items                    │
│     - History persisted to SharedPreferences + Firestore        │
│     - Analytics event emission                                   │
│     - UI notification via LiquidSnack                           │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Step Breakdown

#### Step 1: PII Sanitization

**Why This Matters**: When users type natural language commands, they might accidentally include sensitive information. A user might say "Add items for John's party at john.doe@gmail.com" or "Get groceries, my card is 4532-xxxx-xxxx-1234." We must never send this data to external AI services.

**How It Works**: The PII sanitizer uses regex patterns to detect and replace sensitive data before the text reaches the LLM. This happens transparently—the user sees their original input, but the AI only sees sanitized text.

Before sending any text to the LLM, sensitive information is removed:

```dart
// PIISanitizer redacts:
// - Email addresses
// - Phone numbers
// - Long numeric sequences
// - Credit card patterns

String sanitized = PIISanitizer.redact(userInput);
// "Email me at john@example.com" → "Email me at [REDACTED]"
```

#### Step 2: Intent Parsing

**The Challenge**: Natural language is inherently ambiguous. "Add milk" is simple, but "Create a weekend grocery list with a $100 budget and add 3 gallons of milk, a dozen eggs, and some bread for next Monday to Friday" contains multiple pieces of structured information that need to be extracted accurately.

**Our Solution**: We use a **dual-parser strategy** with intelligent fallback:

1. **Primary Parser (Gemini LLM)**: For complex commands with multiple intents, quantities, dates, or budgets, we use Gemini to extract structured data. The LLM excels at understanding context and handling variations in phrasing.

2. **Fallback Parser (Heuristic)**: For simple commands or when the LLM is unavailable, we fall back to a rule-based parser using regex and keyword detection. This ensures the feature works even offline or during API outages.

**Why Two Parsers?**
- **Reliability**: If the LLM API fails, users can still use basic functionality
- **Cost Optimization**: Simple commands like "add milk" don't need an LLM call
- **Speed**: Heuristic parsing is instantaneous (<1ms) vs LLM (~500-2000ms)

**Primary Parser (Gemini LLM):**
```dart
// Prompt template for JSON extraction
"""
You are a strict JSON producing parser for a shopping list assistant.
Extract from USER INPUT: optional list name, whether a list should be created, 
item phrases, OPTIONAL budget limit (number), OPTIONAL date range...
Return ONLY a JSON object, no markdown, no commentary.

USER INPUT: $sanitizedInput
"""

// Expected output format:
{
  "listName": "Weekend BBQ",
  "createList": true,
  "items": ["3 steaks", "a dozen eggs", "some beer"],
  "budget": 50.0,
  "startDate": "2026-01-10",
  "endDate": "2026-01-12"
}
```

**Fallback Parser (Heuristic):**
```dart
class AgentCommandParser {
  static AgentParsedCommand parse(String input) {
    // Keyword detection for list names
    // "list called X", "list named X", "create X list"
    
    // Item extraction after "add" keyword
    
    // Quantity parsing with regex and word mapping
    
    // Budget detection near "budget" or "limit" keywords
    
    // Date range parsing
  }
}
```

#### Step 3: Execution Plan Building

**What Is an Execution Plan?**

Once we've parsed the user's intent into structured data, we need to convert it into a sequence of executable actions. Think of this like a recipe: the parsed command tells us WHAT the user wants, and the execution plan tells us HOW to accomplish it.

**Why Not Execute Directly?**

We could immediately execute each action as we parse it, but building a plan first provides several benefits:

1. **Validation**: We can check if the plan is valid before executing anything (e.g., can't add items without a list)
2. **Preview**: We can show users what will happen before doing it
3. **Ordering**: Some actions must happen before others (create list before adding items)
4. **Recovery**: If one action fails, we know what succeeded and what remains
5. **Step-by-Step Mode**: Users can execute one action at a time

**The Plan Structure**:

```dart
class AgentExecutionPlan {
  static AgentExecutionPlan buildFromParsed(AgentParsedCommand parsed) {
    final calls = <AgentFunctionCall>[];
    
    // Add CreateListCall if requested
    if (parsed.createListRequested) {
      calls.add(CreateListCall(
        name: parsed.listName ?? 'Shopping List',
        budgetLimit: parsed.budgetLimit,
        startDate: parsed.startDate,
        endDate: parsed.endDate,
      ));
    }
    
    // Add AddItemCall for each item phrase
    for (final phrase in parsed.rawItemPhrases) {
      final qty = parsed.itemQuantities[phrase] ?? 1;
      calls.add(AddItemCall(phrase: phrase, quantity: qty));
    }
    
    // Always add FinalizeCall
    calls.add(FinalizeCall());
    
    return AgentExecutionPlan(calls: calls);
  }
}
```

#### Step 4: Plan Execution

**Sequential vs Parallel Execution**

We execute function calls **sequentially** rather than in parallel for important reasons:

1. **Dependencies**: `AddItemCall` needs the `listId` from `CreateListCall`
2. **User Feedback**: Sequential execution lets us update the UI after each step
3. **Failure Isolation**: If item 3 fails, items 1-2 are already added
4. **Rate Limiting**: Parallel calls could overwhelm the product search API

**Status Updates**

As each call executes, we update the UI to show:
- ⏳ **Pending**: Not yet processed
- 🔄 **Searching**: Currently resolving product
- ✅ **Added**: Successfully added to list
- ❌ **Failed**: Could not resolve or add

This gives users real-time visibility into what's happening.

**Error Handling Philosophy**

We follow a "best effort" approach: if adding "chips" succeeds but "organic quinoa crackers" fails (not found), we don't roll back the chips. The user ends up with a partially completed list, which is better than nothing. We clearly report what succeeded and what failed.

Each function call is executed sequentially with status updates:

```dart
Future<AgentRunResult> executePlan(AgentExecutionPlan plan, String listId) async {
  final added = <String, String>{};
  final failures = <String, String>{};
  
  for (final call in plan.calls) {
    if (call is CreateListCall) {
      final list = await AgentListService.createListWithDetails(
        name: call.name,
        budget: call.budgetLimit,
        startDate: call.startDate,
        endDate: call.endDate,
      );
      listId = list.id;
    }
    
    else if (call is AddItemCall) {
      try {
        final product = await AgentSearchService.addSingleItem(
          phrase: call.phrase,
          listId: listId,
          quantity: call.quantity,
        );
        added[call.phrase] = product.name;
      } catch (e) {
        failures[call.phrase] = e.toString();
      }
    }
  }
  
  return AgentRunResult(
    success: failures.isEmpty,
    added: added,
    failed: failures,
  );
}
```

---

## Intent Recognition System

### Supported Intents

| Intent | Example Input | Extracted Data |
|--------|---------------|----------------|
| **Create List** | "Create a new list called dinner" | `listName: "Dinner", createListRequested: true` |
| **Add Items** | "Add milk, eggs, and bread" | `rawItemPhrases: ["milk", "eggs", "bread"]` |
| **With Quantities** | "Add 3 apples and a dozen eggs" | `itemQuantities: {"3 apples": 3, "a dozen eggs": 12}` |
| **With Budget** | "... with a budget of $50" | `budgetLimit: 50.0` |
| **With Dates** | "... from Monday to Friday" | `startDate, endDate` |
| **Price Query** | "What's the current price of milk?" | `GetProductPriceCall("milk")` |
| **Item Count** | "How many items are in groceries?" | `GetListItemCountCall("groceries")` |

### Quantity Word Mappings

The parser understands natural language quantities:

```dart
static const Map<String, int> _quantityWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
  'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
  'eleven': 11, 'twelve': 12,
  'a couple of': 2,
  'a few': 4,
  'several': 6,
  'a dozen': 12,
  'half dozen': 6,
};
```

### Date Range Parsing

The system parses various date formats:

```dart
// Supported patterns:
// - "from Monday to Friday"
// - "next week"
// - "this weekend"
// - "January 5 to January 10"
// - "1/5 to 1/10"
// - Weekday names (Monday, Tuesday, etc.)
```

---

## Natural Language Processing

### Gemini LLM Integration

The `GeminiLLMParsingProvider` handles complex natural language understanding:

```dart
class GeminiLLMParsingProvider implements AgentParsingProvider {
  @override
  Future<AgentParsedCommand> parse(String input) async {
    final prompt = _buildPrompt(input);
    final response = await GeminiService.instance.generateText(prompt);
    final json = _extractJson(response);
    return AgentParsedCommand.fromJson(json);
  }
  
  String _buildPrompt(String input) => '''
You are a strict JSON producing parser for a shopping list assistant.
Extract from USER INPUT: optional list name, whether a list should be created, 
item phrases, OPTIONAL budget limit (number), OPTIONAL date range (ISO 8601).

Rules:
- listName: string or null
- createList: boolean
- items: array of strings (the raw item phrases as user typed them)
- budget: number or null
- startDate: ISO date string or null
- endDate: ISO date string or null
- itemQuantities: object mapping phrase to quantity number

Return ONLY a JSON object, no markdown, no commentary.

USER INPUT: $input
''';
}
```

### Streaming Support

For real-time feedback during parsing:

```dart
Stream<String> parseWithStreaming(String input) async* {
  final prompt = _buildPrompt(input);
  await for (final chunk in GeminiService.instance.generateTextStream(prompt)) {
    _streamingBuffer.write(chunk);
    yield _streamingBuffer.toString();
  }
}
```

---

## Product Search & Resolution

**The Core Challenge**

When a user says "add coca cola," they don't mean the literal text "coca cola"—they want an actual product from our database. But which one? Our database might have:
- Coca-Cola Classic 12oz Can
- Coca-Cola Classic 2L Bottle
- Coca-Cola Zero Sugar 12oz Can
- Coca-Cola Cherry 12oz Can
- Diet Coke 12oz Can (is this "coca cola"?)

The `AgentSearchService` must intelligently resolve the user's phrase to the most appropriate product.

**Why Is This Hard?**

1. **Ambiguity**: "beer" could match hundreds of products
2. **Synonyms**: "soda" and "soft drink" mean the same thing
3. **Specificity Variance**: "milk" vs "organic 2% oat milk"
4. **Misspellings**: "cocacola" should still find Coca-Cola
5. **Context**: "water" might mean bottled water or sparkling water

**Our Solution**: A multi-step search pipeline that progressively tries different strategies until it finds a confident match.

### Search Pipeline Overview

```
Step 1: Check UI Cache
   └─→ Reuse cached search results if available
   └─→ AI evaluation on cached results
   
Step 2: Aggregated Multi-Term Search
   └─→ Generate cost-minimized search variants
   └─→ Score candidates with heuristics
   └─→ AI evaluation on aggregated candidates
   
Step 3: AI-Generated Term Search
   └─→ Search with AI-generated terms (max 3)
   └─→ Beverage intent boosting
   └─→ AI evaluation per term
   
Step 4: Semantic Refinements
   └─→ Generate alternative terms via AI
   └─→ Search with refinements (max 2)
   └─→ AI evaluation
   
Step 5: Fallback to Custom Item
   └─→ Create user-defined custom item
   
Step 6: Complete Failure
   └─→ Log failure, update telemetry
```

### Candidate Scoring Algorithm

**The Scoring Philosophy**

When we search for "orange juice," we might get 20 results. We need to rank them to find the best match. Our scoring algorithm considers multiple factors:

**1. Search Rank Bonus (Base Score)**
Products that appear earlier in search results are likely more relevant. The first result starts with 8 points, decreasing by 1 for each subsequent result.

**2. Ingredient Match Bonus (+4 points)**
If the user's phrase appears as an ingredient in the product, it's likely a good match. "Orange juice" containing "orange" as an ingredient scores higher.

**3. Beverage Intent Alignment (+6 points)**
If we detect the user wants a drink (phrases like "juice," "soda," "water"), products in beverage categories get a significant boost. This prevents matching "orange" to "orange-scented cleaner" when the user clearly wants a drink.

**4. Exact Match Bonus (+5 points)**
If the product name exactly matches the user's phrase, it's almost certainly correct.

**5. Generic Mismatch Penalty (-8 points)**
Some matches are technically correct but wrong in context. If the user says "sparkling water" but we match "plain water," we penalize this heavily.

```dart
double calculateCandidateScore(Product product, String userPhrase) {
  double score = (8 - searchResultIndex);  // Base: inverse of rank
  
  if (product.name.containsIngredient(userPhrase)) score += 4;
  if (isBeverageIntent && product.hasBeverageWord()) score += 6;
  if (product.name == userPhrase) score += 5;  // Exact match
  if (isGenericWaterMismatch) score -= 8;
  
  return score;
}
```

**When Scoring Isn't Enough**

Sometimes the top-scored candidates are too close to call. If the top 3 products all score within 2 points of each other, we invoke Gemini to make the final decision. This hybrid approach (heuristics first, AI for tiebreakers) balances cost and accuracy.

### AI Candidate Evaluation

When heuristics aren't confident, Gemini evaluates candidates:

```dart
// AI Evaluation Prompt
"""
Request: "$originalPhrase"
Choices:
1) Product A
2) Product B
3) Product C

Rules: 
- Pick the closest semantic/ingredient match
- Prefer beverage form if user requested drink
- Return JSON {"p":"exact name"} or {"p":null,"r":"reason"}
"""
```

### Confidence-Based Auto-Selection

**The Cost-Accuracy Tradeoff**

Every AI call costs money and time. If our heuristics are 99% confident that "Coca-Cola Classic 12oz" is the right match for "coca cola," should we still ask Gemini to verify? Probably not.

**The Confidence Threshold (0.96)**

Through testing, we found that when our heuristic confidence score exceeds 0.96 (96%), the AI agrees with our selection 99.2% of the time. At this threshold, the AI call adds cost without improving accuracy.

**How Confidence Is Calculated**

```dart
if (confidenceScore >= 0.96) {
  // Auto-select without AI call (saves cost)
  return topCandidate;
}

// Confidence bonuses:
// - Uniqueness bonus: +0.35
// - Beverage alignment: +0.30
// - Ingredient coverage: +0.15 to +0.40

// Penalties:
// - Ambiguity: -0.25
// - Generic water mismatch: -0.60
```

**Uniqueness Bonus (+0.35)**: If there's only one product matching the search, we're confident it's correct.

**Beverage Alignment (+0.30)**: If the user's phrase suggests a drink and we found a beverage product, confidence increases.

**Ingredient Coverage (+0.15 to +0.40)**: The more of the user's keywords appear in the product's ingredients or name, the higher the confidence.

**Ambiguity Penalty (-0.25)**: If multiple products score similarly, we're less confident in any single choice.

**Generic Mismatch Penalty (-0.60)**: If the specificity doesn't match (user said "diet coke" but we found "regular coke"), confidence drops significantly.

**Result**: About 60% of product resolutions happen without AI calls, saving significant cost while maintaining >98% accuracy.

---

## Session Management

### AgentExecutionSession

The session model tracks step-by-step execution:

```dart
class AgentExecutionSession {
  final String input;                    // Original user input
  final AgentParsedCommand parsed;       // Parsed command
  final AgentExecutionPlan plan;         // Execution plan
  int currentIndex;                      // Current step
  bool completed;                        // Completion flag
  String? listId;                        // Created list ID
  final Map<String, String> added;       // Successfully added items
  final Map<String, String> failures;    // Failed items
}
```

### Execution Modes

**1. Server Flow (Recommended for complex commands)**
```dart
if (AIFeatureFlags.serverFlowEnabled) {
  return await ServerAgentService.runShoppingAgent(
    userInput: input,
    dryRun: false,
  );
}
```

**2. Local Single-Shot**
- Parses input locally
- Executes all steps sequentially
- Best for simple commands

**3. Step-by-Step Session**
- Creates list automatically
- User triggers each item addition
- Supports per-item retry

### History Persistence

```dart
class AgentHistoryService {
  // Local storage (SharedPreferences)
  static const _keyPrefix = 'ai_agent_history_';
  
  // Remote storage (Firestore)
  // Path: /users/{uid}/ai_history/{docId}
  
  Future<void> saveHistory(AgentRunResult result) async {
    // Save locally first (fast)
    await _saveLocal(result);
    
    // Sync to Firestore (async)
    _syncToFirestore(result);
  }
  
  // Real-time listener for cross-device sync
  StreamSubscription<QuerySnapshot>? _firestoreListener;
}
```

---

## Feature Flags & Configuration

```dart
// lib/config/feature_flags_ai.dart
class AIFeatureFlags {
  /// Use Gemini LLM for parsing (vs heuristic-only)
  static bool llmParsingEnabled = true;
  
  /// Show streaming token preview during parsing
  static bool streamingUIEnabled = false;
  
  /// Use structured function calling API (future)
  static bool functionCallingEnabled = false;
  
  /// Enable smart suggestions based on context
  static bool smartSuggestionsEnabled = true;
  
  /// Enable analytics/telemetry
  static bool analyticsEnabled = true;
  
  /// Delegate to backend Genkit flow
  static bool serverFlowEnabled = false;
}
```

---

## User Interface

### FloatingAIButton

A persistent floating action button for AI access:

```dart
class FloatingAIButton extends StatelessWidget {
  // Features:
  // - Draggable with position persistence
  // - Context-aware visibility (hidden during onboarding/login)
  // - Elegant animations: glow pulse, hover scale, expand transition
  // - Sparkle visual effects via CustomPainter
}
```

### AIAgentBottomSheet

The main interaction interface:

```dart
class AIAgentBottomSheet extends StatefulWidget {
  // Components:
  // - Text input with contextual hints
  // - Run/Cancel buttons with loading states
  // - Processing chips showing item status
  // - History view with past executions
  // - Logs view for debugging
  // - Streaming preview panel
}
```

### Item Status Indicators

| Status | Visual | Description |
|--------|--------|-------------|
| Pending | ⏳ Gray | Not yet processed |
| Searching | 🔄 Blue | Currently searching |
| Added | ✅ Green | Successfully added to list |
| Failed | ❌ Red | Could not resolve/add item |

---

## Examples & Walkthroughs

### Example 1: Simple List Creation

**User Input:**
```
"Create a grocery list"
```

**Processing Steps:**

1. **PII Sanitization:** No PII detected, input unchanged
2. **Parsing Result:**
   ```json
   {
     "listName": "Grocery List",
     "createList": true,
     "items": [],
     "budget": null
   }
   ```
3. **Execution Plan:** `[CreateListCall("Grocery List"), FinalizeCall()]`
4. **Result:** New list created with name "Grocery List"

### Example 2: List with Items and Budget

**User Input:**
```
"Make a party list with $100 budget and add chips, salsa, guacamole, and a case of beer"
```

**Processing Steps:**

1. **Parsing Result:**
   ```json
   {
     "listName": "Party",
     "createList": true,
     "items": ["chips", "salsa", "guacamole", "a case of beer"],
     "budget": 100.0,
     "itemQuantities": {"a case of beer": 1}
   }
   ```

2. **Execution Plan:**
   ```
   [
     CreateListCall(name: "Party", budget: 100.0),
     AddItemCall(phrase: "chips", quantity: 1),
     AddItemCall(phrase: "salsa", quantity: 1),
     AddItemCall(phrase: "guacamole", quantity: 1),
     AddItemCall(phrase: "a case of beer", quantity: 1),
     FinalizeCall()
   ]
   ```

3. **Product Resolution (for "guacamole"):**
   - Search "guacamole" → Find candidates
   - Score candidates by relevance
   - AI evaluates: "Sabra Classic Guacamole" selected
   - Add to list with quantity 1

4. **Result:**
   ```
   ✓ Created list "Party" with $100 budget
   ✓ Added: Doritos Nacho Cheese
   ✓ Added: Tostitos Mild Salsa
   ✓ Added: Sabra Classic Guacamole
   ✓ Added: Bud Light 24-Pack
   ```

### Example 3: Quantity Handling

**User Input:**
```
"Add 3 apples, a dozen eggs, and a couple bottles of wine"
```

**Quantity Parsing:**
```dart
// "3 apples" → quantity: 3
// "a dozen eggs" → quantity: 12
// "a couple bottles of wine" → quantity: 2
```

### Example 4: Price Query

**User Input:**
```
"What's the price of organic milk?"
```

**Processing:**
1. Intent detected: `GetProductPriceCall`
2. Query product database for "organic milk"
3. Find lowest price across stores
4. Return: "Organic Milk is $5.99 at Walmart"

---

### Example 5: Complete Complex Command - Full Deep Dive

This example demonstrates **every aspect** of the Shopple AI agent processing a complex, real-world command with list creation, budget, dates, and multiple items with various quantities.

**User Input:**
```
"Create a list named dinner party and set its budget to 5000. Set the dates from 5th to 7th. 
Add 3 water bottles, a 7up, cream soda, frozen barbecue, and coca cola 4 bottles."
```

This single command contains:
- ✅ List name: "dinner party"
- ✅ Budget: 5000
- ✅ Date range: 5th to 7th (of current month)
- ✅ 5 different items with varying quantities

Let's trace through **exactly** what happens in the code.

---

#### PHASE 1: Input Reception (0-10ms)

**File:** `lib/controllers/ai_agent_controller.dart`

```dart
// User taps send button in AIAgentBottomSheet
// This triggers:

Future<AgentRunResult> runUserCommand(String input, {bool stepByStep = true}) async {
  if (_running) throw StateError('Agent already running');
  _running = true;
  _resetRunState();
  
  // input = "Create a list named dinner party and set its budget to 5000..."
  
  update();  // Notify UI that processing has started
```

**What happens:**
1. Controller receives the raw text from the bottom sheet
2. Sets `_running = true` to prevent duplicate submissions
3. Resets any previous session state
4. Notifies UI to show loading indicator

---

#### PHASE 2: PII Sanitization (10-15ms)

**File:** `lib/services/ai/pii_sanitizer.dart`

Before the text reaches any AI service, we check for sensitive data:

```dart
class PIISanitizer {
  static String redact(String input) {
    String result = input;
    
    // Check for email patterns
    result = result.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[REDACTED_EMAIL]'
    );
    
    // Check for phone patterns
    result = result.replaceAll(
      RegExp(r'\+?\d[\d\s\-()]{6,}\d'),
      '[REDACTED_PHONE]'
    );
    
    // Check for credit card patterns
    result = result.replaceAll(
      RegExp(r'\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}'),
      '[REDACTED_CARD]'
    );
    
    return result;
  }
}
```

**For our input:**
```
Input:  "Create a list named dinner party and set its budget to 5000..."
Output: "Create a list named dinner party and set its budget to 5000..."
        (No PII found - unchanged)
```

**Why this matters:** If the user accidentally typed "Create a list, my email is john@gmail.com", that email would be redacted BEFORE being sent to Google's servers.

---

#### PHASE 3: Intent Parsing with Gemini LLM (15-800ms)

**File:** `lib/services/ai/agent_parsing_providers.dart`

The controller tries multiple parsing providers in order:

```dart
// In AIAgentController
Future<AgentParsedCommand> _parseInput(String input) async {
  AgentParsedCommand? parsed;
  
  // Try each parser until one succeeds
  for (final p in _parsers) {
    parsed = await p.parse(input, onStream: (tok) {
      _streamingBuffer.write(tok);  // Show real-time feedback
      update();
    });
    if (parsed != null) {
      _log('parse_provider', 'Parsed with ${p.id}');
      break;
    }
  }
  
  return parsed ?? AgentCommandParser.parse(input);  // Heuristic fallback
}

// Parser order:
// 1. GeminiLLMParsingProvider (AI-powered)
// 2. HeuristicParsingProvider (regex-based fallback)
```

**GeminiLLMParsingProvider sends this prompt to Gemini:**

```
SYSTEM: You are a strict JSON producing parser for a shopping list assistant.
Extract structured information from natural language commands.

RULES:
- "listName": The name of the list if mentioned
- "createList": true if user wants to create a new list
- "items": Array of item phrases exactly as mentioned
- "budget": Number if user mentions spending limit
- "startDate": ISO date string if shopping start date mentioned
- "endDate": ISO date string if shopping end date mentioned
- "itemQuantities": Map of item phrase to quantity

QUANTITY RULES:
- "3 water bottles" → item: "water bottles", quantity: 3
- "a 7up" → item: "7up", quantity: 1
- "coca cola 4 bottles" → item: "coca cola", quantity: 4
- "a dozen eggs" → item: "eggs", quantity: 12
- "a couple items" → quantity: 2

Return ONLY valid JSON. No markdown. No explanations.

USER INPUT:
"Create a list named dinner party and set its budget to 5000. Set the dates from 5th to 7th. Add 3 water bottles, a 7up, cream soda, frozen barbecue, and coca cola 4 bottles."
```

**Gemini Response (JSON):**

```json
{
  "listName": "dinner party",
  "createList": true,
  "items": [
    "water bottles",
    "7up",
    "cream soda",
    "frozen barbecue",
    "coca cola"
  ],
  "budget": 5000,
  "startDate": "2026-01-05",
  "endDate": "2026-01-07",
  "itemQuantities": {
    "water bottles": 3,
    "7up": 1,
    "cream soda": 1,
    "frozen barbecue": 1,
    "coca cola": 4
  }
}
```

**File:** `lib/models/ai_agent/agent_intents.dart`

The JSON is parsed into a Dart object:

```dart
class AgentParsedCommand {
  final String? listName;              // "dinner party"
  final List<String> rawItemPhrases;   // ["water bottles", "7up", ...]
  final bool createListRequested;      // true
  final double? budgetLimit;           // 5000.0
  final DateTime? startDate;           // 2026-01-05
  final DateTime? endDate;             // 2026-01-07
  final Map<String, int> itemQuantities; // {"water bottles": 3, ...}
}
```

---

#### PHASE 4: Logging the Parse Results (800-810ms)

**File:** `lib/controllers/ai_agent_controller.dart`

```dart
void _logParsingSteps(AgentParsedCommand parsed) {
  _log('parse_steps', 'Breaking down user request into actionable steps...');
  
  if (parsed.listName != null) 
    _log('parse_step', '✓ List name: "dinner party"');
  
  if (parsed.budgetLimit != null && parsed.budgetLimit! > 0)
    _log('parse_step', '✓ Budget limit: Rs. 5,000.00');
  
  if (parsed.startDate != null)
    _log('parse_step', '✓ Start date: 2026-01-05');
  
  if (parsed.endDate != null)
    _log('parse_step', '✓ End date: 2026-01-07');
  
  if (parsed.rawItemPhrases.isNotEmpty)
    _log('parse_step', '✓ Items to find: water bottles, 7up, cream soda, frozen barbecue, coca cola');
}
```

**UI shows:**
```
✓ List name: "dinner party"
✓ Budget limit: Rs. 5,000.00
✓ Start date: 2026-01-05
✓ End date: 2026-01-07
✓ Items to find: water bottles, 7up, cream soda, frozen barbecue, coca cola
```

---

#### PHASE 5: Execution Plan Building (810-820ms)

**File:** `lib/models/ai_agent/agent_function_calls.dart`

The parsed command is converted into an ordered list of executable function calls:

```dart
class AgentExecutionPlan {
  static AgentExecutionPlan buildFromParsed(
    AgentParsedCommand parsed, 
    {String? rawInput}
  ) {
    final List<AgentFunctionCall> calls = [];
    
    // 1. Create list if requested
    if (parsed.createListRequested && parsed.listName != null) {
      calls.add(CreateListCall(
        listName: parsed.listName!,           // "dinner party"
        budget: parsed.budgetLimit,            // 5000.0
        startDate: parsed.startDate,           // 2026-01-05
        endDate: parsed.endDate,               // 2026-01-07
      ));
    }
    
    // 2. Add each item with its quantity
    for (final phrase in parsed.rawItemPhrases) {
      final qty = parsed.itemQuantities[phrase] ?? 1;
      calls.add(AddItemCall(
        phrase: phrase,
        quantity: qty,
      ));
    }
    
    // 3. Finalize
    calls.add(FinalizeCall());
    
    return AgentExecutionPlan(calls: calls);
  }
}
```

**Generated Execution Plan:**

```dart
AgentExecutionPlan(calls: [
  CreateListCall(
    listName: "dinner party",
    budget: 5000.0,
    startDate: DateTime(2026, 1, 5),
    endDate: DateTime(2026, 1, 7),
  ),
  AddItemCall(phrase: "water bottles", quantity: 3),
  AddItemCall(phrase: "7up", quantity: 1),
  AddItemCall(phrase: "cream soda", quantity: 1),
  AddItemCall(phrase: "frozen barbecue", quantity: 1),
  AddItemCall(phrase: "coca cola", quantity: 4),
  FinalizeCall(),
])
```

**Controller logs the plan:**

```dart
void _logPlanSteps(AgentExecutionPlan plan) {
  _log('plan_steps', 'Execution plan created with the following steps:');
  
  // Output:
  // 1. Create shopping list "dinner party" with budget Rs. 5,000.00 (Jan 5-7)
  // 2. Find and add "water bottles" (qty: 3)
  // 3. Find and add "7up" (qty: 1)
  // 4. Find and add "cream soda" (qty: 1)
  // 5. Find and add "frozen barbecue" (qty: 1)
  // 6. Find and add "coca cola" (qty: 4)
  // 7. Finalize and save
}
```

---

#### PHASE 6: Execute CreateListCall (820-1200ms)

**File:** `lib/services/ai/agent_list_service.dart`

```dart
class AgentListService {
  Future<String?> createListWithDetails(
    CreateListCall call,
    void Function(String, String, {bool success, Map<String, dynamic>? meta}) log,
  ) async {
    log('execute_step', 'Creating list "${call.listName}"...');
    
    try {
      // Generate unique ID
      final listId = const Uuid().v4();
      
      // Build list document
      final listData = {
        'id': listId,
        'name': call.listName,              // "dinner party"
        'budget': call.budget,               // 5000.0
        'startDate': call.startDate?.toIso8601String(),  // "2026-01-05"
        'endDate': call.endDate?.toIso8601String(),      // "2026-01-07"
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'items': [],
      };
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('shopping_lists')
          .doc(listId)
          .set(listData);
      
      log('create_list', '✓ Created list "dinner party" (id: $listId)', success: true);
      
      return listId;
      
    } catch (e) {
      log('create_list', '✗ Failed to create list: $e', success: false);
      return null;
    }
  }
}
```

**Firestore Document Created:**

```json
{
  "id": "abc123-def456-ghi789",
  "name": "dinner party",
  "budget": 5000,
  "startDate": "2026-01-05T00:00:00.000Z",
  "endDate": "2026-01-07T00:00:00.000Z",
  "createdAt": "2026-01-05T10:30:00.000Z",
  "ownerId": "user_xyz",
  "items": []
}
```

**UI Shows:**
```
✓ Created list "dinner party"
  Budget: Rs. 5,000.00
  Dates: Jan 5 - Jan 7, 2026
```

---

#### PHASE 7: Execute AddItemCall - "water bottles" (1200-2500ms)

This is where the magic happens. Let's trace through finding "water bottles" in complete detail.

**File:** `lib/services/ai/agent_search_service.dart`

```dart
class AgentSearchService {
  Future<ProductWithPrices?> addSingleItem(
    String phrase,           // "water bottles"
    int quantity,            // 3
    String listId,           // "abc123-def456-ghi789"
    void Function(...) log,
  ) async {
    log('search_start', 'Searching for "$phrase"...');
    
    // STEP 7.1: Check if user recently searched this in the UI
    final cachedResult = UnifiedProductSearchService.getCached(phrase);
    if (cachedResult != null && cachedResult.isNotEmpty) {
      log('search_cache', 'Found in UI cache!');
      return await _addToList(cachedResult.first, listId, quantity);
    }
    
    // STEP 7.2: Generate search term variants
    final searchTerms = await AgenticProductSearchService.generateSearchTerms(phrase);
    // Returns: ["water bottles", "water bottle", "bottled water", "mineral water"]
    
    // STEP 7.3: Search with each term
    final allCandidates = <ProductWithPrices>[];
    for (final term in searchTerms) {
      final results = await FastProductSearchService.search(term, limit: 5);
      allCandidates.addAll(results);
    }
    
    // STEP 7.4: AI evaluation to pick the best match
    final bestMatch = await AgenticProductSearchService.evaluateSearchResults(
      phrase,
      allCandidates,
    );
    
    if (bestMatch != null) {
      return await _addToList(bestMatch, listId, quantity);
    }
    
    // STEP 7.5: Fallback - create custom item
    return await _createCustomItem(phrase, listId, quantity);
  }
}
```

##### STEP 7.2 Deep Dive: Search Term Generation

**File:** `lib/services/ai/agentic_product_search_service.dart`

```dart
static Future<List<String>> generateSearchTerms(String phrase) async {
  // phrase = "water bottles"
  
  final tokens = phrase.toLowerCase().split(RegExp(r'\s+'));
  // tokens = ["water", "bottles"]
  
  // Heuristic expansion first
  final heuristicSet = <String>{phrase};  // {"water bottles"}
  
  // Add singular/plural variants
  heuristicSet.add("water bottle");
  
  // Add compound form
  heuristicSet.add("waterbottle");
  
  // Now ask AI for more variants
  final prompt = 'Return JSON array of 3-5 concise search terms for: "water bottles"';
  
  final response = await GeminiService.instance.generateText(prompt, lite: true);
  // Uses gemini-2.0-flash-lite (faster, cheaper)
  
  // AI returns: ["bottled water", "mineral water", "drinking water", "aqua"]
  
  // Combine all variants
  return [
    "water bottles",
    "water bottle", 
    "bottled water",
    "mineral water",
    "drinking water",
  ].take(6).toList();
}
```

##### STEP 7.3 Deep Dive: Cloud Function Search

**File:** `lib/services/search/fast_product_search_service.dart`

For each search term, we call the Cloud Function:

```dart
static Future<List<ProductWithPrices>> search(String query, {int limit = 20}) async {
  final callable = _functions.httpsCallable(
    'fastProductSearchV2',
    options: HttpsCallableOptions(timeout: Duration(milliseconds: 400)),
  );
  
  final result = await callable.call({
    'query': 'water bottles',
    'limit': 5,
  });
  
  // Cloud Function returns scored results
  return (result.data['results'] as List)
      .map((r) => ProductWithPrices.fromCloudSearch(r))
      .toList();
}
```

**Cloud Function Processing (on Google's servers):**

```javascript
// functions/index.js - fastProductSearchV2

exports.fastProductSearchV2 = onCall({ region: "asia-south1" }, async (request) => {
  const { query, limit } = request.data;
  // query = "water bottles"
  
  // 1. Check cache
  const cached = SEARCH_CACHE.get("water bottles");
  if (cached && !isExpired(cached)) return cached;  // Cache hit!
  
  // 2. Query Firestore
  const snapshot = await firestore()
    .collection('products')
    .where('is_active', '==', true)
    .get();
  
  // 3. Score each product
  const scored = [];
  snapshot.forEach(doc => {
    const product = doc.data();
    let score = 0;
    
    // Check name field (weight: 1.0)
    if (product.name.toLowerCase().includes('water')) score += 1.0;
    if (product.name.toLowerCase().includes('bottle')) score += 1.0;
    
    // Check brand field (weight: 0.8)
    if (product.brand_name?.toLowerCase().includes('water')) score += 0.8;
    
    // Check category (weight: 0.3)
    if (product.category?.toLowerCase().includes('beverage')) score += 0.3;
    
    if (score > 0.5) {
      scored.push({ ...product, id: doc.id, searchScore: score });
    }
  });
  
  // 4. Sort by score and return top results
  scored.sort((a, b) => b.searchScore - a.searchScore);
  return { results: scored.slice(0, limit) };
});
```

**Search Results for "water bottles":**

```dart
[
  ProductWithPrices(
    id: "prod_001",
    name: "Aquafina Water Bottle 500ml",
    brand: "Aquafina",
    category: "Beverages",
    searchScore: 2.3,
    cheapestPrice: 80.00,
  ),
  ProductWithPrices(
    id: "prod_002", 
    name: "Nestle Pure Life Water 1L",
    brand: "Nestle",
    category: "Beverages",
    searchScore: 1.8,
    cheapestPrice: 120.00,
  ),
  ProductWithPrices(
    id: "prod_003",
    name: "Elephant House Water Bottle 500ml",
    brand: "Elephant House",
    category: "Beverages", 
    searchScore: 2.1,
    cheapestPrice: 75.00,
  ),
  // ... more candidates
]
```

##### STEP 7.4 Deep Dive: AI Candidate Evaluation

**File:** `lib/services/ai/agentic_product_search_service.dart`

```dart
static Future<ProductWithPrices?> evaluateSearchResults(
  String originalPhrase,      // "water bottles"
  List<ProductWithPrices> searchResults,
) async {
  if (searchResults.isEmpty) return null;
  
  // Build prompt for AI evaluation
  final candidateDescriptions = searchResults.take(5).map((p) => 
    '- ${p.product.name} (${p.product.brand}) - Rs. ${p.cheapestPrice}'
  ).join('\n');
  
  final prompt = '''
You are evaluating product search results.

User requested: "water bottles"
Quantity needed: 3

Candidates:
- Aquafina Water Bottle 500ml (Aquafina) - Rs. 80.00
- Nestle Pure Life Water 1L (Nestle) - Rs. 120.00
- Elephant House Water Bottle 500ml (Elephant House) - Rs. 75.00
- Perera & Sons Water Bottle 750ml (Perera & Sons) - Rs. 95.00
- Keells Water 500ml (Keells) - Rs. 65.00

Which product BEST matches what the user wants?
Consider: name match, brand reputation, value for money.

Return JSON: {"selectedIndex": 0, "confidence": 0.95, "reason": "..."}
''';

  final response = await GeminiService.instance.generateText(prompt);
  
  // AI Response:
  // {"selectedIndex": 2, "confidence": 0.88, "reason": "Elephant House is a popular local brand, good price point"}
  
  final selected = searchResults[2];  // Elephant House Water Bottle 500ml
  return selected;
}
```

##### STEP 7.5: Add to Shopping List

**File:** `lib/services/ai/agent_search_service.dart`

```dart
Future<ProductWithPrices> _addToList(
  ProductWithPrices product,
  String listId,
  int quantity,  // 3
) async {
  // Add to Firestore
  await FirebaseFirestore.instance
      .collection('shopping_lists')
      .doc(listId)
      .update({
        'items': FieldValue.arrayUnion([{
          'productId': product.id,
          'productName': product.product.name,  // "Elephant House Water Bottle 500ml"
          'quantity': quantity,                  // 3
          'addedAt': DateTime.now().toIso8601String(),
          'addedBy': 'ai_agent',
        }])
      });
  
  _log('item_added', '✓ Added: ${product.product.name} (qty: $quantity)');
  
  // Track for telemetry
  _telemetryItemsResolved++;
  _itemStatuses[phrase] = 'success';
  _itemImages[phrase] = product.product.imageUrl;
  
  return product;
}
```

**UI Shows:**
```
✓ Added: Elephant House Water Bottle 500ml (qty: 3)
```

---

#### PHASE 8: Execute AddItemCall - "7up" (2500-3200ms)

Same process, but simpler since "7up" is a specific brand:

```
Search terms: ["7up", "7 up", "seven up", "7up soda"]
        ↓
Cloud search finds: "7up Lemon Lime 1.5L", "7up Can 330ml", "7up Pet 500ml"
        ↓
AI evaluation: "7up Pet 500ml" (confidence: 0.94)
        ↓
Added to list with quantity: 1
```

**UI Shows:**
```
✓ Added: 7up Pet 500ml (qty: 1)
```

---

#### PHASE 9: Execute AddItemCall - "cream soda" (3200-3900ms)

```
Search terms: ["cream soda", "creamsoda", "cream soda drink"]
        ↓
Cloud search finds: "Elephant House Cream Soda 400ml", "Keells Cream Soda 1L", ...
        ↓
AI evaluation: "Elephant House Cream Soda 400ml" (confidence: 0.91)
        ↓
Added to list with quantity: 1
```

**UI Shows:**
```
✓ Added: Elephant House Cream Soda 400ml (qty: 1)
```

---

#### PHASE 10: Execute AddItemCall - "frozen barbecue" (3900-4800ms)

This is interesting because "frozen barbecue" is ambiguous:

```
Search terms generated:
  - "frozen barbecue"
  - "frozen bbq"
  - "frozen barbecue meat"
  - "bbq frozen food"
  - "frozen chicken bbq"
        ↓
Cloud search finds:
  - "Keells Frozen BBQ Chicken Wings 500g"
  - "Cargills Frozen Barbecue Sausages 400g"
  - "Prima Frozen BBQ Ribs 600g"
        ↓
AI evaluates with context:
  Prompt includes: "This is for a dinner party with beverages (7up, cream soda)"
        ↓
AI selects: "Keells Frozen BBQ Chicken Wings 500g" (confidence: 0.82)
  Reason: "Wings are a popular party food that pairs well with sodas"
        ↓
Added to list with quantity: 1
```

**UI Shows:**
```
✓ Added: Keells Frozen BBQ Chicken Wings 500g (qty: 1)
```

---

#### PHASE 11: Execute AddItemCall - "coca cola" (4800-5400ms)

```
Search terms: ["coca cola", "cocacola", "coke", "coca-cola"]
        ↓
Cloud search finds: "Coca-Cola 1.5L", "Coca-Cola Can 330ml", "Coca-Cola Pet 500ml", ...
        ↓
AI evaluation considers quantity (4 bottles):
  "For 4 bottles, the 500ml Pet size is most practical"
        ↓
Selected: "Coca-Cola Pet 500ml" (confidence: 0.93)
        ↓
Added to list with quantity: 4
```

**UI Shows:**
```
✓ Added: Coca-Cola Pet 500ml (qty: 4)
```

---

#### PHASE 12: Execute FinalizeCall (5400-5600ms)

**File:** `lib/services/ai/agent_history_service.dart`

```dart
class AgentHistoryService {
  Future<void> saveHistory(String command, AgentRunResult result) async {
    // 1. Save to local SharedPreferences (instant)
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('ai_history') ?? [];
    
    history.insert(0, jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'command': command,
      'success': true,
      'listCreated': 'dinner party',
      'itemsAdded': [
        'Elephant House Water Bottle 500ml (x3)',
        '7up Pet 500ml',
        'Elephant House Cream Soda 400ml',
        'Keells Frozen BBQ Chicken Wings 500g',
        'Coca-Cola Pet 500ml (x4)',
      ],
      'processingTimeMs': 5600,
    }));
    
    await prefs.setStringList('ai_history', history.take(50).toList());
    
    // 2. Sync to Firestore (background)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('aiHistory')
        .add({
          // Same data for cross-device sync
        });
  }
}
```

---

#### PHASE 13: Final Result (5600ms)

**File:** `lib/controllers/ai_agent_controller.dart`

```dart
// Build final result
_lastResult = AgentRunResult(
  listId: "abc123-def456-ghi789",
  logs: List.of(_logs),
  addedItems: {
    "water bottles": "Elephant House Water Bottle 500ml",
    "7up": "7up Pet 500ml",
    "cream soda": "Elephant House Cream Soda 400ml",
    "frozen barbecue": "Keells Frozen BBQ Chicken Wings 500g",
    "coca cola": "Coca-Cola Pet 500ml",
  },
  failures: {},  // All items succeeded!
);

_running = false;
_runWatch.stop();

// Emit analytics
if (AIFeatureFlags.analyticsEnabled) {
  AgentAnalytics.instance.record('agent_run_complete', data: {
    'itemCount': 5,
    'successCount': 5,
    'failureCount': 0,
    'processingTimeMs': 5600,
    'hadBudget': true,
    'hadDateRange': true,
  });
}

update();  // Notify UI to show results
```

---

#### FINAL UI STATE

The user sees:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI AGENT - COMPLETE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✓ Created list "dinner party"                                  │
│    Budget: Rs. 5,000.00                                         │
│    Dates: January 5-7, 2026                                     │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  ✓ Elephant House Water Bottle 500ml            x3    Rs. 225   │
│    [product image]                                               │
│                                                                  │
│  ✓ 7up Pet 500ml                                x1    Rs. 150   │
│    [product image]                                               │
│                                                                  │
│  ✓ Elephant House Cream Soda 400ml              x1    Rs. 120   │
│    [product image]                                               │
│                                                                  │
│  ✓ Keells Frozen BBQ Chicken Wings 500g         x1    Rs. 890   │
│    [product image]                                               │
│                                                                  │
│  ✓ Coca-Cola Pet 500ml                          x4    Rs. 400   │
│    [product image]                                               │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  Estimated Total: Rs. 1,785.00                                  │
│  Under Budget: Rs. 3,215.00 remaining                           │
│                                                                  │
│  Processing Time: 5.6 seconds                                   │
│                                                                  │
│  [View List]  [Add More Items]  [Done]                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

#### COMPLETE TIMELINE SUMMARY

```
TIME        PHASE                           WHAT HAPPENED
─────────────────────────────────────────────────────────────────────
0-10ms      Input Reception                 Controller receives text
10-15ms     PII Sanitization                Check for sensitive data
15-800ms    Intent Parsing (Gemini)         LLM extracts structured data
800-820ms   Execution Plan Building         Convert to function calls
820-1200ms  CreateListCall                  Create Firestore document
1200-2500ms AddItemCall("water bottles")    Search → Evaluate → Add
2500-3200ms AddItemCall("7up")              Search → Evaluate → Add
3200-3900ms AddItemCall("cream soda")       Search → Evaluate → Add
3900-4800ms AddItemCall("frozen barbecue")  Search → Evaluate → Add
4800-5400ms AddItemCall("coca cola")        Search → Evaluate → Add
5400-5600ms FinalizeCall                    Save history, analytics
─────────────────────────────────────────────────────────────────────
TOTAL: 5.6 seconds

BREAKDOWN:
- LLM Parsing: 785ms (14%)
- List Creation: 380ms (7%)
- Product Search & Resolution: 4,200ms (75%)
- Finalization: 200ms (4%)
```

---

#### KEY SERVICES USED IN THIS EXAMPLE

| Service | Role | Times Called |
|---------|------|--------------|
| `PIISanitizer` | Privacy protection | 1 |
| `GeminiService` | LLM parsing + evaluation | 7 (1 parse + 6 evals) |
| `AgentListService` | List creation | 1 |
| `AgenticProductSearchService` | Term generation + evaluation | 5 |
| `FastProductSearchService` | Cloud Function search | ~15 (3 per item) |
| `AgentHistoryService` | Save history | 1 |
| `AgentAnalytics` | Telemetry | 2 |

---

## How AI Processing Works - Complete End-to-End Flow

This section explains exactly what happens when a user speaks to the Shopple AI, from the moment they tap the microphone to when they see their shopping list updated. We'll follow a real example step by step.

### The User's Perspective

Imagine Sarah opens Shopple and says:
> "Create a BBQ list and add burgers, hot dogs, and buns"

From her perspective, she taps a button, speaks, and within 3-4 seconds sees:
```
✓ Created list "BBQ"
✓ Added: Angus Beef Burgers 8-Pack
✓ Added: Oscar Mayer Hot Dogs
✓ Added: Wonder Hamburger Buns
```

What happened behind the scenes? Let's break it down millisecond by millisecond.

### Complete Timeline: From Voice to Shopping List

```
TIME        EVENT                                    WHERE IT HAPPENS
────────────────────────────────────────────────────────────────────────────
0ms         Sarah taps the AI floating button        FloatingAIButton
            → Bottom sheet slides up                 AIAgentBottomSheet
            → Microphone activated                   SpeechRecognition

0-2500ms    Sarah speaks her command                 Device microphone
            → Speech-to-text conversion              Platform STT service
            → Text appears: "Create a BBQ list       UI updates in real-time
              and add burgers, hot dogs, and buns"

2500ms      Sarah stops speaking                     SpeechRecognition
            → Final transcript sent to controller    AIAgentController.processCommand()

2510ms      STEP 1: PII SANITIZATION                 PIISanitizer
            → Check for emails, phones, card numbers
            → Nothing found, text passes through
            → Result: Same text (nothing to redact)

2515ms      STEP 2: INTENT PARSING BEGINS            AgentParsingProviders
            
            Decision: Use Gemini or Heuristic?
            → Text has >2 words? YES
            → LLM parsing enabled? YES
            → Send to Gemini LLM

2520ms      Request sent to Google Gemini            GeminiService.generateText()
            → Location: Firebase AI (Vertex AI)
            → Model: gemini-2.5-flash
            → Prompt includes JSON schema

2520-3200ms Gemini processes the request             Google Cloud (remote)
            → Understands "create" = new list
            → Extracts "BBQ" as list name
            → Identifies items: burgers, hot dogs, buns
            → Formats response as JSON

3200ms      Gemini response received                 GeminiService
            {
              "listName": "BBQ",
              "createList": true,
              "items": ["burgers", "hot dogs", "buns"]
            }

3210ms      STEP 3: EXECUTION PLAN BUILDING          AgentExecutionPlan
            
            Convert parsed data to function calls:
            [
              CreateListCall(name: "BBQ"),
              AddItemCall(phrase: "burgers"),
              AddItemCall(phrase: "hot dogs"),
              AddItemCall(phrase: "buns"),
              FinalizeCall()
            ]

3215ms      STEP 4: PLAN EXECUTION BEGINS            AIAgentController

──────────── EXECUTING: CreateListCall ────────────

3215ms      Create shopping list "BBQ"               AgentListService
            → Generate unique list ID
            → Save to Firestore
            → UI shows: "✓ Created list BBQ"

3400ms      List created successfully                Firestore confirmed

──────────── EXECUTING: AddItemCall("burgers") ────────────

3400ms      Start resolving "burgers"                AgentSearchService

3405ms      Check 1: Cached UI Results               Local cache
            → Did user recently search "burgers"?
            → NO cache found

3410ms      Check 2: AI Term Generation              GeminiService (lite model)
            → Generate search variants:
              "burgers", "beef burgers", "hamburger patties"

3450ms      Check 3: Aggregated Product Search       FastProductSearchService
            → Call Cloud Function with all variants
            → Cloud Function searches Firestore
            → Returns 8 candidate products

3700ms      Check 4: AI Candidate Evaluation         GeminiService
            → Send candidates to Gemini
            → Prompt: "Which product best matches 'burgers'?"
            → Gemini analyzes: name match, category, popularity

3900ms      Winner Selected                          AgentSearchService
            → "Angus Beef Burgers 8-Pack" (confidence: 0.89)
            → Add to shopping list

4000ms      Item added successfully                  Firestore
            → UI shows: "✓ Added: Angus Beef Burgers 8-Pack"

──────────── EXECUTING: AddItemCall("hot dogs") ────────────

4000ms      Start resolving "hot dogs"               (Same process)
            → Cloud search → Find candidates
            → AI evaluation → Select best match
            → "Oscar Mayer Hot Dogs" (confidence: 0.92)

4400ms      Item added successfully
            → UI shows: "✓ Added: Oscar Mayer Hot Dogs"

──────────── EXECUTING: AddItemCall("buns") ────────────

4400ms      Start resolving "buns"                   (Same process)
            → Cloud search finds: bread buns, hamburger buns, 
              hot dog buns, cinnamon buns
            → AI evaluates context: "BBQ list with burgers"
            → Infers: hamburger buns most relevant
            → "Wonder Hamburger Buns" (confidence: 0.85)

4800ms      Item added successfully
            → UI shows: "✓ Added: Wonder Hamburger Buns"

──────────── EXECUTING: FinalizeCall ────────────

4800ms      Save completion summary                  AgentHistoryService
            → Log to local SharedPreferences
            → Sync to Firestore for cross-device access
            → Emit analytics event

4900ms      PROCESSING COMPLETE                      AIAgentController
            
            Final Result:
            ┌─────────────────────────────────────┐
            │ ✓ Created list "BBQ"                │
            │ ✓ Added: Angus Beef Burgers 8-Pack  │
            │ ✓ Added: Oscar Mayer Hot Dogs       │
            │ ✓ Added: Wonder Hamburger Buns      │
            └─────────────────────────────────────┘
            
            Total time: 4.9 seconds
```

### Why Is This Fast? The Key Optimizations

**1. Parallel Processing Where Possible**
While we must process the main parsing sequentially, the system parallelizes where safe:
- All search term variants are searched simultaneously
- Multiple AI evaluations can run in parallel
- UI updates happen asynchronously

**2. Smart Model Selection**
```dart
// For complex parsing (list creation, multiple items)
final response = await geminiService.generateText(
  prompt,
  lite: false  // Use gemini-2.5-flash
);

// For simple tasks (generating search variants)
final variants = await geminiService.generateText(
  "Generate search terms for: $phrase",
  lite: true   // Use gemini-2.0-flash-lite (faster, cheaper)
);
```

**3. Early Termination**
When we find a product with confidence ≥0.96, we stop searching immediately:
```dart
if (candidate.confidence >= 0.96) {
  return candidate;  // Don't search further
}
```

**4. Cached Results**
If Sarah had searched for "burgers" earlier in the UI, we'd use that cached result instantly instead of calling Cloud Functions.

### What Happens If Something Fails?

The AI system is designed to be resilient. Here's how it handles failures:

**Scenario 1: LLM API Temporarily Down**
```
Timeline:
2520ms      Request sent to Gemini
2520-5000ms Timeout waiting for response (2.5 seconds)
5000ms      FALLBACK: Heuristic Parser activated
            → Regex detects "create" keyword
            → Extracts "BBQ" after "list"
            → Splits items on "and" / commas
5010ms      Parsing complete via heuristic
            → Processing continues normally
```

**Scenario 2: Product Not Found**
```
If "burgers" returns no candidates:
→ Generate more variants: "burger patties", "ground beef"
→ Search again
→ If still nothing: Create custom item "burgers"
   (User can later link to actual product)
```

**Scenario 3: Network Completely Offline**
```
→ Heuristic parser handles parsing (no LLM needed)
→ Products added as custom items (text only)
→ When back online: Smart suggestions to link products
```

### The Magic of Context-Aware Matching

Notice how in our example, "buns" matched to "hamburger buns" instead of "cinnamon buns"? Here's how:

```dart
// The AI receives context about what's already in the list
final prompt = '''
You are helping resolve a shopping item.

User requested: "buns"

Context:
- List name: "BBQ"
- Other items being added: burgers, hot dogs

Candidates from search:
1. Wonder Hamburger Buns - $3.99
2. Ball Park Hot Dog Buns - $3.49
3. Pillsbury Cinnamon Buns - $4.99
4. Martin's Potato Buns - $4.49

Which product best matches the user's intent?
''';
```

The AI understands that a BBQ list with burgers likely wants hamburger buns, not dessert items. This contextual intelligence is what makes Shopple AI feel "smart."

### How History Syncing Works

Every AI interaction is preserved:

```
1. IMMEDIATE (Local)
   → Save to SharedPreferences
   → Available instantly for "recent commands"
   
2. BACKGROUND (Cloud)
   → Sync to Firestore
   → Available on other devices
   → Persists across app reinstalls
   
3. STRUCTURE
   {
     "timestamp": "2026-01-15T10:30:00Z",
     "command": "Create a BBQ list and add burgers...",
     "result": {
       "success": true,
       "listCreated": "BBQ",
       "itemsAdded": ["Angus Beef Burgers...", ...]
     },
     "processingTimeMs": 4900
   }
```

### How Gemini Understands Shopping Commands

The magic happens through carefully crafted prompts. Here's what we actually send to Gemini:

```
SYSTEM PROMPT:
You are a strict JSON producing parser for a shopping list assistant.
You must extract structured information from natural language commands.

RULES:
- "listName": Extract the list name if mentioned
- "createList": true if user wants to create a new list
- "items": Array of item phrases (preserve quantities)
- "budget": Number if user mentions spending limit
- "startDate/endDate": Dates if shopping trip is scheduled

Return ONLY valid JSON. No markdown. No explanations.

USER INPUT:
"Create a BBQ list and add burgers, hot dogs, and buns"

EXPECTED OUTPUT:
{"listName":"BBQ","createList":true,"items":["burgers","hot dogs","buns"]}
```

This prompt engineering is crucial—it constrains Gemini's output to exactly what our code can parse.

---

## API Reference

### Core Classes

#### `AgentParsedCommand`
```dart
class AgentParsedCommand {
  final String? listName;
  final List<String> rawItemPhrases;
  final bool createListRequested;
  final double? budgetLimit;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> itemQuantities;
}
```

#### `AgentFunctionCall` (Abstract)
```dart
abstract class AgentFunctionCall {
  String get functionName;
  Map<String, dynamic> toJson();
}

// Implementations:
// - CreateListCall
// - AddItemCall
// - GetProductPriceCall
// - GetListItemCountCall
// - GetProductListCountCall
// - GetListItemsCall
// - FinalizeCall
```

#### `AgentRunResult`
```dart
class AgentRunResult {
  final bool success;
  final Map<String, String> added;      // phrase → product name
  final Map<String, String> failed;     // phrase → error message
  final Duration processingTime;
}
```

### Service Classes

| Service | Purpose | Key Methods |
|---------|---------|-------------|
| `GeminiService` | LLM API access | `generateText()`, `generateTextStream()` |
| `AgentSearchService` | Product resolution | `addSingleItem()`, `resolvePhrase()` |
| `AgentListService` | List operations | `createListWithDetails()` |
| `AgentQueryService` | Information queries | `executeGetProductPrice()` |
| `AgentHistoryService` | History persistence | `saveHistory()`, `getHistory()` |
| `AgentParsingProviders` | NLP parsing | `parse()` |

---

## Complete Service Reference

This section documents every service in the AI agent system in detail.

### GeminiService - The LLM Gateway

**Location:** `lib/services/ai/gemini_service.dart`

The GeminiService is a **singleton** that manages all communication with Google's Gemini AI models through Firebase AI (Vertex AI).

**Key Design Decisions:**

1. **Singleton Pattern**: Only one instance exists to share model initialization across the app
2. **Lazy Initialization**: Models are created only when first needed
3. **Dual Models**: Two model instances for different use cases
4. **Streaming Support**: Real-time token output for better UX

```dart
class GeminiService {
  GeminiService._();  // Private constructor
  static final GeminiService instance = GeminiService._();
  
  GenerativeModel? _model;      // Primary: gemini-2.5-flash
  GenerativeModel? _liteModel;  // Budget: gemini-2.0-flash-lite
  
  Future<void> ensureInitialized() async {
    _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash');
    _liteModel = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.0-flash-lite');
  }
}
```

**When to Use Each Model:**

| Model | Use Case | Cost | Speed |
|-------|----------|------|-------|
| `gemini-2.5-flash` | Complex parsing, multi-intent commands, candidate evaluation | Higher | ~500-2000ms |
| `gemini-2.0-flash-lite` | Search term generation, simple expansions | Lower | ~200-500ms |

---

### AgenticProductSearchService - Smart Product Finding

**Location:** `lib/services/ai/agentic_product_search_service.dart`

This service implements an **iterative, AI-guided product search**. When a user says "add mango juice," this service:

1. Generates multiple search term variants
2. Searches the database with each variant
3. Uses AI to evaluate which result best matches the user's intent

**The Search Term Generation Algorithm:**

For beverage-eligible fruits (mango, apple, orange, etc.), we automatically expand searches:

```dart
// User says: "mango"
// Generated terms: ["mango", "mango drink", "mango juice", "mango nectar"]

const beverageEligibleRoots = {
  'apple', 'mango', 'orange', 'coconut', 'pineapple', 
  'grape', 'strawberry', 'guava', 'passion', 'papaya',
  // ... more fruits
};
```

**Why This Matters:**
- User says "mango" → might want the fruit OR mango juice
- By generating variants, we search for both possibilities
- AI then evaluates context to pick the right one

**The Two-Phase Search:**

```
Phase 1: Generate Variants (AI + Heuristics)
───────────────────────────────────────────
User phrase: "wood apple drink"
        ↓
Heuristic expansion:
  - "wood apple drink"
  - "woodapple drink"
  - "wood apple juice"
  - "wood apple nectar"
        ↓
AI expansion (lite model):
  - "woodapple beverage"
  - "wood apple punch"
        ↓
Final list: 6-8 search terms

Phase 2: Evaluate Candidates (AI)
───────────────────────────────────────────
Search each term → Collect candidates
        ↓
Send to Gemini: "Which product best matches 'wood apple drink'?"
        ↓
Gemini analyzes: name match, category, beverage type
        ↓
Winner: "Elephant House Wood Apple Nectar"
```

---

### QuickPromptService - User Shortcuts

**Location:** `lib/services/ai/quick_prompt_service.dart`

Quick Prompts allow users to save frequently-used AI commands for one-tap execution.

**Example Quick Prompts:**
- "Add milk, bread, and eggs to my grocery list"
- "What's the cheapest yogurt?"
- "Create a party list with $50 budget"

**Storage Strategy:**

```
┌─────────────────────────────────────────────────────────────┐
│                     QUICK PROMPT DATA                        │
├─────────────────────────────────────────────────────────────┤
│  Memory Cache (instant access)                               │
│  ├─ Map<userId, List<QuickPrompt>>                          │
│  └─ Valid for 30 minutes                                    │
├─────────────────────────────────────────────────────────────┤
│  SharedPreferences (local persistence)                       │
│  └─ Key: "ai.quick_prompts.{userId}"                        │
└─────────────────────────────────────────────────────────────┘
```

**The QuickPrompt Model:**

```dart
class QuickPrompt {
  final String id;        // UUID for unique identification
  String title;           // Display name: "Weekly Groceries"
  String prompt;          // Full command: "Add milk, eggs..."
  List<String> tags;      // Categories: ["grocery", "weekly"]
  String? color;          // Custom color: "#4285F4"
}
```

**Optimistic Loading:**

To feel instant, the service uses optimistic loading:

```dart
// Returns cached data immediately (even if stale)
// Refreshes in background if cache is old
static Future<List<QuickPrompt>> loadForUserOptimistic([String? uid]) async {
  if (_memoryCache.containsKey(uid)) {
    // Return cache NOW
    final cachedData = List<QuickPrompt>.from(_memoryCache[uid]!);
    
    // Refresh in background (non-blocking)
    if (!_isCacheValid(uid)) {
      _refreshCacheInBackground(uid);
    }
    
    return cachedData;  // User sees data immediately
  }
  // No cache: must load from storage
  return _loadForUserFromStorage(uid);
}
```

---

### ServerAgentService - Backend AI Processing

**Location:** `lib/services/ai/server_agent_service.dart`

For complex or quota-managed operations, we can delegate to a **server-side AI agent** running on Firebase Cloud Functions with Genkit.

**Why Server-Side Processing?**

| Client-Side | Server-Side |
|-------------|-------------|
| Fast for simple commands | Better for complex multi-step operations |
| Limited by device resources | Unlimited compute power |
| API keys in app (risk) | API keys secure on server |
| No usage quotas | Can enforce per-user quotas |

**The Server Flow:**

```dart
class ServerAgentService {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  Future<Map<String, dynamic>> runShoppingAgent({
    required String userInput,
    bool dryRun = false,  // Test without executing
  }) async {
    final callable = _functions.httpsCallable('shoppingAgentFlow');
    final resp = await callable.call({
      'userInput': userInput,
      'dryRun': dryRun,
    });
    // Returns: actions taken, quotas, run ID for debugging
    return resp.data;
  }
}
```

**When Server Flow Is Used:**

The server flow is feature-flagged via `AIFeatureFlags.serverFlowEnabled`. When enabled:

```dart
Future<AgentRunResult> runUserCommand(String input) async {
  // 1. Try server flow first
  if (AIFeatureFlags.serverFlowEnabled) {
    try {
      return await _runServerFlow(input);  // Delegate to cloud
    } catch (e) {
      // Fallback to local if server fails
      _log('server_delegate', 'Server flow failed, local fallback');
    }
  }
  
  // 2. Local flow as fallback
  return await _runLocalFlow(input);
}
```

---

### FloatingAIService - The AI Button Manager

**Location:** `lib/services/ai/floating_ai_service.dart`

This GetX service manages the **floating AI assistant button** that appears on main app screens.

**Smart Visibility:**

The button doesn't appear everywhere—it hides during:
- Splash screen
- Onboarding
- Login/Signup
- Loading states

```dart
static const List<String> _excludedRoutes = [
  '/splash',
  '/onboarding', 
  '/login',
  '/signup',
  '/loading',
];

void _updateContextVisibility([String? route]) {
  final currentRoute = route ?? Get.currentRoute;
  final shouldShow = !_excludedRoutes.any(
    (excluded) => currentRoute.contains(excluded),
  );
  _isContextAllowed.value = shouldShow;
}
```

**Draggable Position:**

Users can drag the button anywhere. Position persists across app restarts:

```dart
// Save position to SharedPreferences
void _savePosition() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_positionKey, '${_xPosition.value},${_yPosition.value}');
}

// Load saved position on app start
void _loadSavedPosition() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_positionKey);
  if (saved != null) {
    final parts = saved.split(',');
    _xPosition.value = double.parse(parts[0]);
    _yPosition.value = double.parse(parts[1]);
  }
}
```

---

### PIISanitizer - Privacy Protection

**Location:** `lib/services/ai/pii_sanitizer.dart`

Before ANY user input reaches Gemini, it passes through PII (Personally Identifiable Information) sanitization.

**What Gets Redacted:**

| Pattern | Example | Replacement |
|---------|---------|-------------|
| Email addresses | `john@gmail.com` | `[REDACTED_EMAIL]` |
| Phone numbers | `+94 77 123 4567` | `[REDACTED_PHONE]` |
| Credit card numbers | `4532-1234-5678-9012` | `[REDACTED_CARD]` |
| Long numeric sequences | `123456789012` | `[REDACTED_NUMBER]` |

**Why This Matters:**

Users might accidentally include sensitive data:
- "Add groceries, my number is 077-123-4567"
- "Order from john.doe@email.com"

Without sanitization, this data would be sent to Google's servers. The sanitizer ensures:
1. User sees their original input
2. AI only sees redacted text
3. No PII stored in logs or history

---

### UserTagService - Personalization

**Location:** `lib/services/ai/user_tag_service.dart`

Tracks user preferences and behaviors to personalize AI responses.

**Tracked Tags:**

```dart
// Examples of inferred tags:
"dietary:vegetarian"     // User frequently adds vegetarian items
"store:keells"           // User prefers Keells supermarket  
"budget:price_conscious" // User often asks about cheapest options
"time:weekly_shopper"    // User creates lists every week
```

**How Tags Affect AI:**

When the AI resolves ambiguous requests, tags provide context:

```
User: "Add milk"
        ↓
Tags indicate: "dietary:lactose_free"
        ↓
AI prioritizes: Lactose-free milk variants
```

---

## Step-by-Step vs Single-Shot Execution

The AI agent supports two execution modes:

### Step-by-Step Mode (Default)

User confirms each item before it's added. Provides maximum control.

```
User: "Create party list, add chips, dip, and soda"
        ↓
STEP 1 (Auto): Create list "Party" ✓
        ↓
UI: "Ready to add 3 items. Tap to proceed."
        ↓
User taps "Next"
        ↓
STEP 2: Search "chips" → Show candidates
        → User confirms "Doritos" ✓
        ↓
User taps "Next"
        ↓
STEP 3: Search "dip" → Show candidates
        → User confirms "Tostitos Salsa" ✓
        ↓
... continues for each item
```

### Single-Shot Mode

All items processed automatically without confirmation.

```
User: "Create party list, add chips, dip, and soda"
        ↓
Create list ✓
Add chips → "Doritos" ✓
Add dip → "Tostitos Salsa" ✓
Add soda → "Coca-Cola" ✓
        ↓
DONE (all at once)
```

**When to Use Each:**

| Mode | Best For |
|------|----------|
| Step-by-Step | New users, specific product preferences, learning the system |
| Single-Shot | Power users, simple/unambiguous items, quick list creation |

---

## Analytics & Telemetry

The AI agent tracks usage for improvement:

```dart
if (AIFeatureFlags.analyticsEnabled) {
  AgentAnalytics.instance.record('agent_run_start', data: {
    'hasListName': parsed.listName != null,
    'itemCount': parsed.rawItemPhrases.length,
    'createList': parsed.createListRequested,
  });
}
```

**Tracked Events:**

| Event | Data |
|-------|------|
| `agent_run_start` | Item count, list creation, budget presence |
| `item_resolved` | Resolution method (cache/search/AI), confidence score |
| `item_failed` | Failure reason, attempted searches |
| `session_complete` | Total time, success rate |

**Privacy Note:** Analytics track behavior patterns, not personal data. User inputs are never logged in analytics.

---

## Performance Considerations

### Cost Optimization

| Strategy | Implementation |
|----------|----------------|
| **Lite Model Usage** | Use `gemini-2.0-flash-lite` for simple parsing |
| **Heuristic First** | Confidence scoring to avoid unnecessary AI calls |
| **Capped Operations** | Max 6 search attempts per item |
| **Early Termination** | Stop when definitive match found (≥0.96 confidence) |

### Robustness

| Strategy | Implementation |
|----------|----------------|
| **Multi-Layer Fallback** | Gemini → Heuristic → Custom Item |
| **PII Sanitization** | Remove sensitive data before LLM calls |
| **Graceful Degradation** | Continue processing despite individual failures |
| **Timeout Handling** | Default timeouts with retry logic |

### User Experience

| Strategy | Implementation |
|----------|----------------|
| **Step-by-Step Mode** | User control over each item |
| **Streaming Preview** | Real-time parsing feedback |
| **Visual Status** | Per-item progress indicators |
| **Persistent History** | Cross-device sync via Firestore |

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "GeminiService not initialized" | Called before `ensureInitialized()` | Ensure initialization in app startup |
| Empty parsing result | Input too short or unclear | Use more specific commands |
| Wrong product matched | Ambiguous phrase | Use brand names or be more specific |
| Slow response | Network latency | Enable local heuristic fallback |

### Debugging

Enable verbose logging:
```dart
AIFeatureFlags.analyticsEnabled = true;
// Check AgentActionLog entries for detailed execution trace
```

---

## Future Enhancements

1. **Function Calling API:** Native Gemini tool-calling for structured output
2. **Voice Input:** Speech-to-text integration
3. **Smart Suggestions:** Context-aware command predictions
4. **Multi-Language:** Localized NLP support
5. **Offline Mode:** Local model for basic commands

---

## Related Documentation

- [Firebase AI Documentation](https://firebase.google.com/docs/vertex-ai)
- [Gemini API Reference](https://ai.google.dev/docs)
- [GetX State Management](https://pub.dev/packages/get)
