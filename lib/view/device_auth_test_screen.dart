import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class DeviceAuthTestScreen extends StatefulWidget {
  const DeviceAuthTestScreen({Key? key}) : super(key: key);

  @override
  State<DeviceAuthTestScreen> createState() => _DeviceAuthTestScreenState();
}

class _DeviceAuthTestScreenState extends State<DeviceAuthTestScreen> {
  Map<String, dynamic> deviceInfo = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authService = AuthService.instance;
      final info = await authService.getDeviceAuthInfo();
      setState(() {
        deviceInfo = info;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load device info: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resetDeviceAuth() async {
    try {
      final authService = AuthService.instance;
      await authService.resetDeviceAuth();
      
      Get.snackbar(
        'Success',
        'Device authentication data reset successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      await _loadDeviceInfo();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset device auth: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Auth Test'),
        backgroundColor: const Color(0xFF086F8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Authentication Info',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard('Device ID', deviceInfo['deviceId'] ?? 'Not set'),
                      const SizedBox(height: 12),
                      _buildInfoCard('Last User Email', deviceInfo['lastUserEmail'] ?? 'None'),
                      const SizedBox(height: 12),
                      _buildInfoCard('Is First User', deviceInfo['isFirstUser']?.toString() ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'First Sign-in Time', 
                        deviceInfo['firstSignInTime'] != null 
                          ? DateTime.fromMillisecondsSinceEpoch(deviceInfo['firstSignInTime']).toString()
                          : 'Not set'
                      ),
                      const SizedBox(height: 24),
                      
                      // Current Firebase User Info
                      const Text(
                        'Current Firebase User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final authService = AuthService.instance;
                        final user = authService.currentUser;
                        
                        if (user == null) {
                          return _buildInfoCard('Status', 'Not signed in');
                        }
                        
                        return Column(
                          children: [
                            _buildInfoCard('Email', user.email ?? 'No email'),
                            const SizedBox(height: 8),
                            _buildInfoCard('Display Name', user.displayName ?? 'No name'),
                            const SizedBox(height: 8),
                            _buildInfoCard('UID', user.uid),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadDeviceInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF086F8A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Refresh Info'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetDeviceAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Device Auth'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
