import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/core/theme/app_theme.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/auth/repository/auth_repository.dart';
import 'package:zapchat/features/auth/views/login_screen.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/repository/chat_repository.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_route.dart';
import 'core/routes/route_names.dart';
import 'core/screens/auth_wrapper.dart';
import 'core/services/storage_services.dart';
import 'features/auth/bloc/auth_events.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/home/views/main_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {

    // Create repository instances
    final authRepository = AuthRepository();
    final chatRepository = ChatRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<StorageService>(
          create: (context) => AppConfig.useDevStorage
              ? DevStorageService()
              : FirebaseStorageService(),
        ),
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepository(
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'ZapChat',
              theme: AppTheme.darkTheme,
              debugShowCheckedModeBanner: false,

              initialRoute: RouteNames.splash,
              onGenerateRoute: AppRoutes.generateRoute,
            );

          },
        ),
      ),
    );
  }
}



