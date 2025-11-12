import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/scanner_provider.dart';
import '../widgets/camera_preview.dart';
import '../widgets/scanner_result.dart';
import '../widgets/scan_history.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCameraPermission();
      ref.read(scannerProvider.notifier).loadScanHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to scan One Piece TCG cards. Please grant camera permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // Switch to history tab
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Scanner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scanner'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(scannerState),
          _buildHistoryTab(scannerState),
        ],
      ),
    );
  }

  Widget _buildScannerTab(ScannerState state) {
    return FutureBuilder<bool>(
      future: Permission.camera.isGranted,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!) {
          return _buildPermissionRequired();
        }

        return Column(
          children: [
            Expanded(
              flex: 3,
              child: state.isScanning
                  ? const CameraPreviewWidget()
                  : _buildScanningInstructions(),
            ),
            if (state.scanResult != null)
              Expanded(
                flex: 2,
                child: ScannerResultWidget(
                  scanResult: state.scanResult!,
                  onAddToCollection: (cardId) {
                    ref.read(scannerProvider.notifier).addToCollection(cardId);
                    _showSuccessMessage('Card added to collection!');
                  },
                  onRescan: () {
                    ref.read(scannerProvider.notifier).startScanning();
                  },
                ),
              ),
            if (state.error != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(scannerProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera permission to scan cards',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestCameraPermission,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningInstructions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.center_focus_strong,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Scan',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Position your One Piece TCG card in the camera view.\nThe app will automatically detect and identify it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(scannerProvider.notifier).startScanning();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ScannerState state) {
    if (state.scanHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Scan History',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your recent card scans will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ScanHistoryWidget(
      scanHistory: state.scanHistory,
      onRescan: (scanResult) {
        ref.read(scannerProvider.notifier).retryScan(scanResult);
        _tabController.animateTo(0); // Switch to scanner tab
      },
      onAddToCollection: (cardId) {
        ref.read(scannerProvider.notifier).addToCollection(cardId);
        _showSuccessMessage('Card added to collection!');
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}