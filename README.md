# Football Ear Coach (Offline)

An offline football training **ear-coach** app that calls out randomized commands in your ear: *Shoot, Dribble, Man on, Turn, Sprint, Cross,* etc. Works entirely **offline** using your device's Text-to-Speech (TTS) once an offline voice is installed.

## Features
- Randomized commands with adjustable min/max gap (e.g., 3–6 seconds)
- Choose categories: Ball Control, Passing, Shooting, Defensive, Physical
- **Combo** commands (e.g., "Dribble then Shoot")
- Vibration cue before each command (optional)
- Add your **own custom commands**
- Saves your preferences locally
- One-tap start/stop, fully hands-free with earphones

## 100% Offline
This app uses Android's built-in **offline TTS** if you install a voice:
- Go to **Settings → System → Languages & input → Text-to-speech** (varies by device)
- Install a language pack (English/Hindi/Urdu supported on many devices)
- Select the **Download** option for offline use

> If you prefer recorded human voices instead of TTS, you can later replace TTS with bundled audio files.

## Build the APK (Android)
1. Install Flutter: https://docs.flutter.dev/get-started/install  
2. Extract this project:
   ```bash
   unzip football_ear_coach.zip
   cd football_ear_coach
   ```
3. (One-time) Generate platform folders and IDE configs:
   ```bash
   flutter create .
   ```
4. Fetch packages:
   ```bash
   flutter pub get
   ```
5. Build a release APK:
   ```bash
   flutter build apk --release
   ```
6. The APK will be at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

### Sideload on your phone
- Copy the APK to your Android device and **install** it.
- You might need to enable *Install unknown apps*.

## Customize
- Edit command lists in `lib/main.dart` under `defaultCategories`.
- Add your own commands in-app (persisted with SharedPreferences).
- Tweak difficulty by changing **Min/Max gap** sliders and **Duration**.

## Roadmap (optional)
- Multi-language prompt sets (pre-recorded audio assets)
- Drill programs (warmup → drills → match sim)
- Whistle/beep overlays
- Stats (commands per minute, adherence via watch button tap)

## License
MIT — free to use & modify.

**Made for Akhi.** 🟢
# football_ear_coach
# football_ear_coach
