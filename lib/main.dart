import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/list_survey_page.dart';
import 'pages/monitor_survey_page.dart';
import 'pages/cek_edit_monitor.dart';
import 'pages/cek_edit_survey_page.dart';
import 'pages/province_target_page.dart';
import 'pages/project_tj_page.dart';
import 'pages/detail_responden_bpk_page.dart';
import 'pages/detail_responden_transjakarta_page.dart';
import 'providers/survey_provider.dart';
import 'models/client_model.dart';
import 'models/provinsi_model.dart';

import 'core/utils/storage.dart';
import 'core/utils/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      providers: [ChangeNotifierProvider(create: (_) => SurveyProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AppRouteObserver()],
        initialRoute: isLoggedIn ? initialRoute : null,
        home: _getHome(),
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
                  surveyId: (safeArgs['surveyId'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
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
                  surveyId: (safeArgs['surveyId'] ?? '').toString(),
                  clientSlug: safeArgs['clientSlug'] ?? '',
                  projectSlug: safeArgs['projectSlug'] ?? '',
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

            case '/detail_responden_bpk':
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/detail_responden_bpk'),
                builder: (_) => const DetailRespondenSurveyBpkPage(),
              );

            case '/detail_responden_tj':
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/detail_responden_tj'),
                builder: (_) => const DetailRespondenSurveyTransjakartaPage(),
              );

            default:
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (_) => const LoginPage(),
              );
          }
        },
      ),
    );
  }

  Widget _getHome() {
    if (!isLoggedIn) return const LoginPage();
    return const DashboardPage();
  }
}
