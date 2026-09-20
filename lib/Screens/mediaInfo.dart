import 'package:cinema/MediaModel.dart';
import 'package:cinema/favoritesClass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MediaInfo extends StatefulWidget {
  const MediaInfo({
    super.key,
    required this.id,
    required this.ratingNumber,
    required this.picUrl,
    required this.isNetwork,
    required this.title,
    required this.description,
    required this.rating,
    this.genres = const [],
    required this.media,
  });

  final String picUrl;
  final bool isNetwork;
  final String title;
  final String description;
  final int rating;
  final int ratingNumber;
  final List<dynamic> genres;
  final Media media;
  final String id;

  @override
  State<MediaInfo> createState() => _MediaInfoState();
}

class _MediaInfoState extends State<MediaInfo> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  static const List<String> _bannedWords = [
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'bastard',
    'nigga',
  ];

  CollectionReference<Map<String, dynamic>> get _comments =>
      FirebaseFirestore.instance
          .collection('media')
          .doc(widget.id)
          .collection('comments');

  String _nameFor(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Cinema fan';
  }

  String _censorBadWords(String input) {
    var result = input;
    for (final word in _bannedWords) {
      final expression = RegExp(
        '\\b${RegExp.escape(word)}\\b',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(
        expression,
        (match) => '*' * match.group(0)!.length,
      );
    }
    return result;
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();

    if (user == null) {
      _showMessage('Sign in to join the conversation.');
      return;
    }
    if (text.isEmpty || _isPosting) return;
    if (text.length > 500) {
      _showMessage('Comments can be up to 500 characters.');
      return;
    }

    setState(() => _isPosting = true);
    try {
      await _comments.add({
        'text': _censorBadWords(text),
        'userId': user.uid,
        'userEmail': user.email,
        'username': _nameFor(user),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Could not post your comment.');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _deleteComment(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await reference.delete();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Could not delete your comment.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFavorite() async {
    try {
      await Favorites.addToFavorites(widget.media);
    } catch (_) {
      _showMessage('Could not update favorites. Please try again.');
    }
  }

  Future<void> _toggleWatchLater() async {
    try {
      await WatchLater.addToWatchLater(widget.media);
    } catch (_) {
      _showMessage('Could not update Watch Later. Please try again.');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 440,
            pinned: true,
            stretch: true,
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF111018),
            actions: [
              ValueListenableBuilder<List<Media>>(
                valueListenable: Favorites.listenable,
                builder: (context, _, __) => _HeaderAction(
                  tooltip: 'Favorite',
                  icon: Favorites.contains(widget.media)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  selected: Favorites.contains(widget.media),
                  onPressed: _toggleFavorite,
                ),
              ),
              ValueListenableBuilder<List<Media>>(
                valueListenable: WatchLater.listenable,
                builder: (context, _, __) => _HeaderAction(
                  tooltip: 'Watch later',
                  icon: WatchLater.contains(widget.media)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  selected: WatchLater.contains(widget.media),
                  onPressed: _toggleWatchLater,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _PosterImage(url: widget.picUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black12,
                          Colors.transparent,
                          Color(0xE6111018),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < widget.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFB300),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.ratingNumber} ratings',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.genres.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.genres
                        .map(
                          (genre) => Chip(
                            label: Text(genre.toString()),
                            side: BorderSide.none,
                            backgroundColor:
                                colorScheme.primaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 24),
                Text('Storyline', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  widget.description.trim().isEmpty
                      ? 'No description is available for this title yet.'
                      : widget.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text('Comments', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    Icon(
                      Icons.forum_outlined,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CommentComposer(
                  controller: _commentController,
                  isPosting: _isPosting,
                  signedIn: FirebaseAuth.instance.currentUser != null,
                  onSubmit: _addComment,
                ),
                const SizedBox(height: 18),
                _buildComments(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _comments.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _EmptyComments(
            icon: Icons.cloud_off_outlined,
            message: 'Comments could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return const _EmptyComments(
            icon: Icons.chat_bubble_outline_rounded,
            message: 'No comments yet. Start the conversation.',
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        return Column(
          children: documents.map((document) {
            final data = document.data();
            final username = data['username']?.toString().trim();
            final email = data['userEmail']?.toString();
            final displayName = username != null && username.isNotEmpty
                ? (username.contains('@')
                    ? username.split('@').first
                    : username)
                : (email?.split('@').first ?? 'Cinema fan');
            final createdAt = data['createdAt'] as Timestamp?;

            return _CommentCard(
              displayName: displayName,
              text: _censorBadWords(data['text']?.toString() ?? ''),
              createdAt: createdAt?.toDate(),
              canDelete: data['userId'] == currentUserId,
              onDelete: () => _deleteComment(document.reference),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black38,
        foregroundColor: selected ? const Color(0xFFFFB300) : Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF4A2600),
        child: Center(
          child: Icon(Icons.movie_outlined, color: Colors.white54, size: 72),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF4A2600),
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white54, size: 72),
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isPosting,
    required this.signedIn,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isPosting;
  final bool signedIn;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: signedIn && !isPosting,
      maxLength: 500,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: signedIn
            ? 'Share what you thought...'
            : 'Sign in to leave a comment',
        counterText: '',
        suffixIcon: isPosting
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Post comment',
                onPressed: signedIn ? onSubmit : null,
                icon: const Icon(Icons.send_rounded),
              ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.displayName,
    required this.text,
    required this.createdAt,
    required this.canDelete,
    required this.onDelete,
  });

  final String displayName;
  final String text;
  final DateTime? createdAt;
  final bool canDelete;
  final VoidCallback onDelete;

  String get _dateLabel {
    if (createdAt == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(displayName.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        _dateLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                tooltip: 'Delete comment',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
