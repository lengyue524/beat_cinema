import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;
  late LevelParseService service;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('level_parse_test_');
    service = LevelParseService();
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('parseSingleLevel returns null for non-existing directory', () async {
    final missingPath = p.join(tempRoot.path, 'missing-level');
    final result = await service.parseSingleLevel(missingPath);
    expect(result, isNull);
  });

  test('parseSingleLevel parses info.dat from level directory', () async {
    final levelDir = Directory(p.join(tempRoot.path, 'custom_level_a'))
      ..createSync(recursive: true);
    final infoFile = File(p.join(levelDir.path, Constants.customLevelInfoName));
    final info = {
      '_songName': 'Song A',
      '_songAuthorName': 'Author A',
      '_difficultyBeatmapSets': [],
    };
    infoFile.writeAsStringSync(json.encode(info));

    final result = await service.parseSingleLevel(levelDir.path);
    expect(result, isNotNull);
    expect(result!.songName, 'Song A');
    expect(result.songAuthorName, 'Author A');
    expect(result.levelPath, levelDir.path);
  });

  test('parseSingleLevel uses hash from CustomLevel directory name', () async {
    const rawHash = '0B75C8EE24A8406D4E43B3C38A5A3E793518F7D0';
    final levelDir = Directory(p.join(tempRoot.path, 'CustomLevel$rawHash'))
      ..createSync(recursive: true);
    final infoFile = File(p.join(levelDir.path, Constants.customLevelInfoName));
    final info = {
      '_songName': 'Song Hash',
      '_songAuthorName': 'Author Hash',
      '_difficultyBeatmapSets': [],
    };
    infoFile.writeAsStringSync(json.encode(info));

    final result = await service.parseSingleLevel(levelDir.path);
    expect(result, isNotNull);
    expect(result!.mapHash, rawHash.toLowerCase());
  });

  test('parseSingleLevel keeps computed hash when info parse fails', () async {
    final levelDir = Directory(p.join(tempRoot.path, 'broken_level'))
      ..createSync(recursive: true);
    final infoFile = File(p.join(levelDir.path, Constants.customLevelInfoName));
    infoFile.writeAsStringSync('{ invalid json ');
    final easyFile = File(p.join(levelDir.path, 'EasyStandard.dat'));
    easyFile.writeAsStringSync('dummy beatmap');

    final result = await service.parseSingleLevel(levelDir.path);
    expect(result, isNotNull);
    expect(result!.parseStatus, ParseStatus.failed);
    expect(result.mapHash, isNotEmpty);
    expect(RegExp(r'^[a-f0-9]{40}$').hasMatch(result.mapHash), isTrue);
  });

  test('parseSingleLevel parses v4 info schema', () async {
    final levelDir = Directory(p.join(tempRoot.path, 'v4_level'))
      ..createSync(recursive: true);
    final infoFile = File(p.join(levelDir.path, Constants.customLevelInfoName));
    final info = {
      'version': '4.0.1',
      'song': {
        'title': 'Bubble',
        'subTitle': 'Sub',
        'author': 'Yorushika',
      },
      'coverImageFilename': 'cover.jpg',
      'difficultyBeatmaps': [
        {
          'difficulty': 'ExpertPlus',
          'beatmapDataFilename': 'ExpertPlus.dat',
        },
      ],
    };
    infoFile.writeAsStringSync(json.encode(info));

    final result = await service.parseSingleLevel(levelDir.path);
    expect(result, isNotNull);
    expect(result!.songName, 'Bubble');
    expect(result.songSubName, 'Sub');
    expect(result.songAuthorName, 'Yorushika');
    expect(result.coverImageFilename, 'cover.jpg');
    expect(result.difficulties, contains('ExpertPlus'));
  });

  test('parseSingleLevel can skip hash computation when disabled', () async {
    const rawHash = '0B75C8EE24A8406D4E43B3C38A5A3E793518F7D0';
    final levelDir = Directory(p.join(tempRoot.path, 'CustomLevel$rawHash'))
      ..createSync(recursive: true);
    final infoFile = File(p.join(levelDir.path, Constants.customLevelInfoName));
    final info = {
      '_songName': 'Song No Hash',
      '_songAuthorName': 'Author No Hash',
      '_difficultyBeatmapSets': [],
    };
    infoFile.writeAsStringSync(json.encode(info));

    final result = await service.parseSingleLevel(
      levelDir.path,
      includeMapHash: false,
    );
    expect(result, isNotNull);
    expect(result!.mapHash, isEmpty);
  });
}
