# OrbitGram

Мессенджер на Flutter + Firebase (анонимный вход, Firestore).

## Сборка APK

APK собирается автоматически в GitHub Actions (`.github/workflows/build.yml`) при пуше в `main`
или вручную через вкладку Actions → Run workflow. Папка `android/` генерируется на лету
командой `flutter create`, поэтому в репозитории её нет.

Локально:

```bash
flutter create . --platforms=android --project-name=orbitgram --org com.example
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```

В Firebase Console должны быть включены Authentication → Anonymous и Firestore Database.
