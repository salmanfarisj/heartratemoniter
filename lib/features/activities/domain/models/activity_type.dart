enum ActivityType {
  run,
  ride,
  swim,
  gym,
  walk,
  hike,
  yoga,
  hiit,
  rowing,
  basketball,
  tennis,
  soccer,
  dancing,
  boxing,
  climbing,
  skiing,
  snowboarding,
  elliptical,
  stairmaster,
  other;

  String get label {
    switch (this) {
      case ActivityType.run:
        return 'Run';
      case ActivityType.ride:
        return 'Ride';
      case ActivityType.swim:
        return 'Swim';
      case ActivityType.gym:
        return 'Gym';
      case ActivityType.walk:
        return 'Walk';
      case ActivityType.hike:
        return 'Hike';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.hiit:
        return 'HIIT';
      case ActivityType.rowing:
        return 'Rowing';
      case ActivityType.basketball:
        return 'Basketball';
      case ActivityType.tennis:
        return 'Tennis';
      case ActivityType.soccer:
        return 'Soccer';
      case ActivityType.dancing:
        return 'Dancing';
      case ActivityType.boxing:
        return 'Boxing';
      case ActivityType.climbing:
        return 'Climbing';
      case ActivityType.skiing:
        return 'Skiing';
      case ActivityType.snowboarding:
        return 'Snowboard';
      case ActivityType.elliptical:
        return 'Elliptical';
      case ActivityType.stairmaster:
        return 'StairMaster';
      case ActivityType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.run:
        return 'directions_run';
      case ActivityType.ride:
        return 'directions_bike';
      case ActivityType.swim:
        return 'pool';
      case ActivityType.gym:
        return 'fitness_center';
      case ActivityType.walk:
        return 'directions_walk';
      case ActivityType.hike:
        return 'terrain';
      case ActivityType.yoga:
        return 'self_improvement';
      case ActivityType.hiit:
        return 'timer';
      case ActivityType.rowing:
        return 'rowing';
      case ActivityType.basketball:
        return 'sports_basketball';
      case ActivityType.tennis:
        return 'sports_tennis';
      case ActivityType.soccer:
        return 'sports_soccer';
      case ActivityType.dancing:
        return 'nightlife';
      case ActivityType.boxing:
        return 'sports_mma';
      case ActivityType.climbing:
        return 'terrain';
      case ActivityType.skiing:
        return 'downhill_skiing';
      case ActivityType.snowboarding:
        return 'snowboarding';
      case ActivityType.elliptical:
        return 'ellipse';
      case ActivityType.stairmaster:
        return 'stairs';
      case ActivityType.other:
        return 'more_horiz';
    }
  }
}
