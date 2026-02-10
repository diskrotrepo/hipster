part of '../main.dart';

class _SongMetaText extends StatelessWidget {
  const _SongMetaText({
    required this.title,
    required this.artists,
    required this.playCount,
    required this.likes,
    required this.creationTime,
    required this.totalSegments,
    required this.onSquareSelect,
    required this.selectedIndex,
    required this.commercialUse,
  });

  final String title;
  final List<String> artists;
  final int playCount, likes, totalSegments;
  final String creationTime;
  final int selectedIndex;
  final bool commercialUse;
  final void Function(int) onSquareSelect;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: Colors.white, height: 1.2);
    const label = TextStyle(
      color: Colors.white,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: 'Title: ', style: label),
              TextSpan(text: '$title\n'),
              const TextSpan(text: 'Artists: ', style: label),
              TextSpan(text: '${artists.join(', ')}\n\n'),
              const TextSpan(text: 'Commercial Rights: ', style: label),
              TextSpan(text: '${commercialUse ? 'Yes' : 'No'}\n\n'),
              const TextSpan(text: 'Play Count: ', style: label),
              TextSpan(text: '$playCount   '),
              const TextSpan(text: 'Likes: ', style: label),
              TextSpan(text: '$likes\n'),
              const TextSpan(text: 'Creation Time: ', style: label),
              TextSpan(text: '$creationTime\n'),
              const TextSpan(text: 'Total Segments: ', style: label),
              TextSpan(text: '$totalSegments\n\n'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RainbowSquares(
          count: totalSegments,
          onSelect: onSquareSelect,
          selectedIndex: selectedIndex,
        ),
      ],
    );
  }
}

class _SegmentMetaText extends StatefulWidget {
  const _SegmentMetaText({required this.song});

  final Song song;

  @override
  State<_SegmentMetaText> createState() => _SegmentMetaTextState();
}

class _SegmentMetaTextState extends State<_SegmentMetaText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _createRecognizer(Uri uri) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () async {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    _recognizers.clear();
    final song = widget.song;

    const base = TextStyle(color: Colors.white, height: 1.2);
    const label = TextStyle(
      color: Colors.white,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );
    const linkStyle = TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Title: ', style: label),
          TextSpan(text: '${song.title}\n'),
          const TextSpan(text: 'Artist: ', style: label),
          TextSpan(text: '${song.artistName}\n'),
          const TextSpan(text: 'Type: ', style: label),
          TextSpan(text: '${song.type}\n'),
          const TextSpan(text: 'Model: ', style: label),
          TextSpan(text: '${song.model} (${song.majorModelVersion})\n'),
          const TextSpan(text: 'Cover: ', style: label),
          if (song.coverClipId != null)
            TextSpan(
              text: 'View Cover\n',
              style: linkStyle,
              mouseCursor: SystemMouseCursors.click,
              recognizer: _createRecognizer(
                Uri.parse('https://www.suno.com/song/${song.coverClipId}'),
              ),
            )
          else
            const TextSpan(text: 'N/A\n'),
          const TextSpan(text: 'Persona: ', style: label),
          if (song.personaClipId != null)
            TextSpan(
              text: 'View Persona\n',
              style: linkStyle,
              mouseCursor: SystemMouseCursors.click,
              recognizer: _createRecognizer(
                Uri.parse('https://suno.com/persona/${song.personaClipId}'),
              ),
            )
          else
            const TextSpan(text: 'N/A\n'),
          const TextSpan(text: 'Inspiration: ', style: label),
          if (song.playlistId != null)
            if (song.playlistId == 'inspiration')
              const TextSpan(text: 'Drag And Drop Inspo\n')
            else
              TextSpan(
                text: 'View Playlist\n',
                style: linkStyle,
                mouseCursor: SystemMouseCursors.click,
                recognizer: _createRecognizer(
                  Uri.parse('https://www.suno.com/playlist/${song.playlistId}'),
                ),
              )
          else
            const TextSpan(text: 'N/A\n'),
          const TextSpan(text: 'Suno: ', style: label),
          if (song.audioUrl.isNotEmpty)
            TextSpan(
              text: 'View Song\n',
              style: linkStyle,
              mouseCursor: SystemMouseCursors.click,
              recognizer: _createRecognizer(
                Uri.parse('https://www.suno.com/song/${song.id}'),
              ),
            )
          else
            const TextSpan(text: 'Unavailable\n'),
          const TextSpan(text: 'Status: ', style: label),
          TextSpan(text: '${song.status}\n'),
          const TextSpan(text: 'Play Count: ', style: label),
          TextSpan(text: '${song.playCount}\n'),
          const TextSpan(text: 'Is Public: ', style: label),
          TextSpan(text: song.isPublic ? 'Yes\n' : 'No\n'),
          const TextSpan(text: 'Can Remix: ', style: label),
          TextSpan(text: song.canRemix ? 'Yes\n' : 'No\n'),
          const TextSpan(text: 'In Trash?: ', style: label),
          TextSpan(text: song.inTrash ? 'Yes\n' : 'No\n'),
          const TextSpan(text: 'Has Vocals?: ', style: label),
          TextSpan(text: song.hasVocal ? 'Yes\n' : 'No\n'),
          const TextSpan(text: 'Flag Count: ', style: label),
          TextSpan(text: '${song.flagCount}\n'),
          const TextSpan(text: 'Weirdness: ', style: label),
          TextSpan(text: '${song.weirdness}%\n'),
          const TextSpan(text: 'Style Influence: ', style: label),
          TextSpan(text: '${song.style}%\n'),
          const TextSpan(text: 'Audio Influence: ', style: label),
          TextSpan(text: '${song.audioInfluence}%\n'),
          const TextSpan(text: 'Creation Time: ', style: label),
          TextSpan(text: song.created),
        ],
      ),
    );
  }
}
