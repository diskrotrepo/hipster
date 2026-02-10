import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hipster/hipster/suno_service.dart';
import 'package:hipster/logger/logger.dart';

Map<String, dynamic> _fakeSongJson({
  required String id,
  String title = 'Test',
  List<Map<String, dynamic>> concatHistory = const [],
  String? upsampleClipId,
  String? overpaintingClipId,
  String createdAt = '2024-01-01T00:00:00Z',
}) {
  final metadata = <String, dynamic>{
    'prompt': 'test',
    'type': 'gen',
    'tags': '',
    'negative_tags': '',
    'duration': 60.0,
    if (concatHistory.isNotEmpty) 'concat_history': concatHistory,
    if (upsampleClipId != null) 'upsample_clip_id': upsampleClipId,
    if (overpaintingClipId != null) 'overpainting_clip_id': overpaintingClipId,
  };
  return {
    'id': id,
    'title': title,
    'model_name': 'chirp-v3',
    'user_id': 'user-1',
    'handle': 'artist',
    'audio_url': '',
    'image_url': '',
    'avatar_image_url': '',
    'created_at': createdAt,
    'play_count': 0,
    'upvote_count': 0,
    'metadata': metadata,
  };
}

void main() {
  setUpAll(() {
    logger = Logger();
  });

  group('SunoService', () {
    test('fetchSongTree returns a single song', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/clip/song-1');
        return http.Response(
          jsonEncode(_fakeSongJson(id: 'song-1')),
          200,
        );
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(1));
      expect(songs.first.id, 'song-1');
    });

    test('fetchSongTree follows concat_history recursively', () async {
      final responses = {
        'song-1': _fakeSongJson(
          id: 'song-1',
          concatHistory: [{'id': 'song-2'}],
          createdAt: '2024-01-02T00:00:00Z',
        ),
        'song-2': _fakeSongJson(
          id: 'song-2',
          createdAt: '2024-01-01T00:00:00Z',
        ),
      };

      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        return http.Response(jsonEncode(responses[songId]!), 200);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(2));
      // Should be sorted by created date
      expect(songs.first.id, 'song-2');
      expect(songs.last.id, 'song-1');
    });

    test('fetchSongTree follows upsample_clip_id', () async {
      final responses = {
        'song-1': _fakeSongJson(
          id: 'song-1',
          upsampleClipId: 'song-2',
          createdAt: '2024-01-02T00:00:00Z',
        ),
        'song-2': _fakeSongJson(
          id: 'song-2',
          createdAt: '2024-01-01T00:00:00Z',
        ),
      };

      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        return http.Response(jsonEncode(responses[songId]!), 200);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(2));
    });

    test('fetchSongTree follows overpainting_clip_id (covers)', () async {
      final responses = {
        'song-1': _fakeSongJson(
          id: 'song-1',
          overpaintingClipId: 'song-2',
          createdAt: '2024-01-02T00:00:00Z',
        ),
        'song-2': _fakeSongJson(
          id: 'song-2',
          createdAt: '2024-01-01T00:00:00Z',
        ),
      };

      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        return http.Response(jsonEncode(responses[songId]!), 200);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(2));
    });

    test('fetchSongTree skips songs with non-200 status', () async {
      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        if (songId == 'song-1') {
          return http.Response(
            jsonEncode(_fakeSongJson(
              id: 'song-1',
              concatHistory: [{'id': 'deleted-song'}],
            )),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(1));
      expect(songs.first.id, 'song-1');
    });

    test('fetchSongTree skips empty response bodies', () async {
      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        if (songId == 'song-1') {
          return http.Response(
            jsonEncode(_fakeSongJson(
              id: 'song-1',
              concatHistory: [{'id': 'empty-song'}],
            )),
            200,
          );
        }
        return http.Response('', 200);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(1));
    });

    test('fetchSongTree does not revisit already-fetched songs', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode(_fakeSongJson(
            id: 'song-1',
            concatHistory: [{'id': 'song-1'}], // self-reference
          )),
          200,
        );
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-1');

      expect(songs, hasLength(1));
      expect(requestCount, 1);
    });

    test('fetchSongTree sorts results by created date', () async {
      final responses = {
        'song-a': _fakeSongJson(
          id: 'song-a',
          concatHistory: [{'id': 'song-b'}, {'id': 'song-c'}],
          createdAt: '2024-01-03T00:00:00Z',
        ),
        'song-b': _fakeSongJson(
          id: 'song-b',
          createdAt: '2024-01-01T00:00:00Z',
        ),
        'song-c': _fakeSongJson(
          id: 'song-c',
          createdAt: '2024-01-02T00:00:00Z',
        ),
      };

      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        return http.Response(jsonEncode(responses[songId]!), 200);
      });

      final service = SunoService(client: mockClient);
      final songs = await service.fetchSongTree('song-a');

      expect(songs[0].id, 'song-b');
      expect(songs[1].id, 'song-c');
      expect(songs[2].id, 'song-a');
    });

    test('sends bearer token in headers when set', () async {
      String? capturedAuth;
      final mockClient = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response(
          jsonEncode(_fakeSongJson(id: 'song-1')),
          200,
        );
      });

      final service = SunoService(client: mockClient);
      service.bearerToken = 'my-secret-token';
      await service.fetchSongTree('song-1');

      expect(capturedAuth, 'Bearer my-secret-token');
    });

    test('sends no auth header when bearerToken is null', () async {
      bool hasAuthHeader = false;
      final mockClient = MockClient((request) async {
        hasAuthHeader = request.headers.containsKey('Authorization');
        return http.Response(
          jsonEncode(_fakeSongJson(id: 'song-1')),
          200,
        );
      });

      final service = SunoService(client: mockClient);
      await service.fetchSongTree('song-1');

      expect(hasAuthHeader, isFalse);
    });

    test('strips m_ prefix from song IDs in concat_history', () async {
      final responses = {
        'song-1': _fakeSongJson(
          id: 'song-1',
          concatHistory: [{'id': 'm_song-2'}],
        ),
        'song-2': _fakeSongJson(id: 'song-2'),
      };

      final requestedPaths = <String>[];
      final mockClient = MockClient((request) async {
        final songId = request.url.pathSegments.last;
        requestedPaths.add(songId);
        final response = responses[songId];
        if (response != null) {
          return http.Response(jsonEncode(response), 200);
        }
        return http.Response('', 404);
      });

      final service = SunoService(client: mockClient);
      await service.fetchSongTree('song-1');

      expect(requestedPaths, contains('song-2'));
    });
  });
}
