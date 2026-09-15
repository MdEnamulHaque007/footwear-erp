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
