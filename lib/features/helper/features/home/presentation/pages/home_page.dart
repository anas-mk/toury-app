import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../auth/presentation/cubit/helper_auth_cubit.dart';
import '../../../auth/presentation/cubit/helper_auth_state.dart';
import 'home_navigation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HelperAuthCubit, HelperAuthState>(
      listener: (context, state) {
        if (state is HelperAuthUnauthenticated) {
          context.go(AppRouter.roleSelection);
        } else if (state is HelperAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // This is ready for future integration with more specific Blocs/Cubits
        return const HomeNavigationPage();
      },
    );
  }
}
