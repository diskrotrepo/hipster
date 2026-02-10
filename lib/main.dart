// main.dart
import 'dart:js_interop';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hipster/dependency_context.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hipster/hipster/models/song.dart';
import 'package:hipster/hipster/suno_service.dart';
import 'package:hipster/utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

part 'hipster/song_meta_text.dart';
part 'hipster/audio_player.dart';
part 'hipster/clip_selector.dart';
part 'hipster/rainbow_load_bar.dart';
part 'hipster/lyric_formatting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dependencySetup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hipster by diskrot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const ThreeTierLayoutPage(),
    );
  }
}

class ThreeTierLayoutPage extends StatefulWidget {
  const ThreeTierLayoutPage({super.key});

  @override
  State<ThreeTierLayoutPage> createState() => _ThreeTierLayoutPageState();
}

class _ThreeTierLayoutPageState extends State<ThreeTierLayoutPage>
    with TickerProviderStateMixin {
  bool _showAnalyzer = false; // splash first
  String? _songID;
  late List<Song> _songList = <Song>[];
  int _current = 0;
  bool _loading = false;
  final TextEditingController _songIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBearerToken();
  }

  Future<void> _loadBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('bearer_token');
    if (token != null && token.isNotEmpty) {
      di.get<SunoService>().bearerToken = token;
    }
  }

  Future<void> _showSettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('bearer_token') ?? '';
    final controller = TextEditingController(text: current);

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Bearer Token',
              hintText: 'Paste your Suno bearer token',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            minLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;

    await prefs.setString('bearer_token', result);
    di.get<SunoService>().bearerToken = result.isEmpty ? null : result;
  }

  late final AnimationController _rainbow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            if (_loading)
              _loadingBody()
            else if (_showAnalyzer)
              _analyzerBody()
            else
              _splashBody(),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody() => Expanded(
        child: Container(
          width: double.infinity,
          color: Colors.black,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Analyzing Data…',
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 8,
                width: 300,
                child: AnimatedBuilder(
                  animation: _rainbow,
                  builder: (_, __) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _rainbow.value,
                      child: _RainbowStrip(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _submit() async {
    if ((_songID ?? '').isEmpty) return;

    final uuid = extractUuid(_songID!);
    if (uuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a valid Suno song URL or ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final list = await di.get<SunoService>().fetchSongTree(uuid);

      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No song data found for that ID'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() {
        _songList = list;
        _current = list.length - 1;
        _loading = false;
        _showAnalyzer = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _songIdController,
                onChanged: (v) => _songID = v.trim(),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Song ID (Suno URL)',
                  prefixIcon:
                      const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: const Text('Analyze'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: IconButton(
                onPressed: _showSettingsDialog,
                icon: const Icon(Icons.lock),
                tooltip: 'Bearer Token',
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final uri = Uri.parse('https://www.diskrot.com');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.asset('assets/diskrot_logo.png', fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _splashBody() => Expanded(
        child: Container(
          width: double.infinity,
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text(
            'Hipster: Meta Data Analysis',
            style: TextStyle(
              fontSize: 42,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

  @override
  void dispose() {
    _rainbow.dispose();
    _songIdController.dispose();
    super.dispose();
  }

  Widget _analyzerBody() {
    final song = _songList[_current];

    return Expanded(
      child: Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _metaRow(
                          imageUrl: song.image,
                          meta: _SongMetaText(
                            title: song.title,
                            artists: song.artistName.isEmpty
                                ? ['unknown']
                                : song.artistName.split(','),
                            playCount: song.playCount,
                            likes: song.upvoteCount,
                            commercialUse: song.commercialUse,
                            creationTime: song.created,
                            totalSegments: _songList.length,
                            onSquareSelect: (i) => setState(() => _current = i),
                            selectedIndex: _current,
                          ),
                        ),
                        _clipRow(
                          song: song,
                          meta: _SegmentMetaText(
                            song: song,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: BracketColorText(
                          text: song.prompt.isEmpty ? 'no lyrics' : song.prompt,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 70,
                width: double.infinity,
                color: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _AudioControls(url: song.audioUrl),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _metaRow({required String imageUrl, required Widget meta}) => Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                child: SizedBox.expand(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: meta,
              ),
            ),
          ],
        ),
      );

  Widget _clipRow({required Song song, required Widget meta}) => Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CopyableField(
                        title: 'Positive Prompt',
                        text: song.tags,
                      ),
                      const SizedBox(height: 12),
                      _CopyableField(
                        title: 'Negative Tags',
                        text: song.negativeTags,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: meta,
              ),
            ),
          ],
        ),
      );
}

class _CopyableField extends StatelessWidget {
  final String title;
  final String text;
  const _CopyableField({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                final value = text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nothing to copy')),
                  );
                  return;
                }

                await Clipboard.setData(ClipboardData(text: value));

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title copied')),
                );
              },
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: SelectableText(
            text.isEmpty ? '—' : text,
            style:
                const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}
