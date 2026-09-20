# AllVerse Entertainment

My first Flutter and mobile development project, bringing movies, TV shows,
games, and anime together with category/genre search, favorites, Watch Later,
comments, and a golden-orange featured carousel.

## Local setup

1. Install Flutter and run `flutter pub get`.
2. Run `flutterfire configure` for your own Firebase project to generate the
   ignored `lib/firebase_options.dart` and platform configuration files.
3. Copy `config.example.json` to `config.local.json` and enter your RAWG key.
4. Run `flutter run --dart-define-from-file=config.local.json`.
5. Configure Firebase CLI for your project. Use `firebase.example.json` as a
   starting point for `firebase.json`, and deploy Firestore/Storage rules.

## Data and credentials

Content comes from imdbapi.dev, Jikan, and RAWG. Firebase handles authentication
and cloud data; guest lists use local preferences. No OpenAI key is required.

Real Firebase configuration, environment files, logs, builds, and signing material
are excluded from Git. Do not put OpenAI keys or service-account private keys in
Flutter source or build parameters: client builds can be inspected. Use a backend
for calls requiring server secrets. RAWG's build parameter keeps the key out of
Git but does not hide it in a compiled app.

Firestore rules protect saved lists by UID. Comment documents are public, so do
not include private information. Deploy reviewed rules before distributing the
app. Rotate any credential previously exposed; ignoring it does not revoke it.

## Checks

```sh
flutter analyze --no-fatal-infos
flutter test
```
