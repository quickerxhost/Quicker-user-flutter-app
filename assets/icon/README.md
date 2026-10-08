# App Icon & Native Splash

Source images for the QuickerX launcher icon, generated from
`assets/images/logo_mark.png` (the emblem-only crop of the brand logo,
no wordmark text — reads better at small sizes than the full lockup).

- **`app_icon.png`** — 1024×1024, opaque off-white (#FDFDFD) background.
  Used for iOS and as the Android legacy/fallback icon. The logo fills
  ~88% of the canvas width.
- **`app_icon_foreground.png`** — 1024×1024, transparent background, emblem
  at ~72% scale for Android's adaptive-icon layer. Paired with the solid
  `adaptive_icon_background: "#FDFDFD"` color set in `pubspec.yaml`.

## Regenerating the actual launcher icons

These two PNGs are just the *source* — they don't become the real app
icon until you run the generator (requires the Flutter SDK):

```bash
flutter pub get
dart run flutter_launcher_icons
```

This writes the correctly-sized icon files into `android/app/src/main/res/mipmap-*/`,
`ios/Runner/Assets.xcassets/AppIcon.appiconset/`, and (if you build for
those targets) `web/icons/`, `windows/runner/resources/`, and
`macos/Runner/Assets.xcassets/AppIcon.appiconset/`.

The full config lives at the bottom of `pubspec.yaml` under the
`flutter_launcher_icons:` key. If the logo ever looks too small/large
again, adjust the `scale` values in the regeneration script below and
re-run both that script and the command above.

## Native splash screen — currently OFF

Android briefly shows its own OS-level launch background before the
Flutter engine starts, before handing off to the app's own
`SplashScreen` (`lib/features/splash/presentation/splash_screen.dart`,
which has the branding + progress indicator). A branded native splash
was tried here, but per request it's now disabled
(`flutter_native_splash`'s `android`/`ios`/`web` flags are all `false`
in `pubspec.yaml`) — the app goes straight from Android's plain default
background into the app's own loading screen, rather than showing two
separate branded screens back to back.

If a branded native splash was already generated on a previous build,
run this once to restore the platform defaults:

```bash
dart run flutter_native_splash:remove
```

To turn the branded native splash back on later, flip `android`/`ios`
back to `true` under `flutter_native_splash:` in `pubspec.yaml` and run
`dart run flutter_native_splash:create`.

## An unrelated issue you may still see: content only filling part of the screen

If the app renders into only part of the screen width, with a plain bar
down one side, that is **not** a Flutter layout bug —
`SplashScreen`'s background uses `Positioned.fill` inside a
`SizedBox.expand`, so it's forced to cover the entire `Scaffold`. If a
narrowed width still shows up, the cause is outside Flutter: it's the OS
letterboxing the app to a fixed aspect ratio. This is common on Android
12L+ and on Chinese OEM skins (MIUI, ColorOS, OriginOS, Funtouch) that
have a per-app "display size / full screen" toggle.

Fastest fix — check the device setting first:
**Settings → Apps → QuickerX → Display size** (or "Full screen display" /
"App scaling", naming varies by OEM) **→ enable full screen.**

If that setting isn't available or doesn't fix it, add this to
`android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<meta-data
    android:name="android.max_aspect"
    android:value="2.4" />
<meta-data
    android:name="android.allow_multiple_resumed_activities"
    android:value="true" />
```

and on the `<activity>` tag, add:

```xml
android:resizeableActivity="true"
```

## If you want to regenerate these source PNGs yourself

Both were produced from `assets/images/logo_mark.png` with Pillow:

```python
from PIL import Image

mark = Image.open("assets/images/logo_mark.png").convert("RGBA")
CANVAS = 1024

def make_icon(bg, out, scale, transparent=False):
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0) if transparent else bg)
    w = int(CANVAS * scale)
    h = int(w * mark.height / mark.width)
    resized = mark.resize((w, h), Image.LANCZOS)
    canvas.paste(resized, ((CANVAS - w) // 2, (CANVAS - h) // 2), resized)
    canvas.save(out)

make_icon((253, 253, 253, 255), "assets/icon/app_icon.png", scale=0.88)
make_icon(None, "assets/icon/app_icon_foreground.png", scale=0.72, transparent=True)
```
