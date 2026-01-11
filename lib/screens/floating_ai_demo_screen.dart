import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/ai/floating_ai_service.dart';

/// Demo screen to showcase the floating AI button features
///
/// Can be accessed via: Get.to(() => const FloatingAIDemoScreen());
class FloatingAIDemoScreen extends StatelessWidget {
  const FloatingAIDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Floating AI Assistant'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Quick access to toggle AI button
          IconButton(
            icon: Icon(
              Icons.psychology_outlined,
              color: AppColors.primaryAccentColor,
            ),
            onPressed: () => FloatingAIService.instance.openAIAssistant(),
            tooltip: 'Open AI Assistant',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildFeaturesSection(),
            const SizedBox(height: 32),
            _buildControlsSection(),
            const SizedBox(height: 32),
            _buildUsageGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        _buildGuideStep(
          step: '1',
          title: 'Find the AI Button',
          description: 'Look for the floating blue button anywhere in the app',
        ),
        _buildGuideStep(
          step: '2',
          title: 'Tap to Use',
          description: 'Tap the button to open the AI assistant',
        ),
        _buildGuideStep(
          step: '3',
          title: 'Drag to Move',
          description: 'Hold and drag to reposition the button',
        ),
        _buildGuideStep(
          step: '4',
          title: 'Long Press to Expand',
          description: 'Long press to see "Ask AI" text',
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryAccentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Applied Intelligence Assistant',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your intelligent shopping companion is now globally accessible across all screens.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryText70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '💡 Look for the floating AI button anywhere in the app - you can drag it to reposition!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryAccentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.touch_app_outlined,
          title: 'Drag & Drop',
          description: 'Move the AI button anywhere on your screen',
        ),
        _buildFeatureItem(
          icon: Icons.memory,
          title: 'Persistent Position',
          description: 'Your preferred location is remembered',
        ),
        _buildFeatureItem(
          icon: Icons.gesture,
          title: 'Smart Interactions',
          description: 'Tap to open, long press to expand',
        ),
        _buildFeatureItem(
          icon: Icons.auto_awesome,
          title: 'Elegant Animations',
          description: 'Subtle pulse and glow effects',
        ),
        _buildFeatureItem(
          icon: Icons.psychology_outlined,
          title: 'AI Neural Design',
          description: 'Modern neural network visual patterns',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryAccentColor.withValues(alpha: 0.8),
                  AppColors.lightMauveBackgroundColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controls',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final service = FloatingAIService.instance;
          return Column(
            children: [
              _buildControlTile(
                title: 'Show/Hide AI Button',
                subtitle: service.isVisible
                    ? 'AI button is currently visible'
                    : 'AI button is hidden',
                trailing: Switch(
                  value: service.isVisible,
                  onChanged: (_) => service.toggleVisibility(),
                  activeThumbColor: AppColors.primaryAccentColor,
                ),
              ),
              _buildControlTile(
                title: 'Reset Position',
                subtitle: 'Move AI button back to default position',
                trailing: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryAccentColor,
                  ),
                  onPressed: () {
                    service.updatePosition(300.0, 500.0);
                    Get.snackbar(
                      'Position Reset',
                      'AI button moved to default position',
                      backgroundColor: AppColors.surface,
                      colorText: AppColors.primaryText,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ),
              _buildControlTile(
                title: 'Test AI Assistant',
                subtitle: 'Open the AI assistant directly',
                trailing: ElevatedButton(
                  onPressed: service.openAIAssistant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open AI'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildControlTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText70,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
