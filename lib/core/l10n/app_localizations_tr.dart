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
  String get exerciseName => 'Egzersiz Adı';

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
  String get workoutHome => 'Antrenmanlar';

  @override
  String get recentWorkouts => 'Son Antrenmanlar';

  @override
  String get workoutTemplates => 'Şablonlar';

  @override
  String get createNewTemplate => 'Yeni Şablon Oluştur';

  @override
  String get quickStats => 'Hızlı İstatistikler';

  @override
  String get thisWeeksVolume => 'Bu Haftanın Hacmi';

  @override
  String get thisWeeksWorkouts => 'Bu Haftanın Antrenmanları';

  @override
  String get vsLastWeek => 'geçen haftaya göre';

  @override
  String get activeWorkout => 'Aktif Antrenman';

  @override
  String get finishWorkout => 'Bitir';

  @override
  String get discardWorkout => 'Antrenmanı İptal Et';

  @override
  String get discardWorkoutMessage =>
      'Emin misin? Antrenmanın kaydedilmeyecek.';

  @override
  String get previousSession => 'Önceki';

  @override
  String setNumber(int number) {
    return 'Set $number';
  }

  @override
  String get weight => 'Ağırlık';

  @override
  String get reps => 'Tekrar';

  @override
  String get warmup => 'Isınma';

  @override
  String get completeSet => 'Tamamla';

  @override
  String get restTimer => 'Dinlenme Sayacı';

  @override
  String get skipRest => 'Dinlenmeyi Atla';

  @override
  String get readyForNextSet => 'Sonraki set için hazır mısın?';

  @override
  String get addExercise => 'Egzersiz Ekle';

  @override
  String get seconds => 'saniye';

  @override
  String get workoutSummary => 'Antrenman Özeti';

  @override
  String get duration => 'Süre';

  @override
  String get totalVolume => 'Toplam Hacim';

  @override
  String get totalSets => 'Toplam Set';

  @override
  String get exerciseCount => 'Egzersizler';

  @override
  String get newPRs => 'Yeni Rekorlar';

  @override
  String get rateWorkout => 'Antrenmanı Değerlendir';

  @override
  String get workoutNotes => 'Antrenman Notları';

  @override
  String get shareWorkout => 'Antrenmanı Paylaş';

  @override
  String get storyFormat => 'Hikaye Formatı';

  @override
  String get compactCard => 'Kompakt Kart';

  @override
  String get exportJSON => 'JSON Dışa Aktar';

  @override
  String get trackedWithVitalSync => 'VitalSync ile takip edildi';

  @override
  String get exerciseLibrary => 'Egzersiz Kütüphanesi';

  @override
  String get searchExercises => 'Egzersiz ara...';

  @override
  String get allCategories => 'Tümü';

  @override
  String get chest => 'Göğüs';

  @override
  String get back => 'Sırt';

  @override
  String get shoulders => 'Omuzlar';

  @override
  String get arms => 'Kollar';

  @override
  String get legs => 'Bacaklar';

  @override
  String get core => 'Karın';

  @override
  String get cardio => 'Kardio';

  @override
  String get exerciseDetails => 'Egzersiz Detayları';

  @override
  String get instructions => 'Talimatlar';

  @override
  String get exerciseHistory => 'Geçmiş';

  @override
  String get personalRecord => 'Kişisel Rekor';

  @override
  String get weightProgression => 'Ağırlık İlerlemesi';

  @override
  String get createCustomExercise => 'Özel Egzersiz Oluştur';

  @override
  String get progress => 'İlerleme';

  @override
  String get oneWeek => '1H';

  @override
  String get oneMonth => '1A';

  @override
  String get threeMonths => '3A';

  @override
  String get sixMonths => '6A';

  @override
  String get oneYear => '1Y';

  @override
  String get volumeProgression => 'Hacim İlerlemesi';

  @override
  String get workoutFrequency => 'Antrenman Sıklığı';

  @override
  String get personalRecords => 'Kişisel Rekorlar';

  @override
  String get oneRepMax => '1TM';

  @override
  String get selectExercise => 'Egzersiz Seç';

  @override
  String get calendar => 'Takvim';

  @override
  String get monthlyStats => 'Aylık İstatistikler';

  @override
  String get totalWorkouts => 'Toplam Antrenman';

  @override
  String get streak => 'Seri';

  @override
  String get vsPreviousMonth => 'önceki aya göre';

  @override
  String get workoutDetails => 'Antrenman Detayları';

  @override
  String get achievements => 'Başarılar';

  @override
  String get unlocked => 'Açıldı';

  @override
  String get locked => 'Kilitli';

  @override
  String get nearCompletion => 'Neredeyse tamam!';

  @override
  String achievementProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get fitnessCategory => 'Fitness';

  @override
  String get healthCategory => 'Sağlık';

  @override
  String get crossModuleCategory => 'Çapraz Modül';

  @override
  String get templateName => 'Şablon Adı';

  @override
  String get estimatedDuration => 'Tahmini Süre';

  @override
  String get exercises => 'Egzersizler';

  @override
  String get editTemplate => 'Şablonu Düzenle';

  @override
  String get deleteTemplate => 'Şablonu Sil';

  @override
  String get deleteTemplateConfirmation =>
      'Bu şablonu silmek istediğinden emin misin?';

  @override
  String get sets => 'Setler';

  @override
  String get restTime => 'Dinlenme Süresi';

  @override
  String get addExerciseToTemplate => 'Egzersiz Ekle';

  @override
  String get noWorkoutsYet => 'Henüz antrenman yok';

  @override
  String get startYourFirstWorkout =>
      'İlerlemenizi takip etmek için ilk antrenmanınızı başlatın';

  @override
  String get noTemplatesYet => 'Henüz şablon yok';

  @override
  String get createYourFirstTemplate =>
      'Hızlıca antrenman başlatmak için bir şablon oluşturun';

  @override
  String get noExercisesFound => 'Egzersiz bulunamadı';

  @override
  String get noAchievementsYet => 'Henüz başarı yok';

  @override
  String get keepWorkingToUnlock =>
      'Başarıları açmak için antrenman yapmaya devam edin';

  @override
  String get firstWorkoutComplete => 'İlk antrenman tamamlandı! 🔥';

  @override
  String get consistencyIsKey => 'Tutarlılık anahtardır! Serini sürdür';

  @override
  String get newPRCelebration => 'Yeni Kişisel Rekor! 🏆';

  @override
  String get shareYourPR => 'Başarını paylaş';

  @override
  String streakMilestone(int days) {
    return '$days Gün Seri! 🔥';
  }

  @override
  String get shareYourStreak => 'Serini paylaş?';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get min => 'dk';

  @override
  String get noExercises => 'No exercises in this workout';

  @override
  String get muscleGroup => 'Kas Grubu';

  @override
  String get equipment => 'Ekipman';

  @override
  String get exerciseAdded => 'Egzersiz başarıyla eklendi';
}
