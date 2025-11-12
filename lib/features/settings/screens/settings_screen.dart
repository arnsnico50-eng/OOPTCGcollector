import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SettingsSection(
            title: 'Collection',
            children: [
              SettingsTile(
                title: 'Auto-sync Collection',
                subtitle: 'Automatically sync collection across devices',
                leading: const Icon(Icons.sync),
                trailing: Switch(
                  value: settingsState.autoSync,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateAutoSync(value);
                  },
                ),
              ),
              SettingsTile(
                title: 'Price Updates',
                subtitle: 'Update prices daily when online',
                leading: const Icon(Icons.euro),
                trailing: Switch(
                  value: settingsState.autoPriceUpdates,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateAutoPriceUpdates(value);
                  },
                ),
              ),
              SettingsTile(
                title: 'Update Prices Now',
                subtitle: 'Force update all card prices',
                leading: const Icon(Icons.refresh),
                onTap: () {
                  _showPriceUpdateDialog();
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Scanner',
            children: [
              SettingsTile(
                title: 'Auto-capture Cards',
                subtitle: 'Automatically capture when card is detected',
                leading: const Icon(Icons.camera),
                trailing: Switch(
                  value: settingsState.autoCapture,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateAutoCapture(value);
                  },
                ),
              ),
              SettingsTile(
                title: 'Confidence Threshold',
                subtitle: 'Minimum confidence for auto-capture (${(settingsState.confidenceThreshold * 100).toInt()}%)',
                leading: const Icon(Icons.tune),
                onTap: () {
                  _showConfidenceDialog();
                },
              ),
              SettingsTile(
                title: 'Sound Effects',
                subtitle: 'Play sounds when scanning cards',
                leading: const Icon(Icons.volume_up),
                trailing: Switch(
                  value: settingsState.soundEffects,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateSoundEffects(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Display',
            children: [
              SettingsTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                leading: const Icon(Icons.dark_mode),
                trailing: Switch(
                  value: settingsState.darkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateDarkMode(value);
                  },
                ),
              ),
              SettingsTile(
                title: 'Grid View',
                subtitle: 'Display cards in grid layout',
                leading: const Icon(Icons.grid_view),
                trailing: Switch(
                  value: settingsState.gridView,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateGridView(value);
                  },
                ),
              ),
              SettingsTile(
                title: 'Show Card Values',
                subtitle: 'Display card values in collection',
                leading: const Icon(Icons.euro_symbol),
                trailing: Switch(
                  value: settingsState.showCardValues,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateShowCardValues(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Data & Storage',
            children: [
              SettingsTile(
                title: 'Clear Search History',
                subtitle: 'Remove all search history',
                leading: const Icon(Icons.clear_all),
                onTap: () {
                  _showClearSearchHistoryDialog();
                },
              ),
              SettingsTile(
                title: 'Clear Scan History',
                subtitle: 'Remove all scan history',
                leading: const Icon(Icons.delete_sweep),
                onTap: () {
                  _showClearScanHistoryDialog();
                },
              ),
              SettingsTile(
                title: 'Export Collection',
                subtitle: 'Export collection as CSV',
                leading: const Icon(Icons.download),
                onTap: () {
                  _exportCollection();
                },
              ),
              SettingsTile(
                title: 'Import Collection',
                subtitle: 'Import collection from CSV',
                leading: const Icon(Icons.upload),
                onTap: () {
                  _importCollection();
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                title: 'Version',
                subtitle: '1.0.0',
                leading: const Icon(Icons.info),
              ),
              SettingsTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                leading: const Icon(Icons.privacy_tip),
                onTap: () {
                  _openPrivacyPolicy();
                },
              ),
              SettingsTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                leading: const Icon(Icons.description),
                onTap: () {
                  _openTermsOfService();
                },
              ),
              SettingsTile(
                title: 'Contact Support',
                subtitle: 'Get help with the app',
                leading: const Icon(Icons.support_agent),
                onTap: () {
                  _contactSupport();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPriceUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Prices'),
        content: const Text('This will update prices for all cards in your collection. It may take a few minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(settingsProvider.notifier).updateAllPrices();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showConfidenceDialog() {
    final settingsState = ref.read(settingsProvider);
    double threshold = settingsState.confidenceThreshold;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidence Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set the minimum confidence level for automatic card detection.'),
            const SizedBox(height: 16),
            Slider(
              value: threshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              label: '${(threshold * 100).toInt()}%',
              onChanged: (value) {
                threshold = value;
                ref.read(settingsProvider.notifier).updateConfidenceThreshold(value);
              },
            ),
            Text(
              '${(threshold * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showClearSearchHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to clear all search history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(settingsProvider.notifier).clearSearchHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search history cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearScanHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Scan History'),
        content: const Text('Are you sure you want to clear all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(settingsProvider.notifier).clearScanHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan history cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportCollection() {
    // TODO: Implement collection export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _importCollection() {
    // TODO: Implement collection import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }

  void _openPrivacyPolicy() {
    // TODO: Open privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy coming soon')),
    );
  }

  void _openTermsOfService() {
    // TODO: Open terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service coming soon')),
    );
  }

  void _contactSupport() {
    // TODO: Open support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support contact coming soon')),
    );
  }
}