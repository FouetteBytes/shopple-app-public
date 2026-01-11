import 'package:flutter/material.dart';
import 'remote_config_service.dart';

/// Provider widget for Remote Config that rebuilds when config updates
class RemoteConfigProvider extends InheritedWidget {
  final RemoteConfigService configService;

  const RemoteConfigProvider({
    super.key,
    required this.configService,
    required super.child,
  });

  static RemoteConfigService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<RemoteConfigProvider>();
    assert(provider != null, 'RemoteConfigProvider not found in widget tree');
    return provider!.configService;
  }

  static RemoteConfigService? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<RemoteConfigProvider>();
    return provider?.configService;
  }

  @override
  bool updateShouldNotify(RemoteConfigProvider oldWidget) {
    return configService != oldWidget.configService;
  }
}

/// Stateful wrapper that listens to config updates and rebuilds
class RemoteConfigBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, RemoteConfigService config)
  builder;

  const RemoteConfigBuilder({super.key, required this.builder});

  @override
  State<RemoteConfigBuilder> createState() => _RemoteConfigBuilderState();
}

class _RemoteConfigBuilderState extends State<RemoteConfigBuilder> {
  late final RemoteConfigService _configService;

  @override
  void initState() {
    super.initState();
    _configService = RemoteConfigService();
    _configService.onConfigUpdate.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _configService);
  }
}
