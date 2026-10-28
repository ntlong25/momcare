import 'package:flutter/widgets.dart';

import '../services/database_service.dart';

/// Rebuilds [builder] whenever one of the named Hive boxes changes.
///
/// The main navigation keeps every tab alive in an `IndexedStack`, so screens
/// that read Hive directly must listen for changes made from other tabs.
/// Boxes that are not open (e.g. in isolated widget tests) are ignored.
class HiveBoxesListener extends StatefulWidget {
  final List<String> boxNames;
  final WidgetBuilder builder;

  const HiveBoxesListener({
    super.key,
    required this.boxNames,
    required this.builder,
  });

  @override
  State<HiveBoxesListener> createState() => _HiveBoxesListenerState();
}

class _HiveBoxesListenerState extends State<HiveBoxesListener> {
  Listenable? _listenable;

  @override
  void initState() {
    super.initState();
    _listenable = DatabaseService.listenableFor(widget.boxNames);
  }

  @override
  void didUpdateWidget(covariant HiveBoxesListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boxNames.join('|') != widget.boxNames.join('|')) {
      _listenable = DatabaseService.listenableFor(widget.boxNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listenable = _listenable;
    if (listenable == null) return widget.builder(context);
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => widget.builder(context),
    );
  }
}

/// Calls `setState` whenever one of [watchedBoxes] changes, so a stateful
/// screen kept alive in the navigation `IndexedStack` stays up to date.
mixin HiveRefreshMixin<T extends StatefulWidget> on State<T> {
  Listenable? _hiveListenable;

  List<String> get watchedBoxes;

  @override
  void initState() {
    super.initState();
    _hiveListenable = DatabaseService.listenableFor(watchedBoxes);
    _hiveListenable?.addListener(_onHiveChanged);
  }

  void _onHiveChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hiveListenable?.removeListener(_onHiveChanged);
    super.dispose();
  }
}
