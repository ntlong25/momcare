import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/disclaimer_consent_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import 'medical_disclaimer_screen.dart';

/// Shows [child] only once the current disclaimer version is accepted.
/// Everything is built in place, so nothing sits under the consent screen
/// for the back key to reach.
class DisclaimerGate extends ConsumerWidget {
  final Widget child;

  const DisclaimerGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(disclaimerConsentProvider)) {
      null => const Scaffold(body: Center(child: BrandMark())),
      false => const DisclaimerConsentScreen(),
      true => child,
    };
  }
}

/// Mandatory acceptance of the medical disclaimer. "Đồng ý" appears once the
/// end of the text is on screen, re-checked whenever the layout changes.
class DisclaimerConsentScreen extends ConsumerStatefulWidget {
  const DisclaimerConsentScreen({super.key});

  @override
  ConsumerState<DisclaimerConsentScreen> createState() =>
      _DisclaimerConsentScreenState();
}

class _DisclaimerConsentScreenState
    extends ConsumerState<DisclaimerConsentScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkReachedEnd);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Screen size or text scale changed: the end may have moved.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReachedEnd());
  }

  void _checkReachedEnd() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final reachedEnd = position.extentAfter <= 1;
    if (reachedEnd != _reachedEnd) setState(() => _reachedEnd = reachedEnd);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Registers the dependencies that drive didChangeDependencies.
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Tuyên bố miễn trừ y tế'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _checkReachedEnd();
                    return false;
                  },
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      key: const ValueKey('disclaimer-consent-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: const MedicalDisclaimerBody(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                // The button keeps its space while hidden: a viewport that
                // shrank when it appeared would move the end of the text.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Visibility(
                      visible: _reachedEnd,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('disclaimer-accept'),
                          onPressed: () => ref
                              .read(disclaimerConsentProvider.notifier)
                              .accept(),
                          child: const Text('Đồng ý'),
                        ),
                      ),
                    ),
                    if (!_reachedEnd)
                      Text(
                        'Cuộn đến cuối để tiếp tục',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
