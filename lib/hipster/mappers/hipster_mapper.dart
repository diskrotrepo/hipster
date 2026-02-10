// ignore_for_file: avoid_dynamic_calls

import 'package:hipster/hipster/models/song.dart';
import 'package:hipster/logger/logger.dart';

Song responseToSunoSong(Map<String, dynamic> songMap) {
  final Set<String> songList = {};
  String prompt = '';
  String type = '';
  String tags = '';
  String negativeTags = '';
  String title = '';
  double duration = 0;
  String? coverClipId;
  bool isInFill = false;
  bool commercialUse = false;
  String model = 'N/A';
  String upSampleClipId = '';
  String majorModelVersion = 'N/A';
  String status = '';
  String caption = '';
  String? playlistId;
  bool canRemix = false;
  bool inTrash = false;
  bool isPublic = false;
  bool hasVocal = false;
  double durationTime = 0.0;
  String? videoUrl;
  int flagCount = 0;
  double weirdness = 50.0;
  double style = 50.0;
  double audioInfluence = 25.0;

  String? personaClipId;
  String? personaName;
  String? personaOwner;

  if ((!songMap.containsKey('title') || songMap['title'] == null) &&
      songMap['prompt'] != null) {
    title = songMap['prompt'] as String;
  } else {
    title = songMap['title'] as String;
  }

  if (songMap.containsKey('model_name') && songMap['model_name'] != '') {
    model = songMap['model_name'] as String;
  } else {
    model = 'unknown';
  }

  if (songMap.containsKey('caption') && songMap['caption'] != '') {
    caption = songMap['caption'] as String;
  }

  if (!songMap.containsKey('metadata')) {
    throw Exception('Song metadata not found');
  }

  if (songMap.containsKey('ownership')) {
    commercialUse = true;
  }

  final metadata = songMap['metadata'] as Map<String, dynamic>;

  if (metadata.containsKey('concat_history')) {
    final concatHistory = metadata['concat_history'] as List<dynamic>;
    for (final entry in concatHistory) {
      try {
        songList.add(entry['id'] as String);
      } catch (e) {
        logger.e(message: e.toString());
      }
    }
  }

  if (songMap.containsKey('flag_count')) {
    flagCount = songMap['flag_count'] as int;
  }

  if (metadata.containsKey('playlist_id')) {
    playlistId = metadata['playlist_id'] as String;
  }

  if (songMap.containsKey('can_remix')) {
    canRemix = songMap['can_remix'] as bool;
  }

  if (songMap.containsKey('major_model_version') &&
      songMap['major_model_version'] != '') {
    majorModelVersion = songMap['major_model_version'] as String;
  }

  if (songMap.containsKey('is_public')) {
    isPublic = songMap['is_public'] as bool;
  }

  if (songMap.containsKey('video_url')) {
    videoUrl = songMap['video_url'] as String;
  }

  if (songMap.containsKey('status')) {
    status = songMap['status'] as String;
  }

  if (metadata.containsKey('can_remix')) {
    canRemix = metadata['can_remix'] as bool;
  }

  if (songMap.containsKey('persona')) {
    final persona = songMap['persona'] as Map<String, dynamic>;
    personaClipId = persona['id'] as String?;
    personaName = persona['name'] as String?;
    personaOwner = persona['user_handle'] as String?;
  }

  if (metadata.containsKey('control_sliders')) {
    final controlSliders = metadata['control_sliders'] as Map<String, dynamic>;
    if (controlSliders.containsKey('weirdness_constraint')) {
      weirdness = ((controlSliders['weirdness_constraint'] as double) * 100.0)
          .roundToDouble();
    }
    if (controlSliders.containsKey('style_weight')) {
      style =
          ((controlSliders['style_weight'] as double) * 100.0).roundToDouble();
    }
    if (controlSliders.containsKey('audio_weight')) {
      audioInfluence =
          ((controlSliders['audio_weight'] as double) * 100.0).roundToDouble();
    }
  }

  if (metadata.containsKey('is_trashed')) {
    inTrash = metadata['is_trashed'] as bool;
  }

  if (songMap.containsKey('is_trashed')) {
    inTrash = songMap['is_trashed'] as bool;
  }

  if (metadata.containsKey('has_vocal')) {
    hasVocal = metadata['has_vocal'] as bool;
  }

  if (metadata.containsKey('duration_time')) {
    durationTime = double.parse(metadata['duration_time'] as String);
  }

  if (metadata.containsKey('prompt')) {
    prompt = metadata['prompt'] as String;
  }

  if (metadata.containsKey('type')) {
    type = metadata['type'] as String;
  }

  if (metadata.containsKey('upsample_clip_id')) {
    upSampleClipId = metadata['upsample_clip_id'] as String;
    songList.add(upSampleClipId);
  }

  if (metadata.containsKey('speed_clip_id')) {
    final speedClipId = metadata['speed_clip_id'] as String;
    songList.add(speedClipId);
  }

  if (metadata.containsKey('tags')) {
    tags = metadata['tags'] as String;
  }

  if (metadata.containsKey('negative_tags')) {
    negativeTags = metadata['negative_tags'] as String;
  }

  if (metadata.containsKey('infill')) {
    isInFill = metadata['infill'] as bool;
  }

  if (metadata.containsKey('duration')) {
    duration = metadata['duration'] as double;
  }

  if (metadata.containsKey('overpainting_clip_id')) {
    coverClipId = metadata['overpainting_clip_id'] as String;
    songList.add(coverClipId);
  }

  if (metadata.containsKey('edited_clip_id')) {
    final editedClipId = metadata['edited_clip_id'] as String;

    if (metadata['task'] == 'cover' &&
        metadata['cover_clip_id'] == '00000000-0000-0000-0000-000000000000') {
      coverClipId = editedClipId;
      songList.add(editedClipId);
    } else {
      songList.add(editedClipId);
    }
  }

  return Song(
    title: title,
    image:
        songMap.containsKey('image_url') ? songMap['image_url'] as String : '',
    type: type,
    upSampleClipId: upSampleClipId,
    artistId: songMap['user_id'] as String,
    artistName: songMap['handle'] as String,
    avatarImageUrl: songMap.containsKey('avatar_image_url')
        ? songMap['avatar_image_url'] as String
        : '',
    commercialUse: commercialUse,
    tags: tags,
    negativeTags: negativeTags,
    playlistId: playlistId,
    isInFill: isInFill,
    isCover: coverClipId != null && coverClipId.isNotEmpty,
    caption: caption,
    duration: duration,
    task: metadata.containsKey('task') ? metadata['task'] as String : '',
    hasVocal: hasVocal,
    id: songMap.containsKey('id') ? songMap['id'] as String : '',
    prompt: prompt,
    songIds: songList.toList(),
    weirdness: weirdness,
    style: style,
    audioInfluence: audioInfluence,
    created: songMap.containsKey('created_at')
        ? songMap['created_at'] as String
        : '',
    playCount:
        songMap.containsKey('play_count') ? songMap['play_count'] as int : 0,
    upvoteCount: songMap.containsKey('upvote_count')
        ? songMap['upvote_count'] as int
        : 0,
    coverClipId: coverClipId != '' ? coverClipId : null,
    model: model,
    majorModelVersion: majorModelVersion,
    audioUrl:
        songMap.containsKey('audio_url') ? songMap['audio_url'] as String : '',
    status: status,
    canRemix: canRemix,
    inTrash: inTrash,
    isPublic: isPublic,
    durationTime: durationTime,
    videoUrl: videoUrl,
    flagCount: flagCount,
    personaClipId: personaClipId,
    personaName: personaName,
    personaOwner: personaOwner,
  );
}
