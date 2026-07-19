import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';
import 'verification_screen.dart';

/// Shown to lawyers while their application is 'pending' (locked out of all
/// B2B tools) or after it was 'rejected' (shows the admin's reason, which was
/// also emailed via the onLawyerStatusChange Cloud Function, and offers a
/// resubmission path).
class StatusScreen extends StatelessWidget {
  final AppUser user;
  const StatusScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final rejected = user.status == 'rejected';
    return Scaffold(
      appBar: AppBar(
        title: Text(rejected ? t.rejectedTitle : t.pendingTitle),
        actions: [
          IconButton(
              onPressed: AuthService.signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  rejected
                      ? Icons.gpp_bad_outlined
                      : Icons.hourglass_top_outlined,
                  size: 72,
                  color: rejected
                      ? const Color(0xFFB3261E)
                      : MeezanTheme.gold,
                ),
                const SizedBox(height: 16),
                Center(child: StatusChip(user.status)),
                const SizedBox(height: 16),
                if (!rejected)
                  Text(t.pendingBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                if (rejected) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.rejectionReasonLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(user.rejectionReason.isEmpty
                              ? '—'
                              : user.rejectionReason),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => VerificationScreen(user: user))),
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.resubmit),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
