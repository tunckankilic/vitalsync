import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';
import 'package:vitalsync/features/health/presentation/widgets/contextual_onboarding_card.dart';
import 'package:vitalsync/features/health/presentation/widgets/medication_card.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,

      // AppBar is handled by AppShell mostly, but we might want a specific one here.
      // Wait, AppShell has a global AppBar. If we are inside Health tab, AppShell
      // displays "Health" title.
      // But prompt 4.3 says:
      // "- Tabs: Active | All | Completed (animated underline indicator)"
      // "- Search bar (animated expand: icon -> full width input)"
      // This implies we need a custom header or AppBar content.
      // Since AppShell handles the main AppBar, we can put the Tabs and Search
      // in the body, below the AppShell's AppBar (using SafeArea or padding).
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          // We need to account for AppShell's AppBar height if it's transparent/extended
          // AppShell uses extendBodyBehindAppBar: true.
          // So we should add top padding.
          top: true,
          child: Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    _buildSearchBar(l10n),
                    const SizedBox(height: 12),
                    // Tabs
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppTheme.healthPrimary.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppTheme.healthPrimary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppTheme.healthPrimary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: [
                          Tab(text: l10n.active), // "Active"
                          Tab(text: l10n.all), // "All"
                          Tab(text: l10n.completed), // "Completed"
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Medication List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MedicationList(
                      filter: _MedicationFilter.active,
                      searchQuery: _searchQuery,
                    ),
                    _MedicationList(
                      filter: _MedicationFilter.all,
                      searchQuery: _searchQuery,
                    ),
                    _MedicationList(
                      filter: _MedicationFilter.completed,
                      searchQuery: _searchQuery,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/add-medication'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addMedication),
        backgroundColor: AppTheme.healthPrimary,
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    if (!_isSearchVisible) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton.filledTonal(
          onPressed: () => setState(() => _isSearchVisible = true),
          icon: const Icon(Icons.search_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        borderRadius: 30,
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchMedication,
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearchVisible = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _MedicationFilter { active, all, completed }

class _MedicationList extends ConsumerWidget {
  const _MedicationList({required this.filter, required this.searchQuery});

  final _MedicationFilter filter;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);
    final l10n = AppLocalizations.of(context);

    return medicationsAsync.when(
      data: (medications) {
        // Filter logic
        final filteredMeds = medications.where((med) {
          // Search filter
          if (searchQuery.isNotEmpty &&
              !med.name.toLowerCase().contains(searchQuery)) {
            return false;
          }

          // Tab filter
          final now = DateTime.now();
          final isCompleted = med.endDate != null && med.endDate!.isBefore(now);

          switch (filter) {
            case _MedicationFilter.active:
              return med.isActive && !isCompleted;
            case _MedicationFilter.all:
              return true;
            case _MedicationFilter.completed:
              return isCompleted;
          }
        }).toList();

        if (filteredMeds.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredMeds.length,
          itemBuilder: (context, index) {
            final med = filteredMeds[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MedicationCard(medication: med),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(AppLocalizations.of(context).errorGeneric(err))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: ContextualOnboardingCard(),
          ),
          const SizedBox(height: 32),
          Icon(
            Icons.medication_rounded,
            size: 64,
            color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMedicationsFound,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
