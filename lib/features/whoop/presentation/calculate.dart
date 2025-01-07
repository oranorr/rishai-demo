import 'dart:developer';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/activity.dart';

class CalculateWhoopData {
  CalculateWhoopData({
    required this.gender,
    required this.strainValue,
    required this.recoveryScore,
    required this.sleepPerformance,
  });
  final Gender gender;
  final double strainValue;

  final int recoveryScore;
  final int sleepPerformance;

  ({double protein, double fats}) calcStrain() {
    final strain = strainValue.toPrecision();

    if (gender == Gender.male) {
      if (strain > 17.5) {
        return (protein: 1.2, fats: 0.5);
      } else if (strain >= 15 && strain <= 17.4) {
        return (protein: 1.1, fats: 0.47);
      } else if (strain >= 12.5 && strain <= 14.9) {
        return (protein: 1, fats: 0.44);
      } else if (strain >= 10 && strain <= 12.4) {
        return (protein: 0.9, fats: 0.41);
      } else if (strain >= 7.5 && strain <= 9.9) {
        return (protein: 0.8, fats: 0.38);
      } else if (strain <= 7.4) {
        return (protein: 0.7, fats: 0.35);
      }
    } else if (gender == Gender.female) {
      if (strain > 17.5) {
        return (protein: 1, fats: 0.5);
      } else if (strain >= 15 && strain <= 17.4) {
        return (protein: 0.9, fats: 0.47);
      } else if (strain >= 12.5 && strain <= 14.9) {
        return (protein: 0.8, fats: 0.44);
      } else if (strain >= 10 && strain <= 12.4) {
        return (protein: 0.7, fats: 0.41);
      } else if (strain >= 7.5 && strain <= 9.9) {
        return (protein: 0.6, fats: 0.38);
      } else if (strain <= 7.4) {
        return (protein: 0.5, fats: 0.35);
      }
    }
    log('ERROR WHILE CALCULATING STRAIN DATA, incoming was: $gender, $strainValue, AND PRECISE: $strain');
    return (protein: 0.0, fats: 0.0);
  }

  ({double protein, double fats}) calcActivity({required Activity activity}) {
    switch (activity) {
      case Activity.strength:
        if (gender == Gender.male) {
          return (protein: 1.1, fats: 0);
        } else {
          return (protein: 0.9, fats: 0);
        }
      case Activity.cardio:
        if (gender == Gender.male) {
          return (protein: 0.9, fats: 0);
        } else {
          return (protein: 0.7, fats: 0);
        }
      case Activity.hiit:
        if (gender == Gender.male) {
          return (protein: 1, fats: 0);
        } else {
          return (protein: 0.8, fats: 0);
        }
      case Activity.activeRest:
        if (gender == Gender.male) {
          return (protein: 0.8, fats: 0);
        } else {
          return (protein: 0.6, fats: 0);
        }
      // ignore: no_default_cases
      default:
        log('ERROR WHILE CALCULATING activity DATA, incoming was: $gender $activity');
        return (protein: 0, fats: 0);
    }
  }

  ({double protein, double fats}) calculateRecovery() {
    if (gender == Gender.male) {
      if (recoveryScore >= 85 && recoveryScore <= 100) {
        return (protein: 0.7, fats: 0.35);
      } else if (recoveryScore >= 60 && recoveryScore <= 84) {
        return (protein: 0.8, fats: 0.38);
      } else if (recoveryScore >= 45 && recoveryScore <= 59) {
        return (protein: 0.9, fats: 0.41);
      } else if (recoveryScore >= 30 && recoveryScore <= 44) {
        return (protein: 1, fats: 0.44);
      } else if (recoveryScore >= 15 && recoveryScore <= 29) {
        return (protein: 1.1, fats: 0.47);
      } else if (recoveryScore > 0 && recoveryScore <= 14) {
        return (protein: 1.2, fats: 0.5);
      }
    } else {
      if (recoveryScore >= 85 && recoveryScore <= 100) {
        return (protein: 0.5, fats: 0.35);
      } else if (recoveryScore >= 60 && recoveryScore <= 84) {
        return (protein: 0.6, fats: 0.38);
      } else if (recoveryScore >= 45 && recoveryScore <= 59) {
        return (protein: 0.7, fats: 0.41);
      } else if (recoveryScore >= 30 && recoveryScore <= 44) {
        return (protein: 0.8, fats: 0.44);
      } else if (recoveryScore >= 15 && recoveryScore <= 29) {
        return (protein: 0.9, fats: 0.47);
      } else if (recoveryScore > 0 && recoveryScore <= 14) {
        return (protein: 1, fats: 0.5);
      }
    }
    log('ERROR WHILE CALCULATING recovery DATA, incoming was: $gender $recoveryScore');
    return (protein: 0, fats: 0);
  }

  ({double protein}) calculateSleepPerformance() {
    if (gender == Gender.male) {
      if (sleepPerformance >= 85 && sleepPerformance <= 100) {
        return (protein: 0.7);
      } else if (sleepPerformance >= 60 && sleepPerformance <= 84) {
        return (protein: 0.8);
      } else if (sleepPerformance >= 45 && sleepPerformance <= 59) {
        return (protein: 0.9);
      } else if (sleepPerformance >= 30 && sleepPerformance <= 44) {
        return (protein: 1);
      } else if (sleepPerformance >= 15 && sleepPerformance <= 29) {
        return (protein: 1.1);
      } else if (sleepPerformance >= 0 && sleepPerformance <= 14) {
        return (protein: 1.2);
      }
    } else {
      if (sleepPerformance >= 85 && sleepPerformance <= 100) {
        return (protein: 0.5);
      } else if (sleepPerformance >= 60 && sleepPerformance <= 84) {
        return (protein: 0.6);
      } else if (sleepPerformance >= 45 && sleepPerformance <= 59) {
        return (protein: 0.7);
      } else if (sleepPerformance >= 30 && sleepPerformance <= 44) {
        return (protein: 0.8);
      } else if (sleepPerformance >= 15 && sleepPerformance <= 29) {
        return (protein: 0.9);
      } else if (sleepPerformance >= 0 && sleepPerformance <= 14) {
        return (protein: 1);
      }
    }
    log('ERROR WHILE CALCULATING recovery DATA, incoming was: $gender $sleepPerformance');
    return (protein: 0,);
  }
}
