import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme.dart';
import '../../../widgets/tab_header.dart';
import '../../atoms/glass_card.dart';
import '../../../data/models/vault_models.dart';
import '../../../data/services/vault_service.dart';
import '../../../data/services/analytics_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String selectedFilter = 'all'; // 'all', 'scan', 'council'
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('vault_page');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _getFilteredEntries();

    return Scaffold(
      resizeToAvoidBottomInset: true, // Properly resizes when keyboard appears
      backgroundColor: WFColors.base,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header and search section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TabHeader(
                    title: 'Beguile AI',
                    subtitle: 'VAULT',
                  ),
                  
                  const SizedBox(height: 24),

                  // Search and Filter
                  GlassCard(
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search your vault...',
                            hintStyle: WFTextStyles.bodyMedium.copyWith(
                              color: WFColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: WFColors.purple400,
                            ),
                            filled: true,
                            fillColor: WFColors.gray800.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: WFColors.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: WFColors.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: WFColors.purple400, width: 2),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filter Chips
                        Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              isSelected: selectedFilter == 'all',
                              onTap: () => setState(() => selectedFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '🔍 Scan',
                              isSelected: selectedFilter == 'scan',
                              onTap: () => setState(() => selectedFilter = 'scan'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '🧠 Council',
                              isSelected: selectedFilter == 'council',
                              onTap: () => setState(() => selectedFilter = 'council'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Scrollable Vault Entries
            Expanded(
              child: filteredEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VaultEntryCard(
                            entry: entry,
                            onShare: () => _shareEntry(entry),
                            onCopy: () => _copyEntry(entry),
                            onDelete: () => _deleteEntry(entry),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<VaultEntry> _getFilteredEntries() {
    var entries = VaultService.getEntries();
    
    // Apply type filter
    if (selectedFilter != 'all') {
      entries = entries.where((e) => e.type == selectedFilter).toList();
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      entries = entries.where((e) =>
          e.title.toLowerCase().contains(searchQuery) ||
          e.content.toLowerCase().contains(searchQuery)).toList();
    }
    
    // Sort by timestamp (newest first)
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return entries;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Your vault is empty',
            style: WFTextStyles.h3.copyWith(
              color: WFColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI outputs from Scan and Council will appear here',
            style: WFTextStyles.bodyMedium.copyWith(
              color: WFColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _shareEntry(VaultEntry entry) {
    final text = '${entry.title}\n\n${entry.content}\n\n— Beguile AI ${entry.type.toUpperCase()}';
    AnalyticsService.logVaultEntryShared(entry.type);
    Share.share(text);
  }

  void _copyEntry(VaultEntry entry) {
    final text = '${entry.title}\n\n${entry.content}';
    AnalyticsService.logVaultEntryCopied(entry.type);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: WFColors.purple400,
      ),
    );
  }

  void _deleteEntry(VaultEntry entry) async {
    await VaultService.deleteEntry(entry.id);
    setState(() {}); // Refresh UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted'),
          backgroundColor: WFColors.gray700,
        ),
      );
    }
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? WFColors.purple400.withOpacity(0.2)
              : WFColors.gray800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? WFColors.purple400
                : WFColors.gray600.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: WFTextStyles.labelMedium.copyWith(
            color: isSelected ? WFColors.purple300 : WFColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Vault Entry Card Widget
class _VaultEntryCard extends StatelessWidget {
  final VaultEntry entry;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _VaultEntryCard({
    required this.entry,
    required this.onShare,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeIcon = entry.type == 'scan' ? '🔍' : '🧠';
    final typeColor = entry.type == 'scan' ? WFColors.success : WFColors.info;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: typeColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(typeIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      entry.type.toUpperCase(),
                      style: WFTextStyles.labelSmall.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(entry.timestamp),
                style: WFTextStyles.labelSmall.copyWith(
                  color: WFColors.textTertiary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            entry.title,
            style: WFTextStyles.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Content - Show full text with better visibility
          Text(
            entry.content,
            style: WFTextStyles.bodyMedium.copyWith(
              color: WFColors.textPrimary,
              height: 1.5,
            ),
            maxLines: null, // Show all content, not just 3 lines
          ),
          
          const SizedBox(height: 16),
          
          // Metadata
          if (entry.metadata.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: entry.metadata.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WFColors.gray800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: WFTextStyles.labelSmall.copyWith(
                      color: WFColors.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: onCopy,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: onShare,
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: onDelete,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? WFColors.error : WFColors.purple400;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: WFTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}