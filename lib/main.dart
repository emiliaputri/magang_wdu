import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/list_survey_page.dart';
import 'providers/survey_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SurveyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginPage(),
        onGenerateRoute: (settings) {
          switch (settings.name) {

            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              );

            case '/surveys':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => SurveyListPage(
                  clientSlug:   args['clientSlug']   ?? '',
                  clientName:   args['clientName']   ?? '',
                  projectSlug:  args['projectSlug']  ?? '',
                  projectTitle: args['projectTitle'] ?? '',
                ),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
              );
          }
        },
      ),
    );
  }
}