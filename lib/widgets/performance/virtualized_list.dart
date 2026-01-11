import 'package:flutter/material.dart';

/// 📱 VIRTUALIZED LIST WIDGET
///
/// High-performance list widget that virtualizes items to prevent
/// main thread blocking and reduce memory pressure.
///
/// Features:
/// - Smart item recycling
/// - Lazy loading with visible range optimization
/// - Memory pressure management
/// - Scroll performance optimization
class VirtualizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final int visibleItemBuffer;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const VirtualizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.itemExtent,
    this.visibleItemBuffer = 5,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<VirtualizedList<T>> createState() => _VirtualizedListState<T>();
}

class _VirtualizedListState<T> extends State<VirtualizedList<T>>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _controller;
  final Map<int, Widget> _cachedItems = {};
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_onScroll);

    // Initial visible range calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleRange();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onScroll);
    }
    _cachedItems.clear();
    super.dispose();
  }

  void _onScroll() {
    _updateVisibleRange();
    _cleanupCachedItems();
  }

  void _updateVisibleRange() {
    if (!_controller.hasClients || widget.items.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;
    final itemHeight = widget.itemExtent ?? 60.0; // Default estimate

    final scrollOffset = _controller.offset;
    final visibleCount = (viewportHeight / itemHeight).ceil();

    final newFirstIndex = (scrollOffset / itemHeight).floor().clamp(
      0,
      widget.items.length - 1,
    );
    final newLastIndex =
        (newFirstIndex + visibleCount + widget.visibleItemBuffer).clamp(
          0,
          widget.items.length - 1,
        );

    if (newFirstIndex != _firstVisibleIndex ||
        newLastIndex != _lastVisibleIndex) {
      setState(() {
        _firstVisibleIndex = newFirstIndex;
        _lastVisibleIndex = newLastIndex;
      });
    }
  }

  void _cleanupCachedItems() {
    // Remove cached items that are far from visible range
    final cleanupThreshold = widget.visibleItemBuffer * 2;
    final keysToRemove = <int>[];

    for (final key in _cachedItems.keys) {
      if (key < _firstVisibleIndex - cleanupThreshold ||
          key > _lastVisibleIndex + cleanupThreshold) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cachedItems.remove(key);
    }
  }

  Widget _buildItem(int index) {
    if (_cachedItems.containsKey(index)) {
      return _cachedItems[index]!;
    }

    if (index >= widget.items.length) {
      return const SizedBox.shrink();
    }

    final item = widget.items[index];
    final builtWidget = widget.itemBuilder(context, item, index);

    // Cache the widget for reuse
    _cachedItems[index] = builtWidget;

    return builtWidget;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No items'));
    }

    return ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: widget.items.length,
      itemExtent: widget.itemExtent,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.visibleItemBuffer * (widget.itemExtent ?? 60.0),
      itemBuilder: (context, index) {
        // Only build items in visible range + buffer
        if (index < _firstVisibleIndex - widget.visibleItemBuffer ||
            index > _lastVisibleIndex + widget.visibleItemBuffer) {
          return SizedBox(height: widget.itemExtent);
        }

        return _buildItem(index);
      },
    );
  }
}

/// 📱 MEMORY-OPTIMIZED GRID WIDGET
///
/// High-performance grid widget with smart virtualization
class VirtualizedGrid<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const VirtualizedGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
    this.controller,
  });

  @override
  State<VirtualizedGrid<T>> createState() => _VirtualizedGridState<T>();
}

class _VirtualizedGridState<T> extends State<VirtualizedGrid<T>> {
  final Map<int, Widget> _cachedItems = {};

  @override
  void dispose() {
    _cachedItems.clear();
    super.dispose();
  }

  Widget _buildItem(int index) {
    if (_cachedItems.containsKey(index)) {
      return _cachedItems[index]!;
    }

    if (index >= widget.items.length) {
      return const SizedBox.shrink();
    }

    final item = widget.items[index];
    final builtWidget = widget.itemBuilder(context, item, index);

    // Cache with cleanup threshold
    if (_cachedItems.length > 100) {
      // Cleanup threshold
      _cachedItems.clear();
    }
    _cachedItems[index] = builtWidget;

    return builtWidget;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) => _buildItem(index),
    );
  }
}
