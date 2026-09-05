import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'providers/faculty_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/timetable_provider.dart';
import 'utils/theme.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  
  runApp(const YataApp());
}

class YataApp extends StatelessWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FacultyProvider()..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => UiProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TimetableProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'YATA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
