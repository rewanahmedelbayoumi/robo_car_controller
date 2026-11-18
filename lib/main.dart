import 'package:flutter/material.dart';
import 'screens/welcome_screens.dart';
import 'services/robot_controller.dart';
import 'utils/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final RobotController controller = RobotController();
  @override
  void initState(){super.initState();WidgetsBinding.instance.addObserver(this);}
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state != AppLifecycleState.resumed){controller.stop();}
  }
  @override
  void dispose(){WidgetsBinding.instance.removeObserver(this);controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) => MaterialApp(
    title:'RoboCar Controller',debugShowCheckedModeBanner:false,
    theme:ThemeData(
      useMaterial3:true,
      scaffoldBackgroundColor:AppColors.paper,
      colorScheme:ColorScheme.fromSeed(seedColor:AppColors.green,primary:AppColors.green,brightness:Brightness.light),
      fontFamily:'Roboto',
      textTheme:const TextTheme(bodyMedium:TextStyle(color:AppColors.ink),bodyLarge:TextStyle(color:AppColors.ink)),
      inputDecorationTheme:InputDecorationTheme(
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)),
        contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:14),
      ),
    ),
    home:SplashScreen(controller:controller),
  );
}
