import 'package:flutter/widgets.dart';
import '../../services/product/current_price_cache.dart';

class CurrentPriceProvider extends StatefulWidget {
  final Widget child;
  const CurrentPriceProvider({super.key, required this.child});

  static CurrentPriceCache of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_InheritedPriceCache>();
    assert(inherited != null, 'CurrentPriceProvider not found in context');
    return inherited!.cache;
  }

  @override
  State<CurrentPriceProvider> createState() => _CurrentPriceProviderState();
}

class _CurrentPriceProviderState extends State<CurrentPriceProvider> {
  final _cache = CurrentPriceCache.instance;
  Set<String> _lastChanged = const {};

  @override
  void initState() {
    super.initState();
    _cache.changedProducts.listen((changed) {
      setState(() => _lastChanged = changed);
    });
  }

  @override
  Widget build(BuildContext context) => _InheritedPriceCache(
    cache: _cache,
    changed: _lastChanged,
    child: widget.child,
  );
}

class _InheritedPriceCache extends InheritedWidget {
  final CurrentPriceCache cache;
  final Set<String> changed;
  const _InheritedPriceCache({
    required this.cache,
    required this.changed,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedPriceCache oldWidget) {
    if (identical(changed, oldWidget.changed)) return false;
    if (changed.length != oldWidget.changed.length) return true;
    for (final id in changed) {
      if (!oldWidget.changed.contains(id)) return true;
    }
    return false;
  }
}

class CurrentPriceConsumer extends StatefulWidget {
  final List<String> productIds;
  final Widget Function(BuildContext context, Map<String, num?> prices) builder;
  const CurrentPriceConsumer({
    super.key,
    required this.productIds,
    required this.builder,
  });

  @override
  State<CurrentPriceConsumer> createState() => _CurrentPriceConsumerState();
}

class _CurrentPriceConsumerState extends State<CurrentPriceConsumer> {
  Map<String, num?> _last = const {};

  @override
  Widget build(BuildContext context) {
    final cache = CurrentPriceProvider.of(context);
    final map = <String, num?>{};
    for (final id in widget.productIds) {
      map[id] = cache.cheapestFor(id);
    }
    final merged = <String, num?>{};
    for (final entry in map.entries) {
      merged[entry.key] = entry.value ?? _last[entry.key];
    }
    _last = merged;
    return widget.builder(context, merged);
  }
}
