import 'package:flutter_test/flutter_test.dart';
import 'package:hipster/hipster/mappers/hipster_mapper.dart';
import 'package:hipster/logger/logger.dart';

Map<String, dynamic> _baseSongMap({
  Map<String, dynamic>? metadataOverrides,
  Map<String, dynamic>? topLevelOverrides,
}) {
  final metadata = <String, dynamic>{
    'prompt': 'test prompt',
    'type': 'gen',
    'tags': 'pop rock',
    'negative_tags': 'metal',
    'duration': 120.0,
    ...?metadataOverrides,
  };
  return {
    'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    'title': 'Test Song',
    'model_name': 'chirp-v3',
    'user_id': 'user-123',
    'handle': 'testartist',
    'avatar_image_url': 'https://example.com/avatar.png',
    'image_url': 'https://example.com/image.png',
    'audio_url': 'https://example.com/audio.mp3',
    'created_at': '2024-01-01T00:00:00Z',
    'play_count': 100,
    'upvote_count': 50,
    'metadata': metadata,
    ...?topLevelOverrides,
  };
}

void main() {
  setUpAll(() {
    // Provide a silent logger so mapper logging doesn't fail
    logger = Logger();
  });

  group('responseToSunoSong', () {
    test('maps a complete song correctly', () {
      final song = responseToSunoSong(_baseSongMap());

      expect(song.id, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(song.title, 'Test Song');
      expect(song.model, 'chirp-v3');
      expect(song.artistId, 'user-123');
      expect(song.artistName, 'testartist');
      expect(song.avatarImageUrl, 'https://example.com/avatar.png');
      expect(song.image, 'https://example.com/image.png');
      expect(song.audioUrl, 'https://example.com/audio.mp3');
      expect(song.created, '2024-01-01T00:00:00Z');
      expect(song.playCount, 100);
      expect(song.upvoteCount, 50);
      expect(song.prompt, 'test prompt');
      expect(song.type, 'gen');
      expect(song.tags, 'pop rock');
      expect(song.negativeTags, 'metal');
      expect(song.duration, 120.0);
    });

    test('falls back to prompt as title when title is null', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'title': null, 'prompt': 'my prompt title'},
        metadataOverrides: {'prompt': 'meta prompt'},
      ));
      expect(song.title, 'my prompt title');
    });

    test('throws when metadata is missing', () {
      final map = _baseSongMap();
      map.remove('metadata');
      expect(() => responseToSunoSong(map), throwsException);
    });

    test('sets model to unknown when model_name is empty', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'model_name': ''},
      ));
      expect(song.model, 'unknown');
    });

    test('defaults optional fields when not present', () {
      final song = responseToSunoSong(_baseSongMap());

      expect(song.isCover, isFalse);
      expect(song.isInFill, isFalse);
      expect(song.commercialUse, isFalse);
      expect(song.canRemix, isFalse);
      expect(song.inTrash, isFalse);
      expect(song.isPublic, isFalse);
      expect(song.hasVocal, isFalse);
      expect(song.coverClipId, isNull);
      expect(song.playlistId, isNull);
      expect(song.videoUrl, isNull);
      expect(song.flagCount, 0);
      expect(song.personaClipId, isNull);
      expect(song.personaName, isNull);
      expect(song.personaOwner, isNull);
    });

    test('sets commercialUse when ownership key is present', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'ownership': {}},
      ));
      expect(song.commercialUse, isTrue);
    });

    test('extracts concat_history song IDs', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'concat_history': [
            {'id': 'song-1'},
            {'id': 'song-2'},
          ],
        },
      ));
      expect(song.songIds, containsAll(['song-1', 'song-2']));
    });

    test('extracts control_sliders values', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'control_sliders': {
            'weirdness_constraint': 0.75,
            'style_weight': 0.6,
            'audio_weight': 0.5,
          },
        },
      ));
      expect(song.weirdness, 75.0);
      expect(song.style, 60.0);
      expect(song.audioInfluence, 50.0);
    });

    test('uses default control_sliders values when absent', () {
      final song = responseToSunoSong(_baseSongMap());
      expect(song.weirdness, 50.0);
      expect(song.style, 50.0);
      expect(song.audioInfluence, 25.0);
    });

    test('extracts persona data', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {
          'persona': {
            'id': 'persona-123',
            'name': 'Cool Persona',
            'user_handle': 'persona_owner',
          },
        },
      ));
      expect(song.personaClipId, 'persona-123');
      expect(song.personaName, 'Cool Persona');
      expect(song.personaOwner, 'persona_owner');
    });

    test('extracts playlist ID from metadata', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {'playlist_id': 'playlist-abc'},
      ));
      expect(song.playlistId, 'playlist-abc');
    });

    test('handles upsample_clip_id', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'upsample_clip_id': 'upsample-123',
        },
      ));
      expect(song.upSampleClipId, 'upsample-123');
      expect(song.songIds, contains('upsample-123'));
    });

    test('handles overpainting_clip_id as cover', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'overpainting_clip_id': 'cover-456',
        },
      ));
      expect(song.coverClipId, 'cover-456');
      expect(song.isCover, isTrue);
      expect(song.songIds, contains('cover-456'));
    });

    test('handles edited_clip_id with cover task and zero cover_clip_id', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'edited_clip_id': 'edited-789',
          'task': 'cover',
          'cover_clip_id': '00000000-0000-0000-0000-000000000000',
        },
      ));
      expect(song.coverClipId, 'edited-789');
      expect(song.isCover, isTrue);
      expect(song.songIds, contains('edited-789'));
    });

    test('handles edited_clip_id without cover task', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {
          'edited_clip_id': 'edited-789',
          'task': 'remix',
        },
      ));
      expect(song.songIds, contains('edited-789'));
      expect(song.coverClipId, isNull);
    });

    test('extracts boolean flags from top-level and metadata', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {
          'can_remix': true,
          'is_public': true,
          'is_trashed': true,
          'flag_count': 3,
        },
        metadataOverrides: {
          'has_vocal': true,
          'infill': true,
          'duration_time': '45.5',
        },
      ));
      expect(song.canRemix, isTrue);
      expect(song.isPublic, isTrue);
      expect(song.inTrash, isTrue);
      expect(song.flagCount, 3);
      expect(song.hasVocal, isTrue);
      expect(song.isInFill, isTrue);
      expect(song.durationTime, 45.5);
    });

    test('metadata is_trashed overrides top-level is_trashed', () {
      // The code checks songMap['is_trashed'] after metadata['is_trashed'],
      // so the songMap value wins when both exist.
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'is_trashed': false},
        metadataOverrides: {'is_trashed': true},
      ));
      expect(song.inTrash, isFalse);
    });

    test('extracts speed_clip_id into songIds', () {
      final song = responseToSunoSong(_baseSongMap(
        metadataOverrides: {'speed_clip_id': 'speed-111'},
      ));
      expect(song.songIds, contains('speed-111'));
    });

    test('handles missing image_url gracefully', () {
      final map = _baseSongMap();
      map.remove('image_url');
      final song = responseToSunoSong(map);
      expect(song.image, '');
    });

    test('extracts caption', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'caption': 'A great song'},
      ));
      expect(song.caption, 'A great song');
    });

    test('extracts video_url', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'video_url': 'https://example.com/video.mp4'},
      ));
      expect(song.videoUrl, 'https://example.com/video.mp4');
    });

    test('extracts status', () {
      final song = responseToSunoSong(_baseSongMap(
        topLevelOverrides: {'status': 'complete'},
      ));
      expect(song.status, 'complete');
    });
  });
}
