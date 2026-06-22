// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordSubtitle => 'تحديث كلمة مرور تسجيل الدخول';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get update => 'تحديث';

  @override
  String get allFieldsRequired => 'جميع الحقول مطلوبة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور الجديدتان غير متطابقتين';

  @override
  String get passwordMinLength => 'يجب ألا تقل كلمة المرور عن 6 أحرف';

  @override
  String get passwordChangedSignIn =>
      'تم تغيير كلمة المرور! يرجى تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get linkedAssistants => 'المساعدون المرتبطون';

  @override
  String get linkedAssistantsSubtitle => 'عرض المساعدين المرتبطين بحسابك';

  @override
  String get noAssistantsLinked => 'لا يوجد مساعدون مرتبطون';

  @override
  String get noAssistantsLinkedSub => 'سيظهر هنا المساعدون المعيّنون لعيادتك.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get active => 'نشط';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String languageSetTo(String language) {
    return 'تم ضبط اللغة على $language';
  }

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'غير مفعّل';

  @override
  String get darkModeEnabled => 'تم تفعيل الوضع الداكن';

  @override
  String get lightModeEnabled => 'تم تفعيل الوضع الفاتح';

  @override
  String get reportsExport => 'التقارير والتصدير';

  @override
  String get reportsExportSubtitle => 'تصدير المواعيد والمرضى والمالية';

  @override
  String get appointmentsReport => 'تقرير المواعيد';

  @override
  String get patientList => 'قائمة المرضى';

  @override
  String get financeReport => 'التقرير المالي';

  @override
  String get revenueSummary => 'ملخص الإيرادات';

  @override
  String get export => 'تصدير';

  @override
  String get reportGeneratedSuccess => 'تم إنشاء التقرير بنجاح!';

  @override
  String exportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String appointmentsCount(int count) {
    return '$count موعد';
  }

  @override
  String patientsCount(int count) {
    return '$count مريض';
  }

  @override
  String get defaultFees => 'الرسوم الافتراضية';

  @override
  String get defaultFeesSubtitle =>
      'تحديد رسوم الاستشارة وإعادة الزيارة الافتراضية';

  @override
  String get consultationFeeLabel => 'رسوم الاستشارة (جنيه)';

  @override
  String get revisitFeeLabel => 'رسوم إعادة الزيارة (جنيه)';

  @override
  String get save => 'حفظ';

  @override
  String get defaultFeesUpdated => 'تم تحديث الرسوم الافتراضية!';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج';

  @override
  String get signOutConfirmBody => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String drPrefix(String name) {
    return 'د. $name';
  }

  @override
  String get statusScheduled => 'مجدول';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get dashboard => 'الرئيسية';

  @override
  String get appointments => 'المواعيد';

  @override
  String get patients => 'المرضى';

  @override
  String get finance => 'المالية';

  @override
  String get generalPractitioner => 'طبيب عام';

  @override
  String get goodMorning => 'صباح الخير،';

  @override
  String get goodAfternoon => 'مساء الخير،';

  @override
  String get goodEvening => 'مساء الخير،';

  @override
  String get noAppointmentsToday => 'لا توجد مواعيد اليوم';

  @override
  String appointmentsDoneCount(int count, int done) {
    return '$count موعد · $done منتهي';
  }

  @override
  String get clinicOverview => 'نظرة عامة على العيادة';

  @override
  String get seenToday => 'تم رؤيته اليوم';

  @override
  String get remaining => 'المتبقي';

  @override
  String get revenueToday => 'إيرادات اليوم';

  @override
  String get patientActivity => 'نشاط المرضى';

  @override
  String get upNext => 'التالي';

  @override
  String get allAppointments => 'جميع المواعيد';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة';

  @override
  String get allCaughtUp => 'أنت على اطلاع بكل شيء!';

  @override
  String startingAt(String time) {
    return 'يبدأ في $time';
  }

  @override
  String get urgentBadge => 'عاجل';

  @override
  String get startConsultation => 'بدء الاستشارة';

  @override
  String get appointmentsThisMonth => 'المواعيد · هذا الشهر';

  @override
  String get appointmentsLast6Months => 'المواعيد · آخر 6 أشهر';

  @override
  String get appointmentsLast12Months => 'المواعيد · آخر 12 شهر';

  @override
  String totalVisits(int count) {
    return 'الإجمالي: $count زيارة';
  }

  @override
  String get noDataYet => 'لا توجد بيانات بعد';

  @override
  String get month => 'شهر';

  @override
  String get sixMo => '6 أشهر';

  @override
  String get oneYear => 'سنة';

  @override
  String get appointmentsLegend => 'المواعيد';

  @override
  String get newAppointment => 'موعد جديد';

  @override
  String get searchPatientName => 'بحث باسم المريض...';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterUpcoming => 'القادمة';

  @override
  String get filterUrgent => 'عاجل';

  @override
  String get filterDone => 'منتهي';

  @override
  String get noAppointmentsFound => 'لا توجد مواعيد';

  @override
  String get noAppointmentsFoundSub => 'جرّب فلتر مختلف أو احجز موعدًا جديدًا.';

  @override
  String get deleteAppointmentTitle => 'حذف الموعد';

  @override
  String deleteAppointmentBody(String name) {
    return 'حذف موعد $name؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get appointmentBookedSuccess => 'تم حجز الموعد بنجاح!';

  @override
  String get addPatient => 'إضافة مريض';

  @override
  String get searchPatientFull => 'بحث بالاسم أو الهاتف أو الرقم القومي...';

  @override
  String patientsTotalCount(int count) {
    return '$count مريض إجمالاً';
  }

  @override
  String resultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get noPatientsFound => 'لا يوجد مرضى';

  @override
  String get noPatientsFoundSub => 'جرّب بحثًا مختلفًا أو أضف مريضًا جديدًا.';

  @override
  String get totalRevenue => 'الإيرادات الإجمالية';

  @override
  String get collected => 'تم تحصيله';

  @override
  String get outstanding => 'المتبقي';

  @override
  String get collectionRate => 'نسبة التحصيل';

  @override
  String get paymentRecords => 'سجلات الدفع';

  @override
  String get unpaidOnly => 'غير المدفوع فقط';

  @override
  String get noPaymentRecords => 'لا توجد سجلات دفع';

  @override
  String get noPaymentRecordsSub => 'تظهر المدفوعات هنا بعد الحجز.';

  @override
  String get paidBadge => 'مدفوع';

  @override
  String get unpaidBadge => 'غير مدفوع';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get doctorRole => 'طبيب';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get genderLabel => 'الجنس';

  @override
  String get dateOfBirthLabel => 'تاريخ الميلاد';

  @override
  String get ageLabel => 'العمر';

  @override
  String yearsCount(int count) {
    return '$count سنة';
  }

  @override
  String get roleLabel => 'الدور';

  @override
  String get clinicLabel => 'العيادة';

  @override
  String get specializationLabel => 'التخصص';

  @override
  String get licenseNoLabel => 'رقم الترخيص';

  @override
  String get joinedLabel => 'تاريخ الانضمام';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get editPatientTooltip => 'تعديل المريض';

  @override
  String get overviewTab => 'نظرة عامة';

  @override
  String get visitsTab => 'الزيارات';

  @override
  String get reportsTab => 'التقارير';

  @override
  String get patientInformation => 'معلومات المريض';

  @override
  String get nationalIdLabel => 'الرقم القومي';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get regionLabel => 'المنطقة';

  @override
  String get chronicDiseases => 'الأمراض المزمنة';

  @override
  String get noChronicDiseasesRecorded => 'لا توجد أمراض مزمنة مسجلة';

  @override
  String get recentAppointments => 'المواعيد الأخيرة';

  @override
  String get unknownDate => 'تاريخ غير معروف';

  @override
  String get noVisitsRecorded => 'لا توجد زيارات مسجلة';

  @override
  String get noVisitsRecordedSub => 'تظهر الزيارات هنا بعد الاستشارات.';

  @override
  String get noReportsYet => 'لا توجد تقارير بعد';

  @override
  String get noReportsYetSub => 'تظهر التقارير هنا بعد الاستشارات الصوتية.';

  @override
  String visitNumHeader(int num, String date) {
    return 'زيارة #$num  ·  $date';
  }

  @override
  String visitReportTitle(int num) {
    return 'زيارة #$num — تقرير طبي';
  }

  @override
  String get pillDiagnosis => 'التشخيص';

  @override
  String get pillMedications => 'الأدوية';

  @override
  String get pillTreatment => 'التوصيات';

  @override
  String get pillFollowUp => 'تعليمات المتابعة';

  @override
  String get pillNotes => 'ملاحظات';

  @override
  String get treatmentRecommendations => 'التوصيات';

  @override
  String get doctorNotesLabel => 'تعليمات المتابعة';

  @override
  String get aiMedicalImaging => 'التصوير الطبي بالذكاء الاصطناعي';

  @override
  String get xrayAndSkinDetection => 'كشف الأشعة وأمراض الجلد';

  @override
  String get imageUploadTitle => 'رفع الصورة';

  @override
  String get xray => 'أشعة';

  @override
  String get skin => 'جلد';

  @override
  String get aiAnalysisTitle => 'تحليل الذكاء الاصطناعي';

  @override
  String get imagingInfoNotice =>
      'قم برفع صورة أشعة أو صورة طبية. سيقوم الذكاء الاصطناعي بتحليلها وتقديم النتائج والتوصيات.';

  @override
  String get analyzingEllipsis => 'جاري التحليل...';

  @override
  String get analyzeImage => 'تحليل الصورة';

  @override
  String get selectImageToEnable => 'اختر صورة أعلاه لتفعيل التحليل';

  @override
  String get analysisResultTitle => 'نتيجة التحليل';

  @override
  String get voiceReportTitle => 'التقرير الصوتي';

  @override
  String get transcribingAudio => 'جاري تحويل الصوت إلى نص...';

  @override
  String get additionalNotesHint => 'ملاحظات إضافية، تعليمات المتابعة...';

  @override
  String get startingConsultationEllipsis => 'جاري بدء الاستشارة...';

  @override
  String get consultationTitle => 'الاستشارة';

  @override
  String get liveBadge => 'مباشر';

  @override
  String get voiceTabLabel => 'صوت';

  @override
  String get aiImagingTabLabel => 'تصوير ذكي';

  @override
  String get saveDraftBtn => 'حفظ كمسودة';

  @override
  String get completeConsultationBtn => 'إكمال الاستشارة';

  @override
  String get leaveConsultationTitle => 'مغادرة الاستشارة؟';

  @override
  String get leaveConsultationBody => 'حفظ مسودة قبل المغادرة؟';

  @override
  String get stay => 'بقاء';

  @override
  String get leave => 'مغادرة';

  @override
  String get unknownPatient => 'مريض غير معروف';

  @override
  String get consultationDefault => 'استشارة';

  @override
  String get actionStart => 'بدء';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionDetails => 'التفاصيل';

  @override
  String get actionDelete => 'حذف';

  @override
  String get pleaseSelectPatient => 'يرجى اختيار مريض';

  @override
  String get appointmentTimeMustBeFuture =>
      'يجب أن يكون وقت الموعد في المستقبل. يرجى اختيار وقت لاحق.';

  @override
  String get selectedTimeInPast =>
      'الوقت المحدد في الماضي. يرجى اختيار وقت مستقبلي.';

  @override
  String get editAppointmentTitle => 'تعديل الموعد';

  @override
  String get visitType => 'نوع الزيارة';

  @override
  String get visitTypeConsultation => 'استشارة';

  @override
  String get visitTypeRevisit => 'إعادة زيارة';

  @override
  String get feeEgpLabel => 'الرسوم (جنيه)';

  @override
  String get dateTimeLabel => 'التاريخ والوقت';

  @override
  String get reasonNotesOptional => 'السبب / ملاحظات (اختياري)';

  @override
  String get markAsUrgent => 'وضع علامة عاجل';

  @override
  String get markAsPaid => 'وضع علامة مدفوع';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get bookAppointment => 'حجز الموعد';

  @override
  String get searchPatientNameFull =>
      'بحث عن مريض بالاسم أو الهاتف أو الرقم...';

  @override
  String get noPatientsFoundShort => 'لا يوجد مرضى';

  @override
  String get editPatientTitle => 'تعديل المريض';

  @override
  String get addNewPatientTitle => 'إضافة مريض جديد';

  @override
  String get firstNameLabel => 'الاسم الأول';

  @override
  String get lastNameLabel => 'اسم العائلة';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get emailOptionalLabel => 'البريد الإلكتروني (اختياري)';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get genderColonLabel => 'الجنس: ';

  @override
  String get tapToSelect => 'اضغط للاختيار';

  @override
  String get cannotAddNewDiseases => 'لا يمكن إضافة أمراض جديدة';

  @override
  String get firstLastNameRequired => 'الاسم الأول واسم العائلة مطلوبان.';

  @override
  String get diseaseDiabetes => 'السكري';

  @override
  String get diseaseHypertension => 'ارتفاع ضغط الدم';

  @override
  String get diseaseHeartDisease => 'مرض القلب';

  @override
  String get diseaseAsthma => 'الربو';

  @override
  String get diseaseCkd => 'مرض الكلى المزمن';

  @override
  String get currencyEgp => 'جنيه';

  @override
  String get initialConsultation => 'استشارة أولية';

  @override
  String get cameraLabel => 'الكاميرا';

  @override
  String get galleryLabel => 'المعرض';

  @override
  String get noImageSelected => 'لم يتم اختيار صورة';

  @override
  String get tapButtonsToReplace => 'اضغط على الأزرار للاستبدال';

  @override
  String get noAnalysisYet => 'لا يوجد تحليل بعد';

  @override
  String get noAnalysisYetSub =>
      'قم برفع صورة واضغط على \"تحليل الصورة\"\nلرؤية نتائج الذكاء الاصطناعي هنا.';

  @override
  String get runningAiAnalysis => 'جاري تشغيل تحليل الذكاء الاصطناعي…';

  @override
  String get aiAnalysisResultTitle => 'نتيجة تحليل الذكاء الاصطناعي';

  @override
  String get editLabel => 'تعديل';

  @override
  String get doneLabel => 'تم';

  @override
  String get editAiAnalysisHint => 'تعديل تحليل الذكاء الاصطناعي…';

  @override
  String get findingsLabel => 'النتائج';

  @override
  String get impressionLabel => 'الانطباع';

  @override
  String get differentialDiagnosesLabel => 'التشخيصات التفريقية';

  @override
  String get recommendationsLabel => 'التوصيات';

  @override
  String get qualitySuffix => 'الجودة';

  @override
  String get aiDisclaimerText =>
      'نتائج الذكاء الاصطناعي استشارية فقط. يجب مراجعة جميع النتائج وتأكيدها من الطبيب المعالج.';

  @override
  String get linkedDoctor => 'الطبيب المرتبط';

  @override
  String get linkedDoctorSubtitle => 'عرض الطبيب المعيّن لك';

  @override
  String get noDoctorLinked => 'لا يوجد طبيب مرتبط';

  @override
  String get noDoctorLinkedSub => 'تواصل مع مسؤول العيادة لربط حساب طبيب.';

  @override
  String get assistantRoleLabel => 'مساعد';

  @override
  String get payments => 'المدفوعات';

  @override
  String get switchDoctor => 'تبديل الطبيب';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusNoShow => 'لم يحضر';

  @override
  String get welcomeBack => 'مرحبًا بعودتك،';

  @override
  String get noClinic => 'بدون عيادة';

  @override
  String get confirmAppointmentAction => 'تأكيد الموعد';

  @override
  String get markAsCompletedAction => 'وضع علامة مكتمل';

  @override
  String get markAsNoShow => 'وضع علامة لم يحضر';

  @override
  String get appointmentSlotConflict =>
      'هذا الوقت محجوز بالفعل. يرجى اختيار وقت مختلف.';

  @override
  String get cancelAppointmentAction => 'إلغاء الموعد';

  @override
  String get cancelAppointmentConfirm =>
      'هل أنت متأكد أنك تريد إلغاء هذا الموعد؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get appointmentDeleted => 'تم حذف الموعد';

  @override
  String statusUpdatedTo(String status) {
    return 'تم تحديث الحالة إلى $status';
  }

  @override
  String actionFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get failedToLoadAppointments => 'فشل تحميل المواعيد';

  @override
  String get nowServing => 'قيد الخدمة الآن';

  @override
  String get todaysQueue => 'قائمة اليوم';

  @override
  String get pastLabel => 'سابق';

  @override
  String get tapToCreateAppointment => 'اضغط على + لإضافة موعد جديد.';

  @override
  String get deletePatientTitle => 'حذف المريض';

  @override
  String deletePatientBody(String name) {
    return 'حذف $name؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String patientDeleted(String name) {
    return 'تم حذف $name';
  }

  @override
  String get failedToLoadPatients => 'فشل تحميل المرضى';

  @override
  String get diseaseArthritis => 'التهاب المفاصل';

  @override
  String get addressOptionalLabel => 'العنوان (اختياري)';

  @override
  String get nationalIdOptionalLabel => 'الرقم القومي (اختياري)';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get patientUpdatedSuccess => 'تم تحديث بيانات المريض بنجاح';

  @override
  String get patientAddedSuccess => 'تم إضافة المريض بنجاح';

  @override
  String get idLabel => 'الرقم';

  @override
  String get chronicConditionsTitle => 'الأمراض المزمنة';

  @override
  String get conditionsLabel => 'الحالات';

  @override
  String get chronicConditionBadge => '⚠ حالة مزمنة';

  @override
  String appointmentsCountTitle(String count) {
    return 'المواعيد ($count)';
  }

  @override
  String get markedAsPaid => 'تم وضع علامة مدفوع';

  @override
  String get markedAsUnpaid => 'تم وضع علامة غير مدفوع';

  @override
  String failedToUpdatePayment(String error) {
    return 'فشل تحديث الدفع: $error';
  }

  @override
  String get paidCheckLabel => 'مدفوع ✓';

  @override
  String get unpaidTapLabel => 'غير مدفوع — اضغط';

  @override
  String get recordVitals => 'تسجيل العلامات الحيوية';

  @override
  String get vitalsTabLabel => 'العلامات الحيوية';

  @override
  String get patientVitals => 'العلامات الحيوية للمريض';

  @override
  String get bloodPressureLabel => 'ضغط الدم';

  @override
  String get systolicLabel => 'الانقباضي (مم زئبق)';

  @override
  String get diastolicLabel => 'الانبساطي (مم زئبق)';

  @override
  String get heartRateLabel => 'معدل ضربات القلب (نبضة/دقيقة)';

  @override
  String get temperatureLabel => 'درجة الحرارة (°م)';

  @override
  String get weightLabel => 'الوزن (كجم)';

  @override
  String get heightLabel => 'الطول (سم)';

  @override
  String get chiefComplaintLabel => 'الشكوى الرئيسية';

  @override
  String get chiefComplaintHint => 'السبب الرئيسي للزيارة...';

  @override
  String get vitalsNotesLabel => 'ملاحظات';

  @override
  String get vitalsNotesHint => 'ملاحظات إضافية...';

  @override
  String get vitalsSavedSuccess => 'تم حفظ العلامات الحيوية بنجاح';

  @override
  String vitalsSaveFailed(String error) {
    return 'فشل حفظ العلامات الحيوية: $error';
  }

  @override
  String get noVitalsRecorded => 'لم تُسجَّل علامات حيوية';

  @override
  String get noVitalsRecordedSub =>
      'سيقوم المساعد بتسجيل العلامات الحيوية قبل الاستشارة.';

  @override
  String get vitalsRecordedByAssistant => 'سُجِّلت بواسطة المساعد';

  @override
  String get bpmUnit => 'نبضة/دقيقة';

  @override
  String get celsiusUnit => '°م';

  @override
  String get kgUnit => 'كجم';

  @override
  String get cmUnit => 'سم';

  @override
  String get mmhgUnit => 'مم زئبق';

  @override
  String recordVitalsForPatient(String name) {
    return 'تسجيل العلامات الحيوية — $name';
  }

  @override
  String get vitalsOptionalNote => 'جميع الحقول اختيارية. سجِّل ما هو متاح.';

  @override
  String get vitalsAlreadyRecorded =>
      'العلامات الحيوية مسجلة مسبقاً — جارٍ التحديث';

  @override
  String get updateVitals => 'تحديث العلامات الحيوية';

  @override
  String get labReportsTabLabel => 'مختبر';

  @override
  String get labReportsTitle => 'تقارير المختبر';

  @override
  String get uploadLabReport => 'رفع تقرير مختبر';

  @override
  String get noLabReportsYet => 'لا توجد تقارير مختبر بعد';

  @override
  String get noLabReportsYetSub => 'قم برفع تقارير PDF الخاصة بهذه الزيارة.';

  @override
  String get labReportUploadSuccess => 'تم رفع تقرير المختبر بنجاح';

  @override
  String labReportUploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get selectPdfFile => 'اختر ملف PDF';

  @override
  String get noPdfSelected => 'لم يتم اختيار ملف';

  @override
  String get labReportViewerTitle => 'تقرير المختبر';

  @override
  String get aiInterpretationLabel => 'ملخص الطبيب';

  @override
  String get saveInterpretation => 'حفظ';

  @override
  String get interpretationSaved => 'تم حفظ الملخص';

  @override
  String interpretationSaveFailed(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String get editInterpretation => 'تعديل الملخص';

  @override
  String get noInterpretationYet =>
      'لم يتم إضافة ملخص بعد. اضغط تعديل لإضافة ملاحظاتك السريرية.';

  @override
  String get openReportLabel => 'فتح التقرير';

  @override
  String get uploadedOnLabel => 'تاريخ الرفع';

  @override
  String get labReportsForVisit => 'تقارير المختبر';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String profileUpdateFailed(String error) {
    return 'فشل تحديث الملف الشخصي: $error';
  }

  @override
  String get minTwoCharsRequired => 'مطلوب حرفان على الأقل';

  @override
  String get phoneNumberInvalid => 'أدخل رقم هاتف صالح';

  @override
  String get endOfResults => 'نهاية النتائج';

  @override
  String get loadingMore => 'جارٍ التحميل…';
}
