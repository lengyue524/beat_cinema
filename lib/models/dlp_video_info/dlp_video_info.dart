import 'dart:convert';

class DlpVideoInfo {
  String? id;
  String? title;
  String? thumbnail;
  String? description;
  String? channelId;
  String? channelUrl;
  double? duration;
  int? viewCount;
  dynamic averageRating;
  int? ageLimit;
  String? webpageUrl;
  bool? playableInEmbed;
  String? liveStatus;
  dynamic releaseTimestamp;
  int? commentCount;
  dynamic chapters;
  int? likeCount;
  String? channel;
  int? channelFollowerCount;
  bool? channelIsVerified;
  String? uploader;
  String? uploaderId;
  String? uploaderUrl;
  String? uploadDate;
  String? availability;
  String? originalUrl;
  String? webpageUrlBasename;
  String? webpageUrlDomain;
  String? extractor;
  String? extractorKey;
  int? playlistCount;
  String? playlist;
  String? playlistId;
  String? playlistTitle;
  dynamic playlistUploader;
  dynamic playlistUploaderId;
  int? nEntries;
  int? playlistIndex;
  int? lastPlaylistIndex;
  int? playlistAutonumber;
  String? displayId;
  String? fulltitle;
  String? durationString;
  dynamic releaseYear;
  bool? isLive;
  bool? wasLive;
  dynamic requestedSubtitles;
  dynamic hasDrm;
  int? epoch;
  String? format;
  String? formatId;
  String? ext;
  String? protocol;
  String? language;
  String? formatNote;
  int? filesizeApprox;
  double? tbr;
  int? width;
  int? height;
  String? resolution;
  double? fps;
  String? dynamicRange;
  String? vcodec;
  double? vbr;
  dynamic stretchedRatio;
  double? aspectRatio;
  String? acodec;
  double? abr;
  int? asr;
  int? audioChannels;
  String? filename;
  String? type;

  DlpVideoInfo({
    this.id,
    this.title,
    this.thumbnail,
    this.description,
    this.channelId,
    this.channelUrl,
    this.duration,
    this.viewCount,
    this.averageRating,
    this.ageLimit,
    this.webpageUrl,
    this.playableInEmbed,
    this.liveStatus,
    this.releaseTimestamp,
    this.commentCount,
    this.chapters,
    this.likeCount,
    this.channel,
    this.channelFollowerCount,
    this.channelIsVerified,
    this.uploader,
    this.uploaderId,
    this.uploaderUrl,
    this.uploadDate,
    this.availability,
    this.originalUrl,
    this.webpageUrlBasename,
    this.webpageUrlDomain,
    this.extractor,
    this.extractorKey,
    this.playlistCount,
    this.playlist,
    this.playlistId,
    this.playlistTitle,
    this.playlistUploader,
    this.playlistUploaderId,
    this.nEntries,
    this.playlistIndex,
    this.lastPlaylistIndex,
    this.playlistAutonumber,
    this.displayId,
    this.fulltitle,
    this.durationString,
    this.releaseYear,
    this.isLive,
    this.wasLive,
    this.requestedSubtitles,
    this.hasDrm,
    this.epoch,
    this.format,
    this.formatId,
    this.ext,
    this.protocol,
    this.language,
    this.formatNote,
    this.filesizeApprox,
    this.tbr,
    this.width,
    this.height,
    this.resolution,
    this.fps,
    this.dynamicRange,
    this.vcodec,
    this.vbr,
    this.stretchedRatio,
    this.aspectRatio,
    this.acodec,
    this.abr,
    this.asr,
    this.audioChannels,
    this.filename,
    this.type,
  });

  factory DlpVideoInfo.fromMap(Map<String, dynamic> data) => DlpVideoInfo(
        id: data['id'] as String?,
        title: data['title'] as String?,
        thumbnail: data['thumbnail'] as String?,
        description: data['description'] as String?,
        channelId: data['channel_id'] as String?,
        channelUrl: data['channel_url'] as String?,
        duration: (data['duration'] as num?)?.toDouble(),
        viewCount: data['view_count'] as int?,
        averageRating: data['average_rating'] as dynamic,
        ageLimit: data['age_limit'] as int?,
        webpageUrl: data['webpage_url'] as String?,
        playableInEmbed: data['playable_in_embed'] as bool?,
        liveStatus: data['live_status'] as String?,
        releaseTimestamp: data['release_timestamp'] as dynamic,
        commentCount: data['comment_count'] as int?,
        chapters: data['chapters'] as dynamic,
        likeCount: data['like_count'] as int?,
        channel: data['channel'] as String?,
        channelFollowerCount: data['channel_follower_count'] as int?,
        channelIsVerified: data['channel_is_verified'] as bool?,
        uploader: data['uploader'] as String?,
        uploaderId: data['uploader_id'] as String?,
        uploaderUrl: data['uploader_url'] as String?,
        uploadDate: data['upload_date'] as String?,
        availability: data['availability'] as String?,
        originalUrl: data['original_url'] as String?,
        webpageUrlBasename: data['webpage_url_basename'] as String?,
        webpageUrlDomain: data['webpage_url_domain'] as String?,
        extractor: data['extractor'] as String?,
        extractorKey: data['extractor_key'] as String?,
        playlistCount: data['playlist_count'] as int?,
        playlist: data['playlist'] as String?,
        playlistId: data['playlist_id'] as String?,
        playlistTitle: data['playlist_title'] as String?,
        playlistUploader: data['playlist_uploader'] as dynamic,
        playlistUploaderId: data['playlist_uploader_id'] as dynamic,
        nEntries: data['n_entries'] as int?,
        playlistIndex: data['playlist_index'] as int?,
        lastPlaylistIndex: data['__last_playlist_index'] as int?,
        playlistAutonumber: data['playlist_autonumber'] as int?,
        displayId: data['display_id'] as String?,
        fulltitle: data['fulltitle'] as String?,
        durationString: data['duration_string'] as String?,
        releaseYear: data['release_year'] as dynamic,
        isLive: data['is_live'] as bool?,
        wasLive: data['was_live'] as bool?,
        requestedSubtitles: data['requested_subtitles'] as dynamic,
        hasDrm: data['_has_drm'] as dynamic,
        epoch: data['epoch'] as int?,
        format: data['format'] as String?,
        formatId: data['format_id'] as String?,
        ext: data['ext'] as String?,
        protocol: data['protocol'] as String?,
        language: data['language'] as String?,
        formatNote: data['format_note'] as String?,
        filesizeApprox: data['filesize_approx'] as int?,
        tbr: (data['tbr'] as num?)?.toDouble(),
        width: data['width'] as int?,
        height: data['height'] as int?,
        resolution: data['resolution'] as String?,
        fps: (data['fps'] as num?)?.toDouble(),
        dynamicRange: data['dynamic_range'] as String?,
        vcodec: data['vcodec'] as String?,
        vbr: (data['vbr'] as num?)?.toDouble(),
        stretchedRatio: data['stretched_ratio'] as dynamic,
        aspectRatio: (data['aspect_ratio'] as num?)?.toDouble(),
        acodec: data['acodec'] as String?,
        abr: (data['abr'] as num?)?.toDouble(),
        asr: data['asr'] as int?,
        audioChannels: data['audio_channels'] as int?,
        filename: data['filename'] as String?,
        type: data['_type'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'description': description,
        'channel_id': channelId,
        'channel_url': channelUrl,
        'duration': duration,
        'view_count': viewCount,
        'average_rating': averageRating,
        'age_limit': ageLimit,
        'webpage_url': webpageUrl,
        'playable_in_embed': playableInEmbed,
        'live_status': liveStatus,
        'release_timestamp': releaseTimestamp,
        'comment_count': commentCount,
        'chapters': chapters,
        'like_count': likeCount,
        'channel': channel,
        'channel_follower_count': channelFollowerCount,
        'channel_is_verified': channelIsVerified,
        'uploader': uploader,
        'uploader_id': uploaderId,
        'uploader_url': uploaderUrl,
        'upload_date': uploadDate,
        'availability': availability,
        'original_url': originalUrl,
        'webpage_url_basename': webpageUrlBasename,
        'webpage_url_domain': webpageUrlDomain,
        'extractor': extractor,
        'extractor_key': extractorKey,
        'playlist_count': playlistCount,
        'playlist': playlist,
        'playlist_id': playlistId,
        'playlist_title': playlistTitle,
        'playlist_uploader': playlistUploader,
        'playlist_uploader_id': playlistUploaderId,
        'n_entries': nEntries,
        'playlist_index': playlistIndex,
        '__last_playlist_index': lastPlaylistIndex,
        'playlist_autonumber': playlistAutonumber,
        'display_id': displayId,
        'fulltitle': fulltitle,
        'duration_string': durationString,
        'release_year': releaseYear,
        'is_live': isLive,
        'was_live': wasLive,
        'requested_subtitles': requestedSubtitles,
        '_has_drm': hasDrm,
        'epoch': epoch,
        'format': format,
        'format_id': formatId,
        'ext': ext,
        'protocol': protocol,
        'language': language,
        'format_note': formatNote,
        'filesize_approx': filesizeApprox,
        'tbr': tbr,
        'width': width,
        'height': height,
        'resolution': resolution,
        'fps': fps,
        'dynamic_range': dynamicRange,
        'vcodec': vcodec,
        'vbr': vbr,
        'stretched_ratio': stretchedRatio,
        'aspect_ratio': aspectRatio,
        'acodec': acodec,
        'abr': abr,
        'asr': asr,
        'audio_channels': audioChannels,
        'filename': filename,
        '_type': type,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [DlpVideoInfo].
  factory DlpVideoInfo.fromJson(String data) {
    return DlpVideoInfo.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [DlpVideoInfo] to a JSON string.
  String toJson() => json.encode(toMap());
}
