import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';

class AgentHistoryService {
  static const _historyKeyBase = 'agent_history_v1';
  
  List<Map<String, dynamic>> _history = [];
  StreamSubscription<QuerySnapshot>? _historySub;
  bool _remoteHistoryLoaded = false;

  List<Map<String, dynamic>> get history => List.unmodifiable(_history);
  bool get remoteHistoryLoaded => _remoteHistoryLoaded;

  String _historyKeyFor(String uid) => '${_historyKeyBase}_$uid';

  void clearLocalState() {
    _history.clear();
    _remoteHistoryLoaded = false;
    _historySub?.cancel();
  }

  Future<void> loadHistory(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKeyFor(uid));
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          _history = decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {
      /* ignore */
    }
  }

  void initCloudHistory(String uid, Function() onUpdate) {
    try {
      _historySub?.cancel();
      _historySub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ai_history')
          .orderBy('ts', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snap) {
              final remote = snap.docs.map((d) => d.data()).toList();
              _history = remote;
              _remoteHistoryLoaded = true;
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString(_historyKeyFor(uid), json.encode(_history));
              });
              onUpdate();
            },
            onError: (_) {
              _remoteHistoryLoaded = true;
              onUpdate();
            },
          );
    } catch (_) {
      _remoteHistoryLoaded = true;
    }
  }

  Future<void> persistHistoryEntry(
    String input,
    AgentRunResult result,
    int elapsedMs,
    Map<String, String> itemImages, {
    bool requireItems = false,
    String? overrideTs,
    bool updateExisting = false,
    String? activeSessionHistoryTs,
    Function(String?)? onSessionTsUpdate,
  }) async {
    if (requireItems && result.addedItems.isEmpty && result.failures.isEmpty) {
      return;
    }
    try {
      final ts = overrideTs ?? DateTime.now().toIso8601String();
      final addedImagesMap = <String, String>{};
      for (final phrase in result.addedItems.keys) {
        final img = itemImages[phrase];
        if (img != null && img.isNotEmpty) {
          addedImagesMap[phrase] = img;
        }
      }
      final entry = {
        'ts': ts,
        'input': input,
        'listId': result.listId,
        'added': result.addedItems.length,
        'failed': result.failures.length,
        'addedPhrases': result.addedItems.keys.toList(),
        'failedPhrases': result.failures.keys.toList(),
        'addedImages': addedImagesMap,
        'durationMs': elapsedMs,
        'uid': FirebaseAuth.instance.currentUser?.uid,
      };
      
      if (updateExisting) {
        final idx = _history.indexWhere((e) => e['ts'] == ts);
        if (idx != -1) {
          _history[idx] = entry;
        } else {
          _history.insert(0, entry);
        }
      } else {
        _history.insert(0, entry);
      }
      
      if (_history.length > 50) _history = _history.take(50).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await prefs.setString(_historyKeyFor(uid), json.encode(_history));
      }
      
      _persistHistoryEntryRemote(entry);
      
      if (requireItems && !updateExisting && activeSessionHistoryTs == null && onSessionTsUpdate != null) {
        onSessionTsUpdate(ts);
      }
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _persistHistoryEntryRemote(Map<String, dynamic> entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final docId = entry['ts'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_history')
          .doc(docId)
          .set(entry, SetOptions(merge: true));
    } catch (_) {
      /* ignore remote errors */
    }
  }

  Future<void> clearHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _history.clear();
    try {
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_historyKeyFor(uid));
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ai_history');
        final snap = await col.limit(100).get();
        final batch = FirebaseFirestore.instance.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> deleteHistoryEntry(String timestamp) async {
    _history.removeWhere((e) => e['ts'] == timestamp);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_historyKeyFor(uid), json.encode(_history));
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ai_history')
            .doc(timestamp)
            .delete();
      }
    } catch (_) {
      /* ignore */
    }
  }

  void dispose() {
    _historySub?.cancel();
  }
}
