import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ShoppleAiInfoSheet extends StatelessWidget {
  const ShoppleAiInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSpaces.verticalSpace10,
        AppSpaces.verticalSpace20,

        // Header with gradient accent
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              AppSpaces.horizontalSpace20,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopple AI',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Your intelligent shopping assistant',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // How it works - Step by step
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LiquidGlass(
            enableBlur: true,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            gradientColors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ],
            borderColor: Colors.white.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Shopple AI Works',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                _buildStep(
                  '1',
                  'Parse Your Request',
                  'AI reads your text to extract list name, items, quantities, and optional budget limit',
                  Icons.text_fields_outlined,
                  const Color(0xFF00B894),
                ),

                _buildStep(
                  '2',
                  'Create Shopping List',
                  'A new shopping list is created with your specified name and budget (if provided)',
                  Icons.list_alt_outlined,
                  const Color(0xFF6C5CE7),
                ),

                _buildStep(
                  '3',
                  'Search & Match Products',
                  'Each item is searched in the product database and AI selects the best match with pricing',
                  Icons.search_outlined,
                  const Color(0xFFE17055),
                ),

                _buildStep(
                  '4',
                  'Add Items to List',
                  'Matched products are added to your list with quantities and estimated prices',
                  Icons.add_shopping_cart_outlined,
                  const Color(0xFFE84393),
                ),
              ],
            ),
          ),
        ),

        AppSpaces.verticalSpace20,

        // Quick Cards explanation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LiquidGlass(
            enableBlur: true,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            gradientColors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ],
            borderColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Cards - Your Shopping Shortcuts',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Quick Cards are personalized shortcuts for your most common shopping needs. Create up to 3 cards with custom prompts.',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Cards steps
                _buildQuickCardStep(
                  'Tap "+" to Create',
                  'Add a new Quick Card with your custom prompt like "Weekly groceries for 2 people"',
                  Icons.add_circle_outline,
                ),

                _buildQuickCardStep(
                  'One-Tap Activation',
                  'Tap any Quick Card to instantly fill the AI prompt field with your saved request',
                  Icons.touch_app_outlined,
                ),

                _buildQuickCardStep(
                  'Edit & Organize',
                  'Use tags to categorize cards, reorder them, or modify prompts as your needs change',
                  Icons.tune_outlined,
                ),
              ],
            ),
          ),
        ),

        AppSpaces.verticalSpace20,

        // What AI actually does
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LiquidGlass(
            enableBlur: true,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            gradientColors: [
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.02),
            ],
            borderColor: const Color(0xFF00B894).withValues(alpha: 0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What Shopple AI Actually Does',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                _buildCapabilityItem(
                  '✅ Parses item names and quantities from your text',
                  Icons.check_circle_outlined,
                ),
                _buildCapabilityItem(
                  '✅ Extracts budget limits when mentioned (e.g., "budget \$50")',
                  Icons.monetization_on_outlined,
                ),
                _buildCapabilityItem(
                  '✅ Searches product database and finds best matches',
                  Icons.search_outlined,
                ),
                _buildCapabilityItem(
                  '✅ Adds estimated prices from available product data',
                  Icons.local_offer_outlined,
                ),
                _buildCapabilityItem(
                  '✅ Creates organized shopping lists automatically',
                  Icons.list_alt_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  'Note: The AI works with existing product data and pricing. It sets budget limits but doesn\'t actively track spending during shopping.',
                  style: GoogleFonts.lato(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        AppSpaces.verticalSpace20,

        // Close button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: LiquidGlassButton.primary(
              onTap: () => Navigator.pop(context),
              text: 'Got it!',
              gradientColors: [
                const Color(0xFF6C5CE7),
                const Color(0xFFA29BFE),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00B894)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCardStep(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFFA29BFE)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
