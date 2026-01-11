/**
 * Shopple Cloud Functions (lean)
 *
 * This minimized build keeps only the functions actively used by the app to improve
 * performance and reduce costs. Removed: analytics, personalization, and remote recent
 * search endpoints. Retained:
 * - fastProductSearchV2: High-performance product search used by the app
 * - advancedUserSearchV2: People search (used in social features)
 * - matchContacts: Firestore trigger for contact matching (privacy-preserving)
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
// 2nd gen callable + firestore imports
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten, onDocumentCreated } = require("firebase-functions/v2/firestore");

// Presence sync feature imports (used in presence sync functions below)
const { onValueWritten } = require("firebase-functions/v2/database");
const { onSchedule } = require("firebase-functions/v2/scheduler");

admin.initializeApp();

// Helper shortcuts to match existing code usage
const firestore = admin.firestore;
const database = admin.database;
const createHash = crypto.createHash;
const config = functions.config;

exports.hydrationOnItemWrite = onDocumentWritten({ region: "asia-south1" }, "shopping_lists/{listId}/items/{itemId}", async (event) => {
    const { listId } = event.params;
    try {
        const itemsSnap = await firestore()
            .collection('shopping_lists').doc(listId)
            .collection('items')
            .select('quantity', 'estimatedPrice', 'isCompleted')
            .get();
        let totalItems = 0, completedItems = 0, estimatedTotal = 0;
        let distinctProducts = 0, distinctCompleted = 0;
        itemsSnap.forEach(doc => {
            const d = doc.data() || {};
            const q = Number(d.quantity || 0);
            const p = Number(d.estimatedPrice || 0);
            totalItems += q;
            distinctProducts += 1;
            if (d.isCompleted) {
                completedItems += q;
                distinctCompleted += 1;
            }
            estimatedTotal += (q * p);
        });

        // Check if values actually changed before updating to prevent unnecessary stream updates
        const metaRef = firestore().collection('shopping_lists').doc(listId)
            .collection('meta').doc('hydration');
        const parentRef = firestore().collection('shopping_lists').doc(listId);

        const [metaSnap, parentSnap] = await Promise.all([metaRef.get(), parentRef.get()]);
        const currentMeta = metaSnap.exists ? metaSnap.data() : {};
        const currentParent = parentSnap.exists ? parentSnap.data() : {};

        // Only update if values actually changed
        const metaChanged = currentMeta.totalItems !== totalItems ||
            currentMeta.completedItems !== completedItems ||
            Math.abs((currentMeta.estimatedTotal || 0) - estimatedTotal) > 0.001;

        const parentChanged = currentParent.totalItems !== totalItems ||
            currentParent.completedItems !== completedItems ||
            Math.abs((currentParent.estimatedTotal || 0) - estimatedTotal) > 0.001;

        if (metaChanged) {
            await metaRef.set({
                totalItems,
                completedItems,
                estimatedTotal,
                distinctProducts,
                distinctCompleted,
                updatedAt: firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }

        if (parentChanged) {
            await parentRef.set({
                totalItems,
                completedItems,
                estimatedTotal,
                distinctProducts,
                distinctCompleted,
                updatedAt: firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }
    } catch (err) {
        console.error('hydrationOnItemWrite error:', err);
    }
});

exports.getListHydrationBatch = onCall({ region: 'asia-south1' }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    const ids = Array.isArray(request.data?.listIds) ? request.data.listIds : [];
    if (!ids.length) return { results: [] };
    try {
        const chunk = (arr, size) => arr.reduce((acc, _, i) => (i % size ? acc : [...acc, arr.slice(i, i + size)]), []);
        const batches = chunk(ids, 10);
        const results = [];
        for (const group of batches) {
            const snaps = await Promise.all(group.map(id => firestore().collection('shopping_lists').doc(id).collection('meta').doc('hydration').get()));
            snaps.forEach((doc, idx) => {
                const id = group[idx];
                const d = doc.exists ? (doc.data() || {}) : {};
                results.push({
                    id,
                    totalItems: d.totalItems || 0,
                    completedItems: d.completedItems || 0,
                    estimatedTotal: d.estimatedTotal || 0,
                    distinctProducts: d.distinctProducts || 0,
                    distinctCompleted: d.distinctCompleted || 0,
                    updatedAt: d.updatedAt || null
                });
            });
        }
        return { results };
    } catch (err) {
        console.error('getListHydrationBatch error:', err);
        throw new HttpsError('internal', err?.message || 'Unknown error');
    }
});

exports.backfillItemPrices = onCall({ region: 'asia-south1' }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { listId, dryRun = true } = request.data || {};
    if (!listId) {
        throw new HttpsError('invalid-argument', 'listId required');
    }

    try {
        // Get all items in the list that have productId but no estimatedPrice (or 0)
        const itemsSnap = await firestore()
            .collection('shopping_lists').doc(listId)
            .collection('items')
            .where('productId', '!=', null)
            .get();

        const candidates = [];
        const priceQueries = [];

        for (const itemDoc of itemsSnap.docs) {
            const item = itemDoc.data();
            const estimatedPrice = Number(item.estimatedPrice || 0);

            if (estimatedPrice <= 0 && item.productId) {
                candidates.push({ id: itemDoc.id, productId: item.productId, quantity: item.quantity || 1 });
                // Query current_prices for this product
                priceQueries.push(
                    firestore()
                        .collection('current_prices')
                        .where('productId', '==', item.productId)
                        .orderBy('price', 'asc')
                        .limit(1)
                        .get()
                );
            }
        }

        if (candidates.length === 0) {
            return { message: 'No items need price backfill', updated: 0 };
        }

        console.log(`Found ${candidates.length} items needing price backfill`);

        // Execute price queries
        const priceResults = await Promise.all(priceQueries);
        const updates = [];

        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            const priceSnap = priceResults[i];

            if (!priceSnap.empty) {
                const cheapestPrice = priceSnap.docs[0].data();
                const price = Number(cheapestPrice.price || 0);

                if (price > 0) {
                    updates.push({
                        itemId: candidate.id,
                        productId: candidate.productId,
                        price: price,
                        quantity: candidate.quantity
                    });
                }
            }
        }

        if (dryRun) {
            return {
                message: `Dry run: Would update ${updates.length} items`,
                updates: updates.slice(0, 5), // Show first 5 as sample
                total: updates.length
            };
        }

        // Apply updates
        const batch = firestore().batch();
        let batchCount = 0;

        for (const update of updates) {
            const itemRef = firestore()
                .collection('shopping_lists').doc(listId)
                .collection('items').doc(update.itemId);

            batch.set(itemRef, {
                estimatedPrice: update.price,
                updatedAt: firestore.FieldValue.serverTimestamp(),
                priceBackfilledAt: firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            batchCount++;

            // Commit batch every 400 operations (Firestore limit is 500)
            if (batchCount >= 400) {
                await batch.commit();
                batch = firestore().batch();
                batchCount = 0;
            }
        }

        if (batchCount > 0) {
            await batch.commit();
        }

        console.log(`Backfilled prices for ${updates.length} items in list ${listId}`);

        return {
            message: `Successfully updated ${updates.length} items with prices`,
            updated: updates.length
        };

    } catch (err) {
        console.error('backfillItemPrices error:', err);
        throw new HttpsError('internal', err?.message || 'Backfill failed');
    }
});

exports.matchContacts = onDocumentCreated({ region: "asia-south1" }, "contact_syncs/{userId}", async (event) => {
    const userId = event.params.userId;
    const snap = event.data;
    const data = snap?.data() || {};
    const hashedContacts = data.hashedContacts || [];

    console.log(`Processing contact sync for user: ${userId}`);
    console.log(`Number of contact hashes: ${hashedContacts.length}`);

    try {
        // Get all registered users with phone numbers
        const usersSnapshot = await firestore()
            .collection("users")
            .where("phoneNumber", "!=", null)
            .get();

        console.log(`Found ${usersSnapshot.size} registered users`);

        const matches = [];
        const userPhoneMap = new Map();

        // Build map of all possible phone number variations for registered users
        usersSnapshot.forEach((userDoc) => {
            const userData = userDoc.data();
            if (userData.phoneNumber) {
                const variations = generatePhoneVariations(userData.phoneNumber);

                variations.forEach((variation) => {
                    const hash = hashPhoneNumber(variation);
                    userPhoneMap.set(hash, {
                        uid: userDoc.id,
                        name: `${userData.firstName || ""} ${userData.lastName || ""}`.trim(),
                        phoneNumber: userData.phoneNumber,
                        profilePicture: userData.photoURL || null,
                        email: userData.email || null,
                    });
                });
            }
        });

        console.log(`Generated ${userPhoneMap.size} phone hash variations`);

        // Find matches between contact hashes and user hashes
        hashedContacts.forEach((contactHash) => {
            if (userPhoneMap.has(contactHash)) {
                const matchedUser = userPhoneMap.get(contactHash);

                // Avoid adding the user themselves
                if (matchedUser.uid !== userId) {
                    matches.push(matchedUser);
                }
            }
        });

        // Remove duplicates based on uid
        const uniqueMatches = matches.reduce((acc, current) => {
            const existing = acc.find((item) => item.uid === current.uid);
            if (!existing) {
                acc.push(current);
            }
            return acc;
        }, []);

        console.log(`Found ${uniqueMatches.length} unique matches`);

        // Store matches for the user
        await firestore()
            .collection("user_contacts")
            .doc(userId)
            .set({
                matches: uniqueMatches,
                totalProcessed: hashedContacts.length,
                totalMatches: uniqueMatches.length,
                lastUpdated: firestore.FieldValue.serverTimestamp(),
                syncStatus: "completed",
            });

        // Update sync status
        await snap.ref.update({
            status: "completed",
            matchCount: uniqueMatches.length,
            processedAt: firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Contact sync completed for user ${userId}: ${uniqueMatches.length} matches`);

    } catch (error) {
        console.error("Contact matching error:", error);
        await snap.ref.update({
            status: "failed",
            error: error.message,
            processedAt: firestore.FieldValue.serverTimestamp(),
        });
    }
});

exports.advancedUserSearchV2 = onCall({ region: "asia-south1" }, async (request) => {
    // Warmup/ping handling
    if (request.data?.isWarmup || request.data?.queryType === 'ping') {
        return {
            results: [],
            fromCache: false,
            isWarmup: true,
            message: 'Connection warmed'
        };
    }

    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { query, queryType, limit = 15, isShortQuery = false, applyPrivacyFilter = true } = request.data || {};
    const currentUserId = request.auth.uid;

    if (!query || query.trim().length < 1) {
        return { results: [], fromCache: false };
    }

    try {
        let results = [];
        
        if (isShortQuery || query.length <= 2) {
            results = await searchPartialOptimizedUltraFast(query, limit * 2); // Get more for filtering
        } else {
            switch (queryType) {
                case "name":
                    results = await searchByNameOptimized(query, limit * 2);
                    break;
                case "email":
                    results = await searchByEmailOptimized(query, limit * 2);
                    break;
                case "phone":
                    results = await searchByPhoneOptimized(query, limit * 2);
                    break;
                case "mixed":
                    results = await searchMixedOptimized(query, limit * 2);
                    break;
                case "partial":
                    results = await searchPartialOptimized(query, limit * 2);
                    break;
                default:
                    results = await searchByNameOptimized(query, limit * 2);
                    break;
            }
        }

        // Apply server-side privacy filtering to reduce data transfer
        if (applyPrivacyFilter && results.length > 0) {
            results = await filterByPrivacySettings(results, queryType, currentUserId);
        }

        results = rankResults(results, query);
        
        // Return only requested limit after filtering
        return { 
            results: results.slice(0, limit), 
            fromCache: false,
            isInstant: isShortQuery || query.length <= 2,
            performance: (isShortQuery || query.length <= 2) ? 'ultra-fast' : 'standard',
            totalBeforeFilter: results.length
        };

    } catch (error) {
        console.error("Search error (v2):", error);
        return { results: [], error: error.message };
    }
});


// Simple in-memory cache for fast search results (per instance)
const SEARCH_CACHE = new Map(); // key -> { data, ts }
const SEARCH_CACHE_TTL_MS = 15_000; // 15s short TTL
const SEARCH_CACHE_MAX = 200; // basic cap
// Popular query cache (slightly longer TTL for CDN-like behavior)
const POPULAR_CACHE = new Map(); // key (query only) -> { data, ts }
const POPULAR_CACHE_TTL_MS = 120_000; // 2 minutes
const QUERY_HITS = new Map(); // key -> count within runtime
const POPULAR_HIT_THRESHOLD = 3; // promote to popular cache after 3 hits

function getSearchCache(key) {
    const entry = SEARCH_CACHE.get(key);
    if (!entry) return null;
    if (Date.now() - entry.ts > SEARCH_CACHE_TTL_MS) {
        SEARCH_CACHE.delete(key);
        return null;
    }
    return entry.data;
}

function setSearchCache(key, data) {
    if (SEARCH_CACHE.size >= SEARCH_CACHE_MAX) {
        // delete oldest entry (Map preserves insertion order)
        const firstKey = SEARCH_CACHE.keys().next().value;
        if (firstKey) SEARCH_CACHE.delete(firstKey);
    }
    SEARCH_CACHE.set(key, { data, ts: Date.now() });
}

exports.fastProductSearchV2 = onCall({ region: "asia-south1" }, async (request) => {
    const { query = '', filters = {}, limit = 20 } = request.data || {};
    try {
        const startTime = Date.now();

        const normalizedQuery = String(query || '').trim();
        // Return empty quickly for too-short queries
        if (normalizedQuery.length === 0) {
            return { success: true, results: [], metadata: { processingTime: 0, totalFound: 0, query: normalizedQuery, appliedStores: [] } };
        }

        // Build a lightweight cache key
        const storesFilter = Array.isArray(filters?.stores)
            ? filters.stores.filter((s) => typeof s === 'string' && s.trim().length > 0)
            : [];
        // Popular cache quick-hit: only when no category filter and no store filters
        if ((filters?.category ? false : true) && storesFilter.length === 0) {
            const pop = POPULAR_CACHE.get(normalizedQuery.toLowerCase());
            if (pop && (Date.now() - pop.ts) <= POPULAR_CACHE_TTL_MS) {
                const processingTime = Date.now() - startTime;
                return { success: true, results: pop.data.results, metadata: { ...pop.data.metadata, processingTime, cache: 'popular' } };
            }
        }
        const cacheKey = `${normalizedQuery.toLowerCase()}|${filters?.category || ''}|${storesFilter.sort().join(',')}|${limit}`;
        const cached = getSearchCache(cacheKey);
        if (cached) {
            const processingTime = Date.now() - startTime;
            return { success: true, results: cached.results, metadata: { ...cached.metadata, processingTime, cache: true } };
        }

        // Select only necessary fields to cut payload size
        let productsQuery = firestore()
            .collection('products')
            .where('is_active', '==', true)
            .select(
                'name',
                'brand_name',
                'category',
                'original_name',
                'variety',
                'image_url',
                'created_at',
                'updated_at',
                'size',
                'sizeRaw',
                'sizeUnit'
            );
        if (filters && filters.category) {
            productsQuery = productsQuery.where('category', '==', filters.category);
        }

        const snapshot = await productsQuery.limit(Math.min(limit * 3, 100)).get();

        const products = [];
        snapshot.forEach((doc) => {
            const product = { id: doc.id, ...doc.data() };
            const score = calculateSearchScore(product, normalizedQuery);
            if (score > 0.3) {
                products.push({ ...product, searchScore: score });
            }
        });

        // Sort by relevance and take a pre-limit for filtering
        let sorted = products.sort((a, b) => b.searchScore - a.searchScore);
        const preLimit = Math.min(sorted.length, Math.min(limit * 3, 90));
        sorted = sorted.slice(0, preLimit);

        // Optional: server-side filter by selected stores for leaner payloads and attach price preview
        if (storesFilter.length > 0 && sorted.length > 0) {
            const productIds = sorted.map((p) => p.id);

            // Helper to chunk arrays to Firestore 'in' limit (10)
            const chunk = (arr, size) => arr.reduce((acc, _, i) => (i % size ? acc : [...acc, arr.slice(i, i + size)]), []);
            const idChunks = chunk(productIds, 10);

            const hasPriceInStores = new Set();
            const cheapestPreview = new Map(); // productId -> {supermarketId, price}
            for (const ids of idChunks) {
                const priceSnap = await firestore()
                    .collection('current_prices')
                    .where('productId', 'in', ids)
                    .select('productId', 'supermarketId', 'price', 'lastUpdated', 'priceDate')
                    .get();

                priceSnap.forEach((priceDoc) => {
                    const data = priceDoc.data() || {};
                    const pid = data.productId;
                    const store = data.supermarketId;
                    if (pid && store && storesFilter.includes(String(store))) {
                        hasPriceInStores.add(pid);
                        const price = Number(data.price || 0);
                        if (price > 0) {
                            const prev = cheapestPreview.get(pid);
                            if (!prev || price < prev.price) {
                                cheapestPreview.set(pid, { supermarketId: String(store), price, priceDate: data.priceDate || null, lastUpdated: data.lastUpdated || null });
                            }
                        }
                    }
                });
            }

            sorted = sorted.filter((p) => hasPriceInStores.has(p.id));
            // Attach preview
            sorted = sorted.map((p) => {
                const pr = cheapestPreview.get(p.id);
                return pr ? { ...p, cheapestPrice: pr.price, cheapestStore: pr.supermarketId, priceDate: pr.priceDate, priceLastUpdated: pr.lastUpdated } : p;
            });
        }

        // If no stores filter, still compute minimal price preview for top results
        if (storesFilter.length === 0 && sorted.length > 0) {
            const productIds = sorted.map((p) => p.id);
            const chunk = (arr, size) => arr.reduce((acc, _, i) => (i % size ? acc : [...acc, arr.slice(i, i + size)]), []);
            const idChunks = chunk(productIds, 10);
            const cheapestPreview = new Map();
            for (const ids of idChunks) {
                const priceSnap = await firestore()
                    .collection('current_prices')
                    .where('productId', 'in', ids)
                    .select('productId', 'supermarketId', 'price', 'lastUpdated', 'priceDate')
                    .get();
                priceSnap.forEach((priceDoc) => {
                    const d = priceDoc.data() || {};
                    const pid = d.productId;
                    const sid = d.supermarketId;
                    const price = Number(d.price || 0);
                    if (!pid || !sid || !(price > 0)) return;
                    const prev = cheapestPreview.get(pid);
                    if (!prev || price < prev.price) {
                        cheapestPreview.set(pid, { supermarketId: String(sid), price, priceDate: d.priceDate || null, lastUpdated: d.lastUpdated || null });
                    }
                });
            }
            sorted = sorted.map((p) => {
                const pr = cheapestPreview.get(p.id);
                return pr ? { ...p, cheapestPrice: pr.price, cheapestStore: pr.supermarketId, priceDate: pr.priceDate, priceLastUpdated: pr.lastUpdated } : p;
            });
        }

        const results = sorted.slice(0, limit);
        const processingTime = Date.now() - startTime;

        const payload = {
            success: true,
            results,
            metadata: {
                processingTime,
                totalFound: products.length,
                query: normalizedQuery,
                appliedStores: storesFilter,
            },
        };

        // Save to short-lived cache
        if ((filters?.category ? false : true) && storesFilter.length === 0) {
            const key = normalizedQuery.toLowerCase();
            const hits = (QUERY_HITS.get(key) || 0) + 1;
            QUERY_HITS.set(key, hits);
            if (hits >= POPULAR_HIT_THRESHOLD) {
                POPULAR_CACHE.set(key, { data: payload, ts: Date.now() });
            }
        }
        setSearchCache(cacheKey, { results, metadata: payload.metadata });
        return payload;
    } catch (error) {
        console.error('fastProductSearchV2 error:', error);
        throw new HttpsError('internal', error?.message || 'Unknown error');
    }
    // ----------------------------------------------------------------------------
    // Ultra-fast shopping list hydration
    // - Trigger: recompute totals when an item is written
    // - Callable: fetch hydration for a batch of list IDs
    // ----------------------------------------------------------------------------

    // (Removed duplicate exports.hydrationOnItemWrite. The optimized version remains above.)
}
);

// (Removed duplicate exports.getListHydrationBatch. The optimized version remains above.)


/**
 * Generate phone number variations for matching
 * @param {string} phoneNumber - The phone number to generate variations for
 * @return {Array<string>} Array of phone number variations
 */
function generatePhoneVariations(phoneNumber) {
    const variations = new Set();

    // Add original number
    variations.add(phoneNumber);

    // Clean the number
    const cleaned = phoneNumber.replace(/[^\d+]/g, "");
    variations.add(cleaned);

    // Manual variations for common formats
    if (cleaned.startsWith("+1") && cleaned.length === 12) {
        const withoutCountryCode = cleaned.substring(2);
        variations.add(withoutCountryCode);
        variations.add(`1${withoutCountryCode}`);
    }

    return Array.from(variations);
}

/**
 * Hash phone number using SHA256
 * @param {string} phoneNumber - The phone number to hash
 * @return {string} SHA256 hash of the phone number
 */
function hashPhoneNumber(phoneNumber) {
    return createHash("sha256").update(phoneNumber).digest("hex");
}

/**
 * Search by name with optimization
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchByNameOptimized(query, limit) {
    const promises = [];
    const fields = ["firstName", "lastName", "displayName"];

    for (const field of fields) {
        promises.push(
            firestore()
                .collection("users")
                .where(field, ">=", query)
                .where(field, "<=", query + "\uf8ff")
                .limit(Math.ceil(limit / fields.length))
                .get()
        );
    }

    const snapshots = await Promise.all(promises);
    const results = [];
    const seenIds = new Set();

    // Merge results and remove duplicates
    for (const snapshot of snapshots) {
        snapshot.forEach((doc) => {
            if (!seenIds.has(doc.id)) {
                seenIds.add(doc.id);
                results.push({
                    uid: doc.id,
                    ...doc.data(),
                });
            }
        });
    }

    return results.slice(0, limit);
}

/**
 * Search by email with intelligent partial matching
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchByEmailOptimized(query, limit) {
    const promises = [];

    // Direct email search
    promises.push(
        firestore()
            .collection("users")
            .where("email", ">=", query)
            .where("email", "<=", query + "\uf8ff")
            .limit(limit)
            .get()
    );

    // If query doesn't contain @, also search for common email patterns
    if (!query.includes("@")) {
        // Search for users whose email starts with the query
        const commonDomains = ["@gmail.com", "@yahoo.com", "@hotmail.com", "@outlook.com"];
        for (const domain of commonDomains.slice(0, 2)) { // Limit to prevent too many queries
            promises.push(
                firestore()
                    .collection("users")
                    .where("email", ">=", query + domain)
                    .where("email", "<=", query + domain + "\uf8ff")
                    .limit(Math.ceil(limit / 4))
                    .get()
            );
        }
    }

    const snapshots = await Promise.all(promises);
    const results = [];
    const seenIds = new Set();

    for (const snapshot of snapshots) {
        snapshot.forEach((doc) => {
            if (!seenIds.has(doc.id)) {
                seenIds.add(doc.id);
                results.push({
                    uid: doc.id,
                    ...doc.data(),
                });
            }
        });
    }

    return results.slice(0, limit);
}

/**
 * Search by phone with intelligent partial matching
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchByPhoneOptimized(query, limit) {
    // Generate intelligent phone variations for partial matching
    const variations = generateIntelligentPhoneVariations(query);
    const promises = [];

    // Search for exact matches and partial matches
    for (const variation of variations.slice(0, 5)) { // Limit to prevent too many queries
        // Exact match
        promises.push(
            firestore()
                .collection("users")
                .where("phoneNumber", "==", variation)
                .limit(limit)
                .get()
        );

        // Partial match (phone numbers containing the query)
        if (variation.length >= 3) {
            promises.push(
                firestore()
                    .collection("users")
                    .where("phoneNumber", ">=", variation)
                    .where("phoneNumber", "<=", variation + "\uf8ff")
                    .limit(Math.ceil(limit / 2))
                    .get()
            );
        }
    }

    const snapshots = await Promise.all(promises);
    const results = [];
    const seenIds = new Set();

    for (const snapshot of snapshots) {
        snapshot.forEach((doc) => {
            if (!seenIds.has(doc.id)) {
                seenIds.add(doc.id);
                results.push({
                    uid: doc.id,
                    ...doc.data(),
                });
            }
        });
    }

    return results.slice(0, limit);
}

/**
 * Generate intelligent phone number variations for partial matching
 * @param {string} phoneNumber - The partial phone number to generate variations for
 * @return {Array<string>} Array of phone number variations
 */
function generateIntelligentPhoneVariations(phoneNumber) {
    const variations = new Set();

    // Add original number
    variations.add(phoneNumber);

    // Clean the number (remove spaces, dashes, parentheses)
    const cleaned = phoneNumber.replace(/[^\d+]/g, "");
    variations.add(cleaned);

    // Add with country code if missing
    if (!cleaned.startsWith("+") && !cleaned.startsWith("1") && cleaned.length >= 3) {
        variations.add("+1" + cleaned);
        variations.add("1" + cleaned);
    }

    // Remove country code if present
    if (cleaned.startsWith("+1") && cleaned.length > 3) {
        variations.add(cleaned.substring(2));
    }
    if (cleaned.startsWith("1") && cleaned.length > 3 && !cleaned.startsWith("11")) {
        variations.add(cleaned.substring(1));
    }

    // Add formatted versions for partial matching
    if (cleaned.length >= 3) {
        // Add with parentheses format
        if (cleaned.length >= 6) {
            const areaCode = cleaned.substring(0, 3);
            const rest = cleaned.substring(3);
            variations.add(`(${areaCode})${rest}`);
            variations.add(`(${areaCode}) ${rest}`);
        }

        // Add with dashes
        if (cleaned.length >= 6) {
            const formatted = cleaned.replace(/(\d{3})(\d{3})(\d{4})/, "$1-$2-$3");
            variations.add(formatted);
        }
    }

    return Array.from(variations);
}

/**
 * Intelligent mixed search with optimization
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchMixedOptimized(query, limit) {
    const results = [];
    const promises = [];

    // Intelligent detection of query intent
    const hasNumbers = /\d/.test(query);
    const hasAt = query.includes("@");
    const hasPlus = query.includes("+");
    const isLikelyEmail = hasAt || /^[a-zA-Z0-9].*[a-zA-Z]/.test(query);
    const isLikelyPhone = hasNumbers && (hasPlus || query.length >= 3);

    // Try name search (always include this)
    promises.push(searchByNameOptimized(query, Math.ceil(limit * 0.4)));

    // Try email search if it looks like email
    if (isLikelyEmail) {
        promises.push(searchByEmailOptimized(query, Math.ceil(limit * 0.4)));
    }

    // Try phone search if it looks like phone
    if (isLikelyPhone) {
        promises.push(searchByPhoneOptimized(query, Math.ceil(limit * 0.4)));
    }

    // If neither email nor phone, try partial search
    if (!isLikelyEmail && !isLikelyPhone) {
        promises.push(searchPartialOptimized(query, Math.ceil(limit * 0.4)));
    }

    const searchResults = await Promise.all(promises);

    // Merge all results
    for (const resultSet of searchResults) {
        results.push(...resultSet);
    }

    // Remove duplicates and sort by intelligent scoring
    const seenIds = new Set();
    const uniqueResults = results.filter((result) => {
        if (seenIds.has(result.uid)) {
            return false;
        }
        seenIds.add(result.uid);
        return true;
    });

    // Enhanced scoring for mixed queries
    uniqueResults.forEach((result) => {
        result.mixedScore = calculateIntelligentMixedScore(result, query);
    });

    return uniqueResults
        .sort((a, b) => b.mixedScore - a.mixedScore)
        .slice(0, limit);
}

/**
 * Calculate intelligent score for mixed queries
 * @param {Object} result - Search result
 * @param {string} query - Search query
 * @return {number} Mixed search score
 */
function calculateIntelligentMixedScore(result, query) {
    let score = 0;
    const queryLower = query.toLowerCase();

    // Name matching
    const fullName = `${result.firstName || ""} ${result.lastName || ""}`.toLowerCase();
    const displayName = (result.displayName || "").toLowerCase();

    if (fullName.startsWith(queryLower) || displayName.startsWith(queryLower)) {
        score += 100;
    } else if (fullName.includes(queryLower) || displayName.includes(queryLower)) {
        score += 80;
    }

    // Email matching
    if (result.email) {
        const email = result.email.toLowerCase();
        if (email.startsWith(queryLower)) {
            score += 90;
        } else if (email.includes(queryLower)) {
            score += 70;
        }
    }

    // Phone matching
    if (result.phoneNumber) {
        const phone = result.phoneNumber.replace(/[^\d]/g, "");
        const cleanQuery = query.replace(/[^\d]/g, "");
        if (phone.includes(cleanQuery)) {
            score += 85;
        }
    }

    return score;
}

/**
 * Rank search results
 * @param {Array} results - Search results to rank
 * @param {string} query - Original search query
 * @return {Array} Ranked results
 */
function rankResults(results, query) {
    // Simple ranking based on query match
    return results.sort((a, b) => {
        const aScore = calculateMatchScore(a, query);
        const bScore = calculateMatchScore(b, query);
        return bScore - aScore;
    });
}

/**
 * Calculate match score for ranking
 * @param {Object} result - Search result
 * @param {string} query - Search query
 * @return {number} Match score
 */
function calculateMatchScore(result, query) {
    let score = 0;
    const queryLower = query.toLowerCase();

    // Exact name match
    const fullName = `${result.firstName || ""} ${result.lastName || ""}`.toLowerCase();
    if (fullName.includes(queryLower)) {
        score += 10;
    }

    // First name match
    if (result.firstName && result.firstName.toLowerCase().includes(queryLower)) {
        score += 8;
    }

    // Last name match
    if (result.lastName && result.lastName.toLowerCase().includes(queryLower)) {
        score += 6;
    }

    // Email match
    if (result.email && result.email.toLowerCase().includes(queryLower)) {
        score += 7;
    }

    // Display name match (for Google users)
    if (result.displayName && result.displayName.toLowerCase().includes(queryLower)) {
        score += 5;
    }

    return score;
}

/**
 * Ultra-fast search for partial queries (1-2 characters) with instant suggestions
 * Optimized for minimal latency and maximum responsiveness
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchPartialOptimizedUltraFast(query, limit) {
    const startTime = Date.now();

    // PERFORMANCE OPTIMIZATION: Use batched parallel queries with strategic indexing
    const promises = [];

    // Search firstName (highest priority for names) - optimized with strategic limit
    promises.push(
        firestore()
            .collection("users")
            .where("firstName", ">=", query)
            .where("firstName", "<=", query + "\uf8ff")
            .limit(Math.min(Math.ceil(limit * 0.5), 20)) // Strategic limit for speed
            .get()
    );

    // Search lastName (important for last name searches) - optimized
    promises.push(
        firestore()
            .collection("users")
            .where("lastName", ">=", query)
            .where("lastName", "<=", query + "\uf8ff")
            .limit(Math.min(Math.ceil(limit * 0.4), 15)) // Optimized limit
            .get()
    );

    // Search displayName (for Google users) - optimized
    promises.push(
        firestore()
            .collection("users")
            .where("displayName", ">=", query)
            .where("displayName", "<=", query + "\uf8ff")
            .limit(Math.min(Math.ceil(limit * 0.3), 10)) // Optimized limit
            .get()
    );

    // Smart email search - only if query looks like email start
    if (query.match(/^[a-zA-Z@]/)) {
        promises.push(
            firestore()
                .collection("users")
                .where("email", ">=", query)
                .where("email", "<=", query + "\uf8ff")
                .limit(Math.min(Math.ceil(limit * 0.2), 8)) // Optimized limit
                .get()
        );
    }

    // ULTRA-FAST: Execute all queries in parallel with timeout
    const snapshots = await Promise.all(promises);
    const results = [];
    const seenIds = new Set();

    // PERFORMANCE: Process results with optimized scoring
    for (const snapshot of snapshots) {
        snapshot.forEach((doc) => {
            if (!seenIds.has(doc.id) && seenIds.size < limit * 2) { // Limit processing for speed
                seenIds.add(doc.id);
                const userData = doc.data();

                // Skip users without essential data for speed
                if (!userData.firstName && !userData.lastName && !userData.displayName) {
                    return;
                }

                results.push({
                    uid: doc.id,
                    ...userData,
                    // Ultra-optimized instant match score
                    matchScore: calculateTurboMatchScore(userData, query),
                });
            }
        });
    }

    const processTime = Date.now() - startTime;
    console.log(`🚀 ULTRA-FAST SEARCH: "${query}" processed in ${processTime}ms, ${results.length} results`);

    // Turbo-charged sort and return
    return results
        .sort((a, b) => b.matchScore - a.matchScore)
        .slice(0, limit);
}

/**
 * Turbo-charged match score calculation for ultra-fast instant search
 * @param {Object} userData - User data
 * @param {string} query - Search query
 * @return {number} Turbo match score (optimized for speed)
 */
function calculateTurboMatchScore(userData, query) {
    const queryLower = query.toLowerCase();
    let score = 0.5; // Base score

    // ULTRA-FAST: Check firstName (most important) with early returns
    if (userData.firstName) {
        const firstName = userData.firstName.toLowerCase();
        if (firstName.startsWith(queryLower)) {
            return 1.0; // Early return for perfect prefix match
        }
        if (firstName.includes(queryLower)) {
            score = 0.85;
        }
    }

    // Check lastName with optimization
    if (userData.lastName && score < 0.95) {
        const lastName = userData.lastName.toLowerCase();
        if (lastName.startsWith(queryLower)) {
            return 0.95; // Early return for last name prefix
        }
        if (lastName.includes(queryLower)) {
            score = Math.max(score, 0.8);
        }
    }

    // Check displayName (quick check)
    if (userData.displayName && score < 0.9) {
        const displayName = userData.displayName.toLowerCase();
        if (displayName.startsWith(queryLower)) {
            score = Math.max(score, 0.9);
        } else if (displayName.includes(queryLower)) {
            score = Math.max(score, 0.75);
        }
    }

    // SPEED OPTIMIZATION: Quick email check only if query contains @ or looks like email
    if (userData.email && (queryLower.includes('@') || query.length > 2)) {
        const email = userData.email.toLowerCase();
        if (email.startsWith(queryLower)) {
            score = Math.max(score, 0.88);
        }
    }

    return score;
}

/**
 * Ultra-fast match score calculation for instant search (LEGACY - kept for compatibility)
 * @param {Object} userData - User data
 * @param {string} query - Search query
 * @return {number} Ultra-fast match score
 */
function calculateUltraFastMatchScore(userData, query) {
    // Delegate to turbo version for better performance
    return calculateTurboMatchScore(userData, query);
}

/**
 * Search for partial queries (1-2 characters) with instant suggestions
 * @param {string} query - Search query
 * @param {number} limit - Result limit
 * @return {Promise<Array>} Search results
 */
async function searchPartialOptimized(query, limit) {
    // For very short queries, search across all relevant fields
    const promises = [];
    const fields = ["firstName", "lastName", "displayName", "email"];

    // Search each field with prefix matching
    for (const field of fields) {
        promises.push(
            firestore()
                .collection("users")
                .where(field, ">=", query)
                .where(field, "<=", query + "\uf8ff")
                .limit(Math.ceil(limit / fields.length) + 5) // Get more for better results
                .get()
        );
    }

    const snapshots = await Promise.all(promises);
    const results = [];
    const seenIds = new Set();

    // Merge results and remove duplicates
    for (const snapshot of snapshots) {
        snapshot.forEach((doc) => {
            if (!seenIds.has(doc.id)) {
                seenIds.add(doc.id);
                const userData = doc.data();
                results.push({
                    uid: doc.id,
                    ...userData,
                    // Add instant match score for partial queries
                    instantMatchScore: calculateInstantMatchScore(userData, query),
                });
            }
        });
    }

    // Sort by instant match score and return top results
    return results
        .sort((a, b) => b.instantMatchScore - a.instantMatchScore)
        .slice(0, limit);
}

/**
 * Calculate instant match score for partial queries
 * @param {Object} userData - User data
 * @param {string} query - Search query
 * @return {number} Instant match score
 */
function calculateInstantMatchScore(userData, query) {
    let score = 0;
    const queryLower = query.toLowerCase();

    // Higher score for exact prefix matches
    if (userData.firstName && userData.firstName.toLowerCase().startsWith(queryLower)) {
        score += 100;
    }
    if (userData.lastName && userData.lastName.toLowerCase().startsWith(queryLower)) {
        score += 90;
    }
    if (userData.displayName && userData.displayName.toLowerCase().startsWith(queryLower)) {
        score += 85;
    }
    if (userData.email && userData.email.toLowerCase().startsWith(queryLower)) {
        score += 80;
    }

    // Lower score for contains matches
    if (userData.firstName && userData.firstName.toLowerCase().includes(queryLower)) {
        score += 50;
    }
    if (userData.lastName && userData.lastName.toLowerCase().includes(queryLower)) {
        score += 45;
    }
    if (userData.displayName && userData.displayName.toLowerCase().includes(queryLower)) {
        score += 40;
    }
    if (userData.email && userData.email.toLowerCase().includes(queryLower)) {
        score += 35;
    }

    return score;
}

/**
 * Server-side privacy filtering to reduce data transfer
 * Filters out users based on their privacy settings:
 * - Fully private users are always hidden
 * - Users not searchable by the query type are filtered out
 * 
 * @param {Array} results - Search results to filter
 * @param {string} queryType - Type of search query (name, email, phone, mixed, partial)
 * @param {string} currentUserId - The ID of the user performing the search
 * @return {Promise<Array>} Filtered results
 */
async function filterByPrivacySettings(results, queryType, currentUserId) {
    if (!results || results.length === 0) return results;
    
    const userIds = results.map(r => r.uid).filter(id => id && id !== currentUserId);
    if (userIds.length === 0) return results;
    
    try {
        // Batch fetch privacy settings from user documents
        // Privacy is stored in users/{uid}.privacy field
        const privacyMap = new Map();
        
        // Process in batches of 10 (Firestore 'in' query limit)
        for (let i = 0; i < userIds.length; i += 10) {
            const batchIds = userIds.slice(i, i + 10);
            const snapshot = await firestore()
                .collection('users')
                .where(firestore.FieldPath.documentId(), 'in', batchIds)
                .select('privacy') // Only fetch privacy field for efficiency
                .get();
            
            snapshot.forEach(doc => {
                const privacy = doc.data().privacy || {};
                privacyMap.set(doc.id, privacy);
            });
        }
        
        // Filter results based on privacy settings
        return results.filter(result => {
            const uid = result.uid;
            
            // Always include current user
            if (uid === currentUserId) return true;
            
            const privacy = privacyMap.get(uid) || {};
            
            // Filter out fully private users
            if (privacy.isFullyPrivate === true) {
                return false;
            }
            
            // Check searchability based on query type
            switch (queryType) {
                case 'name':
                case 'partial':
                    // Default to true if not set
                    return privacy.searchableByName !== false;
                    
                case 'email':
                    return privacy.searchableByEmail !== false;
                    
                case 'phone':
                    return privacy.searchableByPhone !== false;
                    
                case 'mixed':
                    // For mixed queries, user must be searchable by at least one method
                    return (privacy.searchableByName !== false) ||
                           (privacy.searchableByEmail !== false) ||
                           (privacy.searchableByPhone !== false);
                    
                default:
                    return true;
            }
        });
        
    } catch (error) {
        console.error('Privacy filtering error:', error);
        // On error, return original results to not break search
        return results;
    }
}


function calculateSearchScore(product, query) {
    const queryWords = String(query).toLowerCase().split(' ').filter((w) => w.length > 0);
    if (queryWords.length === 0) return 0;
    let totalScore = 0;

    for (const word of queryWords) {
        let fieldScore = 0;
        const name = (product.name || '').toLowerCase();
        const brand = (product.brand_name || product.brandName || '').toLowerCase();
        const variety = (product.variety || '').toLowerCase();
        const original = (product.original_name || '').toLowerCase();
        const category = (product.category || '').toLowerCase();

        if (name.includes(word)) fieldScore += 1.0;
        if (brand.includes(word)) fieldScore += 0.8;
        if (variety.includes(word)) fieldScore += 0.6;
        if (original.includes(word)) fieldScore += 0.5;
        if (category.includes(word)) fieldScore += 0.3;

        totalScore += fieldScore;
    }
    return totalScore / queryWords.length;
}

// Helper functions reused from comprehensive analytics (lightweight copies to avoid cross-file coupling)
// Helpers for removed personalization features have been pruned to keep the bundle lean.

// Analytics pipelines and helpers removed.

async function getProductDataV2(productId) {
    try {
        const productDoc = await firestore().collection('products').doc(productId).get();
        return productDoc.exists ? productDoc.data() : null;
    } catch (e) {
        return null;
    }
}

exports.syncPresenceToFirestore = onValueWritten(
    {
        ref: '/status/{uid}',
        instance: 'shopple-7a67b-default-rtdb',
        region: 'asia-southeast1',
    },
    async (event) => {
        const uid = event.params.uid;

        // Get the data after the change
        const afterData = event.data.after.val();

        // If the status was deleted (user completely disconnected)
        if (!afterData) {
            console.log(`🔄 Status deleted for user ${uid}, marking as offline`);

            try {
                const batch = firestore().batch();

                // Update status collection
                const statusRef = firestore().collection('status').doc(uid);
                batch.set(statusRef, {
                    state: 'offline',
                    last_changed: firestore.FieldValue.serverTimestamp(),
                }, { merge: true });

                // Update user document
                const userRef = firestore().collection('users').doc(uid);
                batch.set(userRef, {
                    presence: {
                        state: 'offline',
                        last_changed: firestore.FieldValue.serverTimestamp(),
                    }
                }, { merge: true });

                await batch.commit();
                console.log(`✅ Marked user ${uid} as offline (status deleted)`);
            } catch (error) {
                console.error(`❌ Failed to mark user ${uid} as offline:`, error);
            }

            return;
        }

        // Get the current status data from RTDB
        const state = afterData.state || 'offline'; // 'online' or 'offline'
        const lastChanged = afterData.last_changed || Date.now();

        console.log(`🔄 Syncing presence for user ${uid}: ${state}`);

        try {
            const batch = firestore().batch();

            // Update status collection (primary presence document)
            const statusRef = firestore().collection('status').doc(uid);
            batch.set(statusRef, {
                state: state,
                last_changed: firestore.FieldValue.serverTimestamp(),
                // Preserve any custom status fields that might exist in Firestore
                ...(afterData.customStatus && { customStatus: afterData.customStatus }),
                ...(afterData.statusEmoji && { statusEmoji: afterData.statusEmoji }),
            }, { merge: true });

            // Update user document presence field (for backward compatibility)
            const userRef = firestore().collection('users').doc(uid);
            batch.set(userRef, {
                presence: {
                    state: state,
                    last_changed: firestore.FieldValue.serverTimestamp(),
                }
            }, { merge: true });

            await batch.commit();
            console.log(`✅ Successfully synced presence for user ${uid}: ${state}`);
        } catch (error) {
            console.error(`❌ Failed to sync presence for user ${uid}:`, error);
        }
    }
);

exports.cleanupStalePresence = onSchedule(
    {
        schedule: 'every 30 minutes',
        timeZone: 'Asia/Kolkata',
        region: 'asia-south1',
    },
    async (event) => {
        console.log('🧹 Starting stale presence cleanup...');

        const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);

        try {
            // Get all users marked as online in Firestore, process in batches for scalability
            const rtdb = database();
            const batchSize = 100; // batch size as needed
            let lastDoc = null;
            let staleCount = 0;
            let totalProcessed = 0;
            let moreDocs = true;

            while (moreDocs) {
                let query = firestore()
                    .collection('status')
                    .where('state', '==', 'online')
                    .limit(batchSize);

                if (lastDoc) {
                    query = query.startAfter(lastDoc);
                }

                const onlineUsersSnapshot = await query.get();

                if (onlineUsersSnapshot.empty) {
                    moreDocs = false;
                    break;
                }

                const batch = firestore().batch();

                // Check each online user against RTDB
                for (const doc of onlineUsersSnapshot.docs) {
                    const uid = doc.id;

                    try {
                        // Check RTDB status
                        const rtdbSnapshot = await rtdb.ref(`status/${uid}`).once('value');
                        const rtdbData = rtdbSnapshot.val();

                        // If RTDB says offline but Firestore says online, sync it
                        if (!rtdbData || rtdbData.state === 'offline') {
                            const statusRef = firestore().collection('status').doc(uid);
                            batch.set(statusRef, {
                                state: 'offline',
                                last_changed: firestore.FieldValue.serverTimestamp(),
                            }, { merge: true });

                            const userRef = firestore().collection('users').doc(uid);
                            batch.set(userRef, {
                                presence: {
                                    state: 'offline',
                                    last_changed: firestore.FieldValue.serverTimestamp(),
                                }
                            }, { merge: true });

                            staleCount++;
                        }
                    } catch (error) {
                        console.error(`⚠️ Error checking user ${uid}:`, error);
                    }
                }

                if (staleCount > 0) {
                    await batch.commit();
                    console.log(`✅ Cleaned up ${staleCount} stale presence records in this batch`);
                } else {
                    console.log('✅ No stale presence records found in this batch');
                }

                totalProcessed += onlineUsersSnapshot.docs.length;
                lastDoc = onlineUsersSnapshot.docs[onlineUsersSnapshot.docs.length - 1];
                moreDocs = onlineUsersSnapshot.docs.length === batchSize;
            }

            console.log(`✅ Finished processing ${totalProcessed} online users for stale presence cleanup`);
        } catch (error) {
            console.error('❌ Error in cleanupStalePresence:', error);
        }
    }
);
// ----------------------------------------------------------------------------
// Stream Chat Integration
// ----------------------------------------------------------------------------
const { StreamChat } = require('stream-chat');

// Initialize Stream Chat Client
// Note: Ensure STREAM_API_KEY and STREAM_API_SECRET are set in functions config or env
// firebase functions:config:set stream.key="YOUR_KEY" stream.secret="YOUR_SECRET"
// Or use process.env if set via other means
const getStreamClient = () => {
    // Prefer process.env for V2 (set via .env file or Cloud Console)
    // Fallback to functions.config() for legacy support if needed
    const apiKey = process.env.STREAM_API_KEY || (config().stream && config().stream.key);
    const apiSecret = process.env.STREAM_API_SECRET || (config().stream && config().stream.secret);

    if (!apiKey || !apiSecret) {
        console.error('Stream Chat API key or secret not found in env/config');
        return null;
    }
    return StreamChat.getInstance(apiKey, apiSecret);
};

exports.createStreamUser = functions.region("asia-south1").auth.user().onCreate(async (user) => {
    try {
        const client = getStreamClient();
        if (!client) return;

        console.log(`Creating Stream Chat user for: ${user.uid}`);

        await client.upsertUser({
            id: user.uid,
            name: user.displayName || 'User',
            email: user.email,
            image: user.photoURL,
            firebase_uid: user.uid,
        });

        // Mark as synced in Firestore
        await firestore().collection('users').doc(user.uid).set({
            streamSyncedAt: firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log(`Successfully created Stream Chat user: ${user.uid}`);
    } catch (error) {
        console.error('Error creating Stream Chat user:', error);
        // We don't throw here to avoid infinite retry loops on auth triggers
    }
});

exports.ensureStreamUser = onCall({ region: "asia-south1" }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId } = request.data || {};
    if (!userId) {
        throw new HttpsError('invalid-argument', 'userId is required');
    }

    const client = getStreamClient();
    if (!client) {
        throw new HttpsError('internal', 'Stream Chat configuration missing');
    }

    try {
        console.log(`Ensuring Stream Chat user exists: ${userId}`);

        // 1. Fetch user data from Firestore
        const userDoc = await firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'User not found in Firestore');
        }

        const userData = userDoc.data();

        // 2. Check if already synced (optional optimization, but good to double check)
        if (userData.streamSyncedAt) {
            // We can return early, OR we can force update just in case it's out of sync
            // Let's force update to be safe since this is a "repair" function
        }

        // 3. Prepare Stream User object
        let displayName = userData.displayName || 'User';
        if (userData.firstName) {
            displayName = `${userData.firstName} ${userData.lastName || ''}`.trim();
        }

        // 4. Upsert to Stream Chat
        await client.upsertUser({
            id: userId,
            name: displayName,
            email: userData.email,
            image: userData.customPhotoURL || userData.photoURL,
            firebase_uid: userId,
        });

        // 5. Mark as synced
        await firestore().collection('users').doc(userId).set({
            streamSyncedAt: firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log(`Successfully repaired/synced user: ${userId}`);
        return { success: true, message: 'User synced successfully' };

    } catch (error) {
        console.error(`Error ensuring Stream user ${userId}:`, error);
        throw new HttpsError('internal', error?.message || 'Sync failed');
    }
});

// ============================================================================
// Budget Tracking & Alerts
// ============================================================================

/**
 * Triggered when a shopping list item is completed.
 * Updates budget tracking aggregations and sends alerts if thresholds are exceeded.
 */
exports.budgetTrackingOnItemComplete = onDocumentWritten(
    { region: "asia-south1" },
    "shopping_lists/{listId}/items/{itemId}",
    async (event) => {
        const { listId, itemId } = event.params;
        const beforeData = event.data.before?.data();
        const afterData = event.data.after?.data();

        // Only process when item is marked as completed
        const wasCompleted = beforeData?.isCompleted === true;
        const isNowCompleted = afterData?.isCompleted === true;

        // Skip if not a completion event
        if (!isNowCompleted || wasCompleted) return;

        try {
            const itemPrice = Number(afterData.estimatedPrice || 0);
            const itemQty = Number(afterData.quantity || 1);
            const itemTotal = itemPrice * itemQty;
            const itemCategory = afterData.category || 'other';
            const now = new Date();

            // Get the shopping list to check budget
            const listDoc = await firestore()
                .collection('shopping_lists')
                .doc(listId)
                .get();

            if (!listDoc.exists) return;

            const listData = listDoc.data();
            const budget = Number(listData.budgetLimit || 0);
            const ownerId = listData.createdBy;

            // Update budget tracking document for this list
            const trackingRef = firestore()
                .collection('shopping_lists')
                .doc(listId)
                .collection('meta')
                .doc('budget_tracking');

            const trackingDoc = await trackingRef.get();
            const existingTracking = trackingDoc.exists ? trackingDoc.data() : {};

            // Update daily spend
            const todayKey = now.toISOString().split('T')[0]; // YYYY-MM-DD
            const dailySpend = existingTracking.dailySpend || {};
            dailySpend[todayKey] = (Number(dailySpend[todayKey]) || 0) + itemTotal;

            // Update category spend
            const categorySpend = existingTracking.categorySpend || {};
            categorySpend[itemCategory] = (Number(categorySpend[itemCategory]) || 0) + itemTotal;

            // Calculate total spent (from list's estimatedTotal for accuracy)
            const completedItemsSnap = await firestore()
                .collection('shopping_lists')
                .doc(listId)
                .collection('items')
                .where('isCompleted', '==', true)
                .get();

            let totalSpent = 0;
            completedItemsSnap.forEach(doc => {
                const d = doc.data();
                totalSpent += (Number(d.estimatedPrice || 0) * Number(d.quantity || 1));
            });

            // Update tracking document
            await trackingRef.set({
                totalSpent,
                dailySpend,
                categorySpend,
                lastItemCompleted: firestore.FieldValue.serverTimestamp(),
                lastItemPrice: itemTotal,
                lastItemCategory: itemCategory,
                itemsCompleted: completedItemsSnap.size,
            }, { merge: true });

            // Check for budget alerts
            if (budget > 0 && ownerId) {
                const utilization = totalSpent / budget;
                const alerts = [];

                // Check thresholds (75%, 90%, 100%)
                const previousTotal = totalSpent - itemTotal;
                const previousUtil = previousTotal / budget;

                if (utilization >= 1.0 && previousUtil < 1.0) {
                    alerts.push({
                        type: 'exceeded',
                        threshold: 100,
                        message: `Budget exceeded! You've spent Rs ${totalSpent.toFixed(0)} of Rs ${budget.toFixed(0)} budget.`,
                        utilization,
                    });
                } else if (utilization >= 0.9 && previousUtil < 0.9) {
                    alerts.push({
                        type: 'near_limit',
                        threshold: 90,
                        message: `90% of budget used. Rs ${(budget - totalSpent).toFixed(0)} remaining.`,
                        utilization,
                    });
                } else if (utilization >= 0.75 && previousUtil < 0.75) {
                    alerts.push({
                        type: 'warning',
                        threshold: 75,
                        message: `75% of budget used. Rs ${(budget - totalSpent).toFixed(0)} remaining.`,
                        utilization,
                    });
                }

                // Store alerts for the user
                if (alerts.length > 0) {
                    const alertRef = firestore()
                        .collection('users')
                        .doc(ownerId)
                        .collection('budget_alerts')
                        .doc();

                    await alertRef.set({
                        listId,
                        listName: listData.name || 'Shopping List',
                        alerts,
                        totalSpent,
                        budget,
                        utilization,
                        triggeredBy: itemId,
                        createdAt: firestore.FieldValue.serverTimestamp(),
                        read: false,
                    });

                    console.log(`📊 Budget alert triggered for list ${listId}: ${alerts[0].type}`);
                }
            }

            console.log(`✅ Budget tracking updated for list ${listId}: Rs ${totalSpent.toFixed(0)} spent`);

        } catch (error) {
            console.error('budgetTrackingOnItemComplete error:', error);
        }
    }
);

/**
 * Callable function to get budget summary for a user
 */
exports.getBudgetSummary = onCall({ region: "asia-south1" }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const { period = 'month' } = request.data || {};

    try {
        const now = new Date();
        let startDate;

        switch (period) {
            case 'week':
                startDate = new Date(now);
                startDate.setDate(startDate.getDate() - startDate.getDay());
                break;
            case 'month':
            default:
                startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                break;
        }

        // Get user's active shopping lists
        const listsSnap = await firestore()
            .collection('shopping_lists')
            .where('memberIds', 'array-contains', userId)
            .where('status', '==', 'active')
            .get();

        let totalBudget = 0;
        let totalSpent = 0;
        const categorySpend = {};
        const listSummaries = [];

        for (const listDoc of listsSnap.docs) {
            const listData = listDoc.data();
            const listBudget = Number(listData.budgetLimit || 0);

            // Get tracking data
            const trackingDoc = await firestore()
                .collection('shopping_lists')
                .doc(listDoc.id)
                .collection('meta')
                .doc('budget_tracking')
                .get();

            const tracking = trackingDoc.exists ? trackingDoc.data() : {};
            const listSpent = Number(tracking.totalSpent || 0);

            totalBudget += listBudget;
            totalSpent += listSpent;

            // Aggregate category spending
            const cats = tracking.categorySpend || {};
            for (const [cat, amount] of Object.entries(cats)) {
                categorySpend[cat] = (categorySpend[cat] || 0) + Number(amount);
            }

            listSummaries.push({
                listId: listDoc.id,
                listName: listData.name,
                budget: listBudget,
                spent: listSpent,
                utilization: listBudget > 0 ? listSpent / listBudget : 0,
                isOverBudget: listBudget > 0 && listSpent > listBudget,
            });
        }

        // Sort categories by spend
        const sortedCategories = Object.entries(categorySpend)
            .map(([category, spent]) => ({ category, spent }))
            .sort((a, b) => b.spent - a.spent);

        return {
            success: true,
            summary: {
                totalBudget,
                totalSpent,
                remaining: totalBudget - totalSpent,
                utilization: totalBudget > 0 ? totalSpent / totalBudget : 0,
                isOverBudget: totalBudget > 0 && totalSpent > totalBudget,
                period,
                periodStart: startDate.toISOString(),
            },
            categories: sortedCategories.slice(0, 10),
            lists: listSummaries.sort((a, b) => b.spent - a.spent),
        };

    } catch (error) {
        console.error('getBudgetSummary error:', error);
        throw new HttpsError('internal', error?.message || 'Failed to get budget summary');
    }
});

/**
 * Mark budget alerts as read
 */
exports.markBudgetAlertsRead = onCall({ region: "asia-south1" }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const { alertIds } = request.data || {};

    try {
        const batch = firestore().batch();
        const alertsRef = firestore()
            .collection('users')
            .doc(userId)
            .collection('budget_alerts');

        if (alertIds && Array.isArray(alertIds)) {
            // Mark specific alerts as read
            for (const alertId of alertIds) {
                batch.update(alertsRef.doc(alertId), { read: true });
            }
        } else {
            // Mark all unread alerts as read
            const unreadSnap = await alertsRef.where('read', '==', false).get();
            unreadSnap.forEach(doc => {
                batch.update(doc.ref, { read: true });
            });
        }

        await batch.commit();
        return { success: true };

    } catch (error) {
        console.error('markBudgetAlertsRead error:', error);
        throw new HttpsError('internal', error?.message || 'Failed to mark alerts as read');
    }
});
