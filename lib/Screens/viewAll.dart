import 'package:cinema/MediaModel.dart';
import 'package:cinema/Screens/mediaInfo.dart';
import 'package:flutter/material.dart';

class ViewAll extends StatefulWidget {
  const ViewAll(this.imdbMovies, this.title, {super.key});

  final List<Media> imdbMovies;
  final String title;

  @override
  State<ViewAll> createState() => _ViewAllState();
}

class _ViewAllState extends State<ViewAll> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.imdbMovies.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.title == 'Favorites'
                          ? Icons.favorite_outline_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 58,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nothing here yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open a title and tap the ${widget.title.toLowerCase()} button.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.imdbMovies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final media = widget.imdbMovies[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaInfo(
                            media: media,
                            id: media.id,
                            genres: media.genres,
                            picUrl: media.picLocation,
                            isNetwork: true,
                            title: media.name,
                            description: media.description,
                            rating: media.rating,
                            ratingNumber: media.noOfRatings,
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: SizedBox(
                      height: 132,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 96,
                            height: double.infinity,
                            child: Image.network(
                              media.picLocation,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFF4A2600),
                                child: Icon(
                                  Icons.movie_outlined,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    media.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (star) => Icon(
                                        star < media.rating
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 17,
                                        color: const Color(0xFFFFB300),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    media.description.isEmpty
                                        ? 'No description available.'
                                        : media.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
