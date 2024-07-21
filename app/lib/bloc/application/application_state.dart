part of 'application_bloc.dart';

class ApplicationState {
  final bool hasVibrator;
  final bool hasAmplitudeControl;

  const ApplicationState({
    required this.hasAmplitudeControl,
    required this.hasVibrator,
  });
}
