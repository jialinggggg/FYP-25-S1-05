import 'package:flutter/material.dart';
import 'package:nutri_app/backend/controllers/report_recipe_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:nutri_app/backend/api/spoonacular_service.dart';
import 'package:nutri_app/backend/api/nutridigm_service.dart';
import 'package:nutri_app/backend/signup/nutri_signup_state.dart';
import 'package:nutri_app/backend/signup/biz_signup_state.dart';
import 'package:nutri_app/backend/signup/signup_state.dart';

import 'package:nutri_app/backend/signup/input_validation_service.dart';

import 'user/signup/signup_welcome.dart';
import 'user/signup/signup_you.dart';
import 'user/signup/signup_med.dart';
import 'user/signup/signup_target.dart';
import 'user/signup/signup_goal.dart';
import 'user/signup/signup_activity.dart';
import 'shared/signup_detail.dart';
import 'shared/signup_type.dart';
import 'shared/signup_result.dart';
import 'shared/splash_screen.dart';
import 'shared/login.dart';
import 'user/profile/profile_screen.dart';
import 'user/order/orders_screen.dart';
import 'user/meal/main_log_screen.dart';
import 'user/report/main_report_screen.dart';
import 'user/profile/edit_profile_screen.dart';
import 'user/profile/edit_goals_screen.dart';
import 'user/profile/edit_med.dart';
import 'user/recipes/add_recipe_screen.dart';
import 'user/recipes/main_recipe_screen.dart';
import 'business/signup_biz_contact.dart';
import 'business/biz_profile_screen.dart';
import 'business/biz_products_screen.dart';
import 'business/biz_orders_screen.dart';
import 'shared/biz_main_dashboard.dart';
import 'nutritionist/profile_nutri_screen.dart';

import 'package:nutri_app/backend/controllers/view_daily_nutri_info_controller.dart';
import 'package:nutri_app/backend/controllers/log_meal_controller.dart';
import 'package:nutri_app/backend/controllers/search_recipe_by_name_controller.dart';
import 'package:nutri_app/backend/controllers/log_daily_weight_controller.dart';
import 'package:nutri_app/backend/controllers/view_encouragement_controller.dart';
import 'package:nutri_app/backend/controllers/fetch_recipe_for_meal_log_controller.dart';
import 'package:nutri_app/backend/controllers/add_recipe_controller.dart';
import 'package:nutri_app/backend/controllers/recipe_filter_controller.dart';
import 'package:nutri_app/backend/controllers/recipe_list_controller.dart';
import 'package:nutri_app/backend/controllers/biz_recipe_list_controller.dart';
import 'package:nutri_app/backend/controllers/recipe_search_controller.dart';
import 'package:nutri_app/backend/controllers/fetch_user_profile_info_controller.dart';
import 'package:nutri_app/backend/controllers/fetch_nutri_profile_controller.dart';
import 'package:nutri_app/backend/controllers/biz_signup_controller.dart';
import 'package:nutri_app/backend/controllers/nutritionist_signup_controller.dart';
import 'package:nutri_app/backend/controllers/user_signup_controller.dart';
import 'package:nutri_app/backend/controllers/fetch_biz_profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mmyzsijycjxdkxglrxxl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1teXpzaWp5Y2p4ZGt4Z2xyeHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxNjM3MDEsImV4cCI6MjA1MjczOTcwMX0.kc1OUjoORjgnx2W3N5hG_LNwjvh1OZfy9r3M4-mq4_I',
  );

  // Safe Stripe Initialization
  try {
    Stripe.publishableKey = 'pk_test_51RCCkoFTWCZkOCqTTyN8vwR2q6F8ZWPWOe6nWBgEGJSbLJGc5ZrTFKFnHmFTzKb4jRF9Vku2a9sTVR3W7kEQVqU200HIn3uNPm';
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint('Stripe init failed: $e');
  }

  // Enable Flutter error logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final spoonacularService = SpoonacularService();
    final nutridigmService = NutridigmService();

    return MultiProvider(
      providers: [
        // Core repositories
        Provider(create: (_) => spoonacularService),
        Provider(create: (_) => nutridigmService),
        Provider(create: (_) => InputValidationService()),
        
        // Controllers (state management)
        ChangeNotifierProvider(create: (_) => LogDailyWeightController(supabaseClient: supabase)),
        ChangeNotifierProvider(create: (_) => ViewEncouragementController(supabaseClient: supabase)),
        ChangeNotifierProvider(create: (_) => ViewDailyNutritionInfoController(supabaseClient: supabase)),
        ChangeNotifierProvider(create: (_) => FetchRecipeForMealLogController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => SearchRecipeByNameController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => LogMealController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => RecipeListController(supabase, spoonacularService, nutridigmService)),
        ChangeNotifierProvider(create: (_) => RecipeSearchController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => RecipeFilterController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => ReportRecipeController(supabase)),
        ChangeNotifierProvider(create: (_) => AddRecipeController(supabase, spoonacularService)),
        ChangeNotifierProvider(create: (_) => BusinessRecipeListController(supabase)),
        ChangeNotifierProvider(create: (_) => FetchUserProfileInfoController(supabase)),
        ChangeNotifierProvider(create: (_) => FetchNutritionistProfileInfoController(supabase)),
        ChangeNotifierProvider(create: (_) => FetchBusinessProfileInfoController(supabase)),
        

        // Services
        Provider<SignupController>(create: (_) => SignupController(Supabase.instance.client),),
        Provider<BizSignupController>(create: (_) => BizSignupController(Supabase.instance.client),),
        Provider<NutritionistSignupController>(create: (_) => NutritionistSignupController(Supabase.instance.client),),
        ChangeNotifierProvider(create: (_) => SignupState()),
        ChangeNotifierProvider(create: (_) => BusinessSignupState()),
        ChangeNotifierProvider(create: (_) => NutritionistSignupState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Health App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.green),
          ),
        ),
        initialRoute: '/',
        routes: {
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
          '/user_signup_detail': (context) => const SignupDetail(type: "user"),
          '/signup_result': (context) => const SignupResult(type: "user"),
          '/biz_signup_result': (context) => const SignupResult(type: "business"),
          '/signup_biz_contact': (context) => const SignupBizContactScreen(),
          '/biz_signup_detail': (context) => const SignupDetail(type: "business"),
          '/nutri_signup_detail': (context) => const SignupDetail(type: "nutritionist"),

          // Main feature routes
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/log': (context) => const MainLogScreen(),
          '/dashboard': (context) => const MainReportScreen(),
          '/edit_profile': (context) => EditProfileScreen(onProfileUpdated: () {}),
          '/edit_goals': (context) => EditGoalsScreen(onUpdate: () {}),
          '/edit_med': (context) => EditMedicalHistScreen(onUpdate: () {}),
          '/add_recipe': (context) => const AddRecipeScreen(),
          '/main_recipes': (context) => const MainRecipeScreen(),

          // business
          '/biz_recipes': (context) => const BizPartnerDashboard(),
          '/biz_products':(context) => const BizProductsScreen(),
          '/biz_orders': (context) => const BizOrdersScreen(),
          '/biz_profile': (context) => const BusinessProfileScreen(),
          '/nutri_profile': (context) => const NutritionistProfileScreen(),
          
        },
      ),
    );
  }
}
