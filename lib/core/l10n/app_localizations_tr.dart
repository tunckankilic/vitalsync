// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'VitalSync';

  @override
  String get dashboard => 'Gösterge Paneli';

  @override
  String get health => 'Sağlık';

  @override
  String get fitness => 'Fitness';

  @override
  String get settings => 'Ayarlar';

  @override
  String get profile => 'Profil';

  @override
  String get syncOnline => 'Çevrimiçi';

  @override
  String get syncOffline => 'Çevrimdışı';

  @override
  String get syncing => 'Senkronize Ediliyor';

  @override
  String get syncOnlineTooltip => 'Çevrimiçi - Veriler senkronize edildi';

  @override
  String get syncOfflineTooltip =>
      'Çevrimdışı - Değişiklikler çevrimiçi olunca senkronize edilecek';

  @override
  String get syncingTooltip => 'Senkronize ediliyor...';

  @override
  String get syncSemanticsOnline => 'Çevrimiçi';

  @override
  String get syncSemanticsOffline => 'Çevrimdışı';

  @override
  String get syncSemanticsSyncing => 'Veriler senkronize ediliyor';

  @override
  String get insights => 'İçgörüler';

  @override
  String insightsCountSemantics(int count) {
    return 'İçgörüler, $count okunmamış';
  }

  @override
  String insightsCountTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'içgörü',
      one: 'içgörü',
    );
    return '$count yeni $_temp0';
  }

  @override
  String get addMedication => 'İlaç Ekle';

  @override
  String get logSymptom => 'Semptom Kaydet';

  @override
  String get startWorkout => 'Antrenman Başlat';

  @override
  String get quickAddMenuOpen => 'Hızlı ekleme menüsünü aç';

  @override
  String get quickAddMenuClose => 'Hızlı ekleme menüsünü kapat';

  @override
  String get dashboardTabSemantics => 'Gösterge paneli sekmesi';

  @override
  String get dashboardTabSelectedSemantics => 'Gösterge paneli sekmesi, seçili';

  @override
  String get dashboardTabTooltip =>
      'Birleşik sağlık ve fitness gösterge panelinizi görüntüleyin';

  @override
  String get healthTabSemantics => 'Sağlık sekmesi';

  @override
  String get healthTabSelectedSemantics => 'Sağlık sekmesi, seçili';

  @override
  String get healthTabTooltip => 'İlaçları ve semptomları yönetin';

  @override
  String get fitnessTabSemantics => 'Fitness sekmesi';

  @override
  String get fitnessTabSelectedSemantics => 'Fitness sekmesi, seçili';

  @override
  String get fitnessTabTooltip => 'Antrenmanları ve ilerlemeyi takip edin';

  @override
  String get settingsSemantics => 'Ayarlar';

  @override
  String get settingsTooltip => 'Ayarları aç';

  @override
  String get profileSemantics => 'Profil';

  @override
  String get returnToWorkout => 'Antrenman\'a Dön';

  @override
  String get timeElapsed => 'Geçen süre';

  @override
  String get goodMorning => 'Günaydın';

  @override
  String get goodAfternoon => 'İyi günler';

  @override
  String get goodEvening => 'İyi akşamlar';

  @override
  String get goodNight => 'İyi geceler';

  @override
  String get todaysMedications => 'Bugünün İlaçları';

  @override
  String nextMedicationIn(Object time) {
    return 'Sonraki: $time';
  }

  @override
  String get noUpcomingMedications => 'Yaklaşan ilaç yok';

  @override
  String get hoursShort => 's';

  @override
  String get minutesShort => 'dk';

  @override
  String get currentStreak => 'gün serisi';

  @override
  String get inProgress => 'Devam ediyor';

  @override
  String get weeklyOverview => 'Haftalık Genel Bakış';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get last30Days => 'Son 30 Gün';

  @override
  String get medicationCompliance => 'İlaç';

  @override
  String get workoutVolume => 'Antrenman';

  @override
  String get viewReport => 'Rapor Görüntüle';

  @override
  String get recentActivity => 'Son Aktiviteler';

  @override
  String get viewAll => 'Tümünü Gör';

  @override
  String get noRecentActivity => 'Son aktivite yok';

  @override
  String get dataCollecting => 'Veri toplandıkça öneriler burada görünecek';

  @override
  String get startFirstWorkout => 'İlk antrenmanını yap';

  @override
  String get addFirstMedication => 'İlk ilacını ekle';

  @override
  String get dismissInsightTitle => 'Önerimi Kapat';

  @override
  String get dismissInsightMessage =>
      'Bu öneriyi kapatmak istediğinizden emin misiniz?';

  @override
  String get cancel => 'İptal';

  @override
  String get dismiss => 'Kapat';

  @override
  String get errorLoadingDashboard => 'Gösterge paneli yüklenirken hata';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get active => 'Aktif';

  @override
  String get all => 'Tümü';

  @override
  String get completed => 'Tamamlanan';

  @override
  String get searchMedication => 'İlaç ara...';

  @override
  String get noMedicationsFound => 'İlaç bulunamadı';

  @override
  String get editMedication => 'İlacı Düzenle';

  @override
  String get medicationName => 'İlaç Adı';

  @override
  String get dosage => 'Dozaj';

  @override
  String get requiredField => 'Bu alan zorunludur';

  @override
  String get frequency => 'Sıklık';

  @override
  String get scheduledTimes => 'Planlanan Zamanlar';

  @override
  String get color => 'Renk';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get save => 'Kaydet';

  @override
  String get medicationDetails => 'İlaç Detayları';

  @override
  String get deleteMedication => 'İlacı Sil';

  @override
  String get deleteConfirmation =>
      'Bu ilacı silmek istediğinizden emin misiniz?';

  @override
  String get delete => 'Sil';

  @override
  String get complianceHistory => 'Uyum Geçmişi';

  @override
  String get history => 'Geçmiş';

  @override
  String get noLogsYet => 'Henüz kayıt yok';

  @override
  String get takenAt => 'Alındı:';

  @override
  String get shareReport => 'Raporu Paylaş';

  @override
  String get symptoms => 'Semptomlar';

  @override
  String get mostFrequent => 'En Sık Görülen';

  @override
  String get recentTimeline => 'Son Zaman Çizelgesi';

  @override
  String get noSymptomsLogged => 'Kaydedilmiş semptom yok';

  @override
  String get symptomName => 'Semptom Adı';

  @override
  String get severity => 'Şiddet';

  @override
  String get date => 'Tarih';

  @override
  String get time => 'Saat';

  @override
  String get notes => 'Notlar';

  @override
  String get healthTimeline => 'Sağlık Zaman Çizelgesi';

  @override
  String get compliance => 'Uyum';

  @override
  String get medications => 'İlaçlar';

  @override
  String get complianceTrend => 'Uyum Eğilimi';

  @override
  String get skip => 'Atla';

  @override
  String get take => 'Al';

  @override
  String get workoutHome => 'Workouts';

  @override
  String get recentWorkouts => 'Recent Workouts';

  @override
  String get workoutTemplates => 'Templates';

  @override
  String get createNewTemplate => 'Create New Template';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get thisWeeksVolume => 'This Week\'s Volume';

  @override
  String get thisWeeksWorkouts => 'This Week\'s Workouts';

  @override
  String get vsLastWeek => 'vs last week';

  @override
  String get activeWorkout => 'Active Workout';

  @override
  String get finishWorkout => 'Finish';

  @override
  String get discardWorkout => 'Discard Workout';

  @override
  String get discardWorkoutMessage =>
      'Are you sure? Your workout won\'t be saved.';

  @override
  String get previousSession => 'Previous';

  @override
  String setNumber(int number) {
    return 'Set $number';
  }

  @override
  String get weight => 'Weight';

  @override
  String get reps => 'Reps';

  @override
  String get warmup => 'Warmup';

  @override
  String get completeSet => 'Complete';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get skipRest => 'Skip Rest';

  @override
  String get readyForNextSet => 'Ready for next set?';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get seconds => 'seconds';

  @override
  String get workoutSummary => 'Workout Summary';

  @override
  String get duration => 'Duration';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get totalSets => 'Total Sets';

  @override
  String get exerciseCount => 'Exercises';

  @override
  String get newPRs => 'New PRs';

  @override
  String get rateWorkout => 'Rate Your Workout';

  @override
  String get workoutNotes => 'Workout Notes';

  @override
  String get shareWorkout => 'Share Workout';

  @override
  String get storyFormat => 'Story Format';

  @override
  String get compactCard => 'Compact Card';

  @override
  String get exportJSON => 'Export JSON';

  @override
  String get trackedWithVitalSync => 'Tracked with VitalSync';

  @override
  String get exerciseLibrary => 'Exercise Library';

  @override
  String get searchExercises => 'Search exercises...';

  @override
  String get allCategories => 'All';

  @override
  String get chest => 'Chest';

  @override
  String get back => 'Back';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get arms => 'Arms';

  @override
  String get legs => 'Legs';

  @override
  String get core => 'Core';

  @override
  String get cardio => 'Cardio';

  @override
  String get exerciseDetails => 'Exercise Details';

  @override
  String get instructions => 'Instructions';

  @override
  String get exerciseHistory => 'History';

  @override
  String get personalRecord => 'Personal Record';

  @override
  String get weightProgression => 'Weight Progression';

  @override
  String get createCustomExercise => 'Create Custom Exercise';

  @override
  String get progress => 'Progress';

  @override
  String get oneWeek => '1W';

  @override
  String get oneMonth => '1M';

  @override
  String get threeMonths => '3M';

  @override
  String get sixMonths => '6M';

  @override
  String get oneYear => '1Y';

  @override
  String get volumeProgression => 'Volume Progression';

  @override
  String get workoutFrequency => 'Workout Frequency';

  @override
  String get personalRecords => 'Personal Records';

  @override
  String get oneRepMax => '1RM';

  @override
  String get selectExercise => 'Select Exercise';

  @override
  String get calendar => 'Calendar';

  @override
  String get monthlyStats => 'Monthly Stats';

  @override
  String get totalWorkouts => 'Total Workouts';

  @override
  String get streak => 'Streak';

  @override
  String get vsPreviousMonth => 'vs previous month';

  @override
  String get workoutDetails => 'Workout Details';

  @override
  String get achievements => 'Achievements';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get locked => 'Locked';

  @override
  String get nearCompletion => 'Almost there!';

  @override
  String achievementProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get fitnessCategory => 'Fitness';

  @override
  String get healthCategory => 'Health';

  @override
  String get crossModuleCategory => 'Cross-Module';

  @override
  String get templateName => 'Template Name';

  @override
  String get estimatedDuration => 'Estimated Duration';

  @override
  String get exercises => 'Exercises';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get deleteTemplateConfirmation =>
      'Are you sure you want to delete this template?';

  @override
  String get sets => 'Sets';

  @override
  String get restTime => 'Rest Time';

  @override
  String get addExerciseToTemplate => 'Add Exercise';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get startYourFirstWorkout =>
      'Start your first workout to begin tracking your progress';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get createYourFirstTemplate =>
      'Create a template to quickly start workouts';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get noAchievementsYet => 'No achievements yet';

  @override
  String get keepWorkingToUnlock => 'Keep working out to unlock achievements';

  @override
  String get firstWorkoutComplete => 'First workout complete! 🔥';

  @override
  String get consistencyIsKey => 'Consistency is key! Keep your streak going';

  @override
  String get newPRCelebration => 'New Personal Record! 🏆';

  @override
  String get shareYourPR => 'Share your achievement';

  @override
  String streakMilestone(int days) {
    return '$days Day Streak! 🔥';
  }

  @override
  String get shareYourStreak => 'Share your streak?';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get min => 'min';
}
