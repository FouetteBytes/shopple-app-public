# Search analytics standards and events (Shopple)

This document outlines the minimum viable analytics schema and events to collect for high-signal search insights without logging every keystroke.

## Core principles
- Privacy-first: no raw keystroke logging; aggregate events only.
- Lightweight: send compact payloads; dedupe on the server; cache on client when offline.
- Sessionized: include sessionId for all events.
- Action-focused: prioritize events that predict intent (query submit, result click/tap, add-to-list/cart, price check).
- Facet-aware: capture category and brand facets used/derived.

## Key events and fields
1) search_submit
- userId, sessionId, ts
- query (trimmed, lowercased), resultCount
- selectedFilters: { category?, brand?, priceRange? }
- device/network hints (optional)

2) result_click (aka product_interaction: tap)
- userId, sessionId, ts
- productId, brand, category
- searchQuery (origin query if from a search session)
- position (optional index in result set)

3) product_view (dwell)
- userId, sessionId, ts
- productId, brand, category
- timeSpent (ms)
- viewStartTime, viewEndTime

4) price_check
- userId, sessionId, ts
- productId, supermarket, price
- comparisonType (best_price, over_x_percent, etc.)

5) zero_results
- userId, sessionId, ts
- query, appliedFilters

6) refinement
- userId, sessionId, ts
- fromQuery -> toQuery
- addedFilters / removedFilters

7) conversion proxy (optional)
- add_to_list, share, copy_link
- productId, listId?, source (search/results/details)

## Aggregations stored server-side
- Per-user: topQueries [query, frequency, score], topBrands [brand, freq], topCategories [name, freq], preferredSearchTimes
- Global: trendingQueries, trendingBrands/Categories, CTR by facet, zero-result queries

## Retention
- Raw events: 30–90 days (configurable)
- Aggregates: long-term

## Implementation notes (current code)
- Client
  - trackSearchEventV2: search_submit
  - trackUserBehaviorV2: product_view, product_interaction (tap), price_check
  - Session IDs generated on app start
- Server (functions/index.js)
  - getUserMostSearchedV2 for personalized defaults (topQueries, recommendations, userPreferences)
  - fastProductSearchV2 for ultra-fast cloud search

## KPIs
- Search CTR, result Dwell, zero-result rate, refinement rate, add-to-list rate, best-offer clickthrough

## Next additions
- Log zero_results/refinements on client
- Record position for result_click events
- Cohort dashboards by category/brand interest
