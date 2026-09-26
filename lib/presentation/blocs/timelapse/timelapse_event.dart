/// ============================================================================
/// ফাইল: lib/presentation/blocs/timelapse/timelapse_event.dart
/// স্তর: Presentation BLoC | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: TimelapseEvent, LoadTimelapseData, PlayTimelapse, PauseTimelapse, ResetTimelapse, SetPlaybackSpeed, TickTimelapse
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/timelapse/timelapse_config_entity.dart';

sealed class TimelapseEvent extends Equatable {
  const TimelapseEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimelapseData extends TimelapseEvent {
  const LoadTimelapseData(this.config);

  final TimelapseConfig config;

  @override
  List<Object?> get props => [config];
}

class PlayTimelapse extends TimelapseEvent {
  const PlayTimelapse();
}

class PauseTimelapse extends TimelapseEvent {
  const PauseTimelapse();
}

class ResetTimelapse extends TimelapseEvent {
  const ResetTimelapse();
}

class SetPlaybackSpeed extends TimelapseEvent {
  const SetPlaybackSpeed(this.speed);

  final double speed;

  @override
  List<Object?> get props => [speed];
}

class TickTimelapse extends TimelapseEvent {
  const TickTimelapse(this.visiblePoints);

  final int visiblePoints;

  @override
  List<Object?> get props => [visiblePoints];
}
