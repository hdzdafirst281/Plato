// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ExerciseDao? _exerciseDaoInstance;

  FoodDao? _foodDaoInstance;

  WorkoutProgramDao? _workoutProgramDaoInstance;

  WorkoutDao? _workoutDaoInstance;

  NutritionDao? _nutritionDaoInstance;

  RewardClaimDao? _rewardClaimDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 6,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `exercises` (`id` TEXT NOT NULL, `idx` INTEGER, `name` TEXT NOT NULL, `primary_muscle` TEXT, `secondary_muscles` TEXT, `instructions` TEXT, `type` TEXT NOT NULL, `equipment` TEXT, `url_instructions` TEXT, `created_at` TEXT, `updated_at` TEXT, `is_deleted` INTEGER NOT NULL, `is_custom` INTEGER NOT NULL, `local_image_path` TEXT, `user_note` TEXT, `image` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `foods` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `cal` INTEGER NOT NULL, `p` INTEGER NOT NULL, `c` INTEGER NOT NULL, `f` INTEGER NOT NULL, `unit` TEXT NOT NULL, `amount` REAL NOT NULL, `mealType` TEXT, `updated_at` TEXT, `is_deleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `workout_programs_local` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `description` TEXT NOT NULL, `environment` TEXT NOT NULL, `difficulty` TEXT NOT NULL, `goal` TEXT NOT NULL, `routines` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `workout_history_local` (`id` TEXT NOT NULL, `routineId` TEXT, `programName` TEXT, `name` TEXT NOT NULL, `startTime` INTEGER NOT NULL, `endTime` INTEGER, `durationSeconds` INTEGER NOT NULL, `totalCaloriesBurned` INTEGER NOT NULL, `totalVolume` REAL NOT NULL, `totalSets` INTEGER NOT NULL, `rpe` INTEGER, `xpEarned` INTEGER NOT NULL, `prCount` INTEGER NOT NULL, `payloadJson` TEXT NOT NULL, `syncStatus` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `routines_local` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `programName` TEXT, `payloadJson` TEXT NOT NULL, `syncStatus` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `nutrition_daily_local` (`dateId` TEXT NOT NULL, `waterConsumedLiters` REAL NOT NULL, `breakfastJson` TEXT NOT NULL, `lunchJson` TEXT NOT NULL, `dinnerJson` TEXT NOT NULL, `snackJson` TEXT NOT NULL, `syncStatus` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`dateId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `scheduled_workouts_local` (`id` TEXT NOT NULL, `routineId` TEXT NOT NULL, `routineName` TEXT NOT NULL, `targetDateMillis` INTEGER NOT NULL, `isCompleted` INTEGER NOT NULL, `colorHex` TEXT, `recurrenceGroupId` TEXT, `syncStatus` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `reward_claims_local` (`id` TEXT NOT NULL, `sourceType` TEXT NOT NULL, `sourceRef` TEXT NOT NULL, `periodKey` TEXT NOT NULL, `actionType` TEXT NOT NULL, `xpAmount` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, `syncStatus` TEXT NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ExerciseDao get exerciseDao {
    return _exerciseDaoInstance ??= _$ExerciseDao(database, changeListener);
  }

  @override
  FoodDao get foodDao {
    return _foodDaoInstance ??= _$FoodDao(database, changeListener);
  }

  @override
  WorkoutProgramDao get workoutProgramDao {
    return _workoutProgramDaoInstance ??=
        _$WorkoutProgramDao(database, changeListener);
  }

  @override
  WorkoutDao get workoutDao {
    return _workoutDaoInstance ??= _$WorkoutDao(database, changeListener);
  }

  @override
  NutritionDao get nutritionDao {
    return _nutritionDaoInstance ??= _$NutritionDao(database, changeListener);
  }

  @override
  RewardClaimDao get rewardClaimDao {
    return _rewardClaimDaoInstance ??=
        _$RewardClaimDao(database, changeListener);
  }
}

class _$ExerciseDao extends ExerciseDao {
  _$ExerciseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _exerciseInsertionAdapter = InsertionAdapter(
            database,
            'exercises',
            (Exercise item) => <String, Object?>{
                  'id': item.id,
                  'idx': item.sortIndex,
                  'name': item.name,
                  'primary_muscle':
                      _muscleGroupConverter.encode(item.primaryMuscle),
                  'secondary_muscles':
                      _muscleGroupListConverter.encode(item.secondaryMuscles),
                  'instructions': item.instructions,
                  'type': _exerciseTypeConverter.encode(item.type),
                  'equipment': _equipmentConverter.encode(item.equipment),
                  'url_instructions': item.instructionVideoUrl,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_deleted': item.isDeleted ? 1 : 0,
                  'is_custom': item.isCustom ? 1 : 0,
                  'local_image_path': item.localImagePath,
                  'user_note': item.userNote,
                  'image': item.image
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Exercise> _exerciseInsertionAdapter;

  @override
  Future<List<Exercise>> getAllExercises() async {
    return _queryAdapter.queryList(
        'SELECT * FROM exercises WHERE is_deleted = 0',
        mapper: (Map<String, Object?> row) => Exercise(
            id: row['id'] as String,
            sortIndex: row['idx'] as int?,
            name: row['name'] as String,
            primaryMuscle:
                _muscleGroupConverter.decode(row['primary_muscle'] as String?),
            secondaryMuscles: _muscleGroupListConverter
                .decode(row['secondary_muscles'] as String?),
            instructions: row['instructions'] as String?,
            type: _exerciseTypeConverter.decode(row['type'] as String),
            equipment: _equipmentConverter.decode(row['equipment'] as String?),
            instructionVideoUrl: row['url_instructions'] as String?,
            createdAt: row['created_at'] as String?,
            updatedAt: row['updated_at'] as String?,
            isDeleted: (row['is_deleted'] as int) != 0,
            isCustom: (row['is_custom'] as int) != 0,
            localImagePath: row['local_image_path'] as String?,
            userNote: row['user_note'] as String?,
            image: row['image'] as String?));
  }

  @override
  Stream<List<Exercise>> watchAllExercises() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM exercises WHERE is_deleted = 0',
        mapper: (Map<String, Object?> row) => Exercise(
            id: row['id'] as String,
            sortIndex: row['idx'] as int?,
            name: row['name'] as String,
            primaryMuscle:
                _muscleGroupConverter.decode(row['primary_muscle'] as String?),
            secondaryMuscles: _muscleGroupListConverter
                .decode(row['secondary_muscles'] as String?),
            instructions: row['instructions'] as String?,
            type: _exerciseTypeConverter.decode(row['type'] as String),
            equipment: _equipmentConverter.decode(row['equipment'] as String?),
            instructionVideoUrl: row['url_instructions'] as String?,
            createdAt: row['created_at'] as String?,
            updatedAt: row['updated_at'] as String?,
            isDeleted: (row['is_deleted'] as int) != 0,
            isCustom: (row['is_custom'] as int) != 0,
            localImagePath: row['local_image_path'] as String?,
            userNote: row['user_note'] as String?,
            image: row['image'] as String?),
        queryableName: 'exercises',
        isView: false);
  }

  @override
  Future<List<Exercise>> searchExercisesLocal(String query) async {
    return _queryAdapter.queryList(
        'SELECT * FROM exercises WHERE name LIKE ?1 AND is_deleted = 0',
        mapper: (Map<String, Object?> row) => Exercise(
            id: row['id'] as String,
            sortIndex: row['idx'] as int?,
            name: row['name'] as String,
            primaryMuscle:
                _muscleGroupConverter.decode(row['primary_muscle'] as String?),
            secondaryMuscles: _muscleGroupListConverter
                .decode(row['secondary_muscles'] as String?),
            instructions: row['instructions'] as String?,
            type: _exerciseTypeConverter.decode(row['type'] as String),
            equipment: _equipmentConverter.decode(row['equipment'] as String?),
            instructionVideoUrl: row['url_instructions'] as String?,
            createdAt: row['created_at'] as String?,
            updatedAt: row['updated_at'] as String?,
            isDeleted: (row['is_deleted'] as int) != 0,
            isCustom: (row['is_custom'] as int) != 0,
            localImagePath: row['local_image_path'] as String?,
            userNote: row['user_note'] as String?,
            image: row['image'] as String?),
        arguments: [query]);
  }

  @override
  Future<void> deleteExercisesByIds(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM exercises WHERE id IN (' + _sqliteVariablesForIds + ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteCustomExerciseById(String id) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM exercises WHERE id = ?1 AND is_custom = 1',
        arguments: [id]);
  }

  @override
  Future<void> deleteAllCustomExercises() async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM exercises WHERE is_custom = 1');
  }

  @override
  Future<void> updateUserNote(
    String id,
    String note,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE exercises SET user_note = ?2 WHERE id = ?1',
        arguments: [id, note]);
  }

  @override
  Future<void> clearAllUserNotes() async {
    await _queryAdapter.queryNoReturn('UPDATE exercises SET user_note = NULL');
  }

  @override
  Future<void> insertAll(List<Exercise> exercises) async {
    await _exerciseInsertionAdapter.insertList(
        exercises, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertExercise(Exercise exercise) async {
    await _exerciseInsertionAdapter.insert(
        exercise, OnConflictStrategy.replace);
  }
}

class _$FoodDao extends FoodDao {
  _$FoodDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _foodResultInsertionAdapter = InsertionAdapter(
            database,
            'foods',
            (FoodResult item) => <String, Object?>{
                  'id': item.id,
                  'name': item.foodName,
                  'cal': item.baseCalories,
                  'p': item.baseProtein,
                  'c': item.baseCarbs,
                  'f': item.baseFat,
                  'unit': _foodUnitConverter.encode(item.measurementUnit),
                  'amount': item.consumedAmount,
                  'mealType': _mealTypeConverter.encode(item.assignedMealType),
                  'updated_at': item.lastUpdatedAt,
                  'is_deleted': item.isMarkedForDeletion ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FoodResult> _foodResultInsertionAdapter;

  @override
  Future<List<FoodResult>> getAllFoods() async {
    return _queryAdapter.queryList('SELECT * FROM foods',
        mapper: (Map<String, Object?> row) => FoodResult(
            id: row['id'] as String,
            foodName: row['name'] as String,
            baseCalories: row['cal'] as int,
            baseProtein: row['p'] as int,
            baseCarbs: row['c'] as int,
            baseFat: row['f'] as int,
            measurementUnit: _foodUnitConverter.decode(row['unit'] as String),
            consumedAmount: row['amount'] as double,
            assignedMealType:
                _mealTypeConverter.decode(row['mealType'] as String?),
            lastUpdatedAt: row['updated_at'] as String?,
            isMarkedForDeletion: (row['is_deleted'] as int) != 0));
  }

  @override
  Future<void> deleteFoodById(String id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM foods WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<void> insertOrReplaceFood(FoodResult food) async {
    await _foodResultInsertionAdapter.insert(food, OnConflictStrategy.replace);
  }
}

class _$WorkoutProgramDao extends WorkoutProgramDao {
  _$WorkoutProgramDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _workoutProgramEntityInsertionAdapter = InsertionAdapter(
            database,
            'workout_programs_local',
            (WorkoutProgramEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'description': item.description,
                  'environment':
                      _workoutEnvironmentConverter.encode(item.environment),
                  'difficulty': item.difficulty,
                  'goal': _workoutGoalConverter.encode(item.goal),
                  'routines': item.routinesJson,
                  'updatedAt': item.updatedAt
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WorkoutProgramEntity>
      _workoutProgramEntityInsertionAdapter;

  @override
  Future<List<WorkoutProgramEntity>> getAllPrograms() async {
    return _queryAdapter.queryList('SELECT * FROM workout_programs_local',
        mapper: (Map<String, Object?> row) => WorkoutProgramEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            environment: _workoutEnvironmentConverter
                .decode(row['environment'] as String),
            difficulty: row['difficulty'] as String,
            goal: _workoutGoalConverter.decode(row['goal'] as String),
            routinesJson: row['routines'] as String,
            updatedAt: row['updatedAt'] as int));
  }

  @override
  Stream<List<WorkoutProgramEntity>> watchAllPrograms() {
    return _queryAdapter.queryListStream('SELECT * FROM workout_programs_local',
        mapper: (Map<String, Object?> row) => WorkoutProgramEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            environment: _workoutEnvironmentConverter
                .decode(row['environment'] as String),
            difficulty: row['difficulty'] as String,
            goal: _workoutGoalConverter.decode(row['goal'] as String),
            routinesJson: row['routines'] as String,
            updatedAt: row['updatedAt'] as int),
        queryableName: 'workout_programs_local',
        isView: false);
  }

  @override
  Future<void> deleteProgramsByIds(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM workout_programs_local WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> insertPrograms(List<WorkoutProgramEntity> programs) async {
    await _workoutProgramEntityInsertionAdapter.insertList(
        programs, OnConflictStrategy.replace);
  }
}

class _$WorkoutDao extends WorkoutDao {
  _$WorkoutDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _scheduledWorkoutEntityInsertionAdapter = InsertionAdapter(
            database,
            'scheduled_workouts_local',
            (ScheduledWorkoutEntity item) => <String, Object?>{
                  'id': item.id,
                  'routineId': item.routineId,
                  'routineName': item.routineName,
                  'targetDateMillis': item.targetDateMillis,
                  'isCompleted': item.isCompleted ? 1 : 0,
                  'colorHex': item.colorHex,
                  'recurrenceGroupId': item.recurrenceGroupId,
                  'syncStatus': item.syncStatus,
                  'updatedAt': item.updatedAt,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _routineEntityInsertionAdapter = InsertionAdapter(
            database,
            'routines_local',
            (RoutineEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'programName': item.programName,
                  'payloadJson': item.payloadJson,
                  'syncStatus': item.syncStatus,
                  'updatedAt': item.updatedAt,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _workoutSessionEntityInsertionAdapter = InsertionAdapter(
            database,
            'workout_history_local',
            (WorkoutSessionEntity item) => <String, Object?>{
                  'id': item.id,
                  'routineId': item.routineId,
                  'programName': item.programName,
                  'name': item.name,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'durationSeconds': item.durationSeconds,
                  'totalCaloriesBurned': item.totalCaloriesBurned,
                  'totalVolume': item.totalVolume,
                  'totalSets': item.totalSets,
                  'rpe': item.rpe,
                  'xpEarned': item.xpEarned,
                  'prCount': item.prCount,
                  'payloadJson': item.payloadJson,
                  'syncStatus': item.syncStatus,
                  'updatedAt': item.updatedAt,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduledWorkoutEntity>
      _scheduledWorkoutEntityInsertionAdapter;

  final InsertionAdapter<RoutineEntity> _routineEntityInsertionAdapter;

  final InsertionAdapter<WorkoutSessionEntity>
      _workoutSessionEntityInsertionAdapter;

  @override
  Stream<List<ScheduledWorkoutEntity>> watchAllScheduledWorkouts() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM scheduled_workouts_local WHERE isDeleted = 0',
        mapper: (Map<String, Object?> row) => ScheduledWorkoutEntity(
            id: row['id'] as String,
            routineId: row['routineId'] as String,
            routineName: row['routineName'] as String,
            targetDateMillis: row['targetDateMillis'] as int,
            isCompleted: (row['isCompleted'] as int) != 0,
            colorHex: row['colorHex'] as String?,
            recurrenceGroupId: row['recurrenceGroupId'] as String?,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'scheduled_workouts_local',
        isView: false);
  }

  @override
  Future<void> deleteScheduledWorkout(String id) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM scheduled_workouts_local WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> deleteScheduledWorkoutGroup(String groupId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM scheduled_workouts_local WHERE recurrenceGroupId = ?1',
        arguments: [groupId]);
  }

  @override
  Stream<List<RoutineEntity>> watchAllRoutines() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM routines_local WHERE isDeleted = 0 ORDER BY id ASC',
        mapper: (Map<String, Object?> row) => RoutineEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            programName: row['programName'] as String?,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'routines_local',
        isView: false);
  }

  @override
  Future<List<RoutineEntity>> getAllRoutines() async {
    return _queryAdapter.queryList(
        'SELECT * FROM routines_local WHERE isDeleted = 0 ORDER BY id ASC',
        mapper: (Map<String, Object?> row) => RoutineEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            programName: row['programName'] as String?,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<void> softDeleteRoutine(
    String id,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE routines_local SET isDeleted = 1, updatedAt = ?2, syncStatus = \'PENDING\' WHERE id = ?1',
        arguments: [id, time]);
  }

  @override
  Future<List<RoutineEntity>> getPendingSyncRoutines() async {
    return _queryAdapter.queryList(
        'SELECT * FROM routines_local WHERE syncStatus = \'PENDING\'',
        mapper: (Map<String, Object?> row) => RoutineEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            programName: row['programName'] as String?,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<void> markRoutinesAsSynced(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE routines_local SET syncStatus = \'SYNCED\' WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteAllRoutines() async {
    await _queryAdapter.queryNoReturn('DELETE FROM routines_local');
  }

  @override
  Future<void> deleteAllScheduledWorkouts() async {
    await _queryAdapter.queryNoReturn('DELETE FROM scheduled_workouts_local');
  }

  @override
  Stream<List<WorkoutSessionEntity>> watchAllHistory() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM workout_history_local WHERE isDeleted = 0',
        mapper: (Map<String, Object?> row) => WorkoutSessionEntity(
            id: row['id'] as String,
            routineId: row['routineId'] as String?,
            programName: row['programName'] as String?,
            name: row['name'] as String,
            startTime: row['startTime'] as int,
            endTime: row['endTime'] as int?,
            durationSeconds: row['durationSeconds'] as int,
            totalCaloriesBurned: row['totalCaloriesBurned'] as int,
            totalVolume: row['totalVolume'] as double,
            totalSets: row['totalSets'] as int,
            rpe: row['rpe'] as int?,
            xpEarned: row['xpEarned'] as int,
            prCount: row['prCount'] as int,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'workout_history_local',
        isView: false);
  }

  @override
  Future<List<WorkoutSessionEntity>> getAllHistory() async {
    return _queryAdapter.queryList(
        'SELECT * FROM workout_history_local WHERE isDeleted = 0',
        mapper: (Map<String, Object?> row) => WorkoutSessionEntity(
            id: row['id'] as String,
            routineId: row['routineId'] as String?,
            programName: row['programName'] as String?,
            name: row['name'] as String,
            startTime: row['startTime'] as int,
            endTime: row['endTime'] as int?,
            durationSeconds: row['durationSeconds'] as int,
            totalCaloriesBurned: row['totalCaloriesBurned'] as int,
            totalVolume: row['totalVolume'] as double,
            totalSets: row['totalSets'] as int,
            rpe: row['rpe'] as int?,
            xpEarned: row['xpEarned'] as int,
            prCount: row['prCount'] as int,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<int?> getLocalWorkoutCount() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM workout_history_local',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> softDelete(
    String id,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE workout_history_local SET isDeleted = 1, updatedAt = ?2, syncStatus = \'PENDING\' WHERE id = ?1',
        arguments: [id, time]);
  }

  @override
  Future<List<WorkoutSessionEntity>> getPendingSyncSessions() async {
    return _queryAdapter.queryList(
        'SELECT * FROM workout_history_local WHERE syncStatus = \'PENDING\'',
        mapper: (Map<String, Object?> row) => WorkoutSessionEntity(
            id: row['id'] as String,
            routineId: row['routineId'] as String?,
            programName: row['programName'] as String?,
            name: row['name'] as String,
            startTime: row['startTime'] as int,
            endTime: row['endTime'] as int?,
            durationSeconds: row['durationSeconds'] as int,
            totalCaloriesBurned: row['totalCaloriesBurned'] as int,
            totalVolume: row['totalVolume'] as double,
            totalSets: row['totalSets'] as int,
            rpe: row['rpe'] as int?,
            xpEarned: row['xpEarned'] as int,
            prCount: row['prCount'] as int,
            payloadJson: row['payloadJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<void> markWorkoutsAsSynced(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE workout_history_local SET syncStatus = \'SYNCED\' WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteAllHistory() async {
    await _queryAdapter.queryNoReturn('DELETE FROM workout_history_local');
  }

  @override
  Future<void> deleteHistoryByIds(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM workout_history_local WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> insertScheduledWorkout(ScheduledWorkoutEntity entity) async {
    await _scheduledWorkoutEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertOrUpdateRoutine(RoutineEntity entity) async {
    await _routineEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertRoutines(List<RoutineEntity> routines) async {
    await _routineEntityInsertionAdapter.insertList(
        routines, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertOrUpdate(WorkoutSessionEntity entity) async {
    await _workoutSessionEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertHistory(List<WorkoutSessionEntity> history) async {
    await _workoutSessionEntityInsertionAdapter.insertList(
        history, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSessions(List<WorkoutSessionEntity> sessions) async {
    await _workoutSessionEntityInsertionAdapter.insertList(
        sessions, OnConflictStrategy.replace);
  }

  @override
  Future<void> replaceLocalWithRemote(
    List<WorkoutSessionEntity> history,
    List<RoutineEntity> routines,
  ) async {
    if (database is sqflite.Transaction) {
      await super.replaceLocalWithRemote(history, routines);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.workoutDao
            .replaceLocalWithRemote(history, routines);
      });
    }
  }
}

class _$NutritionDao extends NutritionDao {
  _$NutritionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _nutritionDailyEntityInsertionAdapter = InsertionAdapter(
            database,
            'nutrition_daily_local',
            (NutritionDailyEntity item) => <String, Object?>{
                  'dateId': item.dateId,
                  'waterConsumedLiters': item.waterConsumedLiters,
                  'breakfastJson': item.breakfastJson,
                  'lunchJson': item.lunchJson,
                  'dinnerJson': item.dinnerJson,
                  'snackJson': item.snackJson,
                  'syncStatus': item.syncStatus,
                  'updatedAt': item.updatedAt,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<NutritionDailyEntity>
      _nutritionDailyEntityInsertionAdapter;

  @override
  Future<NutritionDailyEntity?> getDailyNutritionByDate(String date) async {
    return _queryAdapter.query(
        'SELECT * FROM nutrition_daily_local WHERE dateId = ?1 AND isDeleted = 0',
        mapper: (Map<String, Object?> row) => NutritionDailyEntity(dateId: row['dateId'] as String, waterConsumedLiters: row['waterConsumedLiters'] as double, breakfastJson: row['breakfastJson'] as String, lunchJson: row['lunchJson'] as String, dinnerJson: row['dinnerJson'] as String, snackJson: row['snackJson'] as String, syncStatus: row['syncStatus'] as String, updatedAt: row['updatedAt'] as int, isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [date]);
  }

  @override
  Stream<NutritionDailyEntity?> watchDailyNutritionByDate(String date) {
    return _queryAdapter.queryStream(
        'SELECT * FROM nutrition_daily_local WHERE dateId = ?1 AND isDeleted = 0',
        mapper: (Map<String, Object?> row) => NutritionDailyEntity(
            dateId: row['dateId'] as String,
            waterConsumedLiters: row['waterConsumedLiters'] as double,
            breakfastJson: row['breakfastJson'] as String,
            lunchJson: row['lunchJson'] as String,
            dinnerJson: row['dinnerJson'] as String,
            snackJson: row['snackJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [date],
        queryableName: 'nutrition_daily_local',
        isView: false);
  }

  @override
  Future<List<NutritionDailyEntity>> getAllNutritionHistory() async {
    return _queryAdapter.queryList(
        'SELECT * FROM nutrition_daily_local WHERE isDeleted = 0 ORDER BY dateId DESC',
        mapper: (Map<String, Object?> row) => NutritionDailyEntity(
            dateId: row['dateId'] as String,
            waterConsumedLiters: row['waterConsumedLiters'] as double,
            breakfastJson: row['breakfastJson'] as String,
            lunchJson: row['lunchJson'] as String,
            dinnerJson: row['dinnerJson'] as String,
            snackJson: row['snackJson'] as String,
            syncStatus: row['syncStatus'] as String,
            updatedAt: row['updatedAt'] as int,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<void> deleteAllNutrition() async {
    await _queryAdapter.queryNoReturn('DELETE FROM nutrition_daily_local');
  }

  @override
  Future<void> insertOrUpdateDailyNutrition(NutritionDailyEntity entity) async {
    await _nutritionDailyEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$RewardClaimDao extends RewardClaimDao {
  _$RewardClaimDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _rewardClaimEntityInsertionAdapter = InsertionAdapter(
            database,
            'reward_claims_local',
            (RewardClaimEntity item) => <String, Object?>{
                  'id': item.id,
                  'sourceType': item.sourceType,
                  'sourceRef': item.sourceRef,
                  'periodKey': item.periodKey,
                  'actionType': item.actionType,
                  'xpAmount': item.xpAmount,
                  'createdAt': item.createdAt,
                  'syncStatus': item.syncStatus
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<RewardClaimEntity> _rewardClaimEntityInsertionAdapter;

  @override
  Future<List<RewardClaimEntity>> getClaimsByPeriod(String periodKey) async {
    return _queryAdapter.queryList(
        'SELECT * FROM reward_claims_local WHERE periodKey = ?1 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => RewardClaimEntity(id: row['id'] as String, sourceType: row['sourceType'] as String, sourceRef: row['sourceRef'] as String, periodKey: row['periodKey'] as String, actionType: row['actionType'] as String, xpAmount: row['xpAmount'] as int, createdAt: row['createdAt'] as int, syncStatus: row['syncStatus'] as String),
        arguments: [periodKey]);
  }

  @override
  Future<List<RewardClaimEntity>> getPendingSyncClaims() async {
    return _queryAdapter.queryList(
        'SELECT * FROM reward_claims_local WHERE syncStatus = \'PENDING\'',
        mapper: (Map<String, Object?> row) => RewardClaimEntity(
            id: row['id'] as String,
            sourceType: row['sourceType'] as String,
            sourceRef: row['sourceRef'] as String,
            periodKey: row['periodKey'] as String,
            actionType: row['actionType'] as String,
            xpAmount: row['xpAmount'] as int,
            createdAt: row['createdAt'] as int,
            syncStatus: row['syncStatus'] as String));
  }

  @override
  Future<void> markClaimsAsSynced(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE reward_claims_local SET syncStatus = \'SYNCED\' WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteAllClaims() async {
    await _queryAdapter.queryNoReturn('DELETE FROM reward_claims_local');
  }

  @override
  Future<void> insertClaim(RewardClaimEntity entity) async {
    await _rewardClaimEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertClaims(List<RewardClaimEntity> claims) async {
    await _rewardClaimEntityInsertionAdapter.insertList(
        claims, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _muscleGroupConverter = MuscleGroupConverter();
final _exerciseTypeConverter = ExerciseTypeConverter();
final _foodUnitConverter = FoodUnitConverter();
final _mealTypeConverter = MealTypeConverter();
final _workoutEnvironmentConverter = WorkoutEnvironmentConverter();
final _workoutGoalConverter = WorkoutGoalConverter();
final _muscleGroupListConverter = MuscleGroupListConverter();
final _equipmentConverter = EquipmentConverter();
