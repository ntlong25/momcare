import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/bump_photo_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/share_helper.dart';
import '../bump_camera_source.dart';
import '../bump_photo_share.dart';
import 'bump_journal_screen.dart';

enum _Phase { starting, ready, capturing, review, failed }

/// Quick capture for "Nhật ký ảnh bụng bầu": a live preview, the shutter, a
/// review of the photo, then "Lưu vào tuần X", "Chia sẻ" or "Chụp lại". Saving
/// returns to the page that opened the camera; "Chia sẻ" saves first and
/// returns after the share sheet, so the photo is kept whatever happens to
/// the sharing. The photo is taken in this process,
/// so Android has no other activity to kill the app behind.
class BumpCameraScreen extends ConsumerStatefulWidget {
  /// Week the photo is saved to.
  final int week;

  /// The journal is the page below: the grid button pops back to it.
  final bool fromJournal;

  const BumpCameraScreen({
    super.key,
    required this.week,
    this.fromJournal = false,
  });

  /// Number of these screens alive, so the home-screen widget does not open
  /// a second one over a photo under review.
  static int openCount = 0;

  /// Replaces the camera in tests.
  @visibleForTesting
  static BumpCameraSource Function()? debugSource;

  /// Replaces opening the system settings in tests.
  @visibleForTesting
  static Future<bool> Function()? debugOpenSettings;

  static const String permissionTitle = 'MomCare+ chưa được dùng camera';
  static const String permissionMessage =
      'Hãy bật quyền Camera trong Cài đặt của máy để chụp ảnh bụng bầu. '
      'Ảnh chỉ lưu trên thiết bị này.';
  static const String noCameraMessage =
      'Không tìm thấy camera trên thiết bị này. Bạn vẫn có thể chọn ảnh từ '
      'thư viện trong nhật ký ảnh.';
  static const String startErrorMessage =
      'Không mở được camera. Vui lòng thử lại.';
  static const String captureErrorMessage =
      'Không chụp được ảnh. Vui lòng thử lại.';
  static const String saveErrorMessage =
      'Không lưu được ảnh. Vui lòng thử lại.';

  /// The photo is saved and the review is gone: the retry is in the journal.
  static String shareErrorMessage(int week) =>
      'Đã lưu ảnh vào tuần $week nhưng chưa chia sẻ được. '
      'Bạn có thể chia sẻ lại từ nhật ký ảnh.';

  @override
  ConsumerState<BumpCameraScreen> createState() => _BumpCameraScreenState();
}

class _BumpCameraScreenState extends ConsumerState<BumpCameraScreen>
    with WidgetsBindingObserver {
  late final BumpCameraSource _camera;

  _Phase _phase = _Phase.starting;
  BumpCameraFailure? _failure;
  BumpLens _lens = BumpLens.back;
  List<BumpLens> _lenses = const [];
  bool _flash = false;

  /// The camera's own file, shown during the review.
  XFile? _photo;

  /// Whether [_photo] is flipped to match the preview.
  bool _mirrored = false;

  /// The file to save, finished in the background during the review.
  Future<XFile>? _finished;

  /// The preview as it was when the shutter was pressed.
  ui.Image? _frozenFrame;
  final GlobalKey _previewKey = GlobalKey();
  bool _saving = false;

  /// The save in progress came from "Chia sẻ".
  bool _sharing = false;
  bool _inBackground = false;

  /// Bumped by every start and stop, so work that finishes after the camera
  /// moved on is ignored.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    BumpCameraScreen.openCount++;
    _camera = BumpCameraScreen.debugSource?.call() ?? PluginBumpCameraSource();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    unawaited(ShareHelper.clearCameraTempFiles());
    unawaited(_loadLensAndStart());
  }

  @override
  void dispose() {
    BumpCameraScreen.openCount--;
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const []);
    _run++;
    unawaited(_camera.close());
    unawaited(_discardPhoto());
    _frozenFrame?.dispose();
    super.dispose();
  }

  Future<void> _loadLensAndStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.bumpCameraLensKey);
      if (saved == BumpLens.front.name) _lens = BumpLens.front;
    } catch (error) {
      AppLogger.instance.warning('Could not read the camera lens: $error');
    }
    if (mounted) await _start();
  }

  Future<void> _saveLens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.bumpCameraLensKey, _lens.name);
    } catch (error) {
      AppLogger.instance.warning('Could not save the camera lens: $error');
    }
  }

  Future<void> _start() async {
    final run = ++_run;
    setState(() {
      _phase = _Phase.starting;
      _failure = null;
      _clearFrozenFrame();
    });
    bool stale() => !mounted || run != _run;
    try {
      final lenses = await _camera.lenses();
      if (stale()) return;
      if (lenses.isEmpty) {
        throw const BumpCameraException(BumpCameraFailure.noCamera);
      }
      _lenses = lenses;
      if (!lenses.contains(_lens)) _lens = lenses.first;
      await _camera.open(_lens);
      if (stale()) return;
      await _applyFlash();
      if (stale()) return;
      setState(() => _phase = _Phase.ready);
    } on BumpCameraException catch (error) {
      if (!stale()) _fail(error.failure);
    } catch (error) {
      AppLogger.instance.warning('Could not start the camera: $error');
      if (!stale()) _fail(BumpCameraFailure.error);
    }
  }

  void _fail(BumpCameraFailure failure) => setState(() {
    _phase = _Phase.failed;
    _failure = failure;
  });

  /// Stops the preview before the camera behind it goes away.
  void _stop() {
    _run++;
    setState(() {
      if (_phase != _Phase.review) _phase = _Phase.starting;
      _clearFrozenFrame();
    });
    unawaited(_camera.close());
  }

  /// The plugin's default is auto flash, so the choice is always applied.
  Future<void> _applyFlash() async {
    try {
      await _camera.setFlash(_flash && _lens == BumpLens.back);
    } catch (error) {
      AppLogger.instance.warning('Could not set the flash: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_inBackground) return;
        _inBackground = true;
        // `inactive` is not enough: the permission dialog causes it, and the
        // camera must keep starting behind that dialog.
        if (_phase != _Phase.review) _stop();
      case AppLifecycleState.resumed:
        if (!_inBackground) return;
        _inBackground = false;
        if (_phase != _Phase.review) unawaited(_start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _toggleFlash() {
    setState(() => _flash = !_flash);
    unawaited(_applyFlash());
  }

  void _switchLens() {
    if (_phase != _Phase.ready || _lenses.length < 2) return;
    _lens = _lens == BumpLens.back ? BumpLens.front : BumpLens.back;
    unawaited(_saveLens());
    _stop();
    unawaited(_start());
  }

  /// Stops the picture on screen. Called after the frame with the shutter
  /// flash: the grab reads pixels on the raster thread, and queued first it
  /// would hold that frame back.
  Future<void> _freezeFrame(int run) async {
    bool stale() => !mounted || run != _run || _phase != _Phase.capturing;
    if (stale()) return;
    final boundary = _previewKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    try {
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      if (!stale()) {
        setState(() => _frozenFrame = image);
      } else {
        image.dispose();
      }
    } catch (error) {
      AppLogger.instance.warning('Could not freeze the preview: $error');
    }
  }

  void _clearFrozenFrame() {
    _frozenFrame?.dispose();
    _frozenFrame = null;
  }

  Future<void> _capture() async {
    // Set before the first await: a second tap finds the phase changed.
    if (_phase != _Phase.ready) return;
    final run = _run;
    final mirrored = bumpPhotoMirrored(_lens, defaultTargetPlatform);
    unawaited(HapticFeedback.lightImpact());
    setState(() => _phase = _Phase.capturing);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_freezeFrame(run)),
    );
    try {
      final photo = await _camera.capture();
      if (!mounted || run != _run) {
        await ShareHelper.deletePickerTempFile(photo.path);
        return;
      }
      _photo = photo;
      _mirrored = mirrored;
      _finished = _camera.finish(photo, mirror: mirrored);
      setState(() {
        _phase = _Phase.review;
        _clearFrozenFrame();
      });
      _run++;
      // No live camera while the photo is reviewed.
      unawaited(_camera.close());
    } catch (error) {
      AppLogger.instance.warning('Could not take a bump photo: $error');
      // The plugin creates its file first and leaves it behind empty. No other
      // photo exists during a capture.
      await ShareHelper.clearCameraTempFiles();
      if (!mounted || run != _run) return;
      setState(() {
        _phase = _Phase.ready;
        _clearFrozenFrame();
      });
      _showSnack(BumpCameraScreen.captureErrorMessage);
    }
  }

  Future<void> _discardPhoto() async {
    final photo = _photo;
    final finished = _finished;
    _photo = null;
    _finished = null;
    if (photo == null) return;
    await ShareHelper.deletePickerTempFile(photo.path);
    if (finished == null) return;
    // The crop may still be running; the camera does not wait for it.
    final done = await finished;
    if (done.path != photo.path) {
      await ShareHelper.deletePickerTempFile(done.path);
    }
  }

  Future<void> _retake() async {
    if (_saving) return;
    unawaited(_discardPhoto());
    if (mounted) await _start();
  }

  Future<void> _save({bool share = false, Rect? origin}) async {
    final photo = _photo;
    final finished = _finished;
    if (photo == null || finished == null || _saving) return;
    setState(() {
      _saving = true;
      _sharing = share;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final week = widget.week;
    var added = 0;
    XFile? saved;
    try {
      saved = await finished;
      added = await ref.read(bumpPhotoProvider.notifier).addFiles(week, [
        saved,
      ]);
    } catch (error) {
      AppLogger.instance.warning('Could not save a bump photo: $error');
    }
    if (!mounted) return;
    if (added == 0) {
      setState(() {
        _saving = false;
        _sharing = false;
      });
      _showSnack(BumpCameraScreen.saveErrorMessage);
      return;
    }
    // Saved: nothing below may save again. The review stays on screen behind
    // the choice sheet, so _photo stays until the sharing is over.
    _finished = null;
    final shared = !share || await _offerShare(origin);
    if (!mounted) return;
    // addFiles removed the saved copy; only the camera's own file is left.
    _photo = null;
    if (saved?.path != photo.path) {
      unawaited(ShareHelper.deletePickerTempFile(photo.path));
    }
    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          shared
              ? 'Đã lưu ảnh vào tuần $week'
              : BumpCameraScreen.shareErrorMessage(week),
        ),
      ),
    );
  }

  /// False when sharing failed; dismissing the choice is not a failure.
  Future<bool> _offerShare(Rect? origin) async {
    final notifier = ref.read(bumpPhotoProvider.notifier);
    try {
      final photo = notifier.lastAdded.single;
      final file =
          notifier.fileFor(photo) ?? await BumpPhotoService.fileFor(photo);
      if (!mounted) return true;
      await BumpPhotoShare.offer(
        context,
        photo: photo,
        file: file,
        origin: origin,
      );
      return true;
    } catch (error) {
      AppLogger.instance.warning('Could not share a bump photo: $error');
      return false;
    }
  }

  void _openJournal() {
    final navigator = Navigator.of(context);
    if (widget.fromJournal) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => BumpJournalScreen(initialWeek: widget.week),
      ),
    );
  }

  Future<void> _openSettings() async {
    final open = BumpCameraScreen.debugOpenSettings ?? openAppSettings;
    await open();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final reviewing = _phase == _Phase.review;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // Back from the review is "Chụp lại", the photo is not saved.
        canPop: !reviewing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_retake());
        },
        child: Scaffold(
          backgroundColor: AppCameraColors.background,
          body: SafeArea(child: reviewing ? _buildReview() : _buildCamera()),
        ),
      ),
    );
  }

  Widget _buildCamera() {
    final failure = _failure;
    return Column(
      children: [
        _TopBar(
          onClose: () => Navigator.of(context).maybePop(),
          onJournal: _openJournal,
        ),
        if (_phase == _Phase.failed && failure != null)
          Expanded(
            child: _FailureView(
              failure: failure,
              onOpenSettings: _openSettings,
              onRetry: _start,
              onJournal: _openJournal,
            ),
          )
        else ...[
          Expanded(
            child: _Frame(
              child: _phase == _Phase.starting
                  ? const _Starting()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          key: _previewKey,
                          child: _LivePreview(
                            key: ValueKey(_lens),
                            aspectRatio: _camera.previewAspectRatio,
                            preview: _camera.buildPreview(),
                          ),
                        ),
                        if (_frozenFrame case final frame?)
                          RawImage(
                            key: const ValueKey('bump-camera-frozen'),
                            image: frame,
                            fit: BoxFit.cover,
                          ),
                        if (_phase == _Phase.capturing)
                          const _ShutterFeedback(),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Controls(
            canShoot: _phase == _Phase.ready,
            flash: _flash,
            onFlash: _phase == _Phase.ready && _lens == BumpLens.back
                ? _toggleFlash
                : null,
            onSwitch: _phase == _Phase.ready && _lenses.length > 1
                ? _switchLens
                : null,
            onShutter: _capture,
          ),
          const SizedBox(height: AppSpacing.md),
          _WeekPill(week: widget.week),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildReview() {
    final photo = _photo;
    final secondary = OutlinedButton.styleFrom(
      foregroundColor: AppCameraColors.foreground,
      disabledForegroundColor: AppCameraColors.foregroundDisabled,
      side: const BorderSide(color: AppCameraColors.foregroundSoft),
    );
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: _Frame(
            child: photo == null
                ? const _Starting()
                // The camera's own file, shown as it will be saved: the frame
                // crops it like the finished photo.
                : Transform.flip(
                    key: const ValueKey('bump-camera-review-flip'),
                    flipX: _mirrored,
                    child: Image.file(
                      File(photo.path),
                      key: const ValueKey('bump-camera-review-photo'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const BumpPhotoPlaceholder(),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const ValueKey('bump-camera-save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppCameraColors.accent,
                  foregroundColor: AppCameraColors.onAccent,
                  disabledBackgroundColor: AppCameraColors.surface,
                  disabledForegroundColor: AppCameraColors.foregroundDisabled,
                ),
                onPressed: _saving ? null : _save,
                icon: _saving && !_sharing
                    ? const _ButtonSpinner()
                    : const Icon(Icons.check),
                label: Text(
                  'Lưu vào tuần ${widget.week}',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Same height at any text scale, one line each.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('bump-camera-retake'),
                        style: secondary,
                        onPressed: _saving ? null : _retake,
                        icon: const Icon(Icons.replay),
                        label: const _OneLine('Chụp lại'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Builder(
                        builder: (button) => OutlinedButton.icon(
                          key: const ValueKey('bump-camera-share'),
                          style: secondary,
                          onPressed: _saving
                              ? null
                              : () => _save(
                                  share: true,
                                  origin: ShareHelper.originOf(button),
                                ),
                          icon: _sharing
                              ? const _ButtonSpinner()
                              : const Icon(Icons.ios_share),
                          label: const _OneLine('Chia sẻ'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// A button label that shrinks rather than wraps.
class _OneLine extends StatelessWidget {
  final String text;

  const _OneLine(this.text);

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: AppCameraColors.foregroundDisabled,
    ),
  );
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onJournal;

  const _TopBar({required this.onClose, required this.onJournal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const ValueKey('bump-camera-close'),
            tooltip: 'Đóng',
            color: AppCameraColors.foreground,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
          IconButton(
            key: const ValueKey('bump-camera-journal'),
            tooltip: 'Nhật ký ảnh',
            color: AppCameraColors.foreground,
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: onJournal,
          ),
        ],
      ),
    );
  }
}

/// The large rounded square, centred in the space it is given.
class _Frame extends StatelessWidget {
  final Widget child;

  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: AspectRatio(
          key: const ValueKey('bump-camera-frame'),
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: ColoredBox(
              color: AppCameraColors.surface,
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppCameraColors.foreground),
  );
}

/// A quick white flash when the shutter is pressed, then a spinner that only
/// fades in when the camera is slow.
class _ShutterFeedback extends StatelessWidget {
  static const Duration _flash = Duration(milliseconds: 180);
  static const Duration _spinnerDelay = Duration(milliseconds: 900);

  const _ShutterFeedback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 0),
          duration: _flash,
          builder: (_, opacity, _) => IgnorePointer(
            child: ColoredBox(
              color: AppCameraColors.foreground.withValues(alpha: opacity),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _spinnerDelay,
          curve: const Interval(0.7, 1),
          builder: (_, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: const _Starting(),
        ),
      ],
    );
  }
}

/// Fills the frame from the middle of the picture, without stretching it.
class _LivePreview extends StatelessWidget {
  /// Layout size only; the [FittedBox] scales it to the frame.
  static const double _baseHeight = 1000;

  final double aspectRatio;
  final Widget preview;

  const _LivePreview({
    super.key,
    required this.aspectRatio,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      key: const ValueKey('bump-camera-preview'),
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _baseHeight * aspectRatio,
        height: _baseHeight,
        child: preview,
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool canShoot;
  final bool flash;
  final VoidCallback? onFlash;
  final VoidCallback? onSwitch;
  final VoidCallback onShutter;

  const _Controls({
    required this.canShoot,
    required this.flash,
    required this.onFlash,
    required this.onSwitch,
    required this.onShutter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          key: const ValueKey('bump-camera-flash'),
          tooltip: flash ? 'Tắt đèn flash' : 'Bật đèn flash',
          icon: flash ? Icons.flash_on : Icons.flash_off,
          onPressed: onFlash,
        ),
        _Shutter(onPressed: canShoot ? onShutter : null),
        _RoundButton(
          key: const ValueKey('bump-camera-switch'),
          tooltip: 'Đổi camera trước/sau',
          icon: Icons.cameraswitch_outlined,
          onPressed: onSwitch,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  static const double _size = 52;

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: _size, height: _size),
      style: IconButton.styleFrom(
        backgroundColor: AppCameraColors.surface,
        foregroundColor: AppCameraColors.foreground,
        disabledBackgroundColor: AppCameraColors.surface,
        disabledForegroundColor: AppCameraColors.foregroundDisabled,
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

class _Shutter extends StatelessWidget {
  static const double _size = 84;
  static const double _ring = 4;
  static const double _gap = 5;

  final VoidCallback? onPressed;

  const _Shutter({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Chụp ảnh',
      child: ExcludeSemantics(
        child: Container(
          width: _size,
          height: _size,
          padding: const EdgeInsets.all(_ring + _gap),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? AppCameraColors.foreground
                  : AppCameraColors.foregroundDisabled,
              width: _ring,
            ),
          ),
          child: Material(
            color: enabled ? AppCameraColors.accent : AppCameraColors.surface,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('bump-camera-shutter'),
              onTap: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekPill extends StatelessWidget {
  final int week;

  const _WeekPill({required this.week});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCameraColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'Tuần $week',
          key: const ValueKey('bump-camera-week'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppCameraColors.foreground),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final BumpCameraFailure failure;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;
  final VoidCallback onJournal;

  const _FailureView({
    required this.failure,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onJournal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: AppCameraColors.accent,
      foregroundColor: AppCameraColors.onAccent,
    );
    final (icon, title, message, action) = switch (failure) {
      BumpCameraFailure.permissionDenied => (
        Icons.no_photography_outlined,
        BumpCameraScreen.permissionTitle,
        BumpCameraScreen.permissionMessage,
        FilledButton(
          key: const ValueKey('bump-camera-open-settings'),
          style: style,
          onPressed: onOpenSettings,
          child: const Text('Mở Cài đặt', textAlign: TextAlign.center),
        ),
      ),
      BumpCameraFailure.noCamera => (
        Icons.no_photography_outlined,
        null,
        BumpCameraScreen.noCameraMessage,
        FilledButton(
          key: const ValueKey('bump-camera-failure-journal'),
          style: style,
          onPressed: onJournal,
          child: const Text('Mở nhật ký ảnh', textAlign: TextAlign.center),
        ),
      ),
      BumpCameraFailure.error => (
        Icons.error_outline,
        null,
        BumpCameraScreen.startErrorMessage,
        FilledButton(
          key: const ValueKey('bump-camera-retry'),
          style: style,
          onPressed: onRetry,
          child: const Text('Thử lại', textAlign: TextAlign.center),
        ),
      ),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppCameraColors.foregroundSoft),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppCameraColors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              key: const ValueKey('bump-camera-failure'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppCameraColors.foregroundSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            action,
          ],
        ),
      ),
    );
  }
}
