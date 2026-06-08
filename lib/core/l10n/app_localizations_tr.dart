// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'VitalSynch';

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
  String get syncSemanticsError => 'Senkronizasyon hatası';

  @override
  String get syncErrorTooltip =>
      'Senkronizasyon hatası - tekrar denemek için dokunun';

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
  String get trackedWithVitalSynch => 'VitalSynch ile takip edildi';

  @override
  String get exerciseLibrary => 'Egzersiz Kütüphanesi';

  @override
  String get searchExercises => 'Egzersiz ara...';

  @override
  String get allCategories => 'Tümü';

  @override
  String get chest => 'Göğüs';

  @override
  String get back => 'Geri';

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
  String get noExercises => 'Bu antrenmanda egzersiz yok';

  @override
  String get muscleGroup => 'Kas Grubu';

  @override
  String get equipment => 'Ekipman';

  @override
  String get exerciseAdded => 'Egzersiz başarıyla eklendi';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String get personalInformation => 'Kişisel Bilgiler';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get enterFullName => 'Lütfen adınızı girin';

  @override
  String get dateOfBirth => 'Doğum Tarihi';

  @override
  String get selectDate => 'Tarih Seç';

  @override
  String get gender => 'Cinsiyet';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderOther => 'Diğer';

  @override
  String get genderPreferNotToSay => 'Belirtmek istemiyorum';

  @override
  String get emergencyContact => 'Acil Durum Kişisi';

  @override
  String get contactName => 'Kişi Adı';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get profileUpdatedSuccess => 'Profil başarıyla güncellendi';

  @override
  String profileUpdateError(Object error) {
    return 'Profil güncellenirken hata: $error';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get appearance => 'Görünüm';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get materialYou => 'Material You';

  @override
  String get materialYouSubtitle => 'Duvar kâğıdından dinamik renkleri kullan';

  @override
  String get language => 'Dil';

  @override
  String get languageEn => 'English';

  @override
  String get languageTr => 'Türkçe';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get enableNotifications => 'Bildirimleri Etkinleştir';

  @override
  String get units => 'Birimler';

  @override
  String get unitSystem => 'Birim Sistemi';

  @override
  String get unitMetric => 'Metrik (kg, cm)';

  @override
  String get unitImperial => 'Emperyal (lbs, in)';

  @override
  String get privacyData => 'Gizlilik ve Veri';

  @override
  String get manageConsents => 'İzinleri Yönet';

  @override
  String get manageConsentsSubtitle =>
      'GDPR gizlilik tercihlerinizi güncelleyin';

  @override
  String get exportData => 'Verileri Dışa Aktar';

  @override
  String get exportDataSubtitle => 'Verilerinizin bir kopyasını indirin';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountSubtitle =>
      'Hesabınızı ve verilerinizi kalıcı olarak silin';

  @override
  String get sync => 'Senkronizasyon';

  @override
  String get syncStatus => 'Senkronizasyon Durumu';

  @override
  String get syncIdle => 'Yakın zamanda senkronize edildi';

  @override
  String get syncError =>
      'Senkronizasyon başarısız. Yeniden denemek için dokunun.';

  @override
  String get syncNow => 'Şimdi Senkronize Et';

  @override
  String get about => 'Hakkında';

  @override
  String get version => 'Sürüm';

  @override
  String get licenses => 'Açık Kaynak Lisansları';

  @override
  String get exportStarted => 'Dışa aktarma başladı...';

  @override
  String get deleteAccountDialogTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountDialogMessage =>
      'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecek.';

  @override
  String get deleteAccountRequested => 'Hesap silme talebi alındı.';

  @override
  String get defaultUser => 'Kullanıcı';

  @override
  String get noEmail => 'E-posta yok';

  @override
  String errorLoadingProfile(Object error) {
    return 'Profil yüklenirken hata: $error';
  }

  @override
  String get logOut => 'Çıkış Yap';

  @override
  String get workouts => 'Antrenmanlar';

  @override
  String get getStarted => 'Başla';

  @override
  String get next => 'İleri';

  @override
  String get welcomeTitle => 'VitalSynch\'e Hoş Geldiniz';

  @override
  String get welcomeSubtitle =>
      'Sağlığınızı ve fitness\'ınızı tek bir yerden yönetin.';

  @override
  String get personalizationTitle => 'Sizin için en önemli olan ne?';

  @override
  String get interestMedication => 'İlaç Takibi';

  @override
  String get interestFitness => 'Fitness ve Antrenman';

  @override
  String get interestInsights => 'Akıllı İçgörüler';

  @override
  String get interestAnalysis => 'İlerleme Analizi';

  @override
  String get quickSetupTitle => 'Hızlı Kurulum';

  @override
  String get quickSetupSubtitle =>
      'İlk öğenizi ekleyerek hızlı bir başlangıç yapın.';

  @override
  String get quickAddMedication => 'İlaç Ekle';

  @override
  String get quickAddMedicationSubtitle => 'Ad ve saati hızlıca ayarlayın';

  @override
  String get quickPickTemplate => 'Antrenman Şablonu Seç';

  @override
  String get quickPickTemplateSubtitle => 'Popüler rutinlerden seçin';

  @override
  String get privacyTitle => 'Gizliliğiniz Önemli';

  @override
  String get privacySubtitle =>
      'Şeffaflığa inanıyoruz. Lütfen verilerinizin nasıl işlendiğini inceleyin ve yönetin.';

  @override
  String get consentHealthTitle => 'Sağlık Verisi İşleme';

  @override
  String get consentHealthDescription =>
      'İlaçları ve semptomları yerel olarak takip etmek için gereklidir.';

  @override
  String get consentFitnessTitle => 'Fitness Verisi İşleme';

  @override
  String get consentFitnessDescription =>
      'Antrenmanları kaydetmek ve ilerlemeyi yerel olarak izlemek için gereklidir.';

  @override
  String get consentAnalyticsTitle => 'Analitik ve Kullanım';

  @override
  String get consentAnalyticsDescription =>
      'Anonim kullanım verilerini paylaşarak VitalSynch\'i geliştirmemize yardımcı olun.';

  @override
  String get consentBackupTitle => 'Bulut Yedekleme';

  @override
  String get consentBackupDescription =>
      'Verilerinizi kaybetmemek için bulutta güvenle yedekleyin.';

  @override
  String get readPrivacyPolicy => 'Gizlilik Politikasının Tamamını Oku';

  @override
  String get acceptContinue => 'Kabul Et ve Devam Et';

  @override
  String get requiredTag => 'GEREKLİ';

  @override
  String consentRequiredMessage(String module) {
    return 'Bu, $module modülünün çalışması için gereklidir.';
  }

  @override
  String get welcomeBack => 'Tekrar Hoş Geldiniz';

  @override
  String get signInSubtitle =>
      'Sağlıklı yolculuğunuza devam etmek için giriş yapın';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get logIn => 'Giriş Yap';

  @override
  String get orSeparator => 'VEYA';

  @override
  String get continueWithApple => 'Apple ile Devam Et';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu?';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get enterEmail => 'Lütfen e-postanızı girin';

  @override
  String get enterPassword => 'Lütfen şifrenizi girin';

  @override
  String loginFailed(Object error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Apple girişi başarısız: $error';
  }

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get joinVitalSynch => 'Bugün VitalSynch\'e katılın';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get passwordLengthError => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get confirmPasswordError => 'Lütfen şifrenizi onaylayın';

  @override
  String registrationFailed(Object error) {
    return 'Kayıt başarısız: $error';
  }

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get resetPasswordSubtitle =>
      'Sıfırlama bağlantısı almak için e-postanızı girin';

  @override
  String get sendResetLink => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get resetEmailSent =>
      'Şifre sıfırlama e-postası gönderildi. Gelen kutunuzu kontrol edin.';

  @override
  String resetPasswordError(Object error) {
    return 'Hata: $error';
  }

  @override
  String get onboardingWelcomeTitle => 'VitalSynch\'e Hoş Geldiniz';

  @override
  String get onboardingWelcomeSubtitle =>
      'Hepsi bir arada sağlık ve fitness yardımcınız';

  @override
  String get onboardingPrivacyNote =>
      'Verileriniz cihazınızda kalır. Gizliliğinize saygı duyuyoruz.';

  @override
  String get onboardingHealthTitle => 'Sağlığınızı Takip Edin';

  @override
  String get onboardingHealthDescription =>
      'İlaçları, semptomları ve sağlık zaman çizelgesini yönetin';

  @override
  String get onboardingHealthFeature1 =>
      'Akıllı hatırlatıcılarla hiçbir ilacı kaçırmayın';

  @override
  String get onboardingHealthFeature2 =>
      'Semptomları kaydedin ve kalıpları takip edin';

  @override
  String get onboardingHealthFeature3 =>
      'Eksiksiz sağlık zaman çizelgenizi görüntüleyin';

  @override
  String get onboardingFitnessTitle => 'Fitness Seviyenizi Yükseltin';

  @override
  String get onboardingFitnessDescription =>
      'Antrenmanları kaydedin, ilerlemeyi takip edin, hedeflerinizi ezin';

  @override
  String get onboardingFitnessFeature1 =>
      'Detaylı egzersiz kaydı ile antrenmanları takip edin';

  @override
  String get onboardingFitnessFeature2 =>
      'Görsel grafiklerle ilerlemenizi izleyin';

  @override
  String get onboardingFitnessFeature3 =>
      'Başarıların kilidini açın ve seriler oluşturun';

  @override
  String get onboardingPrivacyTitle => 'Gizliliğiniz, Kontrolünüz';

  @override
  String get onboardingPrivacyDescription =>
      'Hangi verileri paylaşmak istediğinizi seçin';

  @override
  String get onboardingPreferencesTitle => 'Deneyiminizi Kişiselleştirin';

  @override
  String get onboardingPreferencesDescription =>
      'Dil ve tema tercihlerinizi ayarlayın';

  @override
  String get onboardingPreferencesNote =>
      'Bu ayarları istediğiniz zaman değiştirebilirsiniz';

  @override
  String get gdprAnalyticsTitle => 'Analitik ve İçgörüler';

  @override
  String get gdprAnalyticsDescription =>
      'Anonim kullanım verileriyle uygulamayı geliştirmemize yardımcı olun';

  @override
  String get gdprHealthDataTitle => 'Sağlık Verisi Depolama';

  @override
  String get gdprHealthDataDescription =>
      'İlaç ve semptom verilerinizi saklayın (gerekli)';

  @override
  String get gdprFitnessDataTitle => 'Fitness Verisi Depolama';

  @override
  String get gdprFitnessDataDescription =>
      'Antrenman ve ilerleme verilerinizi saklayın (gerekli)';

  @override
  String get gdprCloudBackupTitle => 'Bulut Yedekleme';

  @override
  String get gdprCloudBackupDescription =>
      'Cihazlar arası senkronizasyon için verilerinizi buluta yedekleyin';

  @override
  String get gdprNote =>
      'Gerekli onaylar, temel uygulama işlevselliği için gereklidir. Onayları istediğiniz zaman Ayarlar\'dan yönetebilirsiniz.';

  @override
  String get workoutComplete => 'Antrenman Tamamlandı!';

  @override
  String get greatJob => 'Harika iş! Böyle devam!';

  @override
  String get workoutNotFound => 'Antrenman bulunamadı';

  @override
  String get done => 'Tamam';

  @override
  String get share => 'Paylaş';

  @override
  String get comingSoon => 'Yakında gelecek!';

  @override
  String get volumeChart => 'Hacim Grafiği';

  @override
  String get chartComingSoon => 'Grafik yakında gelecek';

  @override
  String get summary => 'Özet';

  @override
  String get avgDuration => 'Ort. Süre';

  @override
  String get prsAchieved => 'Kırılan Rekorlar';

  @override
  String get noPRsYet => 'Henüz kişisel rekor yok. Devam et!';

  @override
  String get dismissed => 'Reddedilenler';

  @override
  String get overallWellness => 'Genel Sağlık';

  @override
  String get insightDismissed => 'İçgörü reddedildi';

  @override
  String get noDismissedInsights => 'Reddedilen içgörü yok';

  @override
  String get noInsightsYet => 'Henüz içgörü yok';

  @override
  String get insightsEmptyDescription =>
      'Veriler toplandıkça içgörüler burada görünecek';

  @override
  String dataCollectedProgress(int collected, int total) {
    return '$collected/$total gün veri toplandı';
  }

  @override
  String errorLoadingInsights(Object error) {
    return 'İçgörüler yüklenirken hata: $error';
  }

  @override
  String errorLoadingDismissedInsights(Object error) {
    return 'Reddedilen içgörüler yüklenirken hata: $error';
  }

  @override
  String get symptomHeadache => 'Baş Ağrısı';

  @override
  String get symptomNausea => 'Mide Bulantısı';

  @override
  String get symptomFatigue => 'Yorgunluk';

  @override
  String get symptomDizziness => 'Baş Dönmesi';

  @override
  String get symptomStomachPain => 'Karın Ağrısı';

  @override
  String get symptomBackPain => 'Bel Ağrısı';

  @override
  String get symptomJointPain => 'Eklem Ağrısı';

  @override
  String get symptomInsomnia => 'Uykusuzluk';

  @override
  String get symptomAnxiety => 'Anksiyete';

  @override
  String get symptomShortnessOfBreath => 'Nefes Darlığı';

  @override
  String get pleaseEnterSymptomName => 'Lütfen semptom adı girin';

  @override
  String get symptomLoggedSuccess => 'Semptom başarıyla kaydedildi';

  @override
  String errorLoggingSymptom(Object error) {
    return 'Semptom kaydedilirken hata: $error';
  }

  @override
  String get severityMild => 'Hafif';

  @override
  String get severityModerate => 'Orta';

  @override
  String get severitySevere => 'Şiddetli';

  @override
  String get severityVerySevere => 'Çok Şiddetli';

  @override
  String get severityUnbearable => 'Dayanılmaz';

  @override
  String get medicationNotFound => 'İlaç bulunamadı';

  @override
  String errorLoadingMedication(Object error) {
    return 'İlaç yüklenirken hata: $error';
  }

  @override
  String get medicationAddedSuccess => 'İlaç başarıyla eklendi';

  @override
  String get medicationUpdatedSuccess => 'İlaç başarıyla güncellendi';

  @override
  String errorSavingMedication(Object error) {
    return 'İlaç kaydedilirken hata: $error';
  }

  @override
  String get addFirstMedicationButton => 'İlk İlacı Ekle';

  @override
  String get welcomeToHealth => 'Sağlık\'a Hoş Geldiniz!';

  @override
  String get onboardingHealthMessage =>
      'İlk ilacınızı ekleyerek başlayalım. Uyumu takip etmek sağlığınıza yardımcı olur!';

  @override
  String get weeklyReport => 'Haftalık Rapor';

  @override
  String errorLoadingReport(Object error) {
    return 'Rapor yüklenirken hata: $error';
  }

  @override
  String get taken => 'Alındı';

  @override
  String get missed => 'Kaçırıldı';

  @override
  String get skipped => 'Atlandı';

  @override
  String get volume => 'Hacim';

  @override
  String get healthRing => 'Sağlık';

  @override
  String get fitnessRing => 'Fitness';

  @override
  String get wellnessRing => 'İyi Oluş';

  @override
  String get activityRings => 'Aktivite Halkaları';

  @override
  String get shareAsInfographic => 'İnfografik Olarak Paylaş (1080x1920)';

  @override
  String get perfectForStories => 'Instagram Hikayeleri için ideal';

  @override
  String get shareAsCompactCard => 'Kompakt Kart Olarak Paylaş (1080x1080)';

  @override
  String get perfectForSharing => 'Genel paylaşım için ideal';

  @override
  String get exportAsJSON => 'JSON Olarak Dışa Aktar';

  @override
  String get gdprDataPortability => 'KVKK veri taşınabilirliği';

  @override
  String get generatingImage => 'Görsel oluşturuluyor...';

  @override
  String get myWeeklyReport => 'VitalSynch haftalık raporum';

  @override
  String errorSharing(Object error) {
    return 'Paylaşım hatası: $error';
  }

  @override
  String get weeklyReportData => 'VitalSynch Haftalık Rapor Verileri';

  @override
  String get reportExportedAsJSON => 'Rapor JSON olarak dışa aktarıldı';

  @override
  String errorExporting(Object error) {
    return 'Dışa aktarma hatası: $error';
  }

  @override
  String get wasThisInsightHelpful => 'Bu içgörü faydalı mıydı?';

  @override
  String get helpful => 'Faydalı';

  @override
  String get notHelpful => 'Faydalı Değil';

  @override
  String get dismissInsight => 'İçgörüyü Kaldır';

  @override
  String get thankYouForFeedback => 'Geri bildiriminiz için teşekkürler!';

  @override
  String errorSubmittingFeedback(Object error) {
    return 'Geri bildirim gönderilirken hata: $error';
  }

  @override
  String errorDismissingInsight(Object error) {
    return 'İçgörü kaldırılırken hata: $error';
  }

  @override
  String get privacyAndData => 'Gizlilik ve Veriler';

  @override
  String get restTimerSeconds => 'saniye';

  @override
  String get skipRestButton => 'Dinlenmeyi Atla';

  @override
  String get achievementUnlocked => 'Başarım Açıldı!';

  @override
  String errorGeneric(Object error) {
    return 'Hata: $error';
  }

  @override
  String get healthSummary => 'Sağlık Özeti';

  @override
  String get fitnessSummary => 'Fitness Özeti';

  @override
  String get nextWeekSuggestions => 'Gelecek Hafta Önerileri';

  @override
  String get keepUpGreatWork => 'Harika gidiyorsun, devam et!';

  @override
  String vsLastWeekPercent(String percent) {
    return '%$percent geçen haftaya göre';
  }

  @override
  String mostMissed(String timeSlot) {
    return 'En çok kaçırılan: $timeSlot';
  }

  @override
  String bestWorkout(String name, String volume) {
    return 'En iyi antrenman: $name — ${volume}kg';
  }

  @override
  String get newPersonalRecords => 'Yeni Kişisel Rekorlar';

  @override
  String validUntilDays(int days) {
    return '$days gün geçerli';
  }

  @override
  String validUntilHours(int hours) {
    return '$hours saat geçerli';
  }

  @override
  String get validUntilSoon => 'Yakında sona erecek';

  @override
  String get takeAction => 'Harekete Geç';

  @override
  String errorLoadingInsight(Object error) {
    return 'İçgörü yüklenirken hata: $error';
  }

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String weeksAgo(int weeks) {
    return '${weeks}h önce';
  }

  @override
  String monthsAgo(int months) {
    return '${months}ay önce';
  }

  @override
  String get loading => 'Yükleniyor...';

  @override
  String errorAddingSet(Object error) {
    return 'Set eklenirken hata: $error';
  }

  @override
  String get chartError => 'Grafik Hatası';

  @override
  String get shareFunctionalityComingSoon => 'Paylaşım özelliği yakında!';

  @override
  String severityLabel(int severity) {
    return 'Şiddet: $severity';
  }

  @override
  String get errorLoadingCalendar => 'Takvim yüklenirken hata';

  @override
  String get createTemplate => 'Şablon Oluştur';

  @override
  String get createFirstTemplate =>
      'Hızlıca antrenman başlatmak için ilk şablonunu oluştur';

  @override
  String get templateSaved => 'Şablon kaydedildi';

  @override
  String get selectExercises => 'Şablonun için egzersiz seç';

  @override
  String get defaultValues => 'Varsayılan Değerler';

  @override
  String get shareAsStory => 'Story Formatı';

  @override
  String get shareAsCompact => 'Kompakt Kart';

  @override
  String get exportAsJson => 'JSON Dışa Aktar';

  @override
  String get trackedWithVitalSync => 'VitalSync ile takip edildi';

  @override
  String get biometricLogin => 'Biyometrik Giriş';

  @override
  String get biometricLoginDescription =>
      'Hızlı giriş için parmak izi veya yüz tanıma kullan';

  @override
  String get dashboardEditMode => 'Dashboard Düzenle';

  @override
  String get longPressToReorder =>
      'Kartları yeniden sıralamak için basılı tutup sürükle';

  @override
  String get previousWeek => 'Önceki Hafta';

  @override
  String get security => 'Güvenlik';

  @override
  String get invalidEmail => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get enterValidWeightAndReps =>
      'Lütfen geçerli ağırlık ve tekrar sayısı girin';

  @override
  String get weightOutOfRange => 'Ağırlık 0–999 kg arasında olmalıdır';

  @override
  String get repsOutOfRange => 'Tekrar sayısı 1–999 arasında olmalıdır';
}
