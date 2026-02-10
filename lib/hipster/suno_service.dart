import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hipster/hipster/mappers/hipster_mapper.dart';
import 'package:hipster/hipster/models/song.dart';
import 'package:hipster/logger/logger.dart';

class SunoService {
  SunoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseAPI = 'studio-api.prod.suno.com';

  String? bearerToken;

  Map<String, String> get _headers =>
      bearerToken != null ? {'Authorization': 'Bearer $bearerToken'} : {};

  Future<List<Song>> fetchSongTree(String songId) async {
    final Set<String> songIds = {};
    final List<String> songStack = [];
    final List<Song> listOfSongs = [];
    final Set<String> coverIds = {};
    final Set<String> upsampleClipIds = {};

    logger.i(message: 'Fetching song list for $songId');

    songStack.add(songId);

    do {
      final songToGrab = songStack.removeLast();

      if (songIds.contains(songToGrab)) {
        continue;
      }

      final results = await _client.get(
        Uri.https(baseAPI, '/api/clip/$songToGrab'),
        headers: _headers,
      );

      logger.i(message: 'Fetching song: /api/clip/$songToGrab');

      // User hard deleted song :-(
      if (results.statusCode != 200) {
        continue;
      }

      if (results.body == '' || results.body.isEmpty) {
        continue;
      }

      late Song sunoSong;

      try {
        sunoSong = responseToSunoSong(
          jsonDecode(results.body) as Map<String, dynamic>,
        );
      } catch (e) {
        logger.e(message: 'Error loading $songToGrab: $e');
        continue;
      }

      listOfSongs.add(sunoSong);
      songIds.add(sunoSong.id);

      // Add cover clip id to the stack
      if (sunoSong.coverClipId != null) {
        coverIds.add(sunoSong.coverClipId!);
        songStack.add(sunoSong.coverClipId!);
      }

      // Add upsample clip id to the stack
      if (sunoSong.upSampleClipId != null &&
          sunoSong.upSampleClipId!.isNotEmpty) {
        upsampleClipIds.add(sunoSong.upSampleClipId!);
        songStack.add(sunoSong.upSampleClipId!);
      }

      for (final songId in sunoSong.songIds) {
        // Songs that are uploaded have m_ prefix for some reason
        if (!songIds.contains(songId.replaceAll('m_', ''))) {
          songStack.add(songId.replaceAll('m_', ''));
        }
      }
    } while (songStack.isNotEmpty);

    listOfSongs.sort((a, b) => a.created.compareTo(b.created));

    return listOfSongs;
  }
}
