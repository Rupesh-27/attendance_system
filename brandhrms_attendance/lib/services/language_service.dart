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
      'work_information': 'Work Information',
      'assigned_office': 'Assigned Office',
      'geofence_radius': 'Geofence Radius',
      'meters': 'meters',
      'app_preferences': 'App Preferences',
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
      'work_information': 'Arbeitsinformationen',
      'assigned_office': 'Zugewiesenes Büro',
      'geofence_radius': 'Geofence-Radius',
      'meters': 'Meter',
      'app_preferences': 'App-Einstellungen',
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
      'work_information': 'Працоўная інфармацыя',
      'assigned_office': 'Прызначаны офіс',
      'geofence_radius': 'Радыус геазоны',
      'meters': 'метраў',
      'app_preferences': 'Налады праграмы',
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
