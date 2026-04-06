import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class CropFormScreen extends StatefulWidget {
  const CropFormScreen({super.key});

  @override
  State<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends State<CropFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'N': TextEditingController(),
    'P': TextEditingController(),
    'K': TextEditingController(),
    'temperature': TextEditingController(),
    'humidity': TextEditingController(),
    'ph': TextEditingController(),
    'rainfall': TextEditingController(),
  };

  bool _isLoading = false;
  String _backendBaseUrl = ApiConfig.defaultBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadBackendUrl();
  }

  Future<void> _loadBackendUrl() async {
    final backendBaseUrl = await ApiConfig.getBaseUrl();
    if (!mounted) {
      return;
    }
    setState(() {
      _backendBaseUrl = backendBaseUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Recommendation Form'),
        actions: [
          IconButton(
            onPressed: _showBackendSettings,
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Backend URL',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5EFE2), Color(0xFFDCE7DB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF143F2E), Color(0xFF48745B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0xFF0F2D21),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.science_outlined,
                                  size: 42,
                                  color: Color(0xFFEFD4A5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Enter Soil and Climate Data',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Use sharp, field-ready inputs to send a full soil profile to the recommendation engine.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFFD8E6DD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFF264939), width: 1.1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Backend Connection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF143F2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _backendBaseUrl,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4F5B54),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'On a real phone, replace localhost with your computer\'s Wi-Fi IP, like http://192.168.1.5:8000.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF6A736E),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _showBackendSettings,
                                  child: const Text('Edit Backend URL'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildInputTile(
                                keyName: 'N',
                                label: 'Nitrogen (N)',
                                icon: Icons.opacity,
                              ),
                              _buildInputTile(
                                keyName: 'P',
                                label: 'Phosphorus (P)',
                                icon: Icons.bubble_chart_outlined,
                              ),
                              _buildInputTile(
                                keyName: 'K',
                                label: 'Potassium (K)',
                                icon: Icons.grass_outlined,
                              ),
                              _buildInputTile(
                                keyName: 'temperature',
                                label: 'Temperature (C)',
                                icon: Icons.thermostat,
                              ),
                              _buildInputTile(
                                keyName: 'humidity',
                                label: 'Humidity (%)',
                                icon: Icons.water_drop_outlined,
                              ),
                              _buildInputTile(
                                keyName: 'ph',
                                label: 'pH Level',
                                icon: Icons.balance_outlined,
                              ),
                              _buildInputTile(
                                keyName: 'rainfall',
                                label: 'Rainfall (mm)',
                                icon: Icons.umbrella_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _submitForm,
                            child: const Text('Get Recommendation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputTile({
    required String keyName,
    required String label,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = (screenWidth > 700 ? 405.0 : screenWidth - 40)
        .clamp(0.0, 405.0)
        .toDouble();

    return SizedBox(
      width: tileWidth,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF264939), width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF143F2E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF143F2E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: controllers[keyName],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        await ApiConfig.recommendUri(),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'N': double.parse(controllers['N']!.text),
          'P': double.parse(controllers['P']!.text),
          'K': double.parse(controllers['K']!.text),
          'temperature': double.parse(controllers['temperature']!.text),
          'humidity': double.parse(controllers['humidity']!.text),
          'ph': double.parse(controllers['ph']!.text),
          'rainfall': double.parse(controllers['rainfall']!.text),
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        Navigator.pushNamed(
          context,
          '/crop-result',
          arguments: result,
        );
        return;
      }

      String errorMessage = 'Failed to get recommendation. Please try again.';
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final detail = errorBody['detail'];
        if (detail is String && detail.isNotEmpty) {
          errorMessage = detail;
        }
      } catch (_) {
        // Fall back to the default message when the response is not JSON.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection failed. Check the backend URL and make sure the API server is running. Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showBackendSettings() async {
    final controller = TextEditingController(text: _backendBaseUrl);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backend URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use your computer\'s local IP when testing the APK on a real phone.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Example: http://192.168.1.5:8000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ApiConfig.setBaseUrl(controller.text);
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (saved == true) {
      await _loadBackendUrl();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend URL updated to $_backendBaseUrl')),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
