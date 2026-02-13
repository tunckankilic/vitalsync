/// VitalSync — Seed Data.
///
/// Default data for exercises, workout templates, achievements,
/// symptoms, and insight rules. This data is inserted on first app launch.
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/equipment.dart';
import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/data/local/database.dart';

/// Seeds the database with default data.
/// Should be called on first app launch or when database is empty.
Future<void> seedDatabase(AppDatabase db) async {
  await db.transaction(() async {
    // Seed exercises
    final exerciseIds = await _seedExercises(db);

    // Seed workout templates
    await _seedWorkoutTemplates(db, exerciseIds);

    // Seed achievements
    await _seedAchievements(db);
  });
}

/// Seeds default exercises (50+ exercises across all categories).
Future<Map<String, int>> _seedExercises(AppDatabase db) async {
  final exerciseIds = <String, int>{};

  final exercises = [
    //  CHEST EXERCISES
    _exerciseData(
      'Barbell Bench Press',
      ExerciseCategory.chest,
      'Pectorals, Triceps, Deltoids',
      Equipment.barbell,
      'Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up to starting position.',
    ),
    _exerciseData(
      'Incline Bench Press',
      ExerciseCategory.chest,
      'Upper Pectorals, Deltoids',
      Equipment.barbell,
      'Set bench to 30-45 degree incline, press barbell from upper chest to full extension.',
    ),
    _exerciseData(
      'Dumbbell Flyes',
      ExerciseCategory.chest,
      'Pectorals',
      Equipment.dumbbell,
      'Lie on bench, arms slightly bent, lower dumbbells in wide arc, bring back to center.',
    ),
    _exerciseData(
      'Push-ups',
      ExerciseCategory.chest,
      'Pectorals, Triceps, Core',
      Equipment.bodyweight,
      'Hands shoulder-width apart, lower chest to ground, push back up while maintaining straight body.',
    ),
    _exerciseData(
      'Cable Crossover',
      ExerciseCategory.chest,
      'Pectorals',
      Equipment.cable,
      'Stand between cable towers, pull handles down and across body in front of chest.',
    ),
    _exerciseData(
      'Chest Dips',
      ExerciseCategory.chest,
      'Lower Pectorals, Triceps',
      Equipment.bodyweight,
      'On parallel bars, lean forward, lower body by bending elbows, push back up.',
    ),
    _exerciseData(
      'Decline Bench Press',
      ExerciseCategory.chest,
      'Lower Pectorals',
      Equipment.barbell,
      'Set bench to decline, press barbell from lower chest to full extension.',
    ),
    _exerciseData(
      'Dumbbell Bench Press',
      ExerciseCategory.chest,
      'Pectorals',
      Equipment.dumbbell,
      'Lie on bench, press dumbbells from chest level to full extension above chest.',
    ),

    // BACK EXERCISES
    _exerciseData(
      'Deadlift',
      ExerciseCategory.back,
      'Entire Back, Hamstrings, Glutes',
      Equipment.barbell,
      'Feet hip-width, grip bar, lift by extending hips and knees, keep back straight throughout.',
    ),
    _exerciseData(
      'Barbell Row',
      ExerciseCategory.back,
      'Lats, Rhomboids, Traps',
      Equipment.barbell,
      'Bend at hips, pull bar to lower chest, squeeze shoulder blades together.',
    ),
    _exerciseData(
      'Lat Pulldown',
      ExerciseCategory.back,
      'Latissimus Dorsi',
      Equipment.machine,
      'Grip bar wide, pull down to upper chest, control return to starting position.',
    ),
    _exerciseData(
      'Pull-ups',
      ExerciseCategory.back,
      'Lats, Biceps',
      Equipment.bodyweight,
      'Hang from bar, pull body up until chin over bar, lower with control.',
    ),
    _exerciseData(
      'Seated Cable Row',
      ExerciseCategory.back,
      'Middle Back, Lats',
      Equipment.cable,
      'Sit upright, pull cable handles to torso, squeeze shoulder blades together.',
    ),
    _exerciseData(
      'T-Bar Row',
      ExerciseCategory.back,
      'Middle Back, Lats',
      Equipment.barbell,
      'Straddle bar, pull handle to chest while maintaining flat back.',
    ),
    _exerciseData(
      'Face Pulls',
      ExerciseCategory.back,
      'Rear Deltoids, Upper Back',
      Equipment.cable,
      'Pull rope attachment to face level, separate hands at end of movement.',
    ),
    _exerciseData(
      'Single Arm Dumbbell Row',
      ExerciseCategory.back,
      'Lats, Rhomboids',
      Equipment.dumbbell,
      'Support body with one hand on bench, row dumbbell to hip with other arm.',
    ),

    //  SHOULDER EXERCISES
    _exerciseData(
      'Overhead Press',
      ExerciseCategory.shoulders,
      'Deltoids, Triceps',
      Equipment.barbell,
      'Press barbell from shoulders to full extension overhead, keep core tight.',
    ),
    _exerciseData(
      'Lateral Raises',
      ExerciseCategory.shoulders,
      'Lateral Deltoids',
      Equipment.dumbbell,
      'Lift dumbbells to sides until arms parallel to floor, control descent.',
    ),
    _exerciseData(
      'Front Raises',
      ExerciseCategory.shoulders,
      'Anterior Deltoids',
      Equipment.dumbbell,
      'Lift dumbbells forward to shoulder height, keep slight bend in elbows.',
    ),
    _exerciseData(
      'Arnold Press',
      ExerciseCategory.shoulders,
      'All Deltoid Heads',
      Equipment.dumbbell,
      'Start palms facing body, press while rotating palms forward to overhead position.',
    ),
    _exerciseData(
      'Reverse Flyes',
      ExerciseCategory.shoulders,
      'Rear Deltoids',
      Equipment.dumbbell,
      'Bend forward at hips, raise dumbbells to sides in wide arc.',
    ),
    _exerciseData(
      'Dumbbell Shoulder Press',
      ExerciseCategory.shoulders,
      'Deltoids',
      Equipment.dumbbell,
      'Press dumbbells from shoulder level to full extension overhead.',
    ),
    _exerciseData(
      'Cable Lateral Raises',
      ExerciseCategory.shoulders,
      'Lateral Deltoids',
      Equipment.cable,
      'Stand sideways to cable, raise handle from low to shoulder height.',
    ),

    //  ARM EXERCISES
    _exerciseData(
      'Barbell Bicep Curls',
      ExerciseCategory.arms,
      'Biceps',
      Equipment.barbell,
      'Stand with barbell at thighs, curl to shoulders keeping elbows stationary.',
    ),
    _exerciseData(
      'Hammer Curls',
      ExerciseCategory.arms,
      'Biceps, Brachialis',
      Equipment.dumbbell,
      'Curl dumbbells with neutral grip (palms facing each other) to shoulders.',
    ),
    _exerciseData(
      'Tricep Pushdown',
      ExerciseCategory.arms,
      'Triceps',
      Equipment.cable,
      'Push cable attachment down by extending elbows, keep upper arms stationary.',
    ),
    _exerciseData(
      'Skull Crushers',
      ExerciseCategory.arms,
      'Triceps',
      Equipment.barbell,
      'Lie on bench, lower bar to forehead by bending elbows, extend back up.',
    ),
    _exerciseData(
      'Preacher Curls',
      ExerciseCategory.arms,
      'Biceps',
      Equipment.barbell,
      'Rest upper arms on preacher bench, curl bar up while keeping arms supported.',
    ),
    _exerciseData(
      'Tricep Dips',
      ExerciseCategory.arms,
      'Triceps',
      Equipment.bodyweight,
      'On parallel bars, body upright, lower by bending elbows, press back up.',
    ),
    _exerciseData(
      'EZ Bar Curls',
      ExerciseCategory.arms,
      'Biceps',
      Equipment.barbell,
      'Curl EZ bar using angled grip to reduce wrist strain.',
    ),
    _exerciseData(
      'Overhead Tricep Extension',
      ExerciseCategory.arms,
      'Triceps',
      Equipment.dumbbell,
      'Hold dumbbell overhead, lower behind head by bending elbows, extend back up.',
    ),

    //  LEG EXERCISES
    _exerciseData(
      'Barbell Squat',
      ExerciseCategory.legs,
      'Quadriceps, Glutes, Hamstrings',
      Equipment.barbell,
      'Bar on upper back, squat down until thighs parallel to floor, drive back up.',
    ),
    _exerciseData(
      'Leg Press',
      ExerciseCategory.legs,
      'Quadriceps, Glutes',
      Equipment.machine,
      'Press platform away by extending knees and hips, control descent.',
    ),
    _exerciseData(
      'Romanian Deadlift',
      ExerciseCategory.legs,
      'Hamstrings, Glutes, Lower Back',
      Equipment.barbell,
      'Hinge at hips with slight knee bend, lower bar along shins, return to standing.',
    ),
    _exerciseData(
      'Leg Curl',
      ExerciseCategory.legs,
      'Hamstrings',
      Equipment.machine,
      'Curl legs by flexing knees, control return to starting position.',
    ),
    _exerciseData(
      'Leg Extension',
      ExerciseCategory.legs,
      'Quadriceps',
      Equipment.machine,
      'Extend legs by straightening knees, control descent back to start.',
    ),
    _exerciseData(
      'Calf Raises',
      ExerciseCategory.legs,
      'Calves',
      Equipment.machine,
      'Raise heels as high as possible, lower with control below starting position.',
    ),
    _exerciseData(
      'Lunges',
      ExerciseCategory.legs,
      'Quadriceps, Glutes',
      Equipment.dumbbell,
      'Step forward, lower back knee toward ground, push back to starting position.',
    ),
    _exerciseData(
      'Bulgarian Split Squat',
      ExerciseCategory.legs,
      'Quadriceps, Glutes',
      Equipment.dumbbell,
      'Rear foot elevated on bench, squat down on front leg until thigh parallel.',
    ),
    _exerciseData(
      'Front Squat',
      ExerciseCategory.legs,
      'Quadriceps, Core',
      Equipment.barbell,
      'Bar on front shoulders, squat down keeping torso upright, drive back up.',
    ),
    _exerciseData(
      'Hip Thrust',
      ExerciseCategory.legs,
      'Glutes, Hamstrings',
      Equipment.barbell,
      'Shoulders on bench, drive hips up by squeezing glutes, lower with control.',
    ),

    //  CORE EXERCISES
    _exerciseData(
      'Plank',
      ExerciseCategory.core,
      'Entire Core',
      Equipment.bodyweight,
      'Forearms and toes on ground, maintain straight line from head to heels.',
    ),
    _exerciseData(
      'Crunches',
      ExerciseCategory.core,
      'Rectus Abdominis',
      Equipment.bodyweight,
      'Lie on back, knees bent, curl upper body toward knees.',
    ),
    _exerciseData(
      'Russian Twists',
      ExerciseCategory.core,
      'Obliques',
      Equipment.bodyweight,
      'Seated position, lean back slightly, rotate torso side to side.',
    ),
    _exerciseData(
      'Leg Raises',
      ExerciseCategory.core,
      'Lower Abs',
      Equipment.bodyweight,
      'Lie on back, raise legs to vertical while keeping them straight.',
    ),
    _exerciseData(
      'Cable Woodchops',
      ExerciseCategory.core,
      'Obliques, Core Rotation',
      Equipment.cable,
      'Pull cable diagonally across body in chopping motion.',
    ),
    _exerciseData(
      'Ab Wheel Rollout',
      ExerciseCategory.core,
      'Entire Core',
      Equipment.other,
      'Roll wheel forward while maintaining core tension, pull back to start.',
    ),
    _exerciseData(
      'Hanging Knee Raises',
      ExerciseCategory.core,
      'Lower Abs',
      Equipment.bodyweight,
      'Hang from bar, raise knees to chest, lower with control.',
    ),
    _exerciseData(
      'Side Plank',
      ExerciseCategory.core,
      'Obliques, Core Stability',
      Equipment.bodyweight,
      'On side, support on forearm and side of foot, maintain straight line.',
    ),

    //  CARDIO EXERCISES
    _exerciseData(
      'Treadmill Running',
      ExerciseCategory.cardio,
      'Cardiovascular System',
      Equipment.machine,
      'Run at steady pace or use interval training for cardiovascular fitness.',
    ),
    _exerciseData(
      'Stationary Cycling',
      ExerciseCategory.cardio,
      'Cardiovascular System, Legs',
      Equipment.machine,
      'Cycle at various resistance levels for cardiovascular endurance.',
    ),
    _exerciseData(
      'Rowing Machine',
      ExerciseCategory.cardio,
      'Full Body, Cardiovascular',
      Equipment.machine,
      'Pull handle to torso, extend legs, reverse motion with control.',
    ),
    _exerciseData(
      'Jump Rope',
      ExerciseCategory.cardio,
      'Cardiovascular System, Calves',
      Equipment.other,
      'Jump rope continuously for cardiovascular fitness and coordination.',
    ),
    _exerciseData(
      'Stair Climber',
      ExerciseCategory.cardio,
      'Cardiovascular System, Legs',
      Equipment.machine,
      'Climb stairs at consistent pace for cardiovascular endurance.',
    ),
    _exerciseData(
      'Elliptical',
      ExerciseCategory.cardio,
      'Cardiovascular System, Full Body',
      Equipment.machine,
      'Move pedals in elliptical motion for low-impact cardio workout.',
    ),
  ];

  for (final exercise in exercises) {
    final id = await db.into(db.exercises).insert(exercise);
    exerciseIds[exercise.name.value] = id;
  }

  return exerciseIds;
}

/// Seeds default workout templates.
Future<void> _seedWorkoutTemplates(
  AppDatabase db,
  Map<String, int> exerciseIds,
) async {
  final templates = [
    // Push Day
    _WorkoutTemplate(
      name: 'Push Day',
      description: 'Chest, Shoulders, and Triceps workout',
      color: 0xFFFF6B6B,
      estimatedDuration: 60,
      exercises: [
        ('Barbell Bench Press', 4, 8, 60.0, 180),
        ('Incline Bench Press', 3, 10, 50.0, 120),
        ('Dumbbell Flyes', 3, 12, 20.0, 90),
        ('Dumbbell Shoulder Press', 3, 10, 30.0, 120),
        ('Lateral Raises', 3, 15, 10.0, 60),
        ('Tricep Pushdown', 3, 12, 30.0, 90),
      ],
    ),

    // Pull Day
    _WorkoutTemplate(
      name: 'Pull Day',
      description: 'Back and Biceps workout',
      color: 0xFF4ECDC4,
      estimatedDuration: 60,
      exercises: [
        ('Deadlift', 4, 6, 100.0, 240),
        ('Pull-ups', 3, 10, null, 120),
        ('Barbell Row', 4, 8, 60.0, 120),
        ('Lat Pulldown', 3, 12, 50.0, 90),
        ('Face Pulls', 3, 15, 20.0, 60),
        ('Barbell Bicep Curls', 3, 10, 30.0, 90),
        ('Hammer Curls', 3, 12, 15.0, 90),
      ],
    ),

    // Leg Day
    _WorkoutTemplate(
      name: 'Leg Day',
      description: 'Complete leg workout',
      color: 0xFF95E1D3,
      estimatedDuration: 70,
      exercises: [
        ('Barbell Squat', 4, 8, 80.0, 180),
        ('Romanian Deadlift', 3, 10, 70.0, 120),
        ('Leg Press', 3, 12, 150.0, 90),
        ('Leg Curl', 3, 12, 40.0, 90),
        ('Leg Extension', 3, 12, 50.0, 90),
        ('Calf Raises', 4, 15, 60.0, 60),
        ('Lunges', 3, 12, 20.0, 90),
      ],
    ),

    // Upper Body
    _WorkoutTemplate(
      name: 'Upper Body',
      description: 'Full upper body workout',
      color: 0xFFFEA47F,
      estimatedDuration: 75,
      exercises: [
        ('Barbell Bench Press', 3, 10, 60.0, 120),
        ('Barbell Row', 3, 10, 60.0, 120),
        ('Dumbbell Shoulder Press', 3, 10, 30.0, 90),
        ('Pull-ups', 3, 8, null, 120),
        ('Tricep Pushdown', 3, 12, 30.0, 90),
        ('Barbell Bicep Curls', 3, 10, 30.0, 90),
        ('Lateral Raises', 3, 15, 10.0, 60),
      ],
    ),

    // Lower Body
    _WorkoutTemplate(
      name: 'Lower Body',
      description: 'Focused leg and glute workout',
      color: 0xFFB4A7D6,
      estimatedDuration: 65,
      exercises: [
        ('Barbell Squat', 4, 10, 70.0, 120),
        ('Hip Thrust', 4, 12, 80.0, 90),
        ('Bulgarian Split Squat', 3, 10, 20.0, 90),
        ('Leg Curl', 3, 12, 40.0, 90),
        ('Calf Raises', 4, 15, 60.0, 60),
      ],
    ),

    // Full Body
    _WorkoutTemplate(
      name: 'Full Body',
      description: 'Complete full body workout',
      color: 0xFFFFD93D,
      estimatedDuration: 80,
      exercises: [
        ('Barbell Squat', 3, 10, 70.0, 120),
        ('Barbell Bench Press', 3, 10, 60.0, 120),
        ('Deadlift', 3, 6, 90.0, 180),
        ('Pull-ups', 3, 8, null, 120),
        ('Dumbbell Shoulder Press', 3, 10, 30.0, 90),
        ('Barbell Row', 3, 10, 50.0, 90),
        ('Plank', 3, 60, null, 60),
      ],
    ),
  ];

  for (final template in templates) {
    final templateId = await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            name: template.name,
            description: Value(template.description),
            color: template.color,
            estimatedDuration: template.estimatedDuration,
            isDefault: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // Add exercises to template
    for (var i = 0; i < template.exercises.length; i++) {
      final (exerciseName, sets, reps, weight, rest) = template.exercises[i];
      final exerciseId = exerciseIds[exerciseName];

      if (exerciseId != null) {
        await db
            .into(db.templateExercises)
            .insert(
              TemplateExercisesCompanion.insert(
                templateId: templateId,
                exerciseId: exerciseId,
                orderIndex: i,
                defaultSets: sets,
                defaultReps: reps,
                defaultWeight: Value(weight),
                restSeconds: rest,
              ),
            );
      }
    }
  }
}

/// Seeds default achievements.
Future<void> _seedAchievements(AppDatabase db) async {
  final achievements = [
    //  FITNESS STREAK ACHIEVEMENTS
    _achievementData(
      AchievementType.streak,
      'First Step',
      'Complete your first workout',
      1,
      'fitness_first_step',
    ),
    _achievementData(
      AchievementType.streak,
      'Week Warrior',
      'Maintain a 7-day workout streak',
      7,
      'fitness_week_warrior',
    ),
    _achievementData(
      AchievementType.streak,
      'Monthly Master',
      'Maintain a 30-day workout streak',
      30,
      'fitness_monthly_master',
    ),
    _achievementData(
      AchievementType.streak,
      'Iron Will',
      'Maintain a 100-day workout streak',
      100,
      'fitness_iron_will',
    ),

    //  VOLUME ACHIEVEMENTS
    _achievementData(
      AchievementType.volume,
      'Ton Club',
      'Lift a total of 1,000 kg',
      1000,
      'fitness_ton_club',
    ),
    _achievementData(
      AchievementType.volume,
      'Heavy Lifter',
      'Lift a total of 10,000 kg',
      10000,
      'fitness_heavy_lifter',
    ),
    _achievementData(
      AchievementType.volume,
      'Powerhouse',
      'Lift a total of 100,000 kg',
      100000,
      'fitness_powerhouse',
    ),
    _achievementData(
      AchievementType.volume,
      'Mountain Mover',
      'Lift a total of 500,000 kg',
      500000,
      'fitness_mountain_mover',
    ),

    //  WORKOUT COUNT ACHIEVEMENTS
    _achievementData(
      AchievementType.workouts,
      'Beginner',
      'Complete 1 workout',
      1,
      'fitness_beginner',
    ),
    _achievementData(
      AchievementType.workouts,
      'Consistent',
      'Complete 10 workouts',
      10,
      'fitness_consistent',
    ),
    _achievementData(
      AchievementType.workouts,
      'Dedicated',
      'Complete 50 workouts',
      50,
      'fitness_dedicated',
    ),
    _achievementData(
      AchievementType.workouts,
      'Gym Rat',
      'Complete 100 workouts',
      100,
      'fitness_gym_rat',
    ),
    _achievementData(
      AchievementType.workouts,
      'Fitness Legend',
      'Complete 500 workouts',
      500,
      'fitness_legend',
    ),

    //  PR ACHIEVEMENTS
    _achievementData(
      AchievementType.pr,
      'First PR',
      'Set your first personal record',
      1,
      'fitness_first_pr',
    ),
    _achievementData(
      AchievementType.pr,
      'Record Breaker',
      'Set 10 personal records',
      10,
      'fitness_record_breaker',
    ),
    _achievementData(
      AchievementType.pr,
      'Elite',
      'Set 50 personal records',
      50,
      'fitness_elite',
    ),

    //  HEALTH/MEDICATION ACHIEVEMENTS
    _achievementData(
      AchievementType.medicationCompliance,
      'Perfect Day',
      'Take all medications on schedule for 1 day',
      1,
      'health_perfect_day',
    ),
    _achievementData(
      AchievementType.medicationCompliance,
      'Week of Wellness',
      'Maintain 100% medication compliance for 7 days',
      7,
      'health_week_wellness',
    ),
    _achievementData(
      AchievementType.medicationCompliance,
      'Health Hero',
      'Maintain 100% medication compliance for 30 days',
      30,
      'health_hero',
    ),

    //  CROSS-MODULE ACHIEVEMENTS
    _achievementData(
      AchievementType.consistency,
      'Balance Master',
      'Achieve 100% medication compliance and 4 workouts in the same week',
      1,
      'cross_balance_master',
    ),
    _achievementData(
      AchievementType.consistency,
      'Synced Up',
      'Maintain both medication compliance and workout streak for 30 days',
      30,
      'cross_synced_up',
    ),
    _achievementData(
      AchievementType.consistency,
      'Wellness Warrior',
      'Complete 50 workouts with 90%+ medication compliance',
      50,
      'cross_wellness_warrior',
    ),
  ];

  for (final achievement in achievements) {
    await db.into(db.achievements).insert(achievement);
  }
}

//  HELPER CLASSES

class _WorkoutTemplate {
  // (name, sets, reps, weight, rest)

  _WorkoutTemplate({
    required this.name,
    required this.description,
    required this.color,
    required this.estimatedDuration,
    required this.exercises,
  });
  final String name;
  final String description;
  final int color;
  final int estimatedDuration;
  final List<(String, int, int, double?, int)> exercises;
}

//  HELPER FUNCTIONS

ExercisesCompanion _exerciseData(
  String name,
  ExerciseCategory category,
  String muscleGroup,
  Equipment equipment,
  String instructions,
) {
  return ExercisesCompanion.insert(
    name: name,
    category: category,
    muscleGroup: muscleGroup,
    equipment: equipment,
    instructions: Value(instructions),
    isCustom: const Value(false),
    createdAt: Value(DateTime.now()),
  );
}

AchievementsCompanion _achievementData(
  AchievementType type,
  String title,
  String description,
  int requirement,
  String iconName,
) {
  return AchievementsCompanion.insert(
    type: type,
    title: title,
    description: description,
    requirement: requirement,
    iconName: iconName,
    unlockedAt: const Value(null),
  );
}

//  COMMON SYMPTOMS

/// Predefined common symptoms for quick logging.
/// These should be localized in the UI layer.
class CommonSymptoms {
  static const Map<String, Map<String, String>> symptoms = {
    'headache': {'en': 'Headache', 'tr': 'Baş Ağrısı', 'de': 'Kopfschmerzen'},
    'nausea': {'en': 'Nausea', 'tr': 'Mide Bulantısı', 'de': 'Übelkeit'},
    'fatigue': {'en': 'Fatigue', 'tr': 'Yorgunluk', 'de': 'Müdigkeit'},
    'dizziness': {'en': 'Dizziness', 'tr': 'Baş Dönmesi', 'de': 'Schwindel'},
    'stomach_pain': {
      'en': 'Stomach Pain',
      'tr': 'Karın Ağrısı',
      'de': 'Bauchschmerzen',
    },
    'back_pain': {
      'en': 'Back Pain',
      'tr': 'Sırt Ağrısı',
      'de': 'Rückenschmerzen',
    },
    'joint_pain': {
      'en': 'Joint Pain',
      'tr': 'Eklem Ağrısı',
      'de': 'Gelenkschmerzen',
    },
    'insomnia': {'en': 'Insomnia', 'tr': 'Uykusuzluk', 'de': 'Schlaflosigkeit'},
    'anxiety': {'en': 'Anxiety', 'tr': 'Anksiyete', 'de': 'Angst'},
    'shortness_of_breath': {
      'en': 'Shortness of Breath',
      'tr': 'Nefes Darlığı',
      'de': 'Atemnot',
    },
    'muscle_pain': {
      'en': 'Muscle Pain',
      'tr': 'Kas Ağrısı',
      'de': 'Muskelschmerzen',
    },
    'chest_pain': {
      'en': 'Chest Pain',
      'tr': 'Göğüs Ağrısı',
      'de': 'Brustschmerzen',
    },
  };

  /// Get symptom name in specified locale.
  static String getName(String symptomKey, String locale) {
    return symptoms[symptomKey]?[locale] ??
        symptoms[symptomKey]?['en'] ??
        symptomKey;
  }

  /// Get all symptom keys.
  static List<String> getAllKeys() => symptoms.keys.toList();
}

//  INSIGHT RULES

/// Default insight rule definitions for the InsightEngine.
/// Each rule has an ID, minimum sample size, threshold, and message template.
class InsightRules {
  static const List<InsightRule> rules = [
    //  CORRELATION RULES
    InsightRule(
      id: 'correlation_workout_medication',
      type: InsightType.correlation,
      category: InsightCategory.crossModule,
      minimumSampleSize: 14,
      threshold: 0.6,
      messageTemplate:
          'Your workout performance tends to be {correlation} on days when you take your medications on time.',
    ),

    InsightRule(
      id: 'correlation_symptom_medication',
      type: InsightType.correlation,
      category: InsightCategory.health,
      minimumSampleSize: 10,
      threshold: 0.5,
      messageTemplate:
          'You experience {symptom} more frequently when you miss your {medication}.',
    ),

    InsightRule(
      id: 'correlation_symptom_exercise',
      type: InsightType.correlation,
      category: InsightCategory.crossModule,
      minimumSampleSize: 14,
      threshold: 0.5,
      messageTemplate:
          '{symptom} appears to {trend} after {exerciseCategory} workouts.',
    ),

    //  TREND RULES
    InsightRule(
      id: 'trend_volume_increase',
      type: InsightType.trend,
      category: InsightCategory.fitness,
      minimumSampleSize: 4,
      threshold: 0.15,
      messageTemplate:
          'Great progress! Your total volume has increased by {percentage}% over the past {weeks} weeks.',
    ),

    InsightRule(
      id: 'trend_volume_decrease',
      type: InsightType.trend,
      category: InsightCategory.fitness,
      minimumSampleSize: 4,
      threshold: -0.15,
      messageTemplate:
          'Your workout volume has decreased by {percentage}% recently. Consider adjusting your training intensity.',
    ),

    InsightRule(
      id: 'trend_compliance_decrease',
      type: InsightType.trend,
      category: InsightCategory.health,
      minimumSampleSize: 7,
      threshold: -0.20,
      messageTemplate:
          'Your medication compliance has dropped to {percentage}% this week. Stay consistent for better health outcomes.',
    ),

    //  ANOMALY RULES
    InsightRule(
      id: 'anomaly_missed_workout',
      type: InsightType.anomaly,
      category: InsightCategory.fitness,
      minimumSampleSize: 7,
      threshold: 3.0,
      messageTemplate:
          'You haven\'t worked out in {days} days. A quick session can help you maintain your streak!',
    ),

    InsightRule(
      id: 'anomaly_symptom_spike',
      type: InsightType.anomaly,
      category: InsightCategory.health,
      minimumSampleSize: 7,
      threshold: 2.0,
      messageTemplate:
          'You\'ve logged {symptom} {count} times this week, which is unusually high. Consider consulting your doctor.',
    ),

    //  SUGGESTION RULES
    InsightRule(
      id: 'suggestion_rest_day',
      type: InsightType.suggestion,
      category: InsightCategory.fitness,
      minimumSampleSize: 7,
      threshold: 6.0,
      messageTemplate:
          'You\'ve worked out {days} days straight. Consider taking a rest day for recovery.',
    ),

    InsightRule(
      id: 'suggestion_medication_time',
      type: InsightType.suggestion,
      category: InsightCategory.health,
      minimumSampleSize: 14,
      threshold: 0.8,
      messageTemplate:
          'You take {medication} most consistently at {time}. Consider setting all reminders around this time.',
    ),

    //  MILESTONE RULES
    InsightRule(
      id: 'milestone_pr_achieved',
      type: InsightType.milestone,
      category: InsightCategory.fitness,
      minimumSampleSize: 1,
      threshold: 0.0,
      messageTemplate:
          'New personal record! You lifted {weight} kg on {exercise}!',
    ),

    InsightRule(
      id: 'milestone_perfect_week',
      type: InsightType.milestone,
      category: InsightCategory.crossModule,
      minimumSampleSize: 7,
      threshold: 1.0,
      messageTemplate:
          'Perfect week! 100% medication compliance and {workouts} workouts completed.',
    ),
  ];
}

/// Insight rule definition.
class InsightRule {
  const InsightRule({
    required this.id,
    required this.type,
    required this.category,
    required this.minimumSampleSize,
    required this.threshold,
    required this.messageTemplate,
  });
  final String id;
  final InsightType type;
  final InsightCategory category;
  final int minimumSampleSize;
  final double threshold;
  final String messageTemplate;
}
