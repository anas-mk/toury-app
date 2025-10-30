import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/accounts_settings_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/explore_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/home_page.dart';
import '../../../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../cubit/bottom_nav_cubit.dart';
import '../cubit/bottom_nav_state.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {

    final pages = const [
      HomePage(),
      ExplorePage(),
      AccountSettingsPage(),
    ];

    return BlocBuilder<BottomNavCubit, BottomNavState>(
      builder: (context, state) {
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            child: IndexedStack(
              key: ValueKey(state.currentIndex),
              index: state.currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<BottomNavCubit>().changeTab(index),
          ),
        );
      },
    );
  }
}
