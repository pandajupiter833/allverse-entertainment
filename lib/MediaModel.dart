class Media {
  final String description;
  final String type;
  final List<dynamic> genres;
  final String id;
  final String name;
  final int rating;
  final int noOfRatings;
  final String picLocation;

  const Media(this.name, this.rating, this.noOfRatings, this.picLocation,
      this.type, this.description, this.genres, this.id);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rating': rating,
      'noOfRatings': noOfRatings,
      'picLocation': picLocation,
      'type': type,
      'description': description,
      'genres': genres,
      'id': id
    };
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      json['name']?.toString() ?? 'Unknown',
      (json['rating'] as num?)?.toInt() ?? 0,
      (json['noOfRatings'] as num?)?.toInt() ?? 0,
      json['picLocation']?.toString() ?? '',
      json['type']?.toString() ?? 'movie',
      json['description']?.toString() ?? '',
      List<dynamic>.from(json['genres'] as List? ?? const []),
      json['id']?.toString() ?? '',
    );
  }
}
