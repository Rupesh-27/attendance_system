import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  german('de', 'German', 'Deutsch', '🇩🇪'),
  belarusian('be', 'Belarusian', 'Беларуская', '🇧🇾'),
  english('en', 'English', 'English', '🇬🇧');

  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage(this.code, this.name, this.nativeName, this.flag);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'de':
        return AppLanguage.german;
      case 'be':
        return AppLanguage.belarusian;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  static const String _prefLanguageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;
  String get currentCode => _currentLanguage.code;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefLanguageKey);
      if (code != null) {
        _currentLanguage = AppLanguage.fromCode(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, language.code);
    } catch (_) {}
  }

  static String tr(String key) {
    final lang = instance._currentLanguage;
    final dict = _translations[lang] ?? _translations[AppLanguage.english]!;
    return dict[key] ?? _translations[AppLanguage.english]?[key] ?? key;
  }

  static String localizeLeaveType(String? nameOrCode) {
    if (nameOrCode == null || nameOrCode.isEmpty) return '';
    final trimmed = nameOrCode.trim();
    final direct = tr(trimmed);
    if (direct != trimmed) return direct;

    final lower = trimmed.toLowerCase();
    if (lower.contains('casual') || trimmed.toUpperCase() == 'CL') {
      return tr('Casual Leave');
    }
    if (lower.contains('sick') || trimmed.toUpperCase() == 'SL') {
      return tr('Sick Leave');
    }
    if (lower.contains('paid') || trimmed.toUpperCase() == 'PL') {
      return tr('Paid Leave');
    }
    return trimmed;
  }

  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      // General & Bottom Nav
      'dashboard': 'Dashboard',
      'attendance': 'Attendance',
      'leaves': 'Leaves',
      'profile': 'Profile',
      'my_profile': 'My Profile',
      'logout': 'Logout',
      'change': 'Change',
      'cancel': 'Cancel',

      // Profile Screen
      'employee_information': 'Employee Information',
      'employee_id': 'Employee ID',
      'email': 'Email',
      'status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',
      'role': 'Role',
      'EMPLOYEE': 'Employee',
      'Employee': 'Employee',
      'ADMIN': 'Administrator',
      'HR': 'HR',
      'work_information': 'Work Information',
      'assigned_office': 'Assigned Office',
      'geofence_radius': 'Geofence Radius',
      'meters': 'meters',
      'app_preferences': 'App Preferences',
      'language_preferences': 'Language Preferences',
      'Language preferences': 'Language Preferences',
      'language': 'Language',
      'language_selection': 'Language Selection',
      'choose_language': 'Select Language',
      'choose_language_desc': 'Choose your preferred language for the application interface',
      'language_updated': 'Language updated successfully',

      // Dashboard
      'welcome_back': 'Welcome back',
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'checked_in': 'Checked In',
      'checked_out': 'Checked Out',
      'todays_attendance': 'Today\'s Attendance',
      'working_hours': 'Working Hours',
      'current_location': 'Current Location',
      'inside_office': 'Inside Office',
      'outside_office': 'Outside Office',
      'quick_actions': 'Quick Actions',
      'view_history': 'View History',
      'confirm_check_in': 'Confirm Check In',
      'confirm_check_out': 'Confirm Check Out',
      'refresh': 'Refresh',
      'daily_effort': 'Daily Effort',
      'monthly_effort': 'Monthly Effort',
      'total_break_hours': 'Total Break Hours',
      'not_checked_in': 'Not Checked In',
      'verifying_location': 'Verifying Location...',
      'geofence_status': 'Location Status',

      // Leave Management
      'my_leaves': 'My Leaves',
      'leave_balance': 'Leave Balance',
      'application_history': 'Application History',
      'all_requests': 'All Requests',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'withdrawn': 'Withdrawn',
      'cancel_requested': 'Cancel Requested',
      'cancelled': 'Cancelled',
      'no_leave_requests': 'No Leave Requests Found',
      'no_requests_filter': 'No requests match the selected filter(s)',
      'tap_apply_leave': 'Tap "Apply Leave" below to submit your first request',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'duration': 'Duration',
      'applied_on': 'Applied On',
      'applying_to': 'Applying To',
      'cc_to': 'CC To',
      'reason': 'Reason',
      'manager_remarks': 'Manager Remarks',
      'leave_balances': 'Leave Balances',
      'apply_leave': 'Apply Leave',
      'select_leave_type': 'Select Leave Type',
      'reason_for_leave': 'Reason for Leave',
      'submit_application': 'Submit Application',
      'withdraw': 'Withdraw',
      'withdraw_application': 'Withdraw Application',
      'request_cancellation': 'Request Cancellation',
      'day': 'Day',
      'days': 'Days',
      'Days': 'Days',
      'days_left': 'days left',
      'history': 'History',
      'History': 'History',
      'allocated': 'Allocated',
      'Allocated': 'Allocated',
      'used': 'Used',
      'Used': 'Used',
      'available': 'Available',
      'Available': 'Available',
      'Casual Leave': 'Casual Leave',
      'Paid Leave': 'Paid Leave',
      'Sick Leave': 'Sick Leave',
      'casual_leave': 'Casual Leave',
      'paid_leave': 'Paid Leave',
      'sick_leave': 'Sick Leave',
      'filtered_by': 'Filtered by',
      'rule_cl': 'Max 1 day per application • Urgent personal work',
      'rule_sl': 'Medical certificate required for 2+ consecutive days',
      'rule_pl': 'Privilege leave for planned holidays and family events',
      'rule_standard': 'Annual allowance for standard employee entitlement',
      'show_all_requests': 'Show All Requests',
      'Show All Requests': 'Show All Requests',
      'back': 'Back',
      'Back': 'Back',
      'total_duration': 'Total Duration',
      'apply_for_leave': 'Apply for Leave',
      'leave_type': 'Leave Type',
      'add': 'Add',
      'Add': 'Add',
      'cl_policy_banner': 'Casual Leave: Max 1 day • 1 application per calendar month',
      'sl_policy_banner': 'Medical certificate document is required for Sick Leave of 2+ days',
      'half_day_leave': 'Half Day Leave',
      'half_day_desc': '0.5 day deduction for partial shift',
      'session_1_am': 'Session 1 (AM)',
      'session_2_pm': 'Session 2 (PM)',
      'reason_hint': 'e.g. Doctor appointment, family function, personal work...',
      'attach_file': 'Attach File',
      'file_selected': '1 file selected',
      'optional_file_types': 'Optional (PDF, JPG, PNG)',
      'upload_supporting_doc': 'Upload Supporting Document',
      'upload_size_limit': 'PDF or Images up to 10 MB',
      'browse': 'Browse',
      'submit_leave_request': 'Submit Leave Request',
      'add_cc': 'Add CC',
      'add_cc_desc': 'Enter colleague name or email to keep them notified:',
      'add_cc_hint': 'e.g. Alice Smith, HR',
      'leave_applied_success': 'Leave application submitted successfully!',
      'error_select_leave_type': 'Please select a leave type',
      'error_provide_reason': 'Please provide a reason for the leave',
      'error_cl_max_1_day': 'Casual Leave cannot exceed 1 day per application.',
      'error_file_too_large': 'Selected file exceeds the 10 MB limit.',
      'error_pick_file': 'Unable to pick file. Please try again.',
      'month_1': 'Jan',
      'month_2': 'Feb',
      'month_3': 'Mar',
      'month_4': 'Apr',
      'month_5': 'May',
      'month_6': 'Jun',
      'month_7': 'Jul',
      'month_8': 'Aug',
      'month_9': 'Sep',
      'month_10': 'Oct',
      'month_11': 'Nov',
      'month_12': 'Dec',

      // Attendance History
      'attendance_history': 'Attendance History',
      'present': 'Present',
      'absent': 'Absent',
      'filter': 'Filter',
      'view': 'View',
      'monthly_attendance': 'Monthly Attendance',
      'select_month_year': 'Select Month & Year',

      // Login
      'welcome_to_brandhrms': 'Welcome to BrandHRMS',
      'employee_login': 'Employee Login',
      'employee_id_or_email': 'Employee ID or Email',
      'password': 'Password',
      'remember_me': 'Remember Me',
      'login': 'Login',
    },

    AppLanguage.german: {
      // General & Bottom Nav
      'dashboard': 'Dashboard',
      'attendance': 'Anwesenheit',
      'leaves': 'Urlaub',
      'profile': 'Profil',
      'my_profile': 'Mein Profil',
      'logout': 'Abmelden',
      'change': 'Ändern',
      'cancel': 'Abbrechen',

      // Profile Screen
      'employee_information': 'Mitarbeiterinformationen',
      'employee_id': 'Mitarbeiter-ID',
      'email': 'E-Mail',
      'status': 'Status',
      'active': 'Aktiv',
      'inactive': 'Inaktiv',
      'role': 'Rolle',
      'EMPLOYEE': 'Mitarbeiter',
      'Employee': 'Mitarbeiter',
      'ADMIN': 'Administrator',
      'HR': 'Personalabteilung',
      'work_information': 'Arbeitsinformationen',
      'assigned_office': 'Zugewiesenes Büro',
      'geofence_radius': 'Standortradius (Geofence)',
      'meters': 'Meter',
      'app_preferences': 'App-Einstellungen',
      'language_preferences': 'Spracheinstellungen',
      'Language preferences': 'Spracheinstellungen',
      'language': 'Sprache',
      'language_selection': 'Sprachauswahl',
      'choose_language': 'Sprache auswählen',
      'choose_language_desc': 'Wählen Sie Ihre bevorzugte Sprache für die Benutzeroberfläche',
      'language_updated': 'Sprache erfolgreich auf Deutsch aktualisiert',

      // Dashboard
      'welcome_back': 'Willkommen zurück',
      'check_in': 'Einchecken',
      'check_out': 'Auschecken',
      'checked_in': 'Eingecheckt',
      'checked_out': 'Ausgecheckt',
      'todays_attendance': 'Heutige Anwesenheit',
      'working_hours': 'Arbeitszeit',
      'current_location': 'Aktueller Standort',
      'inside_office': 'Im Büro',
      'outside_office': 'Außerhalb des Büros',
      'quick_actions': 'Schnellaktionen',
      'view_history': 'Verlauf anzeigen',
      'confirm_check_in': 'Einchecken bestätigen',
      'confirm_check_out': 'Auschecken bestätigen',
      'refresh': 'Aktualisieren',
      'daily_effort': 'Täglicher Aufwand',
      'monthly_effort': 'Monatlicher Aufwand',
      'total_break_hours': 'Gesamte Pausenzeit',
      'not_checked_in': 'Nicht eingecheckt',
      'verifying_location': 'Standort wird überprüft...',
      'geofence_status': 'Standortstatus',

      // Leave Management
      'my_leaves': 'Mein Urlaub',
      'leave_balance': 'Urlaubskonto',
      'application_history': 'Antragsverlauf',
      'all_requests': 'Alle Anträge',
      'pending': 'Ausstehend',
      'approved': 'Genehmigt',
      'rejected': 'Abgelehnt',
      'withdrawn': 'Zurückgezogen',
      'cancel_requested': 'Stornierung beantragt',
      'cancelled': 'Storniert',
      'no_leave_requests': 'Keine Urlaubsanträge gefunden',
      'no_requests_filter': 'Keine Anträge entsprechen dem ausgewählten Filter',
      'tap_apply_leave': 'Tippen Sie unten auf „Urlaub beantragen“, um Ihren ersten Antrag einzureichen',
      'from_date': 'Von Datum',
      'to_date': 'Bis Datum',
      'duration': 'Dauer',
      'applied_on': 'Beantragt am',
      'applying_to': 'Antrag an',
      'cc_to': 'CC an',
      'reason': 'Grund',
      'manager_remarks': 'Bemerkungen des Vorgesetzten',
      'leave_balances': 'Urlaubssalden',
      'apply_leave': 'Urlaub beantragen',
      'select_leave_type': 'Urlaubsart auswählen',
      'reason_for_leave': 'Grund für den Urlaub',
      'submit_application': 'Antrag einreichen',
      'withdraw': 'Zurückziehen',
      'withdraw_application': 'Antrag zurückziehen',
      'request_cancellation': 'Stornierung beantragen',
      'day': 'Tag',
      'days': 'Tage',
      'Days': 'Tage',
      'days_left': 'Tage übrig',
      'history': 'Verlauf',
      'History': 'Verlauf',
      'allocated': 'Zugewiesen',
      'Allocated': 'Zugewiesen',
      'used': 'Genommen',
      'Used': 'Genommen',
      'available': 'Verfügbar',
      'Available': 'Verfügbar',
      'Casual Leave': 'Sonderurlaub',
      'Paid Leave': 'Erholungsurlaub',
      'Sick Leave': 'Krankenurlaub',
      'casual_leave': 'Sonderurlaub',
      'paid_leave': 'Erholungsurlaub',
      'sick_leave': 'Krankenurlaub',
      'filtered_by': 'Gefiltert nach',
      'rule_cl': 'Max. 1 Tag pro Antrag • Dringende persönliche Angelegenheiten',
      'rule_sl': 'Ärztliches Attest ab 2 aufeinanderfolgenden Tagen erforderlich',
      'rule_pl': 'Erholungsurlaub für geplante Ferien und Familienfeiern',
      'rule_standard': 'Jahreskontingent für regulären Mitarbeiteranspruch',
      'show_all_requests': 'Alle Anträge anzeigen',
      'Show All Requests': 'Alle Anträge anzeigen',
      'back': 'Zurück',
      'Back': 'Zurück',
      'total_duration': 'Gesamtdauer',
      'apply_for_leave': 'Urlaub beantragen',
      'leave_type': 'Urlaubsart',
      'add': 'Hinzufügen',
      'Add': 'Hinzufügen',
      'cl_policy_banner': 'Sonderurlaub: Max. 1 Tag • 1 Antrag pro Kalendermonat',
      'sl_policy_banner': 'Ärztliches Attest für Krankenurlaub ab 2 Tagen erforderlich',
      'half_day_leave': 'Halber Tag Urlaub',
      'half_day_desc': '0,5 Tage Abzug für Teilschicht',
      'session_1_am': 'Schicht 1 (Vormittag)',
      'session_2_pm': 'Schicht 2 (Nachmittag)',
      'reason_hint': 'z.B. Arzttermin, Familienfeier, persönliche Angelegenheiten...',
      'attach_file': 'Datei anhängen',
      'file_selected': '1 Datei ausgewählt',
      'optional_file_types': 'Optional (PDF, JPG, PNG)',
      'upload_supporting_doc': 'Nachweisdokument hochladen',
      'upload_size_limit': 'PDF oder Bilder bis zu 10 MB',
      'browse': 'Durchsuchen',
      'submit_leave_request': 'Urlaubsantrag einreichen',
      'add_cc': 'CC hinzufügen',
      'add_cc_desc': 'Geben Sie den Namen oder die E-Mail des Kollegen ein:',
      'add_cc_hint': 'z.B. Alice Smith, HR',
      'leave_applied_success': 'Urlaubsantrag erfolgreich eingereicht!',
      'error_select_leave_type': 'Bitte wählen Sie eine Urlaubsart aus',
      'error_provide_reason': 'Bitte geben Sie einen Grund für den Urlaub an',
      'error_cl_max_1_day': 'Sonderurlaub darf 1 Tag pro Antrag nicht überschreiten.',
      'error_file_too_large': 'Die ausgewählte Datei überschreitet das 10-MB-Limit.',
      'error_pick_file': 'Datei konnte nicht ausgewählt werden. Bitte erneut versuchen.',
      'month_1': 'Jan',
      'month_2': 'Feb',
      'month_3': 'Mär',
      'month_4': 'Apr',
      'month_5': 'Mai',
      'month_6': 'Jun',
      'month_7': 'Jul',
      'month_8': 'Aug',
      'month_9': 'Sep',
      'month_10': 'Okt',
      'month_11': 'Nov',
      'month_12': 'Dez',

      // Attendance History
      'attendance_history': 'Anwesenheitsverlauf',
      'present': 'Anwesend',
      'absent': 'Abwesend',
      'filter': 'Filter',
      'view': 'Ansicht',
      'monthly_attendance': 'Monatliche Anwesenheit',
      'select_month_year': 'Monat & Jahr auswählen',

      // Login
      'welcome_to_brandhrms': 'Willkommen bei BrandHRMS',
      'employee_login': 'Mitarbeiter-Login',
      'employee_id_or_email': 'Mitarbeiter-ID oder E-Mail',
      'password': 'Passwort',
      'remember_me': 'Angemeldet bleiben',
      'login': 'Anmelden',
    },

    AppLanguage.belarusian: {
      // General & Bottom Nav
      'dashboard': 'Галоўная',
      'attendance': 'Наведвальнасць',
      'leaves': 'Адпачынак',
      'profile': 'Профіль',
      'my_profile': 'Мой профіль',
      'logout': 'Выйсці',
      'change': 'Змяніць',
      'cancel': 'Адмена',

      // Profile Screen
      'employee_information': 'Інфармацыя пра супрацоўніка',
      'employee_id': 'ID супрацоўніка',
      'email': 'Электронная пошта',
      'status': 'Статус',
      'active': 'Актыўны',
      'inactive': 'Неактыўны',
      'role': 'Роля',
      'EMPLOYEE': 'Супрацоўнік',
      'Employee': 'Супрацоўнік',
      'ADMIN': 'Адміністратар',
      'HR': 'HR',
      'work_information': 'Працоўная інфармацыя',
      'assigned_office': 'Прызначаны офіс',
      'geofence_radius': 'Радыус геазоны',
      'meters': 'метраў',
      'app_preferences': 'Налады праграмы',
      'language_preferences': 'Налады мовы',
      'Language preferences': 'Налады мовы',
      'language': 'Мова',
      'language_selection': 'Выбар мовы',
      'choose_language': 'Выберыце мову',
      'choose_language_desc': 'Абярыце зручную для вас мову інтэрфейсу праграмы',
      'language_updated': 'Мова паспяхова зменена на беларускую',

      // Dashboard
      'welcome_back': 'З вяртаннем',
      'check_in': 'Адзначыць прыход',
      'check_out': 'Адзначыць сыход',
      'checked_in': 'На працы',
      'checked_out': 'Не на працы',
      'todays_attendance': 'Сённяшняя наведвальнасць',
      'working_hours': 'Працоўны час',
      'current_location': 'Бягучае месцазнаходжанне',
      'inside_office': 'У офісе',
      'outside_office': 'Па-за офісам',
      'quick_actions': 'Хуткія дзеянні',
      'view_history': 'Паглядзець гісторыю',
      'confirm_check_in': 'Пацвердзіць прыход',
      'confirm_check_out': 'Пацвердзіць сыход',
      'refresh': 'Абнавіць',
      'daily_effort': 'Дзённыя высілкі',
      'monthly_effort': 'Месячныя высілкі',
      'total_break_hours': 'Агульны час перапынкаў',
      'not_checked_in': 'Не на працы',
      'verifying_location': 'Праверка месцазнаходжання...',
      'geofence_status': 'Статус геазоны',

      // Leave Management
      'my_leaves': 'Мае водпускі',
      'leave_balance': 'Баланс адпачынку',
      'application_history': 'Гісторыя заявак',
      'all_requests': 'Усе заяўкі',
      'pending': 'На разглядзе',
      'approved': 'Ухвалена',
      'rejected': 'Адхілена',
      'withdrawn': 'Адазвана',
      'cancel_requested': 'Запытана адмена',
      'cancelled': 'Адменена',
      'no_leave_requests': 'Заявак на адпачынак не знойдзена',
      'no_requests_filter': 'Няма заявак для абранага фільтра',
      'tap_apply_leave': 'Націсніце «Падаць заяўку» ніжэй, каб стварыць запыт',
      'from_date': 'З даты',
      'to_date': 'Па дату',
      'duration': 'Працягласць',
      'applied_on': 'Пададзена',
      'applying_to': 'Каму',
      'cc_to': 'Копія',
      'reason': 'Прычына',
      'manager_remarks': 'Заўвагі кіраўніка',
      'leave_balances': 'Баланс адпачынкаў',
      'apply_leave': 'Падаць заяўку',
      'select_leave_type': 'Абярыце тып адпачынку',
      'reason_for_leave': 'Прычына адпачынку',
      'submit_application': 'Адправіць заяўку',
      'withdraw': 'Адазваць',
      'withdraw_application': 'Адазваць заяўку',
      'request_cancellation': 'Запытаць адмену',
      'day': 'дзень',
      'days': 'дзён',
      'Days': 'дзён',
      'days_left': 'дзён засталося',
      'history': 'Гісторыя',
      'History': 'Гісторыя',
      'allocated': 'Выдзелена',
      'Allocated': 'Выдзелена',
      'used': 'Выкарыстана',
      'Used': 'Выкарыстана',
      'available': 'Даступна',
      'Available': 'Даступна',
      'Casual Leave': 'Казуальны адпачынак',
      'Paid Leave': 'Аплачваны адпачынак',
      'Sick Leave': 'Бальнічны',
      'casual_leave': 'Казуальны адпачынак',
      'paid_leave': 'Аплачваны адпачынак',
      'sick_leave': 'Бальнічны',
      'filtered_by': 'Фільтр па',
      'rule_cl': 'Максімум 1 дзень на заяўку • Неадкладныя асабістыя справы',
      'rule_sl': 'Медыцынская даведка патрабуецца на 2+ дні запар',
      'rule_pl': 'Прывілеяваны водпуск для планаванага адпачынку і сямейных падзей',
      'rule_standard': 'Штогадовая норма для стандартнага права супрацоўніка',
      'show_all_requests': 'Паказаць усе заяўкі',
      'Show All Requests': 'Паказаць усе заяўкі',
      'back': 'Назад',
      'Back': 'Назад',
      'total_duration': 'Агульная працягласць',
      'apply_for_leave': 'Падаць заяўку на адпачынак',
      'leave_type': 'Тып адпачынку',
      'add': 'Дадаць',
      'Add': 'Дадаць',
      'cl_policy_banner': 'Казуальны адпачынак: макс. 1 дзень • 1 заяўка на каляндарны месяц',
      'sl_policy_banner': 'Медыцынская даведка патрабуецца пры бальнічным ад 2 дзён',
      'half_day_leave': 'Палова дня адпачынку',
      'half_day_desc': 'Спісанне 0,5 дня за няпоўную змену',
      'session_1_am': 'Змена 1 (Раніца)',
      'session_2_pm': 'Змена 2 (Дзень)',
      'reason_hint': 'напр., візіт да лекара, сямейная падзея, асабістыя справы...',
      'attach_file': 'Далучыць файл',
      'file_selected': '1 файл абраны',
      'optional_file_types': 'Неабавязкова (PDF, JPG, PNG)',
      'upload_supporting_doc': 'Загрузіць пацвярджальны дакумент',
      'upload_size_limit': 'PDF або выявы да 10 МБ',
      'browse': 'Агляд',
      'submit_leave_request': 'Адправіць заяўку на адпачынак',
      'add_cc': 'Дадаць копію',
      'add_cc_desc': 'Увядзіце імя або пошту калегі для апавяшчэння:',
      'add_cc_hint': 'напр. Аліса Сміт, HR',
      'leave_applied_success': 'Заяўка на адпачынак паспяхова адпраўлена!',
      'error_select_leave_type': 'Калі ласка, абярыце тып адпачынку',
      'error_provide_reason': 'Калі ласка, укажыце прычыну адпачынку',
      'error_cl_max_1_day': 'Казуальны адпачынак не можа перавышаць 1 дзень на заяўку.',
      'error_file_too_large': 'Абраны файл перавышае ліміт 10 МБ.',
      'error_pick_file': 'Не ўдалося выбраць файл. Паспрабуйце зноў.',
      'month_1': 'студз',
      'month_2': 'лют',
      'month_3': 'сак',
      'month_4': 'крас',
      'month_5': 'мая',
      'month_6': 'чэрв',
      'month_7': 'ліп',
      'month_8': 'жнів',
      'month_9': 'вер',
      'month_10': 'кастр',
      'month_11': 'ліст',
      'month_12': 'снеж',

      // Attendance History
      'attendance_history': 'Гісторыя наведвальнасці',
      'present': 'Прысутнічаў',
      'absent': 'Адсутнічаў',
      'filter': 'Фільтр',
      'view': 'Прагляд',
      'monthly_attendance': 'Штомесячная наведвальнасць',
      'select_month_year': 'Выберыце месяц і год',

      // Login
      'welcome_to_brandhrms': 'Сардэчна запрашаем у BrandHRMS',
      'employee_login': 'Уваход для супрацоўнікаў',
      'employee_id_or_email': 'ID супрацоўніка або пошта',
      'password': 'Пароль',
      'remember_me': 'Запомніць мяне',
      'login': 'Увайсці',
    },
  };
}

/// Shorthand translation function
String tr(String key) => LanguageService.tr(key);
