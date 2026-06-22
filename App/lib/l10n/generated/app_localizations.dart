import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your login password'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordChangedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Password changed! Please sign in with your new password.'**
  String get passwordChangedSignIn;

  /// No description provided for @linkedAssistants.
  ///
  /// In en, this message translates to:
  /// **'Linked Assistants'**
  String get linkedAssistants;

  /// No description provided for @linkedAssistantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View assistants linked to your account'**
  String get linkedAssistantsSubtitle;

  /// No description provided for @noAssistantsLinked.
  ///
  /// In en, this message translates to:
  /// **'No assistants linked'**
  String get noAssistantsLinked;

  /// No description provided for @noAssistantsLinkedSub.
  ///
  /// In en, this message translates to:
  /// **'Assistants assigned to your clinic will appear here.'**
  String get noAssistantsLinkedSub;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to {language}'**
  String languageSetTo(String language);

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeEnabled;

  /// No description provided for @lightModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Light mode enabled'**
  String get lightModeEnabled;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export'**
  String get reportsExport;

  /// No description provided for @reportsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export appointments, patients & finance'**
  String get reportsExportSubtitle;

  /// No description provided for @appointmentsReport.
  ///
  /// In en, this message translates to:
  /// **'Appointments Report'**
  String get appointmentsReport;

  /// No description provided for @patientList.
  ///
  /// In en, this message translates to:
  /// **'Patient List'**
  String get patientList;

  /// No description provided for @financeReport.
  ///
  /// In en, this message translates to:
  /// **'Finance Report'**
  String get financeReport;

  /// No description provided for @revenueSummary.
  ///
  /// In en, this message translates to:
  /// **'Revenue summary'**
  String get revenueSummary;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @reportGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully!'**
  String get reportGeneratedSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @appointmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments'**
  String appointmentsCount(int count);

  /// No description provided for @patientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} patients'**
  String patientsCount(int count);

  /// No description provided for @defaultFees.
  ///
  /// In en, this message translates to:
  /// **'Default Fees'**
  String get defaultFees;

  /// No description provided for @defaultFeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set consultation & revisit fee defaults'**
  String get defaultFeesSubtitle;

  /// No description provided for @consultationFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee (EGP)'**
  String get consultationFeeLabel;

  /// No description provided for @revisitFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Revisit Fee (EGP)'**
  String get revisitFeeLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @defaultFeesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default fees updated!'**
  String get defaultFeesUpdated;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmBody;

  /// No description provided for @drPrefix.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name}'**
  String drPrefix(String name);

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @generalPractitioner.
  ///
  /// In en, this message translates to:
  /// **'General Practitioner'**
  String get generalPractitioner;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No appointments today'**
  String get noAppointmentsToday;

  /// No description provided for @appointmentsDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointment{count, plural, =1{} other{s}} · {done} done'**
  String appointmentsDoneCount(int count, int done);

  /// No description provided for @clinicOverview.
  ///
  /// In en, this message translates to:
  /// **'Clinic overview'**
  String get clinicOverview;

  /// No description provided for @seenToday.
  ///
  /// In en, this message translates to:
  /// **'Seen today'**
  String get seenToday;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @revenueToday.
  ///
  /// In en, this message translates to:
  /// **'Revenue today'**
  String get revenueToday;

  /// No description provided for @patientActivity.
  ///
  /// In en, this message translates to:
  /// **'Patient activity'**
  String get patientActivity;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @allAppointments.
  ///
  /// In en, this message translates to:
  /// **'All Appointments'**
  String get allAppointments;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @startingAt.
  ///
  /// In en, this message translates to:
  /// **'Starting at {time}'**
  String startingAt(String time);

  /// No description provided for @urgentBadge.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgentBadge;

  /// No description provided for @startConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start consultation'**
  String get startConsultation;

  /// No description provided for @appointmentsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Appointments · this month'**
  String get appointmentsThisMonth;

  /// No description provided for @appointmentsLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Appointments · last 6 months'**
  String get appointmentsLast6Months;

  /// No description provided for @appointmentsLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Appointments · last 12 months'**
  String get appointmentsLast12Months;

  /// No description provided for @totalVisits.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} visits'**
  String totalVisits(int count);

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @sixMo.
  ///
  /// In en, this message translates to:
  /// **'6 Mo'**
  String get sixMo;

  /// No description provided for @oneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get oneYear;

  /// No description provided for @appointmentsLegend.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsLegend;

  /// No description provided for @newAppointment.
  ///
  /// In en, this message translates to:
  /// **'New Appointment'**
  String get newAppointment;

  /// No description provided for @searchPatientName.
  ///
  /// In en, this message translates to:
  /// **'Search patient name...'**
  String get searchPatientName;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get filterUpcoming;

  /// No description provided for @filterUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get filterUrgent;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @noAppointmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No appointments found'**
  String get noAppointmentsFound;

  /// No description provided for @noAppointmentsFoundSub.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or book a new appointment.'**
  String get noAppointmentsFoundSub;

  /// No description provided for @deleteAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Appointment'**
  String get deleteAppointmentTitle;

  /// No description provided for @deleteAppointmentBody.
  ///
  /// In en, this message translates to:
  /// **'Delete appointment for {name}? This cannot be undone.'**
  String deleteAppointmentBody(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @appointmentBookedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked successfully!'**
  String get appointmentBookedSuccess;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @searchPatientFull.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, or national ID...'**
  String get searchPatientFull;

  /// No description provided for @patientsTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} patients total'**
  String patientsTotalCount(int count);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @noPatientsFoundSub.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or add a new patient.'**
  String get noPatientsFoundSub;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate'**
  String get collectionRate;

  /// No description provided for @paymentRecords.
  ///
  /// In en, this message translates to:
  /// **'Payment Records'**
  String get paymentRecords;

  /// No description provided for @unpaidOnly.
  ///
  /// In en, this message translates to:
  /// **'Unpaid only'**
  String get unpaidOnly;

  /// No description provided for @noPaymentRecords.
  ///
  /// In en, this message translates to:
  /// **'No payment records'**
  String get noPaymentRecords;

  /// No description provided for @noPaymentRecordsSub.
  ///
  /// In en, this message translates to:
  /// **'Payments appear here after booking.'**
  String get noPaymentRecordsSub;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidBadge;

  /// No description provided for @unpaidBadge.
  ///
  /// In en, this message translates to:
  /// **'UNPAID'**
  String get unpaidBadge;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @doctorRole.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorRole;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @yearsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} years'**
  String yearsCount(int count);

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @clinicLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinicLabel;

  /// No description provided for @specializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specializationLabel;

  /// No description provided for @licenseNoLabel.
  ///
  /// In en, this message translates to:
  /// **'License No.'**
  String get licenseNoLabel;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @editPatientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient'**
  String get editPatientTooltip;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @visitsTab.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsTab;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @patientInformation.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInformation;

  /// No description provided for @nationalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @regionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionLabel;

  /// No description provided for @chronicDiseases.
  ///
  /// In en, this message translates to:
  /// **'Chronic Diseases'**
  String get chronicDiseases;

  /// No description provided for @noChronicDiseasesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No chronic diseases recorded'**
  String get noChronicDiseasesRecorded;

  /// No description provided for @recentAppointments.
  ///
  /// In en, this message translates to:
  /// **'Recent Appointments'**
  String get recentAppointments;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @noVisitsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No visits recorded'**
  String get noVisitsRecorded;

  /// No description provided for @noVisitsRecordedSub.
  ///
  /// In en, this message translates to:
  /// **'Visits appear here after consultations.'**
  String get noVisitsRecordedSub;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @noReportsYetSub.
  ///
  /// In en, this message translates to:
  /// **'Reports appear here after voice consultations.'**
  String get noReportsYetSub;

  /// No description provided for @visitNumHeader.
  ///
  /// In en, this message translates to:
  /// **'Visit #{num}  ·  {date}'**
  String visitNumHeader(int num, String date);

  /// No description provided for @visitReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit #{num} — Medical Report'**
  String visitReportTitle(int num);

  /// No description provided for @pillDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get pillDiagnosis;

  /// No description provided for @pillMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get pillMedications;

  /// No description provided for @pillTreatment.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get pillTreatment;

  /// No description provided for @pillFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Instructions'**
  String get pillFollowUp;

  /// No description provided for @pillNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pillNotes;

  /// No description provided for @treatmentRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get treatmentRecommendations;

  /// No description provided for @doctorNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Instructions'**
  String get doctorNotesLabel;

  /// No description provided for @aiMedicalImaging.
  ///
  /// In en, this message translates to:
  /// **'AI Medical Imaging'**
  String get aiMedicalImaging;

  /// No description provided for @xrayAndSkinDetection.
  ///
  /// In en, this message translates to:
  /// **'X-ray & skin disease detection'**
  String get xrayAndSkinDetection;

  /// No description provided for @imageUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Upload'**
  String get imageUploadTitle;

  /// No description provided for @xray.
  ///
  /// In en, this message translates to:
  /// **'X-Ray'**
  String get xray;

  /// No description provided for @skin.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get skin;

  /// No description provided for @aiAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysisTitle;

  /// No description provided for @imagingInfoNotice.
  ///
  /// In en, this message translates to:
  /// **'Upload an X-ray or medical image. The AI will analyze it and provide findings and recommendations.'**
  String get imagingInfoNotice;

  /// No description provided for @analyzingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzingEllipsis;

  /// No description provided for @analyzeImage.
  ///
  /// In en, this message translates to:
  /// **'Analyze Image'**
  String get analyzeImage;

  /// No description provided for @selectImageToEnable.
  ///
  /// In en, this message translates to:
  /// **'Select an image above to enable analysis'**
  String get selectImageToEnable;

  /// No description provided for @analysisResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis Result'**
  String get analysisResultTitle;

  /// No description provided for @voiceReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Report'**
  String get voiceReportTitle;

  /// No description provided for @transcribingAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio...'**
  String get transcribingAudio;

  /// No description provided for @additionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes, follow-up instructions...'**
  String get additionalNotesHint;

  /// No description provided for @startingConsultationEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Starting consultation...'**
  String get startingConsultationEllipsis;

  /// No description provided for @consultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationTitle;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @voiceTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTabLabel;

  /// No description provided for @aiImagingTabLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Imaging'**
  String get aiImagingTabLabel;

  /// No description provided for @saveDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraftBtn;

  /// No description provided for @completeConsultationBtn.
  ///
  /// In en, this message translates to:
  /// **'Complete Consultation'**
  String get completeConsultationBtn;

  /// No description provided for @leaveConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Consultation?'**
  String get leaveConsultationTitle;

  /// No description provided for @leaveConsultationBody.
  ///
  /// In en, this message translates to:
  /// **'Save a draft before leaving?'**
  String get leaveConsultationBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @unknownPatient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Patient'**
  String get unknownPatient;

  /// No description provided for @consultationDefault.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationDefault;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get actionDetails;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @pleaseSelectPatient.
  ///
  /// In en, this message translates to:
  /// **'Please select a patient'**
  String get pleaseSelectPatient;

  /// No description provided for @appointmentTimeMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Appointment time must be in the future. Please pick a later time.'**
  String get appointmentTimeMustBeFuture;

  /// No description provided for @selectedTimeInPast.
  ///
  /// In en, this message translates to:
  /// **'Selected time is in the past. Please choose a future time.'**
  String get selectedTimeInPast;

  /// No description provided for @editAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Appointment'**
  String get editAppointmentTitle;

  /// No description provided for @visitType.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get visitType;

  /// No description provided for @visitTypeConsultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get visitTypeConsultation;

  /// No description provided for @visitTypeRevisit.
  ///
  /// In en, this message translates to:
  /// **'Revisit'**
  String get visitTypeRevisit;

  /// No description provided for @feeEgpLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee (EGP)'**
  String get feeEgpLabel;

  /// No description provided for @dateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTimeLabel;

  /// No description provided for @reasonNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason / Notes (optional)'**
  String get reasonNotesOptional;

  /// No description provided for @markAsUrgent.
  ///
  /// In en, this message translates to:
  /// **'Mark as Urgent'**
  String get markAsUrgent;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @searchPatientNameFull.
  ///
  /// In en, this message translates to:
  /// **'Search patient by name, phone or ID...'**
  String get searchPatientNameFull;

  /// No description provided for @noPatientsFoundShort.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFoundShort;

  /// No description provided for @editPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient'**
  String get editPatientTitle;

  /// No description provided for @addNewPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Patient'**
  String get addNewPatientTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @genderColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender: '**
  String get genderColonLabel;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @cannotAddNewDiseases.
  ///
  /// In en, this message translates to:
  /// **'Cannot add new diseases'**
  String get cannotAddNewDiseases;

  /// No description provided for @firstLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First and last name are required.'**
  String get firstLastNameRequired;

  /// No description provided for @diseaseDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diseaseDiabetes;

  /// No description provided for @diseaseHypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get diseaseHypertension;

  /// No description provided for @diseaseHeartDisease.
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get diseaseHeartDisease;

  /// No description provided for @diseaseAsthma.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get diseaseAsthma;

  /// No description provided for @diseaseCkd.
  ///
  /// In en, this message translates to:
  /// **'Chronic Kidney Disease'**
  String get diseaseCkd;

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currencyEgp;

  /// No description provided for @initialConsultation.
  ///
  /// In en, this message translates to:
  /// **'Initial Consultation'**
  String get initialConsultation;

  /// No description provided for @cameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @tapButtonsToReplace.
  ///
  /// In en, this message translates to:
  /// **'Tap buttons to replace'**
  String get tapButtonsToReplace;

  /// No description provided for @noAnalysisYet.
  ///
  /// In en, this message translates to:
  /// **'No analysis yet'**
  String get noAnalysisYet;

  /// No description provided for @noAnalysisYetSub.
  ///
  /// In en, this message translates to:
  /// **'Upload an image and tap \"Analyze Image\"\nto see AI results here.'**
  String get noAnalysisYetSub;

  /// No description provided for @runningAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Running AI analysis…'**
  String get runningAiAnalysis;

  /// No description provided for @aiAnalysisResultTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Result'**
  String get aiAnalysisResultTitle;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @editAiAnalysisHint.
  ///
  /// In en, this message translates to:
  /// **'Edit AI analysis…'**
  String get editAiAnalysisHint;

  /// No description provided for @findingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get findingsLabel;

  /// No description provided for @impressionLabel.
  ///
  /// In en, this message translates to:
  /// **'Impression'**
  String get impressionLabel;

  /// No description provided for @differentialDiagnosesLabel.
  ///
  /// In en, this message translates to:
  /// **'Differential Diagnoses'**
  String get differentialDiagnosesLabel;

  /// No description provided for @recommendationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsLabel;

  /// No description provided for @qualitySuffix.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualitySuffix;

  /// No description provided for @aiDisclaimerText.
  ///
  /// In en, this message translates to:
  /// **'AI results are advisory only. All findings must be reviewed and confirmed by the treating physician.'**
  String get aiDisclaimerText;

  /// No description provided for @linkedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Linked Doctor'**
  String get linkedDoctor;

  /// No description provided for @linkedDoctorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View the doctor you are assigned to'**
  String get linkedDoctorSubtitle;

  /// No description provided for @noDoctorLinked.
  ///
  /// In en, this message translates to:
  /// **'No doctor linked'**
  String get noDoctorLinked;

  /// No description provided for @noDoctorLinkedSub.
  ///
  /// In en, this message translates to:
  /// **'Contact your clinic admin to link a doctor account.'**
  String get noDoctorLinkedSub;

  /// No description provided for @assistantRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantRoleLabel;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @switchDoctor.
  ///
  /// In en, this message translates to:
  /// **'Switch doctor'**
  String get switchDoctor;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get statusNoShow;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @noClinic.
  ///
  /// In en, this message translates to:
  /// **'No Clinic'**
  String get noClinic;

  /// No description provided for @confirmAppointmentAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment'**
  String get confirmAppointmentAction;

  /// No description provided for @markAsCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompletedAction;

  /// No description provided for @markAsNoShow.
  ///
  /// In en, this message translates to:
  /// **'Mark as No-Show'**
  String get markAsNoShow;

  /// No description provided for @appointmentSlotConflict.
  ///
  /// In en, this message translates to:
  /// **'This time slot is already booked. Please choose a different time.'**
  String get appointmentSlotConflict;

  /// No description provided for @cancelAppointmentAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointmentAction;

  /// No description provided for @cancelAppointmentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get cancelAppointmentConfirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @appointmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Appointment deleted'**
  String get appointmentDeleted;

  /// No description provided for @statusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Status updated to {status}'**
  String statusUpdatedTo(String status);

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String actionFailed(String error);

  /// No description provided for @failedToLoadAppointments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load appointments'**
  String get failedToLoadAppointments;

  /// No description provided for @nowServing.
  ///
  /// In en, this message translates to:
  /// **'Now Serving'**
  String get nowServing;

  /// No description provided for @todaysQueue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Queue'**
  String get todaysQueue;

  /// No description provided for @pastLabel.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastLabel;

  /// No description provided for @tapToCreateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new appointment.'**
  String get tapToCreateAppointment;

  /// No description provided for @deletePatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Patient'**
  String get deletePatientTitle;

  /// No description provided for @deletePatientBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String deletePatientBody(String name);

  /// No description provided for @patientDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String patientDeleted(String name);

  /// No description provided for @failedToLoadPatients.
  ///
  /// In en, this message translates to:
  /// **'Failed to load patients'**
  String get failedToLoadPatients;

  /// No description provided for @diseaseArthritis.
  ///
  /// In en, this message translates to:
  /// **'Arthritis'**
  String get diseaseArthritis;

  /// No description provided for @addressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptionalLabel;

  /// No description provided for @nationalIdOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID (optional)'**
  String get nationalIdOptionalLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @patientUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Patient updated successfully'**
  String get patientUpdatedSuccess;

  /// No description provided for @patientAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Patient added successfully'**
  String get patientAddedSuccess;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @chronicConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chronic Conditions'**
  String get chronicConditionsTitle;

  /// No description provided for @conditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsLabel;

  /// No description provided for @chronicConditionBadge.
  ///
  /// In en, this message translates to:
  /// **'⚠ Chronic Condition'**
  String get chronicConditionBadge;

  /// No description provided for @appointmentsCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments ({count})'**
  String appointmentsCountTitle(String count);

  /// No description provided for @markedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get markedAsPaid;

  /// No description provided for @markedAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as unpaid'**
  String get markedAsUnpaid;

  /// No description provided for @failedToUpdatePayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to update payment: {error}'**
  String failedToUpdatePayment(String error);

  /// No description provided for @paidCheckLabel.
  ///
  /// In en, this message translates to:
  /// **'PAID ✓'**
  String get paidCheckLabel;

  /// No description provided for @unpaidTapLabel.
  ///
  /// In en, this message translates to:
  /// **'UNPAID — Tap'**
  String get unpaidTapLabel;

  /// No description provided for @recordVitals.
  ///
  /// In en, this message translates to:
  /// **'Record Vitals'**
  String get recordVitals;

  /// No description provided for @vitalsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitalsTabLabel;

  /// No description provided for @patientVitals.
  ///
  /// In en, this message translates to:
  /// **'Patient Vitals'**
  String get patientVitals;

  /// No description provided for @bloodPressureLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressureLabel;

  /// No description provided for @systolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Systolic (mmHg)'**
  String get systolicLabel;

  /// No description provided for @diastolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Diastolic (mmHg)'**
  String get diastolicLabel;

  /// No description provided for @heartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate (bpm)'**
  String get heartRateLabel;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureLabel;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightLabel;

  /// No description provided for @chiefComplaintLabel.
  ///
  /// In en, this message translates to:
  /// **'Chief Complaint'**
  String get chiefComplaintLabel;

  /// No description provided for @chiefComplaintHint.
  ///
  /// In en, this message translates to:
  /// **'Main reason for visit...'**
  String get chiefComplaintHint;

  /// No description provided for @vitalsNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vitalsNotesLabel;

  /// No description provided for @vitalsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional observations...'**
  String get vitalsNotesHint;

  /// No description provided for @vitalsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vitals saved successfully'**
  String get vitalsSavedSuccess;

  /// No description provided for @vitalsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vitals: {error}'**
  String vitalsSaveFailed(String error);

  /// No description provided for @noVitalsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No vitals recorded'**
  String get noVitalsRecorded;

  /// No description provided for @noVitalsRecordedSub.
  ///
  /// In en, this message translates to:
  /// **'The assistant will record vitals before the consultation.'**
  String get noVitalsRecordedSub;

  /// No description provided for @vitalsRecordedByAssistant.
  ///
  /// In en, this message translates to:
  /// **'Recorded by assistant'**
  String get vitalsRecordedByAssistant;

  /// No description provided for @bpmUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpmUnit;

  /// No description provided for @celsiusUnit.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get celsiusUnit;

  /// No description provided for @kgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// No description provided for @cmUnit.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cmUnit;

  /// No description provided for @mmhgUnit.
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get mmhgUnit;

  /// No description provided for @recordVitalsForPatient.
  ///
  /// In en, this message translates to:
  /// **'Record Vitals — {name}'**
  String recordVitalsForPatient(String name);

  /// No description provided for @vitalsOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional. Record what is available.'**
  String get vitalsOptionalNote;

  /// No description provided for @vitalsAlreadyRecorded.
  ///
  /// In en, this message translates to:
  /// **'Vitals already recorded — updating'**
  String get vitalsAlreadyRecorded;

  /// No description provided for @updateVitals.
  ///
  /// In en, this message translates to:
  /// **'Update Vitals'**
  String get updateVitals;

  /// No description provided for @labReportsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get labReportsTabLabel;

  /// No description provided for @labReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab Reports'**
  String get labReportsTitle;

  /// No description provided for @uploadLabReport.
  ///
  /// In en, this message translates to:
  /// **'Upload Lab Report'**
  String get uploadLabReport;

  /// No description provided for @noLabReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No lab reports yet'**
  String get noLabReportsYet;

  /// No description provided for @noLabReportsYetSub.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF lab reports for this visit.'**
  String get noLabReportsYetSub;

  /// No description provided for @labReportUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lab report uploaded successfully'**
  String get labReportUploadSuccess;

  /// No description provided for @labReportUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String labReportUploadFailed(String error);

  /// No description provided for @selectPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Select PDF File'**
  String get selectPdfFile;

  /// No description provided for @noPdfSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noPdfSelected;

  /// No description provided for @labReportViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab Report'**
  String get labReportViewerTitle;

  /// No description provided for @aiInterpretationLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s Summary'**
  String get aiInterpretationLabel;

  /// No description provided for @saveInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveInterpretation;

  /// No description provided for @interpretationSaved.
  ///
  /// In en, this message translates to:
  /// **'Summary saved'**
  String get interpretationSaved;

  /// No description provided for @interpretationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String interpretationSaveFailed(String error);

  /// No description provided for @editInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Edit Summary'**
  String get editInterpretation;

  /// No description provided for @noInterpretationYet.
  ///
  /// In en, this message translates to:
  /// **'No summary added yet. Tap Edit to add your clinical notes.'**
  String get noInterpretationYet;

  /// No description provided for @openReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Report'**
  String get openReportLabel;

  /// No description provided for @uploadedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedOnLabel;

  /// No description provided for @labReportsForVisit.
  ///
  /// In en, this message translates to:
  /// **'Lab Reports'**
  String get labReportsForVisit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profileUpdateFailed(String error);

  /// No description provided for @minTwoCharsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum 2 characters required'**
  String get minTwoCharsRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneNumberInvalid;

  /// No description provided for @endOfResults.
  ///
  /// In en, this message translates to:
  /// **'End of results'**
  String get endOfResults;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get loadingMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
