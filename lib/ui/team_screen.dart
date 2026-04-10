import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/team_service.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final _serverController = TextEditingController();
  final _tokenController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  TeamLicense? _license;
  List<TeamMember> _members = [];
  TeamStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _tokenController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    final team = ref.read(teamServiceProvider);
    if (!team.isInTeam) return;

    setState(() => _loading = true);
    final results = await Future.wait([
      team.getLicense(),
      team.getMembers(),
      team.getTeamStats(),
    ]);
    if (mounted) {
      setState(() {
        _license = results[0] as TeamLicense?;
        _members = results[1] as List<TeamMember>;
        _stats = results[2] as TeamStats?;
        _loading = false;
      });
    }
  }

  Future<void> _joinTeam() async {
    final team = ref.read(teamServiceProvider);
    await team.configure(
      serverUrl: _serverController.text.trim(),
      authToken: _tokenController.text.trim(),
    );
    final success = await team.joinTeam(_codeController.text.trim());
    if (mounted) {
      if (success) {
        await _loadTeamData();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join team')),
        );
      }
    }
  }

  Future<void> _leaveTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave team?'),
        content: const Text('You will no longer receive team settings or appear in team stats.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(teamServiceProvider).leaveTeam();
      if (mounted) setState(() {});
    }
  }

  Future<void> _pushSettings() async {
    final team = ref.read(teamServiceProvider);
    final settings = ref.read(settingsProvider);
    final success = await team.pushTeamSettings(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Settings pushed to team' : 'Push failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(teamServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      body: team.isInTeam
          ? _buildTeamDashboard(context, team)
          : _buildJoinForm(context),
    );
  }

  Widget _buildJoinForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join a Team', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Enter your team server details and invite code to join.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://your-team-server.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Auth Token',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Team Invite Code',
              hintText: 'ABC123',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _joinTeam,
              child: const Text('Join Team'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDashboard(BuildContext context, TeamService team) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // License info
          if (_license != null) _LicenseCard(license: _license!),
          const SizedBox(height: 16),

          // Team stats
          if (_stats != null) _TeamStatsCard(stats: _stats!),
          const SizedBox(height: 16),

          // Members list
          Text('Members', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._members.map((m) => _MemberTile(member: m)),

          // Admin actions
          if (team.isAdmin) ...[
            const Divider(height: 32),
            Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pushSettings,
              icon: const Icon(Icons.upload),
              label: const Text('Push Settings to Team'),
            ),
          ],

          const Divider(height: 32),
          TextButton.icon(
            onPressed: _leaveTeam,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text('Leave Team', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final TeamLicense license;

  const _LicenseCard({required this.license});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 8),
                Text(license.teamName,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(
                  label: Text(license.isValid ? 'Active' : 'Expired'),
                  backgroundColor: license.isValid
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${license.usedSeats} / ${license.totalSeats} seats used  |  '
              '${license.availableSeats} available',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: license.totalSeats > 0
                  ? license.usedSeats / license.totalSeats
                  : 0,
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamStatsCard extends StatelessWidget {
  final TeamStats stats;

  const _TeamStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                  label: 'Active Today',
                  value: '${stats.activeToday}/${stats.totalMembers}',
                  icon: Icons.people,
                ),
                _MiniStat(
                  label: 'Avg Health',
                  value: '${stats.avgHealthScore.round()}',
                  icon: Icons.favorite,
                ),
                _MiniStat(
                  label: 'Breaks Today',
                  value: '${stats.totalBreaksToday}',
                  icon: Icons.free_breakfast,
                ),
                _MiniStat(
                  label: 'Compliance',
                  value: '${(stats.avgBreakCompliance * 100).round()}%',
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          )),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final TeamMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isOnline = member.lastSeen != null &&
        DateTime.now().difference(member.lastSeen!).inMinutes < 10;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOnline ? Colors.green.shade100 : Colors.grey.shade200,
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: isOnline ? Colors.green.shade700 : Colors.grey,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(member.name),
          if (member.role == 'admin') ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Admin',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
            ),
          ],
        ],
      ),
      subtitle: Text(member.email),
      trailing: member.healthScore != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${member.healthScore}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: member.healthScore! >= 80
                        ? Colors.green
                        : member.healthScore! >= 60
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Text('score', style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          : null,
    );
  }
}
