import 'path_point.dart';

class WalkSession {
  final String id;
  final DateTime dateTime;
  final Duration duration;
  final double distanceMeters;
  final String? recordingPath;
  final String? screenshotPath;
  final List<PathPoint> pathPoints;

  WalkSession({
    required this.id,
    required this.dateTime,
    required this.duration,
    required this.distanceMeters,
    this.recordingPath,
    this.screenshotPath,
    this.pathPoints = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.millisecondsSinceEpoch,
        'duration': duration.inSeconds,
        'distanceMeters': distanceMeters,
        'recordingPath': recordingPath,
        'screenshotPath': screenshotPath,
        'pathPoints': pathPoints.map((p) => p.toJson()).toList(),
      };

  factory WalkSession.fromJson(Map<String, dynamic> json) => WalkSession(
        id: json['id'],
        dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
        duration: Duration(seconds: json['duration']),
        distanceMeters: json['distanceMeters'],
        recordingPath: json['recordingPath'],
        screenshotPath: json['screenshotPath'],
        pathPoints: (json['pathPoints'] as List<dynamic>?)
                ?.map((p) => PathPoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
  }
}