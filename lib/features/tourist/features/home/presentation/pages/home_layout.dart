import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/accounts_settings_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/explore_page.dart';
import '../../../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../cubit/bottom_nav_cubit.dart';
import '../../cubit/bottom_nav_state.dart';
import 'home_page.dart';


class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  final List<Widget> pages = const [
    HomePage(),
    ExplorePage(),
    AccountSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavCubit, BottomNavState>(
      builder: (context, state) {
        return Scaffold(
          body: pages[state.currentIndex],
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<BottomNavCubit>().changeTab(index),
          ),
        );
      },
    );
  }
}
