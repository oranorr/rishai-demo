class WhoopEndpoints {
  String get whoopCycles => 'https://api.prod.whoop.com/developer/v1/cycle';
  String get bodyMeasurements =>
      'https://api.prod.whoop.com/developer/v1/user/measurement/body';
  String get workouts =>
      'https://api.prod.whoop.com/developer/v1/activity/workout';
  String get sleeps => 'https://api.prod.whoop.com/developer/v1/activity/sleep';
  String get recoveries => 'https://api.prod.whoop.com/developer/v1/recovery';
  String recoveryById({required int cycleId}) =>
      'https://api.prod.whoop.com/developer/v1/cycle/$cycleId/recovery';
  String cycleById({required int cycleId}) =>
      'https://api.prod.whoop.com/developer/v1/cycle/$cycleId';
}


// WORKOUT:
// {id: 1206115357, user_id: 57314, created_at: 2024-08-30T06:28:13.828Z, 
// updated_at: 2024-08-30T06:28:17.415Z, start: 2024-08-30T05:30:00.875Z, end: 2024-08-30T06:10:29.061Z, 
// timezone_offset: +04:00, sport_id: 44,
//  score_state: SCORED,
//   score: {strain: 11.6135, average_heart_rate: 121, max_heart_rate: 160, kilojoule: 1272.5337, 
//  percent_recorded: 100.0, distance_meter: 0.0, altitude_gain_meter: 0.0, altitude_change_meter: 0.0, 
//  zone_duration: {zone_zero_milli: 295123, zone_one_milli: 228790, 
// zone_two_milli: 821907, zone_three_milli: 823815, zone_four_milli: 258590, zone_five_milli: 0}}}

// CYCLE:
// {id: 650800430, user_id: 57314, created_at: 2024-08-30T00:11:37.374Z, updated_at: 2024-08-30T06:28:17.545Z,
//  start: 2024-08-29T18:07:34.295Z, end: null, timezone_offset: +04:00,
// score_state: SCORED, score: {strain: 16.434042, kilojoule: 9811.742, average_heart_rate: 73, max_heart_rate: 172}}

///SLEEP:
///{id: 1205779203, user_id: 57314, created_at: 2024-08-30T00:11:37.374Z, 
///updated_at: 2024-08-30T02:05:54.552Z, start: 2024-08-29T18:07:34.295Z, 
///end: 2024-08-30T02:04:08.842Z, timezone_offset: +04:00, nap: false,
/// score_state: SCORED, score: {stage_summary: 
/// {total_in_bed_time_milli: 28524127, total_awake_time_milli: 4123939, total_no_data_time_milli: 0, 
/// total_light_sleep_time_milli: 11681943, total_slow_wave_sleep_time_milli: 7267554, total_rem_sleep_time_milli: 5450691,
///  sleep_cycle_count: 6, disturbance_count: 10}, sleep_needed: {baseline_milli: 26920966, need_from_sleep_debt_milli: 7668000, 
/// need_from_recent_strain_milli: 3758873, need_from_recent_nap_milli: 0}, respiratory_rate: 14.082031,
///  sleep_performance_percentage: 64.0, sleep_consistency_percentage: 55.0, sleep_efficiency_percentage: 88.12612}}
/// 
/// 
/// RECOVERY:
/// {cycle_id: 650800430, sleep_id: 1205779203, user_id: 57314, created_at: 2024-08-30T00:11:37.374Z,
///  updated_at: 2024-08-30T02:05:54.552Z, 
/// score_state: SCORED, score: {user_calibrating: false, recovery_score: 52.0,
///  resting_heart_rate: 51.0, hrv_rmssd_milli: 74.21822, spo2_percentage: 95.42857, skin_temp_celsius: 33.863335}}
