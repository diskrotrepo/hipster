part of '../main.dart';

class _AudioControls extends StatefulWidget {
  const _AudioControls({required this.url});
  final String url;

  @override
  State<_AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends State<_AudioControls> {
  late final AudioPlayer _player;
  bool _loop = false;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double? _dragValueMs;

  bool get _isPlaying => _state == PlayerState.playing;
  bool get _isPaused => _state == PlayerState.paused;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer()..setSourceUrl(widget.url);

    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void didUpdateWidget(covariant _AudioControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _player.stop();
      _loadUrl(widget.url);
      _state = PlayerState.stopped;
      setState(() {});
    }
  }

  void _loadUrl(String url) {
    if (url.isEmpty) return;
    _player.setSourceUrl(url);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int durationMs = _duration.inMilliseconds;
    final int positionMs = (_dragValueMs?.round() ?? _position.inMilliseconds);
    final double progress =
        durationMs > 0 ? (positionMs.clamp(0, durationMs) / durationMs) : 0.0;

    final displayPosition = Duration(
        milliseconds: (progress * (durationMs > 0 ? durationMs : 0)).round());

    const Color darkPink = Color(0xFFC2185B);
    const Color scrubberColor = Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              _formatDurationCompact(displayPosition),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScrubberBar(
                progress: progress,
                enabled: durationMs > 0,
                trackColor: darkPink,
                scrubberColor: scrubberColor,
                onUpdateRelative: (rel) {
                  final ms = (rel.clamp(0.0, 1.0) * durationMs);
                  setState(() => _dragValueMs = ms);
                },
                onSeekRelative: (rel) async {
                  final ms = (rel.clamp(0.0, 1.0) * durationMs).round();
                  await _player.seek(Duration(milliseconds: ms));
                  setState(() => _dragValueMs = null);
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDurationCompact(_duration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.fast_rewind, color: Colors.white),
              tooltip: 'Rewind',
              onPressed: () async {
                await _player.seek(Duration.zero);
                setState(() {
                  _position = Duration.zero;
                  _dragValueMs = null;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              tooltip: _isPlaying ? 'Pause' : 'Play',
              onPressed: () async {
                if (_isPlaying) {
                  await _player.pause();
                } else if (_isPaused) {
                  await _player.resume();
                } else {
                  await _player.play(UrlSource(widget.url));
                }
              },
            ),
            IconButton(
              icon: Icon(
                _loop ? Icons.repeat_one : Icons.repeat,
                color: Colors.white,
              ),
              tooltip: 'Loop',
              onPressed: () {
                _loop = !_loop;
                _player.setReleaseMode(
                  _loop ? ReleaseMode.loop : ReleaseMode.release,
                );
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Download',
              onPressed: () => _downloadFile(widget.url),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDurationCompact(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load file');
      }

      final jsBytes = response.bodyBytes.toJS;
      final blobParts = [jsBytes].toJS;
      final blob = web.Blob(blobParts);
      final objectUrl = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = objectUrl
        ..download = url.split('/').last
        ..style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);

      web.URL.revokeObjectURL(objectUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ScrubberBar extends StatelessWidget {
  const _ScrubberBar({
    required this.progress,
    required this.enabled,
    required this.trackColor,
    required this.scrubberColor,
    required this.onUpdateRelative,
    required this.onSeekRelative,
  });

  final double progress;
  final bool enabled;
  final Color trackColor;
  final Color scrubberColor;
  final ValueChanged<double> onUpdateRelative;
  final ValueChanged<double> onSeekRelative;

  @override
  Widget build(BuildContext context) {
    const double height = 24;
    const double trackHeight = 4;
    const double scrubberWidth = 16;
    const double scrubberHeight = 16;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double x = (progress.clamp(0.0, 1.0) * w).clamp(0.0, w);

          void updateFromDx(double dx) {
            if (!enabled || w <= 0) return;
            final rel = (dx / w).clamp(0.0, 1.0);
            onUpdateRelative(rel);
          }

          Future<void> commitFromDx(double dx) async {
            if (!enabled || w <= 0) return;
            final rel = (dx / w).clamp(0.0, 1.0);
            onSeekRelative(rel);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) async {
              if (!enabled) return;
              await commitFromDx(d.localPosition.dx);
            },
            onHorizontalDragStart: (d) {
              if (!enabled) return;
              updateFromDx(d.localPosition.dx);
            },
            onHorizontalDragUpdate: (d) {
              if (!enabled) return;
              updateFromDx(d.localPosition.dx);
            },
            // ✅ Commit on the SAME gesture family; do not use onPanEnd.
            onHorizontalDragEnd: (_) {
              if (!enabled || w <= 0) return;
              onSeekRelative((x / w).clamp(0.0, 1.0));
            },
            onHorizontalDragCancel: () {
              if (!enabled || w <= 0) return;
              onSeekRelative((x / w).clamp(0.0, 1.0));
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: trackHeight,
                      color: trackColor,
                    ),
                  ),
                ),
                Positioned(
                  left: (x - scrubberWidth / 2).clamp(0.0, w - scrubberWidth),
                  top: (height - scrubberHeight) / 2,
                  child: Container(
                    width: scrubberWidth,
                    height: scrubberHeight,
                    color: scrubberColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
