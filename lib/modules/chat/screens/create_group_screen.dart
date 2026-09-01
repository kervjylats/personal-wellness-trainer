// lib/modules/chat/screens/create_group_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/chat_notifier.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();

  List<TeamMemberModel> _partners = [];
  List<TeamMemberModel> _staff    = [];
  List<TeamMemberModel> _clients  = [];

  final Set<String> _selectedIds = {};

  bool _partnersExpanded = true;
  bool _staffExpanded    = true;
  bool _clientsExpanded  = true;

  bool _isLoading  = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final source  = MockTeamSource();
    final members = await source.getMembers(authState.profile.businessId);
    final myId    = authState.profile.userId;

    final partners = <TeamMemberModel>[];
    final staff    = <TeamMemberModel>[];
    final clients  = <TeamMemberModel>[];

    for (final m in members) {
      if (m.userId == myId) continue;
      switch (m.role.toLowerCase()) {
        case 'partner':
          partners.add(m);
        case 'staff':
          staff.add(m);
        case 'client':
          clients.add(m);
      }
    }

    if (mounted) {
      setState(() {
        _partners  = partners;
        _staff     = staff;
        _clients   = clients;
        _isLoading = false;
      });
    }
  }

  void _toggleMember(TeamMemberModel member) {
    setState(() {
      if (_selectedIds.contains(member.userId)) {
        _selectedIds.remove(member.userId);
      } else {
        _selectedIds.add(member.userId);
      }
    });
  }

  void _removeMember(String userId) {
    setState(() => _selectedIds.remove(userId));
  }

  Future<void> _create() async {
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one member.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final allMembers = [..._partners, ..._staff, ..._clients];
    final nameMap = {for (final m in allMembers) m.userId: m.displayName};

    final ids   = _selectedIds.toList();
    final names = ids.map((id) => nameMap[id] ?? id).toList();

    final conv = await ref
        .read(chatNotifierProvider.notifier)
        .createConversation(
          participantIds: ids,
          participantNames: names,
          groupName: groupName,
        );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (conv != null) {
      context.goNamed(RouteNames.ownerMessageThread, extra: conv);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  '${_selectedIds.length} selected',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGroupNameField(),
                if (_selectedIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildSelectedMemberChips(colorScheme),
                ],
                const Divider(height: AppSpacing.lg),
                Expanded(child: _buildMemberSections(colorScheme)),
                _buildCreateButton(),
              ],
            ),
    );
  }

  // ── Private builder methods ───────────────────────────────────────────────

  Widget _buildGroupNameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH, AppSpacing.md, AppSpacing.screenPaddingH, 0),
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Group name',
          hintText: 'e.g. Team Updates',
          prefixIcon: const Icon(Icons.group_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSelectedMemberChips(ColorScheme colorScheme) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
        children: _selectedIds.map((id) {
          final member = [..._partners, ..._staff, ..._clients]
              .where((m) => m.userId == id).firstOrNull;
          final name = member?.displayName ?? id;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                radius: 12,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
              label: Text(name.split(' ').first,
                  style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurface)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _removeMember(id),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberSections(ColorScheme colorScheme) {
    return ListView(children: [
      if (_partners.isNotEmpty)
        _RoleSection(
          title: 'Partners', icon: Icons.handshake_outlined, color: colorScheme.primary,
          members: _partners, selectedIds: _selectedIds, isExpanded: _partnersExpanded,
          onToggleExpanded: () => setState(() => _partnersExpanded = !_partnersExpanded),
          onToggleMember: _toggleMember,
        ),
      if (_staff.isNotEmpty)
        _RoleSection(
          title: 'Staff', icon: Icons.badge_outlined, color: colorScheme.secondary,
          members: _staff, selectedIds: _selectedIds, isExpanded: _staffExpanded,
          onToggleExpanded: () => setState(() => _staffExpanded = !_staffExpanded),
          onToggleMember: _toggleMember,
        ),
      if (_clients.isNotEmpty)
        _RoleSection(
          title: 'Clients', icon: Icons.people_outline, color: colorScheme.tertiary,
          members: _clients, selectedIds: _selectedIds, isExpanded: _clientsExpanded,
          onToggleExpanded: () => setState(() => _clientsExpanded = !_clientsExpanded),
          onToggleMember: _toggleMember,
        ),
      if (_partners.isEmpty && _staff.isEmpty && _clients.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text('No members available.',
              style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant))),
        ),
      const SizedBox(height: AppSpacing.xxl),
    ]);
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH, 0, AppSpacing.screenPaddingH, AppSpacing.lg),
      child: PrimaryButton(
        label: 'Create Group',
        onPressed: _isCreating ? null : _create,
        isLoading: _isCreating,
      ),
    );
  }
}

// ── Role section (collapsible) ────────────────────────────────────────────────

class _RoleSection extends StatelessWidget {
  const _RoleSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.members,
    required this.selectedIds,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleMember,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<TeamMemberModel> members;
  final Set<String> selectedIds;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<TeamMemberModel> onToggleMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount =
        members.where((m) => selectedIds.contains(m.userId)).length;

    return Column(
      children: [
        // Section header — tappable to expand/collapse
        InkWell(
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(${members.length})',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: AppTextStyles.caption
                          .copyWith(color: colorScheme.onPrimary),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant.withAlpha(120),
                ),
              ],
            ),
          ),
        ),

        // Member tiles
        if (isExpanded)
          ...members.map((member) {
            final isSelected = selectedIds.contains(member.userId);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
              ),
              leading: CircleAvatar(
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : color.withAlpha(30),
                child: isSelected
                    ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
                    : Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isSelected ? colorScheme.onPrimary : color,
                        ),
                      ),
              ),
              title: Text(member.displayName, style: AppTextStyles.bodyMedium),
              subtitle: member.email != null
                  ? Text(member.email!, style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant))
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : Icon(Icons.circle_outlined, color: colorScheme.onSurfaceVariant.withAlpha(60)),
              onTap: () => onToggleMember(member),
            );
          }),

        const Divider(height: 1),
      ],
    );
  }
}