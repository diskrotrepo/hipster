class Song {
  Song({
    required this.title,
    required this.type,
    required this.tags,
    required this.negativeTags,
    required this.artistId,
    required this.avatarImageUrl,
    required this.artistName,
    required this.image,
    required this.id,
    required this.task,
    required this.caption,
    required this.duration,
    required this.songIds,
    required this.prompt,
    required this.created,
    required this.playCount,
    required this.upvoteCount,
    required this.isCover,
    required this.audioUrl,
    required this.hasVocal,
    required this.playlistId,
    this.coverClipId,
    this.upSampleClipId,
    required this.isInFill,
    required this.model,
    required this.majorModelVersion,
    required this.status,
    required this.canRemix,
    required this.inTrash,
    required this.isPublic,
    required this.durationTime,
    required this.videoUrl,
    required this.flagCount,
    required this.weirdness,
    required this.style,
    required this.audioInfluence,
    required this.personaClipId,
    required this.personaName,
    required this.personaOwner,
    required this.commercialUse,
  });

  final String title;
  final String type;
  final String tags;
  final String negativeTags;
  final String id;
  final String caption;
  final double duration;
  final String? playlistId;
  final List<String> songIds;
  final String artistId;
  final String artistName;
  final String avatarImageUrl;
  final String prompt;
  final String created;
  final String image;
  final String? coverClipId;
  final String? upSampleClipId;
  final String? task;
  final int playCount;
  final int upvoteCount;
  final bool isCover;
  final bool isInFill;
  final bool hasVocal;
  final bool commercialUse;
  final String model;
  final String majorModelVersion;
  final String audioUrl;
  final String status;
  final bool canRemix;
  final bool inTrash;
  final bool isPublic;
  final double durationTime;
  final String? videoUrl;
  final int flagCount;
  final double weirdness;
  final double style;
  final double audioInfluence;
  final String? personaClipId;
  final String? personaName;
  final String? personaOwner;
}
