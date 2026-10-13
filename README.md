# 💪 Stronger — Fitness & AI Coach

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Firebase_AI_Logic-Gemini_3.6-4285F4?logo=google&logoColor=white)
[![CI](https://github.com/marwix127/Stronger/actions/workflows/ci.yml/badge.svg)](https://github.com/marwix127/Stronger/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/coverage-85.6%25-brightgreen)

**English** · [Español](README.es.md)

Stronger is a Flutter app for logging workouts, tracking how your body changes
over time, and getting guidance from an AI coach that actually knows your
history. I built it as a portfolio project, so the emphasis is on the things
that are easy to skip in a side project: a clear architecture, data that stays
isolated per user, an automated test suite, and an AI integration that doesn't
leak credentials into a mobile binary.

## Screenshots

|    Home     | Workout |    AI Coach    |    Progress    |    Body    |    Fatigue    |
|---|---|---|---|---|---|
| <img src="docs/screenshots/menu.jpg" alt="Home" width="150"> | <img src="docs/screenshots/training.jpg" alt="Workout" width="150"> | <img src="docs/screenshots/chat.jpg" alt="AI Coach" width="150"> | <img src="docs/screenshots/graphic.jpg" alt="Progress" width="150"> | <img src="docs/screenshots/body.jpg" alt="Body" width="150"> | <img src="docs/screenshots/fatigue.jpg" alt="Fatigue" width="150"> |

## Features

- Email sign-in with Firebase Auth.
- Create, edit and browse workouts, with drafts saved locally so an
  interrupted session isn't lost.
- A shared base catalogue of exercises, plus custom exercises that are private
  to each user.
- Set suggestions based on your previous session of the same exercise.
- Charts for training volume, average weight and body composition: weight,
  body fat, muscle mass, and a muscle-to-fat index that tells you at a glance
  whether your composition is improving, whether you're bulking or cutting.
- A body map that estimates muscle fatigue per muscle group and models how it
  recovers over the following days.
- A contextual AI coach that reads your training history and body
  measurements before answering.
- Account deletion that removes workouts, measurements, fatigue data and
  custom exercises in one go.
- Light and dark themes, and declarative navigation with GoRouter.

## How the AI integration works

```text
Flutter ── Firebase Auth (+ App Check where available) ──> Firebase AI Logic ──> Gemini
   │
   └── Firestore: the signed-in user's data
```

The app uses the official `firebase_ai` SDK. Requests go through the Firebase
AI Logic proxy, so the Gemini credential never lives in the source code, the
APK or the web build. The whole setup runs on the Spark plan and the Gemini
Developer API free tier.

Before every reply, the coach receives a compact, sanitised summary of the
user's recent workouts and body measurements — muscle-to-fat index included —
and is told to treat that data as context, never as instructions.

One honest caveat: App Check protects the web build (reCAPTCHA v3) and debug
builds, but it's deliberately left off in Android release builds. Play
Integrity can only attest apps that Google Play recognises, and Stronger ships
as a direct APK download. That trade-off, and what Firebase's upcoming
enforcement deadline means for it, is written up in
[docs/releases.md](docs/releases.md). Setting up the AI service itself is
covered in [docs/ai.md](docs/ai.md).

## Tech stack

| Area | Technology |
|---|---|
| App | Flutter and Dart 3 |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| AI | Firebase AI Logic + Gemini 3.6 Flash |
| Abuse protection | Firebase App Check |
| State | Provider + ChangeNotifier |
| Navigation | GoRouter |
| Charts | fl_chart |
| Local persistence | SharedPreferences |

## Getting started

Android is the primary platform. You'll need Flutter 3.44 (the version CI
uses), the Android SDK, and a device or emulator to run on.

```bash
git clone https://github.com/marwix127/Stronger.git
cd Stronger
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

The repository ships with the native Android and iOS configuration of the
demo project. To point a fork at your own backend, create a Firebase project,
enable email sign-in in Authentication and Cloud Firestore, and regenerate the
configuration:

```bash
npm install --global firebase-tools@15.17.0
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
firebase deploy --project PROJECT_ID --only firestore:rules
```

Then enable Firebase AI Logic and App Check following the
[AI setup guide](docs/ai.md). There's no `variables.env`, no Gemini API key to
manage and no Cloud Functions to deploy. The client identifiers and API keys
that FlutterFire generates identify the Firebase project; they're not Gemini
secrets.

### Platforms

| Platform | Status |
|---|---|
| Android | Primary platform; build and E2E run automatically in CI |
| iOS | Native configuration included, no automated validation in CI |
| Web, Windows and macOS | Run `flutterfire configure` before first use |
| Linux | Firebase not configured |

Web also needs the public site key of the App Check provider:

```bash
flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=public_site_key
```

## Releases

The app is distributed as an APK from the
[repository releases](../../releases). It isn't on Google Play, so it's
installed manually and doesn't update itself.

Publishing a version is pushing a tag: `git tag v2.1.0 && git push --tags`.
From there, the `release.yml` workflow checks that the tag matches `pubspec.yaml`,
runs the analyzer and the test suite, builds and signs the APK, verifies it
isn't signed with debug keys, and attaches it to a GitHub release. The full
process — generating the keystore, the secrets the workflow expects, and the
App Check trade-off mentioned above — lives in the
[release guide](docs/releases.md).

## Quality

```bash
flutter analyze
flutter test
flutter test --coverage
flutter build apk --debug
```

The suite covers the domain models, the Firestore services, safe formatting of
the AI context, validation of structured responses, fatigue recovery, isolation
of custom exercises, and account data deletion.

Critical flows are also exercised end to end on Android against an isolated
Firebase Emulator Suite. The [testing strategy](docs/testing.md) describes
what that covers, the safety guarantees, and how to run it locally.

Firestore security rules are validated against the real emulator:

```bash
npm ci --prefix firebase-tests
npx --yes firebase-tools@15.17.0 emulators:exec --only firestore \
  --project stronger-rules-test "npm test --prefix firebase-tests"
```

At the time of writing the Flutter suite holds 181 unit, widget and flow
tests with 85.6% instrumented line coverage, plus one Android E2E scenario and
9 rules tests covering anonymous access, isolation between users, and
ownership of custom exercises.

GitHub Actions runs static analysis, the Flutter suite, an 80% coverage gate,
a debug APK build, the rules tests and the E2E on a clean Android emulator on
every `push` and `pull request`. Tags matching `v*` additionally trigger the
release workflow.

## Project structure

```text
lib/
├── models/                        # Domain entities
├── infrastructure/services/
│   ├── firebase/                  # Auth and persistence
│   ├── coach_service.dart         # AI coach via Firebase AI Logic
│   ├── body_index_calculator.dart # Muscle-to-fat index
│   └── muscle_fatigue_service.dart
├── UI/pages/                      # Screens
├── UI/widgets/                    # Reusable components
├── theme/                         # Light and dark themes
└── router.dart                    # Routes and navigation guards
test/                              # Unit, widget and flow tests
integration_test/                  # Android E2E scenario
firebase-tests/                    # Rules tests against the Emulator Suite
firestore.rules                    # Authorisation and data isolation
.github/workflows/                 # Continuous integration and releases
docs/                              # Setup guides and portfolio material
```

## License

Released under the MIT License. See [LICENSE](LICENSE).
