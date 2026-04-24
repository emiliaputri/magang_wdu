import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/list_survey_page.dart';
import 'pages/monitor_survey_page.dart';
import 'pages/cek_edit_monitor.dart';
import 'pages/cek_edit_survey_page.dart';
import 'pages/province_target_page.dart';
import 'pages/project_page.dart';
import 'pages/submission_page.dart';
import 'pages/biodata_page.dart';
import 'pages/camera_capture_page.dart';
import 'providers/auth_provider.dart';
import 'providers/survey_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/font_size_provider.dart';
import 'models/client_model.dart';
import 'models/provinsi_model.dart';

import 'core/utils/storage.dart';
import 'core/utils/route_observer.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    FlutterError.onError = (details) {
      AppLogger.error(
        'FlutterError caught by main.dart',
        error: details.exceptionAsString(),
        stackTrace: details.stack,
        category: 'FlutterError',
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.error(
        'Platform error caught in main.dart',
        error: error,
        stackTrace: stackTrace,
        category: 'Platform',
      );
      return true;
    };
  }

  AppLogger.info('App started', category: 'App');

  // DEBUG: Check token status at app start
  final hasToken = await StorageHelper.hasToken();
  final token = await StorageHelper.getToken();
  debugPrint(
    '[Main] App start - hasToken: $hasToken, token exists: ${token != null}',
  );
  if (token != null) {
    debugPrint('[Main] Token length: ${token.length}');
    debugPrint(
      '[Main] Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
    );
  }

  final isLoggedIn = await StorageHelper.hasToken();
  final lastRoute = await StorageHelper.getLastRouteName();
  final lastArgs = await StorageHelper.getLastRouteArgs();

  runApp(
    MyApp(
      isLoggedIn: isLoggedIn,
      initialRoute: lastRoute,
      initialArgs: lastArgs,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? initialRoute;
  final Map<String, dynamic>? initialArgs;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.initialRoute,
    this.initialArgs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSessionAndLog()),
        ChangeNotifierProvider(create: (_) => SurveyProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = NotificationProvider();
          debugPrint('[Main] NotificationProvider created');
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
      ],
      child: Consumer<FontSizeProvider>(
        builder: (context, fontSizeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeData,
            navigatorObservers: [AppRouteObserver()],
            initialRoute: isLoggedIn ? initialRoute : null,
            home: _getHome(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(fontSizeProvider.fontSizeScale),
                ),
                child: child!,
              );
            },
            onGenerateRoute: (settings) {
          final name = settings.name;
          final args =
              (settings.arguments as Map<String, dynamic>?) ??
              (name == initialRoute ? initialArgs : null);

          switch (name) {
            case '/dashboard':
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/dashboard'),
                builder: (_) => const DashboardPage(),
              );

            case '/surveys':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(name: '/surveys', arguments: safeArgs),
                builder: (_) => SurveyListPage(
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  clientName: safeArgs['clientName'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  projectTitle: safeArgs['projectTitle'] ?? '',
                ),
              );

            case '/monitoring':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/monitoring',
                  arguments: safeArgs,
                ),
                builder: (_) => MonitoringSurveyPage(
                  surveyName: safeArgs['surveyName'] ?? '',
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  surveySlug: safeArgs['surveySlug'] ?? '',
                  totalRespon: safeArgs['totalRespon'] ?? 0,
                  targetLocation: safeArgs['targetLocation'] ?? '-',
                  isOpen: safeArgs['isOpen'] ?? true,
                ),
              );

            case '/cek_edit_monitor':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/cek_edit_monitor',
                  arguments: safeArgs,
                ),
                builder: (_) => CekEditMonitorPage(
                  surveySlug: (safeArgs['surveySlug'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  responseId:
                      int.tryParse(safeArgs['responseId']?.toString() ?? '') ??
                      0,
                ),
              );

            case '/cek_edit_survey':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/cek_edit_survey',
                  arguments: safeArgs,
                ),
                builder: (_) => CekEditSurveyPage(
                  surveySlug: (safeArgs['surveySlug'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  responseId:
                      int.tryParse(safeArgs['responseId']?.toString() ?? '') ??
                      0,
                ),
              );
            case '/province_target':
              final safeArgs = args ?? {};
              final provincesRaw = safeArgs['provinces'] as List? ?? [];
              final provinces = provincesRaw
                  .map(
                    (p) => ProvinceTarget.fromJson(p as Map<String, dynamic>),
                  )
                  .toList();
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/province_target',
                  arguments: safeArgs,
                ),
                builder: (_) => ProvinceTargetPage(
                  surveyName: safeArgs['surveyName'] ?? '',
                  provinces: provinces,
                ),
              );

            case '/project_list':
              final safeArgs = args ?? {};
              final clientData = safeArgs['client'] as Map<String, dynamic>?;
              final client = clientData != null
                  ? Client.fromJson(clientData)
                  : Client(clientName: '');
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/project_list',
                  arguments: safeArgs,
                ),
                builder: (_) => ProjectListPage(client: client),
              );

            case '/submission':
              final safeArgs = args ?? {};
              final provinceTargetsRaw =
                  safeArgs['provinceTargets'] as List? ?? [];
              final provinceTargets = provinceTargetsRaw
                  .map(
                    (p) => ProvinceTarget.fromJson(p as Map<String, dynamic>),
                  )
                  .toList();
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/submission',
                  arguments: safeArgs,
                ),
                builder: (_) => SubmissionPage(
                  surveySlug: (safeArgs['surveySlug'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  biodata: safeArgs['biodata'] as Map<String, dynamic>?,
                  surveyTitle: safeArgs['surveyTitle'] ?? '',
                ),
              );

            case '/biodata':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(name: '/biodata', arguments: safeArgs),
                builder: (_) => BiodataPage(
                  surveySlug: (safeArgs['surveySlug'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                ),
              );

            case '/camera_capture':
              final safeArgs = args ?? {};
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/camera_capture',
                  arguments: safeArgs,
                ),
                builder: (_) => CameraCapturePage(
                  surveySlug: (safeArgs['surveySlug'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
                  biodata: safeArgs['biodata'] as Map<String, dynamic>?,
                  surveyTitle: safeArgs['surveyTitle'] ?? '',
                ),
              );

            default:
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (_) => const LoginPage(),
              );
          }
        },
      );
    },
      ),
    );
  }

  Widget _getHome() {
    if (!isLoggedIn) return const LoginPage();
    return const DashboardPage();
  }
}
