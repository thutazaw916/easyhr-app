import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/employee_login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/leave/screens/leave_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chatbot/screens/ai_chatbot_screen.dart';
import '../../features/billing/screens/subscription_screen.dart';
import '../../features/announcement/screens/announcement_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/employee_list_screen.dart';
import '../../features/admin/screens/add_employee_screen.dart';
import '../../features/admin/screens/attendance_report_screen.dart';
import '../../features/payroll/screens/payroll_screen.dart';
import '../../features/payroll/screens/salary_advance_screen.dart';
import '../../features/settings/screens/company_settings_screen.dart';
import '../../features/settings/screens/branches_screen.dart';
import '../../features/settings/screens/departments_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/shell/main_shell.dart';

// Auth state change notifier for GoRouter
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/employee-login' ||
          state.matchedLocation == '/signup';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/employee-login', builder: (context, state) => const EmployeeLoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

      // Main Shell (Bottom Navigation: Home, Attendance, Payroll, Leave, Profile)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: '/attendance', pageBuilder: (context, state) => const NoTransitionPage(child: AttendanceScreen())),
          GoRoute(path: '/payroll', pageBuilder: (context, state) => const NoTransitionPage(child: PayrollScreen())),
          GoRoute(path: '/leave', pageBuilder: (context, state) => const NoTransitionPage(child: LeaveScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),

      // Full Screen Routes
      GoRoute(path: '/announcements', builder: (context, state) => const AnnouncementScreen()),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/chatbot', builder: (context, state) => const AiChatbotScreen()),

      // Admin Routes
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/employees', builder: (context, state) => const EmployeeListScreen()),
      GoRoute(path: '/admin/employees/add', builder: (context, state) => const AddEmployeeScreen()),
      GoRoute(path: '/admin/attendance-report', builder: (context, state) => const AttendanceReportScreen()),

      // Payroll Sub Routes
      GoRoute(path: '/payroll/advance', builder: (context, state) => const SalaryAdvanceScreen()),

      // Settings Routes
      GoRoute(path: '/settings/company', builder: (context, state) => const CompanySettingsScreen()),
      GoRoute(path: '/settings/branches', builder: (context, state) => const BranchesScreen()),
      GoRoute(path: '/settings/departments', builder: (context, state) => const DepartmentsScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/billing', builder: (context, state) => const SubscriptionScreen()),
    ],
  );
});