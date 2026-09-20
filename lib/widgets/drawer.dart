import 'package:cinema/Screens/about_page.dart';
import 'package:cinema/Screens/viewAll.dart';
import 'package:cinema/auth.dart';
import 'package:cinema/favoritesClass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Drawer drawer(
  double width,
  double height,
  BuildContext context,
  AuthService auth,
) {
  final user = FirebaseAuth.instance.currentUser;
  final name = user?.displayName?.trim().isNotEmpty == true
      ? user!.displayName!.trim()
      : user?.email?.split('@').first ?? 'Guest';

  return Drawer(
    width: width * 0.82,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(name.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        user?.email ?? 'Browsing without an account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ValueListenableBuilder(
            valueListenable: Favorites.listenable,
            builder: (context, items, _) => ListTile(
              leading: const Icon(Icons.favorite_outline_rounded),
              title: const Text('Favorites'),
              trailing: _CountBadge(count: items.length),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewAll(items, 'Favorites'),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: WatchLater.listenable,
            builder: (context, items, _) => ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded),
              title: const Text('Watch Later'),
              trailing: _CountBadge(count: items.length),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewAll(items, 'Watch Later'),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: user == null
                  ? FilledButton.icon(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign in'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('$count'),
    );
  }
}
