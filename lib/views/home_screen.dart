import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'tracking_screen.dart';
import 'walking_history_screen.dart';
import 'feed_screen.dart';

// Main home screen with navigation to tracking, history, and feed
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingXXL),
                
                const Text(
                  'Walking Tracker',
                  style: AppTheme.appTitle,
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                Text(
                  'Track your walks and view your journey history',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textLight),
                ),
                
                const SizedBox(height: AppTheme.spacingXXL),
                
                _buildStartWalkingCard(context),
                
                const SizedBox(height: AppTheme.spacingL),
                
                _buildWalkingHistoryCard(context),
                
                const SizedBox(height: AppTheme.spacingL),
                
                _buildMediaFeedCard(context),
                
                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Primary action card to start walk tracking
  Widget _buildStartWalkingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.statsCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrackingScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha:0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    size: AppTheme.iconSizeXL,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start walking'),
                    style: AppTheme.largePrimaryButton,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                const Text(
                  'Begin tracking your walk',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card with link to walking history screen
  Widget _buildWalkingHistoryCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Text(
              'Walking History',
              style: AppTheme.sectionHeader,
            ),
          ),
          
          const Divider(height: 1),
          
          _buildHistoryOption(
            context: context,
            icon: Icons.history_rounded,
            title: 'View History',
            description: 'See all your screenshots and recordings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalkingHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Card with link to media feed screen
  Widget _buildMediaFeedCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Text(
              'Media Feed',
              style: AppTheme.sectionHeader,
            ),
          ),
          
          const Divider(height: 1),
          
          _buildHistoryOption(
            context: context,
            icon: Icons.feed_rounded,
            title: 'View Feed',
            description: 'Browse infinite scroll media feed',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Reusable navigation option row with icon and description
  Widget _buildHistoryOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconSizeM,
                  color: AppTheme.primaryPurple,
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingS),
              
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textLight,
                size: AppTheme.iconSizeS,
              ),
            ],
          ),
        ),
      ),
    );
  }
}