import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/database/entities.dart';
import '../../../core/database/enums.dart';

class ProgramSeeder {
  static const _uuid = Uuid();

  // ==========================================
  // 1. TỪ ĐIỂN BÀI TẬP & PHÂN LOẠI (SMART DICTIONARY)
  // ==========================================
  static const exWarmUp = {"id": "d85332c1-01e4-4845-9d1d-bb814e36f7d2", "name": "exercises.name_warm_up", "cat": "WARMUP"};

  // 1.1 HEAVY COMPOUND
  static const exBBBench = {"id": "508e26a0-5adc-485a-8114-256b9e878fcb", "name": "exercises.name_bench_press", "cat": "HEAVY"};
  static const exOHP = {"id": "a8922fc8-2235-4181-b637-2e2af59de8f9", "name": "exercises.name_overhead_press", "cat": "HEAVY"};
  static const exBBRow = {"id": "bade7b92-d6b0-4b2f-84cd-e65d9a89d7d9", "name": "exercises.name_barbell_row", "cat": "HEAVY"};
  static const exSquat = {"id": "f3e5a775-5fc7-4d2b-bf67-ece1d8ee18bc", "name": "exercises.name_barbell_squat", "cat": "HEAVY"};
  static const exBBRDL = {"id": "a67467c2-3c5e-4f64-8cb0-e9a203e4d07c", "name": "exercises.name_romanian_deadlift", "cat": "HEAVY"};
  static const exDeadlift = {"id": "9e449cdb-78c4-4f9c-baeb-147a1c603013", "name": "exercises.name_deadlift", "cat": "HEAVY"};
  static const exDBDeadlift = {"id": "95044ae2-30bf-4c74-8568-1d97bf67514b", "name": "exercises.name_dumbbell_deadlift", "cat": "HEAVY"};
  static const exIncBBPress = {"id": "0d186432-a941-4c10-989e-da1dc5cdde8c", "name": "exercises.name_incline_barbell_press", "cat": "HEAVY"};
  static const exDecBBPress = {"id": "6dc5360e-8730-4006-a7ec-76bdb7333067", "name": "exercises.name_decline_bench_press", "cat": "HEAVY"};
  static const exTBarRow = {"id": "22222222-2222-4222-a222-222222222222", "name": "exercises.name_t_bar_row", "cat": "HEAVY"}; // Add this key if missing

  // 1.2 COMPOUND
  static const exIncDBPress = {"id": "fc0ba6d5-e012-4f95-a474-b042e69ceefd", "name": "exercises.name_incline_dumbbell_press", "cat": "COMPOUND"};
  static const exLatPulldown = {"id": "d41fb318-8384-48f7-9b98-b478b1db7195", "name": "exercises.name_lat_pulldown", "cat": "COMPOUND"};
  static const exLegPress = {"id": "414e7822-27e7-454b-9315-3eac5310ecd3", "name": "exercises.name_leg_press", "cat": "COMPOUND"};
  static const exMachineChest = {"id": "9f5b6da2-3720-420b-a7d6-0e45d82493eb", "name": "exercises.name_machine_chest_press", "cat": "COMPOUND"};
  static const exArnoldPress = {"id": "4b12db95-76eb-4efb-87cf-1f03ff88886e", "name": "exercises.name_arnold_press", "cat": "COMPOUND"};
  static const exSeatedRow = {"id": "e48e9a3e-5bbd-470c-9440-920787de5087", "name": "exercises.name_seated_cable_row_vgrip", "cat": "COMPOUND"};
  static const exHipThrust = {"id": "18724e3a-530d-4b92-b2d4-35ee8fbe25c6", "name": "exercises.name_hip_thrust", "cat": "COMPOUND"};
  static const exDBBench = {"id": "3422038b-5862-4c7f-944e-cc69cce8f6f9", "name": "exercises.name_dumbbell_bench_press", "cat": "COMPOUND"};
  static const exDBShoulder = {"id": "ca8e4db1-4db2-4aca-84e5-c27e1f8d1985", "name": "exercises.name_dumbbell_shoulder_press", "cat": "COMPOUND"};
  static const exOneArmRow = {"id": "5c4e20d3-53ad-484b-aca5-c1276edb8146", "name": "exercises.name_one_arm_row", "cat": "COMPOUND"};
  static const exBentOverDBRow = {"id": "dae37013-80ab-43df-b632-1df0a136b794", "name": "exercises.name_dumbbell_row", "cat": "COMPOUND"};
  static const exGobletSquat = {"id": "fb86219b-df55-4ff2-a887-7936339c0b77", "name": "exercises.name_goblet_squat", "cat": "COMPOUND"};
  static const exDBLunge = {"id": "f4e80cc1-970a-4558-8ca6-d6c4679ac1fe", "name": "exercises.name_dumbbell_lunges", "cat": "COMPOUND"};
  static const exDBRDL = {"id": "f29bb1ee-67df-448d-804f-3474c0a63f7e", "name": "exercises.name_dumbbell_rdl", "cat": "COMPOUND"};
  static const exUprightRow = {"id": "f38ab095-d21a-4757-9fa8-ae4f0f51afca", "name": "exercises.name_upright_row", "cat": "COMPOUND"};
  static const exBulgarian = {"id": "ea41efeb-f94f-4c67-9666-29b865a487f8", "name": "exercises.name_bulgarian_split_squat", "cat": "COMPOUND"};
  static const exHackSquat = {"id": "33333333-3333-4333-a333-333333333333", "name": "exercises.name_hack_squat", "cat": "COMPOUND"}; // Add this key if missing
  static const exCloseGripPulldown = {"id": "e43fbff4-565a-413f-8e1f-77d7a1bac160", "name": "exercises.name_close_grip_pulldown", "cat": "COMPOUND"};

  // 1.3 ISOLATION
  static const exTricepPushdown = {"id": "99365bca-e3e2-4dde-9644-340ce03da818", "name": "exercises.name_tricep_pushdown", "cat": "ISOLATION"};
  static const exFacePull = {"id": "9c3feaab-d131-4ef8-8e50-9dfa217a8cd3", "name": "exercises.name_face_pull", "cat": "ISOLATION"};
  static const exBBCurl = {"id": "e8a9a1fb-920d-4b44-a0f4-c383ae2841b9", "name": "exercises.name_barbell_curl", "cat": "ISOLATION"};
  static const exLegCurl = {"id": "58f4ef16-98c0-4e2c-b8a1-0b009c56a4f0", "name": "exercises.name_lying_leg_curl", "cat": "ISOLATION"};
  static const exStandingCalf = {"id": "12173a58-7624-42bb-a69f-903f1666fd4f", "name": "exercises.name_standing_calf_raise", "cat": "ISOLATION"};
  static const exSkullCrushers = {"id": "917be2f9-7589-4c20-a53e-240256b2bfd1", "name": "exercises.name_skull_crushers", "cat": "ISOLATION"};
  static const exRevPecDeck = {"id": "0b84ef74-fcab-4ff8-9084-b50e4d3732c3", "name": "exercises.name_reverse_pec_deck", "cat": "ISOLATION"};
  static const exHammerCurl = {"id": "b9558187-4ed6-46e0-b2c9-cfbb6127b4a6", "name": "exercises.name_hammer_curl", "cat": "ISOLATION"};
  static const exLegExt = {"id": "8cf8c398-24e1-4001-996f-b2bfffd2743b", "name": "exercises.name_leg_extension", "cat": "ISOLATION"};
  static const exSeatedCalf = {"id": "dd36ebd9-005f-47a6-8a06-dfb22bc10bd4", "name": "exercises.name_seated_calf_raise", "cat": "ISOLATION"};
  static const exIncDBFly = {"id": "3cd6e253-a663-45ed-90bb-1ed687aab21f", "name": "exercises.name_incline_dumbbell_fly", "cat": "ISOLATION"};
  static const exOverheadTricep = {"id": "7b0d0cb4-cf83-4a5a-988d-29c8e91baf13", "name": "exercises.name_overhead_triceps_extension", "cat": "ISOLATION"};
  static const exRevDBFly = {"id": "4a4483c5-c227-4e86-96d6-99b93b80fb48", "name": "exercises.name_dumbbell_reverse_fly", "cat": "ISOLATION"};
  static const exDBCurl = {"id": "82ed3c39-e58f-4b9f-aa14-89354ed46d04", "name": "exercises.name_dumbbell_curl", "cat": "ISOLATION"};
  static const exDBFlyes = {"id": "65421940-c135-4cd3-a9b3-10878b1bac2a", "name": "exercises.name_dumbbell_fly", "cat": "ISOLATION"};
  static const exDBShrug = {"id": "fc6651e0-062a-43d8-ad3b-99f90b2370bc", "name": "exercises.name_dumbbell_shrugs", "cat": "ISOLATION"};
  static const exCableCrunch = {"id": "0824045c-64a5-40af-aa50-8063282ace68", "name": "exercises.name_cable_crunch", "cat": "ISOLATION"};
  static const exLatRaise = {"id": "5a023679-9325-4540-954b-b0f13133588c", "name": "exercises.name_dumbbell_lateral_raise", "cat": "ISOLATION"};
  static const exCableCrossover = {"id": "11111111-1111-4111-a111-111111111111", "name": "exercises.name_cable_crossover", "cat": "ISOLATION"}; // Add this key
  static const exPreacherCurl = {"id": "44444444-4444-4444-a444-444444444444", "name": "exercises.name_preacher_curl", "cat": "ISOLATION"}; // Add this key
  static const exPecDeckFly = {"id": "55555555-5555-4555-a555-555555555555", "name": "exercises.name_pec_deck_fly", "cat": "ISOLATION"}; // Add this key
  static const exSeatedLegCurl = {"id": "66666666-6666-4666-a666-666666666666", "name": "exercises.name_seated_leg_curl", "cat": "ISOLATION"}; // Add this key
  static const exCableKickback = {"id": "e459fad7-fd37-42f8-96eb-a1efe1a12473", "name": "exercises.name_cable_kickback", "cat": "ISOLATION"};
  static const exCableLatRaise = {"id": "b0abae7a-09f7-4ee4-83a3-ac1c9d5a53ba", "name": "exercises.name_cable_lateral_raise", "cat": "ISOLATION"};
  static const exHighToLowFly = {"id": "5da74b33-ee77-42ee-ba1a-603d57bdc40e", "name": "exercises.name_low_to_high_fly", "cat": "ISOLATION"};

  // 1.4 BODYWEIGHT HEAVY
  static const exPullUp = {"id": "ff24e899-1f8a-4b22-871b-531c4b3ecc73", "name": "exercises.name_pull_up", "cat": "BW_HEAVY"};
  static const exDips = {"id": "a5088451-198b-4a23-8231-7f587c91aa45", "name": "exercises.name_chest_dips", "cat": "BW_HEAVY"};
  static const exPikePushUp = {"id": "3518b81c-a6e8-4dcc-a948-29c5c12ef36c", "name": "exercises.name_pike_push_up", "cat": "BW_HEAVY"};
  static const exChinUp = {"id": "3422da8e-b1ad-4e56-9478-74888f491c65", "name": "exercises.name_chin_up", "cat": "BW_HEAVY"};
  static const exAustralianPullUp = {"id": "be7244b3-aa99-4e5b-ad9d-74ebb4d654e6", "name": "exercises.name_australian_pull_up", "cat": "BW_HEAVY"};

  // 1.5 BODYWEIGHT LIGHT
  static const exAirSquat = {"id": "ec90bdf1-c111-4613-84ba-fc152acffe60", "name": "exercises.name_squat", "cat": "BW_LIGHT"};
  static const exPushUp = {"id": "a2280d84-ea7d-4f4c-9d36-8ddc98c8b35e", "name": "exercises.name_push_up", "cat": "BW_LIGHT"};
  static const exBenchDip = {"id": "0d109cfd-2936-498c-b5b8-c38d3a30f892", "name": "exercises.name_bench_dips", "cat": "BW_LIGHT"};
  static const exGluteBridge = {"id": "44458889-234d-4df3-93e0-449272a20413", "name": "exercises.name_glute_bridge", "cat": "BW_LIGHT"};
  static const exCrunch = {"id": "e4cda12e-8ea0-4465-8f95-eec063c38ce1", "name": "exercises.name_crunch", "cat": "BW_LIGHT"};
  static const exBicycleCrunch = {"id": "b9d26065-e9bc-41ce-8e52-ce8ac5ddc393", "name": "exercises.name_bicycle_crunches", "cat": "BW_LIGHT"};
  static const exIncPushUp = {"id": "393e1425-a901-43b9-80d3-a4b7f12bc624", "name": "exercises.name_incline_push_up", "cat": "BW_LIGHT"};
  static const exLyingLegRaise = {"id": "ef3af3da-90e2-40aa-adf8-beda1af2cb06", "name": "exercises.name_lying_leg_raise", "cat": "BW_LIGHT"};
  static const exDecPushUp = {"id": "048d702f-26c6-4e21-ae5e-bef75969dd12", "name": "exercises.name_decline_push_up", "cat": "BW_LIGHT"};
  static const exDiamondPushUp = {"id": "14302a59-3b62-4d00-92ee-9de37fe62d1d", "name": "exercises.name_diamond_push_up", "cat": "BW_LIGHT"};
  static const exHangingLegRaise = {"id": "1677ac52-6281-4de1-85bd-0d0c83282263", "name": "exercises.name_hanging_leg_raise", "cat": "BW_LIGHT"};
  static const exHyperextensions = {"id": "b19571dc-57f2-488e-9ce0-883605f3fa86", "name": "exercises.name_hyperextensions", "cat": "BW_LIGHT"};
  static const exRussianTwist = {"id": "cca38797-cdf4-463a-8942-1d56d9356412", "name": "exercises.name_russian_twist", "cat": "BW_LIGHT"};

  // 1.6 TIME & HIIT
  static const exPlank = {"id": "604df66b-057d-413f-8d06-02559815bdbc", "name": "exercises.name_plank", "cat": "TIME_CORE"};
  static const exHighKnees = {"id": "16e6b6a7-c9a3-4d5e-a10b-9355914620c4", "name": "exercises.name_high_knees", "cat": "TIME_CORE"};
  static const exBurpees = {"id": "dadedcf5-c336-41f4-951f-b78e053abafa", "name": "exercises.name_burpees", "cat": "TIME_CORE"};
  static const exJumpingJack = {"id": "45a788c4-f9d8-47f4-91e2-b881fb57728d", "name": "exercises.name_jumping_jacks", "cat": "TIME_CORE"};
  static const exMountainClimber = {"id": "c4ed4325-1172-4461-bba3-20f6874cbe84", "name": "exercises.name_mountain_climbers", "cat": "TIME_CORE"};
  static const exJumpRope = {"id": "a3eca085-d03f-4eab-8f88-93e4a0c24166", "name": "exercises.name_jump_rope", "cat": "TIME_CORE"};
  static const exSuperman = {"id": "d530ca20-9f5c-4374-876e-3ca436abdd93", "name": "exercises.name_superman", "cat": "TIME_CORE"};

  // 1.7 CARDIO
  static const exTreadmill = {"id": "e0f0dc0b-3ba7-4ea8-91a7-2d6f95993f7f", "name": "exercises.name_treadmill", "cat": "CARDIO"};
  static const exCycling = {"id": "6b05600c-d90c-49e4-b7bc-76a65fdcbe7b", "name": "exercises.name_indoor_cycling", "cat": "CARDIO"};
  static const exStairMaster = {"id": "aaa1a546-7912-4632-9574-4e5cf05b249e", "name": "exercises.name_stair_climber", "cat": "CARDIO"};

  // ==========================================
  // 2. AUTO-SCALING LOGIC
  // ==========================================
  static Map<String, dynamic> _ex(Map<String, String> exInfo, String difficulty) {
    int sets = 3; int reps = 10; int time = 0; int rest = 90;
    String cat = exInfo["cat"] ?? "ISOLATION";

    switch (cat) {
      case "WARMUP":
        sets = 1; time = 300; reps = 0; rest = 0; break;
      case "HEAVY":
        if (difficulty == "BEGINNER") { sets = 3; reps = 8; rest = 120; }
        else if (difficulty == "INTERMEDIATE") { sets = 4; reps = 6; rest = 150; }
        else { sets = 5; reps = 5; rest = 180; }
        break;
      case "COMPOUND":
        if (difficulty == "BEGINNER") { sets = 3; reps = 10; rest = 90; }
        else if (difficulty == "INTERMEDIATE") { sets = 4; reps = 10; rest = 120; }
        else { sets = 4; reps = 8; rest = 120; }
        break;
      case "BW_HEAVY":
        if (difficulty == "BEGINNER") { sets = 3; reps = 5; rest = 120; }
        else if (difficulty == "INTERMEDIATE") { sets = 3; reps = 8; rest = 120; }
        else { sets = 4; reps = 12; rest = 120; }
        break;
      case "BW_LIGHT":
        if (difficulty == "BEGINNER") { sets = 2; reps = 12; rest = 60; }
        else if (difficulty == "INTERMEDIATE") { sets = 3; reps = 15; rest = 60; }
        else { sets = 4; reps = 20; rest = 60; }
        break;
      case "ISOLATION":
        if (difficulty == "BEGINNER") { sets = 2; reps = 12; rest = 60; }
        else if (difficulty == "INTERMEDIATE") { sets = 3; reps = 12; rest = 90; }
        else { sets = 4; reps = 15; rest = 90; }
        break;
      case "TIME_CORE":
        reps = 0;
        if (difficulty == "BEGINNER") { sets = 3; time = 30; rest = 45; }
        else if (difficulty == "INTERMEDIATE") { sets = 4; time = 45; rest = 45; }
        else { sets = 5; time = 60; rest = 60; }
        break;
      case "CARDIO":
        reps = 0; rest = 0;
        if (difficulty == "BEGINNER") { sets = 1; time = 600; }
        else if (difficulty == "INTERMEDIATE") { sets = 1; time = 900; }
        else { sets = 1; time = 1200; }
        break;
    }

    return {
      "id": _uuid.v4(),
      "exercise": {"id": exInfo["id"], "name": exInfo["name"]},
      "sets": List.generate(sets, (_) => {
        "id": _uuid.v4(),
        "reps": reps,
        "weight": 0.0,
        "time_seconds": time,
        "distance_km": 0.0,
        "steps": 0,
        "rest_time_seconds": rest,
        "type": "NORMAL",
        "is_completed": false
      })
    };
  }

  static Map<String, dynamic> _buildRoutine(String nameKey, List<Map<String, dynamic>> exercises) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      "id": _uuid.v4(), 
      "name": "routines.$nameKey",
      "start_time": now,
      "payload": {"schema_version": "1.0", "exercises": exercises, "muscle_distribution": {}},
      "sync_status": "PENDING", 
      "updated_at": now, 
      "is_deleted": false
    };
  }

  static List<WorkoutProgramEntity> _generate3Levels(
      String baseKey, WorkoutEnvironment env, WorkoutGoal goal, List<Map<String, dynamic>> Function(String diff) routineBuilder) {
    return [
      WorkoutProgramEntity(
        id: _uuid.v4(), 
        name: "programs.${baseKey}_beg_name", 
        description: "programs.${baseKey}_beg_desc",
        environment: env, difficulty: "BEGINNER", goal: goal,
        routinesJson: jsonEncode(routineBuilder("BEGINNER")), updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      WorkoutProgramEntity(
        id: _uuid.v4(), 
        name: "programs.${baseKey}_int_name", 
        description: "programs.${baseKey}_int_desc",
        environment: env, difficulty: "INTERMEDIATE", goal: goal,
        routinesJson: jsonEncode(routineBuilder("INTERMEDIATE")), updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      WorkoutProgramEntity(
        id: _uuid.v4(), 
        name: "programs.${baseKey}_adv_name", 
        description: "programs.${baseKey}_adv_desc",
        environment: env, difficulty: "ADVANCED", goal: goal,
        routinesJson: jsonEncode(routineBuilder("ADVANCED")), updatedAt: DateTime.now().millisecondsSinceEpoch,
      )
    ];
  }

  // ==========================================
  // 3. ĐỊNH NGHĨA PROGRAMS VỚI LOGIC CẤP ĐỘ RÕ RÀNG
  // ==========================================
  static List<WorkoutProgramEntity> getInitialPrograms() {
    List<WorkoutProgramEntity> allPrograms = [];

    // --- A. GÓI PPL (Đẩy / Kéo / Chân) ---
    allPrograms.addAll(_generate3Levels("ppl_gym", WorkoutEnvironment.GYM, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exMachineChest, diff), _ex(exPecDeckFly, diff), _ex(exArnoldPress, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exLatPulldown, diff), _ex(exSeatedRow, diff), _ex(exBBCurl, diff), _ex(exFacePull, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exSeatedLegCurl, diff), _ex(exStandingCalf, diff)]),
        ];
      } else if (diff == "INTERMEDIATE") {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exBBBench, diff), _ex(exOHP, diff), _ex(exIncDBPress, diff), _ex(exTricepPushdown, diff), _ex(exLatRaise, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exPullUp, diff), _ex(exBBRow, diff), _ex(exSeatedRow, diff), _ex(exBBCurl, diff), _ex(exFacePull, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exSquat, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exLegCurl, diff), _ex(exStandingCalf, diff)]),
          _buildRoutine("push_2", [_ex(exWarmUp, diff), _ex(exOHP, diff), _ex(exDBBench, diff), _ex(exCableCrossover, diff), _ex(exSkullCrushers, diff), _ex(exLatRaise, diff)]),
          _buildRoutine("pull_2", [_ex(exWarmUp, diff), _ex(exLatPulldown, diff), _ex(exTBarRow, diff), _ex(exRevPecDeck, diff), _ex(exHammerCurl, diff), _ex(exDBShrug, diff)]),
          _buildRoutine("legs_2", [_ex(exWarmUp, diff), _ex(exBBRDL, diff), _ex(exHackSquat, diff), _ex(exSeatedLegCurl, diff), _ex(exSeatedCalf, diff)]),
        ];
      } else {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exBBBench, diff), _ex(exIncDBPress, diff), _ex(exCableCrossover, diff), _ex(exOHP, diff), _ex(exLatRaise, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exPullUp, diff), _ex(exBBRow, diff), _ex(exLatPulldown, diff), _ex(exFacePull, diff), _ex(exPreacherCurl, diff), _ex(exHammerCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exSquat, diff), _ex(exHackSquat, diff), _ex(exLegExt, diff), _ex(exBBRDL, diff), _ex(exLegCurl, diff), _ex(exStandingCalf, diff)]),
          _buildRoutine("push_2", [_ex(exWarmUp, diff), _ex(exOHP, diff), _ex(exArnoldPress, diff), _ex(exDBBench, diff), _ex(exPecDeckFly, diff), _ex(exLatRaise, diff), _ex(exSkullCrushers, diff)]),
          _buildRoutine("pull_2", [_ex(exWarmUp, diff), _ex(exTBarRow, diff), _ex(exLatPulldown, diff), _ex(exSeatedRow, diff), _ex(exRevPecDeck, diff), _ex(exBBCurl, diff), _ex(exDBShrug, diff)]),
          _buildRoutine("legs_2", [_ex(exWarmUp, diff), _ex(exDeadlift, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exSeatedLegCurl, diff), _ex(exSeatedCalf, diff), _ex(exStandingCalf, diff)]),
        ];
      }
    }));

    allPrograms.addAll(_generate3Levels("ppl_db", WorkoutEnvironment.HOME_DUMBBELL, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exDBShoulder, diff), _ex(exOverheadTricep, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exOneArmRow, diff), _ex(exBentOverDBRow, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBLunge, diff), _ex(exStandingCalf, diff)]),
        ];
      } else {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exDBShoulder, diff), _ex(exIncDBFly, diff), _ex(exOverheadTricep, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exOneArmRow, diff), _ex(exBentOverDBRow, diff), _ex(exRevDBFly, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBLunge, diff), _ex(exDBRDL, diff), _ex(exStandingCalf, diff)]),
          _buildRoutine("push_2", [_ex(exWarmUp, diff), _ex(exIncDBPress, diff), _ex(exArnoldPress, diff), _ex(exDBFlyes, diff), _ex(exBenchDip, diff)]),
          _buildRoutine("pull_2", [_ex(exWarmUp, diff), _ex(exUprightRow, diff), _ex(exDBShrug, diff), _ex(exOneArmRow, diff), _ex(exHammerCurl, diff)]),
          _buildRoutine("legs_2", [_ex(exWarmUp, diff), _ex(exDBDeadlift, diff), _ex(exBulgarian, diff), _ex(exGluteBridge, diff), _ex(exStandingCalf, diff)]),
        ];
      }
    }));

    // --- B. GÓI UPPER / LOWER ---
    allPrograms.addAll(_generate3Levels("ul_gym", WorkoutEnvironment.GYM, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exMachineChest, diff), _ex(exLatPulldown, diff), _ex(exArnoldPress, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exSeatedLegCurl, diff), _ex(exCrunch, diff)]),
        ];
      } else {
        return [
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exBBBench, diff), _ex(exBBRow, diff), _ex(exOHP, diff), _ex(exLatRaise, diff), _ex(exBBCurl, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exSquat, diff), _ex(exBBRDL, diff), _ex(exLegPress, diff), _ex(exStandingCalf, diff), _ex(exCrunch, diff)]),
          _buildRoutine("upper_2", [_ex(exWarmUp, diff), _ex(exPullUp, diff), _ex(exIncDBPress, diff), _ex(exTBarRow, diff), _ex(exFacePull, diff), _ex(exHammerCurl, diff), _ex(exSkullCrushers, diff)]),
          _buildRoutine("lower_2", [_ex(exWarmUp, diff), _ex(exDeadlift, diff), _ex(exHackSquat, diff), _ex(exLegCurl, diff), _ex(exSeatedCalf, diff), _ex(exPlank, diff)]),
        ];
      }
    }));

    allPrograms.addAll(_generate3Levels("ul_db", WorkoutEnvironment.HOME_DUMBBELL, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exOneArmRow, diff), _ex(exDBShoulder, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBRDL, diff), _ex(exStandingCalf, diff), _ex(exCrunch, diff)]),
        ];
      } else {
        return [
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exOneArmRow, diff), _ex(exDBShoulder, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBRDL, diff), _ex(exStandingCalf, diff), _ex(exCrunch, diff)]),
          _buildRoutine("upper_2", [_ex(exWarmUp, diff), _ex(exIncDBFly, diff), _ex(exBentOverDBRow, diff), _ex(exRevDBFly, diff), _ex(exOverheadTricep, diff)]),
          _buildRoutine("lower_2", [_ex(exWarmUp, diff), _ex(exDBLunge, diff), _ex(exDBDeadlift, diff), _ex(exBulgarian, diff), _ex(exBicycleCrunch, diff)]),
        ];
      }
    }));

    // --- C. GÓI TOÀN THÂN (Full Body) ---
    allPrograms.addAll(_generate3Levels("fb_gym", WorkoutEnvironment.GYM, WorkoutGoal.STRENGTH, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exLegPress, diff), _ex(exMachineChest, diff), _ex(exLatPulldown, diff), _ex(exCrunch, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exHackSquat, diff), _ex(exSeatedRow, diff), _ex(exArnoldPress, diff), _ex(exStandingCalf, diff)]),
        ];
      } else {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exSquat, diff), _ex(exBBBench, diff), _ex(exBBRow, diff), _ex(exBBCurl, diff), _ex(exCrunch, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exDeadlift, diff), _ex(exOHP, diff), _ex(exPullUp, diff), _ex(exTricepPushdown, diff), _ex(exStandingCalf, diff)]),
          _buildRoutine("full_3", [_ex(exWarmUp, diff), _ex(exHackSquat, diff), _ex(exIncDBPress, diff), _ex(exTBarRow, diff), _ex(exLatRaise, diff), _ex(exHammerCurl, diff)]),
        ];
      }
    }));

    allPrograms.addAll(_generate3Levels("fb_db", WorkoutEnvironment.HOME_DUMBBELL, WorkoutGoal.STRENGTH, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBBench, diff), _ex(exOneArmRow, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exDBLunge, diff), _ex(exDBFlyes, diff), _ex(exBentOverDBRow, diff), _ex(exDBShoulder, diff)]),
        ];
      } else {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBBench, diff), _ex(exOneArmRow, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exDBLunge, diff), _ex(exDBFlyes, diff), _ex(exBentOverDBRow, diff), _ex(exDBShoulder, diff)]),
          _buildRoutine("full_3", [_ex(exWarmUp, diff), _ex(exDBDeadlift, diff), _ex(exArnoldPress, diff), _ex(exUprightRow, diff), _ex(exOverheadTricep, diff)]),
        ];
      }
    }));

    allPrograms.addAll(_generate3Levels("fb_bw", WorkoutEnvironment.HOME_BODYWEIGHT, WorkoutGoal.STRENGTH, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exAirSquat, diff), _ex(exPushUp, diff), _ex(exGluteBridge, diff), _ex(exPlank, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exBulgarian, diff), _ex(exIncPushUp, diff), _ex(exCrunch, diff), _ex(exHighKnees, diff)]),
        ];
      } else {
        return [
          _buildRoutine("full_1", [_ex(exWarmUp, diff), _ex(exAirSquat, diff), _ex(exPushUp, diff), _ex(exGluteBridge, diff), _ex(exPlank, diff)]),
          _buildRoutine("full_2", [_ex(exWarmUp, diff), _ex(exBulgarian, diff), _ex(exIncPushUp, diff), _ex(exCrunch, diff), _ex(exHighKnees, diff)]),
          _buildRoutine("full_3", [_ex(exWarmUp, diff), _ex(exLyingLegRaise, diff), _ex(exPikePushUp, diff), _ex(exPullUp, diff), _ex(exBurpees, diff)]),
        ];
      }
    }));

    // --- D. GÓI PPL & UL KẾT HỢP ---
    allPrograms.addAll(_generate3Levels("combo_gym", WorkoutEnvironment.GYM, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exMachineChest, diff), _ex(exArnoldPress, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exLatPulldown, diff), _ex(exSeatedRow, diff), _ex(exBBCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exStandingCalf, diff)]),
        ];
      } else {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exBBBench, diff), _ex(exOHP, diff), _ex(exDips, diff), _ex(exTricepPushdown, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exPullUp, diff), _ex(exBBRow, diff), _ex(exSeatedRow, diff), _ex(exHammerCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exSquat, diff), _ex(exLegPress, diff), _ex(exLegExt, diff), _ex(exStandingCalf, diff)]),
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exIncDBPress, diff), _ex(exLatPulldown, diff), _ex(exLatRaise, diff), _ex(exBBCurl, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exBBRDL, diff), _ex(exLegCurl, diff), _ex(exRevPecDeck, diff), _ex(exPlank, diff)]),
        ];
      }
    }));

    allPrograms.addAll(_generate3Levels("combo_db", WorkoutEnvironment.HOME_DUMBBELL, WorkoutGoal.BULK, (diff) {
      if (diff == "BEGINNER") {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exDBShoulder, diff), _ex(exOverheadTricep, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exOneArmRow, diff), _ex(exBentOverDBRow, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBLunge, diff), _ex(exStandingCalf, diff)]),
        ];
      } else {
        return [
          _buildRoutine("push_1", [_ex(exWarmUp, diff), _ex(exDBBench, diff), _ex(exDBShoulder, diff), _ex(exArnoldPress, diff), _ex(exOverheadTricep, diff)]),
          _buildRoutine("pull_1", [_ex(exWarmUp, diff), _ex(exOneArmRow, diff), _ex(exBentOverDBRow, diff), _ex(exRevDBFly, diff), _ex(exDBCurl, diff)]),
          _buildRoutine("legs_1", [_ex(exWarmUp, diff), _ex(exGobletSquat, diff), _ex(exDBLunge, diff), _ex(exStandingCalf, diff), _ex(exCrunch, diff)]),
          _buildRoutine("upper_1", [_ex(exWarmUp, diff), _ex(exIncDBFly, diff), _ex(exUprightRow, diff), _ex(exDBShoulder, diff), _ex(exHammerCurl, diff)]),
          _buildRoutine("lower_1", [_ex(exWarmUp, diff), _ex(exDBRDL, diff), _ex(exDBDeadlift, diff), _ex(exBulgarian, diff), _ex(exBicycleCrunch, diff)]),
        ];
      }
    }));

    // --- E. GÓI CARDIO & HIIT ---
    allPrograms.add(
      WorkoutProgramEntity(
        id: _uuid.v4(), 
        name: "programs.cardio_gym_int_name", 
        description: "programs.cardio_gym_int_desc",
        environment: WorkoutEnvironment.GYM, difficulty: "INTERMEDIATE", goal: WorkoutGoal.CUT,
        routinesJson: jsonEncode([
          _buildRoutine("cardio_1", [_ex(exWarmUp, "INTERMEDIATE"), _ex(exTreadmill, "INTERMEDIATE"), _ex(exCycling, "INTERMEDIATE"), _ex(exStairMaster, "INTERMEDIATE"), _ex(exCrunch, "INTERMEDIATE")]),
          _buildRoutine("hiit_1", [_ex(exWarmUp, "INTERMEDIATE"), _ex(exBurpees, "INTERMEDIATE"), _ex(exJumpingJack, "INTERMEDIATE"), _ex(exMountainClimber, "INTERMEDIATE")]),
          _buildRoutine("cardio_2", [_ex(exWarmUp, "INTERMEDIATE"), _ex(exTreadmill, "INTERMEDIATE"), _ex(exCycling, "INTERMEDIATE"), _ex(exStairMaster, "INTERMEDIATE"), _ex(exCrunch, "INTERMEDIATE")]),
          _buildRoutine("hiit_2", [_ex(exWarmUp, "INTERMEDIATE"), _ex(exHighKnees, "INTERMEDIATE"), _ex(exJumpRope, "INTERMEDIATE"), _ex(exBicycleCrunch, "INTERMEDIATE")]),
        ]),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      )
    );

    return allPrograms;
  }
}