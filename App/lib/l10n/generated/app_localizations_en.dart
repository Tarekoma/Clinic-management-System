// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update your login password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get update => 'Update';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get passwordsDoNotMatch => 'New passwords do not match';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordChangedSignIn =>
      'Password changed! Please sign in with your new password.';

  @override
  String get linkedAssistants => 'Linked Assistants';

  @override
  String get linkedAssistantsSubtitle =>
      'View assistants linked to your account';

  @override
  String get noAssistantsLinked => 'No assistants linked';

  @override
  String get noAssistantsLinkedSub =>
      'Assistants assigned to your clinic will appear here.';

  @override
  String get retry => 'Retry';

  @override
  String get active => 'Active';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String languageSetTo(String language) {
    return 'Language set to $language';
  }

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get lightModeEnabled => 'Light mode enabled';

  @override
  String get reportsExport => 'Reports & Export';

  @override
  String get reportsExportSubtitle => 'Export appointments, patients & finance';

  @override
  String get appointmentsReport => 'Appointments Report';

  @override
  String get patientList => 'Patient List';

  @override
  String get financeReport => 'Finance Report';

  @override
  String get revenueSummary => 'Revenue summary';

  @override
  String get export => 'Export';

  @override
  String get reportGeneratedSuccess => 'Report generated successfully!';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String appointmentsCount(int count) {
    return '$count appointments';
  }

  @override
  String patientsCount(int count) {
    return '$count patients';
  }

  @override
  String get defaultFees => 'Default Fees';

  @override
  String get defaultFeesSubtitle => 'Set consultation & revisit fee defaults';

  @override
  String get consultationFeeLabel => 'Consultation Fee (EGP)';

  @override
  String get revisitFeeLabel => 'Revisit Fee (EGP)';

  @override
  String get save => 'Save';

  @override
  String get defaultFeesUpdated => 'Default fees updated!';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String drPrefix(String name) {
    return 'Dr. $name';
  }

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get appointments => 'Appointments';

  @override
  String get patients => 'Patients';

  @override
  String get finance => 'Finance';

  @override
  String get generalPractitioner => 'General Practitioner';

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get goodAfternoon => 'Good afternoon,';

  @override
  String get goodEvening => 'Good evening,';

  @override
  String get noAppointmentsToday => 'No appointments today';

  @override
  String appointmentsDoneCount(int count, int done) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count appointment$_temp0 · $done done';
  }

  @override
  String get clinicOverview => 'Clinic overview';

  @override
  String get seenToday => 'Seen today';

  @override
  String get remaining => 'Remaining';

  @override
  String get revenueToday => 'Revenue today';

  @override
  String get patientActivity => 'Patient activity';

  @override
  String get upNext => 'Up Next';

  @override
  String get allAppointments => 'All Appointments';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get allCaughtUp => 'You\'re all caught up!';

  @override
  String startingAt(String time) {
    return 'Starting at $time';
  }

  @override
  String get urgentBadge => 'URGENT';

  @override
  String get startConsultation => 'Start consultation';

  @override
  String get appointmentsThisMonth => 'Appointments · this month';

  @override
  String get appointmentsLast6Months => 'Appointments · last 6 months';

  @override
  String get appointmentsLast12Months => 'Appointments · last 12 months';

  @override
  String totalVisits(int count) {
    return 'Total: $count visits';
  }

  @override
  String get noDataYet => 'No data yet';

  @override
  String get month => 'Month';

  @override
  String get sixMo => '6 Mo';

  @override
  String get oneYear => '1 Year';

  @override
  String get appointmentsLegend => 'Appointments';

  @override
  String get newAppointment => 'New Appointment';

  @override
  String get searchPatientName => 'Search patient name...';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterUrgent => 'Urgent';

  @override
  String get filterDone => 'Done';

  @override
  String get noAppointmentsFound => 'No appointments found';

  @override
  String get noAppointmentsFoundSub =>
      'Try a different filter or book a new appointment.';

  @override
  String get deleteAppointmentTitle => 'Delete Appointment';

  @override
  String deleteAppointmentBody(String name) {
    return 'Delete appointment for $name? This cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get appointmentBookedSuccess => 'Appointment booked successfully!';

  @override
  String get addPatient => 'Add Patient';

  @override
  String get searchPatientFull => 'Search by name, phone, or national ID...';

  @override
  String patientsTotalCount(int count) {
    return '$count patients total';
  }

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String get noPatientsFoundSub =>
      'Try a different search or add a new patient.';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get collected => 'Collected';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get collectionRate => 'Collection Rate';

  @override
  String get paymentRecords => 'Payment Records';

  @override
  String get unpaidOnly => 'Unpaid only';

  @override
  String get noPaymentRecords => 'No payment records';

  @override
  String get noPaymentRecordsSub => 'Payments appear here after booking.';

  @override
  String get paidBadge => 'PAID';

  @override
  String get unpaidBadge => 'UNPAID';

  @override
  String get notAvailable => 'N/A';

  @override
  String get myProfile => 'My Profile';

  @override
  String get doctorRole => 'Doctor';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get genderLabel => 'Gender';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get ageLabel => 'Age';

  @override
  String yearsCount(int count) {
    return '$count years';
  }

  @override
  String get roleLabel => 'Role';

  @override
  String get clinicLabel => 'Clinic';

  @override
  String get specializationLabel => 'Specialization';

  @override
  String get licenseNoLabel => 'License No.';

  @override
  String get joinedLabel => 'Joined';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get editPatientTooltip => 'Edit Patient';

  @override
  String get overviewTab => 'Overview';

  @override
  String get visitsTab => 'Visits';

  @override
  String get reportsTab => 'Reports';

  @override
  String get patientInformation => 'Patient Information';

  @override
  String get nationalIdLabel => 'National ID';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get regionLabel => 'Region';

  @override
  String get chronicDiseases => 'Chronic Diseases';

  @override
  String get noChronicDiseasesRecorded => 'No chronic diseases recorded';

  @override
  String get recentAppointments => 'Recent Appointments';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get noVisitsRecorded => 'No visits recorded';

  @override
  String get noVisitsRecordedSub => 'Visits appear here after consultations.';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get noReportsYetSub =>
      'Reports appear here after voice consultations.';

  @override
  String visitNumHeader(int num, String date) {
    return 'Visit #$num  ·  $date';
  }

  @override
  String visitReportTitle(int num) {
    return 'Visit #$num — Medical Report';
  }

  @override
  String get pillDiagnosis => 'Diagnosis';

  @override
  String get pillMedications => 'Medications';

  @override
  String get pillTreatment => 'Recommendations';

  @override
  String get pillFollowUp => 'Follow-up Instructions';

  @override
  String get pillNotes => 'Notes';

  @override
  String get treatmentRecommendations => 'Recommendations';

  @override
  String get doctorNotesLabel => 'Follow-up Instructions';

  @override
  String get aiMedicalImaging => 'AI Medical Imaging';

  @override
  String get xrayAndSkinDetection => 'X-ray & skin disease detection';

  @override
  String get imageUploadTitle => 'Image Upload';

  @override
  String get xray => 'X-Ray';

  @override
  String get skin => 'Skin';

  @override
  String get aiAnalysisTitle => 'AI Analysis';

  @override
  String get imagingInfoNotice =>
      'Upload an X-ray or medical image. The AI will analyze it and provide findings and recommendations.';

  @override
  String get analyzingEllipsis => 'Analyzing...';

  @override
  String get analyzeImage => 'Analyze Image';

  @override
  String get selectImageToEnable => 'Select an image above to enable analysis';

  @override
  String get analysisResultTitle => 'Analysis Result';

  @override
  String get voiceReportTitle => 'Voice Report';

  @override
  String get transcribingAudio => 'Transcribing audio...';

  @override
  String get additionalNotesHint =>
      'Additional notes, follow-up instructions...';

  @override
  String get startingConsultationEllipsis => 'Starting consultation...';

  @override
  String get consultationTitle => 'Consultation';

  @override
  String get liveBadge => 'Live';

  @override
  String get voiceTabLabel => 'Voice';

  @override
  String get aiImagingTabLabel => 'AI Imaging';

  @override
  String get saveDraftBtn => 'Save Draft';

  @override
  String get completeConsultationBtn => 'Complete Consultation';

  @override
  String get leaveConsultationTitle => 'Leave Consultation?';

  @override
  String get leaveConsultationBody => 'Save a draft before leaving?';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get unknownPatient => 'Unknown Patient';

  @override
  String get consultationDefault => 'Consultation';

  @override
  String get actionStart => 'Start';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDetails => 'Details';

  @override
  String get actionDelete => 'Delete';

  @override
  String get pleaseSelectPatient => 'Please select a patient';

  @override
  String get appointmentTimeMustBeFuture =>
      'Appointment time must be in the future. Please pick a later time.';

  @override
  String get selectedTimeInPast =>
      'Selected time is in the past. Please choose a future time.';

  @override
  String get editAppointmentTitle => 'Edit Appointment';

  @override
  String get visitType => 'Visit Type';

  @override
  String get visitTypeConsultation => 'Consultation';

  @override
  String get visitTypeRevisit => 'Revisit';

  @override
  String get feeEgpLabel => 'Fee (EGP)';

  @override
  String get dateTimeLabel => 'Date & Time';

  @override
  String get reasonNotesOptional => 'Reason / Notes (optional)';

  @override
  String get markAsUrgent => 'Mark as Urgent';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get searchPatientNameFull => 'Search patient by name, phone or ID...';

  @override
  String get noPatientsFoundShort => 'No patients found';

  @override
  String get editPatientTitle => 'Edit Patient';

  @override
  String get addNewPatientTitle => 'Add New Patient';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get emailOptionalLabel => 'Email (optional)';

  @override
  String get addressLabel => 'Address';

  @override
  String get genderColonLabel => 'Gender: ';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get cannotAddNewDiseases => 'Cannot add new diseases';

  @override
  String get firstLastNameRequired => 'First and last name are required.';

  @override
  String get diseaseDiabetes => 'Diabetes';

  @override
  String get diseaseHypertension => 'Hypertension';

  @override
  String get diseaseHeartDisease => 'Heart Disease';

  @override
  String get diseaseAsthma => 'Asthma';

  @override
  String get diseaseCkd => 'Chronic Kidney Disease';

  @override
  String get currencyEgp => 'EGP';

  @override
  String get initialConsultation => 'Initial Consultation';

  @override
  String get cameraLabel => 'Camera';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get tapButtonsToReplace => 'Tap buttons to replace';

  @override
  String get noAnalysisYet => 'No analysis yet';

  @override
  String get noAnalysisYetSub =>
      'Upload an image and tap \"Analyze Image\"\nto see AI results here.';

  @override
  String get runningAiAnalysis => 'Running AI analysis…';

  @override
  String get aiAnalysisResultTitle => 'AI Analysis Result';

  @override
  String get editLabel => 'Edit';

  @override
  String get doneLabel => 'Done';

  @override
  String get editAiAnalysisHint => 'Edit AI analysis…';

  @override
  String get findingsLabel => 'Findings';

  @override
  String get impressionLabel => 'Impression';

  @override
  String get differentialDiagnosesLabel => 'Differential Diagnoses';

  @override
  String get recommendationsLabel => 'Recommendations';

  @override
  String get qualitySuffix => 'Quality';

  @override
  String get aiDisclaimerText =>
      'AI results are advisory only. All findings must be reviewed and confirmed by the treating physician.';

  @override
  String get linkedDoctor => 'Linked Doctor';

  @override
  String get linkedDoctorSubtitle => 'View the doctor you are assigned to';

  @override
  String get noDoctorLinked => 'No doctor linked';

  @override
  String get noDoctorLinkedSub =>
      'Contact your clinic admin to link a doctor account.';

  @override
  String get assistantRoleLabel => 'Assistant';

  @override
  String get payments => 'Payments';

  @override
  String get switchDoctor => 'Switch doctor';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusNoShow => 'No Show';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get noClinic => 'No Clinic';

  @override
  String get confirmAppointmentAction => 'Confirm Appointment';

  @override
  String get markAsCompletedAction => 'Mark as Completed';

  @override
  String get markAsNoShow => 'Mark as No-Show';

  @override
  String get appointmentSlotConflict =>
      'This time slot is already booked. Please choose a different time.';

  @override
  String get cancelAppointmentAction => 'Cancel Appointment';

  @override
  String get cancelAppointmentConfirm =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get appointmentDeleted => 'Appointment deleted';

  @override
  String statusUpdatedTo(String status) {
    return 'Status updated to $status';
  }

  @override
  String actionFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get failedToLoadAppointments => 'Failed to load appointments';

  @override
  String get nowServing => 'Now Serving';

  @override
  String get todaysQueue => 'Today\'s Queue';

  @override
  String get pastLabel => 'Past';

  @override
  String get tapToCreateAppointment => 'Tap + to create a new appointment.';

  @override
  String get deletePatientTitle => 'Delete Patient';

  @override
  String deletePatientBody(String name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String patientDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get failedToLoadPatients => 'Failed to load patients';

  @override
  String get diseaseArthritis => 'Arthritis';

  @override
  String get addressOptionalLabel => 'Address (optional)';

  @override
  String get nationalIdOptionalLabel => 'National ID (optional)';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get patientUpdatedSuccess => 'Patient updated successfully';

  @override
  String get patientAddedSuccess => 'Patient added successfully';

  @override
  String get idLabel => 'ID';

  @override
  String get chronicConditionsTitle => 'Chronic Conditions';

  @override
  String get conditionsLabel => 'Conditions';

  @override
  String get chronicConditionBadge => '⚠ Chronic Condition';

  @override
  String appointmentsCountTitle(String count) {
    return 'Appointments ($count)';
  }

  @override
  String get markedAsPaid => 'Marked as paid';

  @override
  String get markedAsUnpaid => 'Marked as unpaid';

  @override
  String failedToUpdatePayment(String error) {
    return 'Failed to update payment: $error';
  }

  @override
  String get paidCheckLabel => 'PAID ✓';

  @override
  String get unpaidTapLabel => 'UNPAID — Tap';

  @override
  String get recordVitals => 'Record Vitals';

  @override
  String get vitalsTabLabel => 'Vitals';

  @override
  String get patientVitals => 'Patient Vitals';

  @override
  String get bloodPressureLabel => 'Blood Pressure';

  @override
  String get systolicLabel => 'Systolic (mmHg)';

  @override
  String get diastolicLabel => 'Diastolic (mmHg)';

  @override
  String get heartRateLabel => 'Heart Rate (bpm)';

  @override
  String get temperatureLabel => 'Temperature (°C)';

  @override
  String get weightLabel => 'Weight (kg)';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get chiefComplaintLabel => 'Chief Complaint';

  @override
  String get chiefComplaintHint => 'Main reason for visit...';

  @override
  String get vitalsNotesLabel => 'Notes';

  @override
  String get vitalsNotesHint => 'Additional observations...';

  @override
  String get vitalsSavedSuccess => 'Vitals saved successfully';

  @override
  String vitalsSaveFailed(String error) {
    return 'Failed to save vitals: $error';
  }

  @override
  String get noVitalsRecorded => 'No vitals recorded';

  @override
  String get noVitalsRecordedSub =>
      'The assistant will record vitals before the consultation.';

  @override
  String get vitalsRecordedByAssistant => 'Recorded by assistant';

  @override
  String get bpmUnit => 'bpm';

  @override
  String get celsiusUnit => '°C';

  @override
  String get kgUnit => 'kg';

  @override
  String get cmUnit => 'cm';

  @override
  String get mmhgUnit => 'mmHg';

  @override
  String recordVitalsForPatient(String name) {
    return 'Record Vitals — $name';
  }

  @override
  String get vitalsOptionalNote =>
      'All fields are optional. Record what is available.';

  @override
  String get vitalsAlreadyRecorded => 'Vitals already recorded — updating';

  @override
  String get updateVitals => 'Update Vitals';

  @override
  String get labReportsTabLabel => 'Labs';

  @override
  String get labReportsTitle => 'Lab Reports';

  @override
  String get uploadLabReport => 'Upload Lab Report';

  @override
  String get noLabReportsYet => 'No lab reports yet';

  @override
  String get noLabReportsYetSub => 'Upload PDF lab reports for this visit.';

  @override
  String get labReportUploadSuccess => 'Lab report uploaded successfully';

  @override
  String labReportUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get selectPdfFile => 'Select PDF File';

  @override
  String get noPdfSelected => 'No file selected';

  @override
  String get labReportViewerTitle => 'Lab Report';

  @override
  String get aiInterpretationLabel => 'Doctor\'s Summary';

  @override
  String get saveInterpretation => 'Save';

  @override
  String get interpretationSaved => 'Summary saved';

  @override
  String interpretationSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get editInterpretation => 'Edit Summary';

  @override
  String get noInterpretationYet =>
      'No summary added yet. Tap Edit to add your clinical notes.';

  @override
  String get openReportLabel => 'Open Report';

  @override
  String get uploadedOnLabel => 'Uploaded';

  @override
  String get labReportsForVisit => 'Lab Reports';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String profileUpdateFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get minTwoCharsRequired => 'Minimum 2 characters required';

  @override
  String get phoneNumberInvalid => 'Enter a valid phone number';

  @override
  String get endOfResults => 'End of results';

  @override
  String get loadingMore => 'Loading more…';
}
