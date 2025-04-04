import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../backend/state/signup_state.dart';
import '../../backend/state/user_profile_state.dart';
import '../../backend/state/recipe_state.dart';
import '../../backend/repositories/auth_repository.dart';
import '../../backend/repositories/account_repository.dart';
import '../../backend/repositories/user_profiles_repository.dart';
import '../../backend/repositories/user_medical_repository.dart';
import '../../backend/repositories/user_goals_repository.dart';
import '../../backend/repositories/user_measurements_repository.dart';
import '../../backend/repositories/business_profiles_repository.dart';
import '../../backend/repositories/recipe_repository.dart';
import '../../backend/api/spoonacular_api_service.dart';
import '../../backend/services/input_validation_service.dart';
import '../../backend/services/signup_service.dart';
import '../../backend/services/user_profile_service.dart';
import '../../backend/services/add_recipe_service.dart';
import '../../backend/services/edit_recipe_service.dart';
import '../../backend/controller/add_recipe_controller.dart';
import '../../backend/controller/edit_recipe_controller.dart';
import 'user/signup/signup_welcome.dart';
import 'user/signup/signup_you.dart';
import 'user/signup/signup_med.dart';
import 'user/signup/signup_target.dart';
import 'user/signup/signup_goal.dart';
import 'user/signup/signup_activity.dart';
import 'user/signup/signup_detail.dart';
import 'shared/signup_type.dart';
import 'shared/signup_result.dart';
import 'shared/splash_screen.dart';
import 'shared/login.dart';
import 'user/profile/profile_screen.dart';
import 'user/order/orders_screen.dart';
import 'user/recipes/recipes_screen.dart';
import 'user/recipes/recipe_detail_screen.dart';
import 'user/recipes/add_recipe.dart';
import 'user/meal/main_log_screen.dart';
import 'user/report/dashboard_screen.dart';
import 'user/profile/edit_profile.dart';
import 'user/profile/edit_goals.dart';
import 'user/profile/edit_med.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mmyzsijycjxdkxglrxxl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1teXpzaWp5Y2p4ZGt4Z2xyeHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxNjM3MDEsImV4cCI6MjA1MjczOTcwMX0.kc1OUjoORjgnx2W3N5hG_LNwjvh1OZfy9r3M4-mq4_I',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userProfilesRepo = UserProfilesRepository(supabase);

    return MultiProvider(
      providers: [
        // Auth and profile providers
        ChangeNotifierProvider(create: (_) => SignupState()),
        Provider(create: (_) => InputValidationService()),
        Provider(create: (_) => AuthRepository(supabase)),
        Provider(create: (_) => AccountRepository(supabase)),
        Provider(create: (_) => userProfilesRepo),
        Provider(create: (_) => UserMedicalRepository(supabase)),
        Provider(create: (_) => UserGoalsRepository(supabase)),
        Provider(create: (_) => UserMeasurementsRepository(supabase, userProfilesRepo)),
        Provider(create: (_) => BusinessProfilesRepository(supabase)),

        // Recipe-related providers
        Provider(create: (_) => SpoonacularApiService()),
        Provider(create: (_) => RecipeRepository(
          supabase,
          AccountRepository(supabase),
          userProfilesRepo,
          BusinessProfilesRepository(supabase),
        )),
        
        ChangeNotifierProvider(create: (_) => RecipeState()),
        Provider(create: (context) => AddRecipeService(
          context.read<RecipeRepository>(),
          context.read<SpoonacularApiService>(),
        )),
        Provider(create: (context) => AddRecipeController(
          context.read<AddRecipeService>(),
          context.read<RecipeState>(),
        )),

        ChangeNotifierProvider(create: (_) => RecipeState()),
        ProxyProvider<RecipeState, EditRecipeController>(
          update: (_, state, __) => EditRecipeController(
            EditRecipeService(
              RecipeRepository(
                supabase,
                AccountRepository(supabase),
                UserProfilesRepository(supabase),
                BusinessProfilesRepository(supabase),
              ),
              SpoonacularApiService(),
            ),
            state,
          ),
        ),
      
        // Services
        Provider(create: (_) => SignupService(
          authRepo: AuthRepository(supabase),
          accountRepo: AccountRepository(supabase),
          profileRepo: userProfilesRepo,
          medicalRepo: UserMedicalRepository(supabase),
          goalsRepo: UserGoalsRepository(supabase),
          measurementsRepo: UserMeasurementsRepository(supabase, userProfilesRepo),
        )),
        Provider(create: (_) => UserProfileService(supabase)),
        ChangeNotifierProvider(create: (context) => UserProfileState(
          context.read<UserProfileService>(),
        )),

        
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Health App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          // Core app routes
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),

          // Signup flow routes
          '/signup_type': (context) => const SignupType(),
          '/signup_welcome': (context) => const SignupWelcome(),
          '/signup_you': (context) => const SignupYou(),
          '/signup_med': (context) => const SignupMed(),
          '/signup_goal': (context) => const SignupGoal(),
          '/signup_activity': (context) => const SignupActivity(),
          '/signup_target': (context) => const SignupTarget(),
          '/signup_detail': (context) => const SignupDetail(),
          '/signup_result': (context) => const SignupResult(type: "user"),

          // Main feature routes
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/recipes': (context) => const RecipesScreen(),
          '/add_recipe': (context) => const AddRecipeScreen(),
          '/log': (context) => const MainLogScreen(),
          '/dashboard': (context) => const MainReportDashboard(),

          // Recipe routes
          '/recipe_detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return RecipeDetailScreen(
              recipeId: args['recipeId'] as String,
              isFromDatabase: args['isFromDatabase'] as bool,
            );
          },

          // Profile edit routes
          '/edit_profile': (context) => EditProfileScreen(
            onProfileUpdated: () {
              // This will be handled by the ProfileController when needed
            },
          ),
          '/edit_goals': (context) => EditGoalsScreen(
            onUpdate: () {
              // This will be handled by the ProfileController when needed
            },
          ),
          '/edit_med': (context) => EditMedicalHistoryScreen(
            onUpdate: () {
              // This will be handled by the ProfileController when needed
            },
          ),
        },
      ),
    );
  }
}