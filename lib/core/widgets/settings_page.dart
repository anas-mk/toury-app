import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_cubit.dart';
import '../localization/cubit/localization_cubit.dart';
import '../localization/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = Localizations.of(context, AppLocalizations).textDirection == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.toggleTheme,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            themeMode == ThemeMode.dark
                                ? l10n.darkMode
                                : l10n.lightMode,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              context.read<ThemeCubit>().toggleTheme();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.toggleLanguage,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<LocalizationCubit, Locale>(
                    builder: (context, locale) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(l10n.english),
                            leading: const Icon(Icons.flag),
                            trailing: Radio<String>(
                              value: 'en',
                              groupValue: locale.languageCode,
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<LocalizationCubit>().setLanguage(
                                    value,
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              context.read<LocalizationCubit>().setLanguage(
                                'en',
                              );
                            },
                          ),
                          ListTile(
                            title: Text(l10n.arabic),
                            leading: const Icon(Icons.flag),
                            trailing: Radio<String>(
                              value: 'ar',
                              groupValue: locale.languageCode,
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<LocalizationCubit>().setLanguage(
                                    value,
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              context.read<LocalizationCubit>().setLanguage(
                                'ar',
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    leading: const Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('Build'),
                    subtitle: const Text('1'),
                    leading: const Icon(Icons.build),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

