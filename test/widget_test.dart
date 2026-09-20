import 'package:cinema/MediaModel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Media survives JSON persistence', () {
    const media = Media(
      'Arrival',
      5,
      1200,
      'https://example.com/poster.jpg',
      'movie',
      'A linguist meets visitors from another world.',
      ['Drama', 'Sci-Fi'],
      'title-123',
    );

    final restored = Media.fromJson(media.toJson());

    expect(restored.id, media.id);
    expect(restored.name, media.name);
    expect(restored.rating, media.rating);
    expect(restored.genres, media.genres);
  });
}
