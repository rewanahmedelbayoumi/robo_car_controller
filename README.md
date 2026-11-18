# RoboCar Controller – Flutter

Complete UI rebuild of the provided Flutter starter project, based on the supplied 10-screen reference image. The Flutter project contains **Splash, Onboarding, Connection Choice, Connection Confirmation, Home, Manual Control, Live Data, Sensors, Calibration, Run Program, Analytics, Bluetooth Discovery, and Settings**.

## Run on your machine

1. Extract this ZIP, open `robo_car_controller-main` in Android Studio / VS Code as a Flutter project.
2. Run `flutter pub get` to install Flutter packages (`flutter_blue_plus` and `permission_handler`).
3. Run `flutter run` (on an emulator or connected Android device).
4. For Wi-Fi control, connect your phone to `Humanoid_Robot_Setup` (or the ESP32's own AP). Use Settings or Connect to Robot to enter the address; default is **192.168.4.1**.
5. Bluetooth requires a physical phone, Bluetooth enabled, and Nearby Devices permission on Android. If your board broadcasts BLE, go to Bluetooth (BLE) and choose the device. If multiple writable GATT characteristics are discovered, select the actual command characteristic in Settings before sending commands.

## Firmware/API integration

- `GET http://192.168.4.1/status`: checks connectivity and polls status every 2 seconds.
- `POST http://192.168.4.1/command`: JSON payload e.g. `{ "command": "FORWARD", "speed": 60 }`; commands are `FORWARD`, `BACKWARD`, `LEFT`, `RIGHT`, `STOP`.
- The robot's actual firmware decides whether `speed` is supported. The slider does not guarantee PWM control without firmware support.
- BLE sends UTF-8 text `MANUAL:FORWARD` etc. on the selected writable GATT characteristic. Change the command format in `lib/services/robot_controller.dart` if firmware differs. **The firmware GATT UUID is not in the original uploaded starter project.**
- Distance, roll, pitch, yaw, and battery are shown as live values **only if the ESP32 includes them in its `/status` JSON**. The provided firmware integration description only establishes the status and command endpoints, so unsupported fields display `—`.
- The visual sample values (102.78 cm / 47.6°) are **explicitly labelled Preview / Sample Data**, never passed off as real measurements. They can be disabled in Settings.
- Bench Test and Auto Calibration try `POST /bench` and `POST /calibrate`, respectively. They require endpoints to exist in the ESP32 firmware; the app gives an error if not supported.
- Obstacle Avoidance is a UI preset only until a verified obstacle-avoidance firmware routine exists. It will not blindly execute an unsupported autonomous route.
- Manual movement is press-and-hold with an automatic STOP on release. Program steps also include STOP and an emergency STOP action.

## Files

- `lib/main.dart` – app and theme
- `lib/screens/welcome_screens.dart` – welcome, onboarding, Wi-Fi/BLE connection
- `lib/screens/home_shell.dart` – home dashboard and tab bar
- `lib/screens/robot_pages.dart` – manual control, sensors, calibration, programs, charts and settings
- `lib/services/robot_controller.dart` – HTTP/BLE connection and state
- `lib/widgets/robo_ui.dart` – green buttons, cards, chart, waves, shared widgets
- `assets/images/robot_cutout.png` – robot cropped from the reference image provided by the user

## Test

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Requires a Flutter SDK and network access for `flutter pub get`. Device integration must be validated against the actual ESP32 firmware and BLE GATT profile.
