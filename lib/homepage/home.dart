import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cinema/MediaModel.dart';
import 'package:cinema/Screens/mediaInfo.dart';
import 'package:cinema/Screens/viewAll.dart';
import 'package:cinema/auth.dart';
import 'package:cinema/favoritesClass.dart';
import 'package:cinema/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

void main() {
  runApp(const MainApp());
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

const String _allFilter = 'all';

String normalizeMediaType(dynamic value) {
  final type = value?.toString().trim().toLowerCase() ?? '';

  if (type.contains('anime')) return 'anime';
  if (type.contains('game')) return 'game';
  if (type.contains('tv') ||
      type.contains('series') ||
      type.contains('episode')) {
    return 'tvSeries';
  }
  return 'movie';
}

String mediaTypeLabel(String type) {
  switch (normalizeMediaType(type)) {
    case 'tvSeries':
      return 'TV Shows';
    case 'game':
      return 'Games';
    case 'anime':
      return 'Anime';
    default:
      return 'Movies';
  }
}

List<String> cleanGenres(dynamic value) {
  if (value is! List) return [];
  return value
      .where((genre) => genre != null)
      .map((genre) => genre.toString().trim())
      .where((genre) => genre.isNotEmpty)
      .toSet()
      .toList();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentIndex = 0;

  final pages = [
    const Home(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFFE66B00),
          unselectedItemColor: Colors.grey,
          backgroundColor: const Color(0xFFFFD700), // gold

          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: "Featured",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Search",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// MEDIA CLASS
//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////
// HOME PAGE (Your page unchanged except small cleanup)
//////////////////////////////////////////////////////////////////////////////////////////////////////

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<User?>? _authSubscription;
  final PageController _bannerController =
      PageController(viewportFraction: 0.84);
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _loadLibraries(force: true);
    });
    _loadLibraries();
    fetchIMDBMovies();
  }

  Future<void> _loadLibraries({bool force = false}) async {
    await Future.wait([
      Favorites.load(force: force),
      WatchLater.load(force: force),
    ]);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  int get _bannerCount => imdbMovies.length > 8 ? 8 : imdbMovies.length;

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_bannerCount < 2) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;

      final nextIndex = _bannerIndex >= _bannerCount - 1 ? 0 : _bannerIndex + 1;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  late http.Response response;
  List<Media> imdbMovies = [];

  Future<void> fetchIMDBMovies() async {
    List<Media> animeList = [];
    List<Media> gameList = [];
    final response =
        await http.get(Uri.parse("https://api.imdbapi.dev/titles"));
    final animeDataResponse =
        await http.get(Uri.parse("https://api.jikan.moe/v4/anime"));
    final gameDataResponse = await http.get(Uri.parse(
        'https://api.rawg.io/api/games?key=${const String.fromEnvironment("RAWG_API_KEY")}'));

    if (animeDataResponse.statusCode == 200) {
      final data = jsonDecode(animeDataResponse.body)['data'];
      animeList = (data as List).map((anime) {
        return Media(
            anime['title'] ?? "Unknown",
            ((anime['score'] ?? 8) / 2).toInt(),
            anime['scored_by'] ?? 0,
            anime['images']['webp']['image_url'] ?? "",
            "anime",
            anime['synopsis'] ?? "",
            (anime['genres'] as List? ?? const [])
                .map((g) => g['name'].toString())
                .toList(),
            "anime${anime['mal_id']}");
      }).toList();
    } else {
      debugPrint("Failed to fetch anime: ${animeDataResponse.statusCode}");
    }
    if (gameDataResponse.statusCode == 200) {
      final data = jsonDecode(gameDataResponse.body)['results'];
      gameList = (data as List).map((game) {
        return Media(
            game['name'] ?? "Unknown",
            ((game['rating'] ?? 0)).toInt(),
            game['ratings_count'] ?? 0,
            game['background_image'] ?? "",
            "game",
            game['name'] ?? "",
            (game['genres'] as List? ?? const [])
                .map((g) => g['name'].toString())
                .toList(),
            "game${game['id']}");
      }).toList();
    } else {
      debugPrint("Failed to fetch games: ${gameDataResponse.statusCode}");
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['titles'];
      imdbMovies = (data as List).map((movie) {
        return Media(
            movie['primaryTitle'] ?? "Unknown",
            ((movie['rating']?['aggregateRating'] ?? 8) / 2).toInt(),
            movie['rating']?['voteCount'] ?? 0,
            movie['primaryImage']?['url'] ?? "",
            normalizeMediaType(movie['type']),
            movie['plot'] ?? "",
            cleanGenres(movie['genres']),
            movie['id']);
      }).toList();
    } else {
      debugPrint("Failed to fetch movies: ${response.statusCode}");
    }
    imdbMovies = [...imdbMovies, ...animeList, ...gameList];

    if (!mounted) return;
    setState(() {
      _bannerIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bannerController.hasClients) {
        _bannerController.jumpToPage(0);
      }
      _startBannerAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: drawer(width, height, context, AuthService()),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState!.openDrawer();
              },
              child: const Icon(Icons.menu),
            ),
            const Text(
              "Featured",
              style: TextStyle(
                color: Color(0xFFE66B00),
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ======= BIG RECOMMENDED SLIDER =======
            if (imdbMovies.isEmpty)
              SizedBox(
                height: height * 0.4,
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.only(left: width * 0.04, top: 16, bottom: 8),
                    child: Text(
                      "Recommended",
                      style: TextStyle(
                        fontSize: height * 0.028,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: height * 0.43,
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _bannerController,
                            itemCount: _bannerCount,
                            onPageChanged: (index) {
                              setState(() => _bannerIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final media = imdbMovies[index];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.bottomToTop,
                                        child: MediaInfo(
                                          genres: media.genres,
                                          media: media,
                                          id: media.id, // unique id from API
                                          picUrl: media.picLocation,
                                          isNetwork: true,
                                          title: media.name,
                                          description: media.description,
                                          rating: media.rating,
                                          ratingNumber: media.noOfRatings,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFFFFB300),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF57C00)
                                              .withValues(alpha: 0.24),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        // big background image
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          child: Image.network(
                                            media.picLocation,
                                            width: width * 0.8,
                                            height: height * 0.4,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                        // dark gradient + text at bottom
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                bottom: Radius.circular(22),
                                              ),
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  const Color(0xFFF57C00)
                                                      .withValues(alpha: 0.88),
                                                  const Color(0xFF4A2600)
                                                      .withValues(alpha: 0.45),
                                                  Colors.black
                                                      .withValues(alpha: 0),
                                                ],
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  media.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: i < media.rating
                                                          ? const Color(
                                                              0xFFFFD54F)
                                                          : Colors.white54,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "(${media.noOfRatings})",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _bannerCount,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: index == _bannerIndex ? 28 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == _bannerIndex
                                    ? const Color(0xFFF57C00)
                                    : const Color(0xFFFFD180),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // ======= EXISTING SECTIONS =======
            mediaSection(
              width,
              height,
              "Movies",
              imdbMovies
                  .where((e) => normalizeMediaType(e.type) == "movie")
                  .toList(),
              "movie",
            ),
            mediaSection(
              width,
              height,
              "TV Series",
              imdbMovies
                  .where((e) => normalizeMediaType(e.type) == "tvSeries")
                  .toList(),
              "tvSeries",
            ),
            mediaSection(
              width,
              height,
              "Games",
              imdbMovies
                  .where((e) => normalizeMediaType(e.type) == "game")
                  .toList(),
              "game",
            ),
            mediaSection(
              width,
              height,
              "Anime",
              imdbMovies
                  .where((e) => normalizeMediaType(e.type) == "anime")
                  .toList(),
              "anime",
            ),
          ],
        ),
      ),
    );
  }

  // YOUR ORIGINAL WIDGET, UNCHANGED
  // Big "Recommended" slider at the top

  Column mediaSection(double width, double height, String title,
      List<Media> media, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: width * 0.04, top: 20),
          child: Text(
            title,
            style: TextStyle(
                fontSize: height * 0.025, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: height * 0.33,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: media.length > 4 ? 5 : media.length,
            itemBuilder: (context, index) {
              return index == 4
                  ? GestureDetector(
                      onTap: () => {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAll(
                                  imdbMovies.where((e) {
                                    return normalizeMediaType(e.type) == type;
                                  }).toList(),
                                  title),
                            ))
                      },
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02, vertical: 10),
                          child: SizedBox(
                            width: width * 0.3,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward_rounded),
                                Text('See more')
                              ],
                            ),
                          )),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02, vertical: 10),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              PageTransition(
                                  type: PageTransitionType.bottomToTop,
                                  child: MediaInfo(
                                    genres: media[index].genres,
                                    media: media[index],
                                    id: media[index].id,
                                    picUrl: media[index].picLocation,
                                    isNetwork: false,
                                    title: media[index].name,
                                    description: media[index].description,
                                    rating: media[index].rating,
                                    ratingNumber: media[index].noOfRatings,
                                  )));
                        },
                        child: Container(
                          width: width * 0.4,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              )
                            ],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Image.network(
                                media[index].picLocation,
                                width: width * 0.4,
                                height: height * 0.25,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: width * 0.4,
                                  color: Colors.black.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        media[index].name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            Icons.star,
                                            size: 16,
                                            color: i < media[index].rating
                                                ? const Color(0xFFFFB300)
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "(${media[index].noOfRatings})",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// SEARCH PAGE (WORKING SEARCH BAR)
//////////////////////////////////////////////////////////////////////////////////////////////////////

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Media> allMedia = [];
  List<Media> filtered = [];
  bool _isLoading = true;
  String _query = '';
  String _selectedType = _allFilter;
  String _selectedGenre = _allFilter;

  List<String> get _typeOptions => const [
        _allFilter,
        'movie',
        'tvSeries',
        'game',
        'anime',
      ];

  List<String> get _genreOptions {
    final source = allMedia.where((media) {
      return _selectedType == _allFilter ||
          normalizeMediaType(media.type) == _selectedType;
    });

    final genres = source
        .expand((media) => media.genres)
        .map((genre) => genre.toString().trim())
        .where((genre) => genre.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [_allFilter, ...genres];
  }

  @override
  void initState() {
    super.initState();
    _loadMediaForSearch();
  }

  Future<void> _loadMediaForSearch() async {
    try {
      List<Media> animeList = [];
      List<Media> gameList = [];
      List<Media> imdbMoviesLocal = [];

      // Same APIs you already use in Home.fetchIMDBMovies()
      final response =
          await http.get(Uri.parse("https://api.imdbapi.dev/titles"));
      final animeDataResponse =
          await http.get(Uri.parse("https://api.jikan.moe/v4/anime"));
      final gameDataResponse = await http.get(Uri.parse(
          'https://api.rawg.io/api/games?key=${const String.fromEnvironment("RAWG_API_KEY")}'));

      if (animeDataResponse.statusCode == 200) {
        final data = jsonDecode(animeDataResponse.body)['data'];
        animeList = (data as List).map((anime) {
          return Media(
            anime['title'] ?? "Unknown",
            ((anime['score'] ?? 8) / 2).toInt(),
            anime['scored_by'] ?? 0,
            anime['images']['webp']['image_url'] ?? "",
            "anime",
            anime['synopsis'] ?? "",
            (anime['genres'] as List? ?? const [])
                .map((g) => g['name'].toString())
                .toList(),
            "anime${anime['mal_id']}",
          );
        }).toList();
      } else {
        debugPrint(
          "Failed to fetch anime: ${animeDataResponse.statusCode}",
        );
      }

      if (gameDataResponse.statusCode == 200) {
        final data = jsonDecode(gameDataResponse.body)['results'];
        gameList = (data as List).map((game) {
          return Media(
            game['name'] ?? "Unknown",
            ((game['rating'] ?? 0)).toInt(),
            game['ratings_count'] ?? 0,
            game['background_image'] ?? "",
            "game",
            game['name'] ?? "",
            (game['genres'] as List? ?? const [])
                .map((g) => g['name'].toString())
                .toList(),
            "game${game['id']}",
          );
        }).toList();
      } else {
        debugPrint(
          "Failed to fetch games: ${gameDataResponse.statusCode}",
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['titles'];
        imdbMoviesLocal = (data as List).map((movie) {
          return Media(
            movie['primaryTitle'] ?? "Unknown",
            ((movie['rating']?['aggregateRating'] ?? 8) / 2).toInt(),
            movie['rating']?['voteCount'] ?? 0,
            movie['primaryImage']?['url'] ?? "",
            normalizeMediaType(movie['type']),
            movie['plot'] ?? "",
            cleanGenres(movie['genres']),
            movie['id'],
          );
        }).toList();
      } else {
        debugPrint("Failed to fetch movies: ${response.statusCode}");
      }

      final all = [...imdbMoviesLocal, ...animeList, ...gameList];

      setState(() {
        allMedia = all;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint("Error loading media for search: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void search(String text) {
    setState(() {
      _query = text;
      _applyFilters();
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _selectedType = value;
      _selectedGenre = _allFilter;
      _applyFilters();
    });
  }

  void _setGenreFilter(String value) {
    setState(() {
      _selectedGenre = value;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final q = _query.toLowerCase().trim();
    filtered = allMedia.where((media) {
      final typeMatches = _selectedType == _allFilter ||
          normalizeMediaType(media.type) == _selectedType;

      final genreMatches = _selectedGenre == _allFilter ||
          media.genres.any(
            (genre) =>
                genre.toString().toLowerCase() == _selectedGenre.toLowerCase(),
          );

      final textMatches = q.isEmpty ||
          media.name.toLowerCase().contains(q) ||
          media.description.toLowerCase().contains(q) ||
          media.genres.any(
            (genre) => genre.toString().toLowerCase().contains(q),
          );

      return typeMatches && genreMatches && textMatches;
    }).toList();
  }

  String _filterLabel(String value) {
    if (value == _allFilter) return 'All';
    return mediaTypeLabel(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Search",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: search,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          hintText: "Search titles or genres...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _typeOptions
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(_filterLabel(type)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) _setTypeFilter(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_selectedType),
                              initialValue:
                                  _genreOptions.contains(_selectedGenre)
                                      ? _selectedGenre
                                      : _allFilter,
                              decoration: const InputDecoration(
                                labelText: 'Genre',
                                prefixIcon: Icon(Icons.local_offer_outlined),
                              ),
                              items: _genreOptions
                                  .map(
                                    (genre) => DropdownMenuItem(
                                      value: genre,
                                      child: Text(
                                        genre == _allFilter ? 'All' : genre,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) _setGenreFilter(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final media = filtered[index];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              child: MediaInfo(
                                genres: media.genres,
                                media: media,
                                id: media.id, // use the real unique id from API
                                picUrl: media.picLocation,
                                isNetwork: true, // you are using Image.network
                                title: media.name,
                                description: media.description,
                                rating: media.rating,
                                ratingNumber: media.noOfRatings,
                              ),
                              type: PageTransitionType.rightToLeftWithFade,
                            ),
                          );
                        },
                        leading: Image.network(
                          media.picLocation,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 60,
                            height: 60,
                            child: ColoredBox(
                              color: Color(0xFF4A2600),
                              child: Icon(
                                Icons.movie_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          media.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          "${media.rating} ★",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// PROFILE PAGE (SIMPLE PAGE)
//////////////////////////////////////////////////////////////////////////////////////////////////////

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      body: const Center(
        child: Text(
          "Profile Page",
          style: TextStyle(color: Color(0xFFE66B00), fontSize: 24),
        ),
      ),
    );
  }
}
