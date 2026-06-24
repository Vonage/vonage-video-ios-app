# Vonage Video API Reference App for iOS

<img src="https://developer.nexmo.com/assets/images/Vonage_Nexmo.svg" height="48px" alt="Nexmo is now known as Vonage" />

## Welcome to Vonage

If you're new to Vonage, you can [sign up for a Vonage API account](https://dashboard.nexmo.com/sign-up?utm_source=DEV_REL&utm_medium=github&utm_campaign=vonage-video-ios-app) and get some free credit to get you started.

## What is it?

The Vonage Video API Reference App for iOS is an open-source video conferencing reference application built with the [Vonage Video API](https://developer.vonage.com/en/video/client-sdks/web/overview) and iOS SDK. It demonstrates best practices for integrating the Vonage Video API for use cases ranging from one-to-one calls to multi-participant conferencing with CallKit, screen sharing, captions, and more.

## Cross-Platform Support

The reference app is also available for:

- **Web (React)**: [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app)
- **Android**: [vonage-video-android-app](https://github.com/Vonage/vonage-video-android-app)

All three share the same backend infrastructure and demonstrate consistent best practices across platforms.

## Why use it?
The Vonage Video API Reference App for iOS provides developers an easy-to-set-up way to get started with using our APIs with the iOS SDK.

The application is open-source, so you can not only get started quickly, but easily extend it with features needed for your use case. Any features already implemented in the Reference App use best practices for scalability and security.

As a commercial open-source project, you can also count on a solid information security architecture. While no packaged solution can guarantee absolute security, the transparency that comes with open-source software, combined with the proactive and responsive open-source community and vendors, provides significant advantages in addressing information security challenges compared to closed-source alternatives.

This application provides features for common conferencing use cases, such as:

- <details>
    <summary>A landing page for users to create and join meeting rooms.</summary>
    <img src="docs/assets/Welcome.png" alt="Screenshot of landing page">
  </details>

- <details>
    <summary>A waiting room for users to preview their audio and video device settings and set their name before entering a meeting room.</summary>
    <img src="docs/assets/WaitingRoom.png" alt="Screenshot of waiting room">
  </details>
- <details>
    <summary>A post-call page to navigate users to the landing page, re-enter the left room, and display archive(s), if any.</summary>
    <img src="docs/assets/Goodbye.png" alt="Screenshot of goodbye page">
  </details>

- A video conferencing “room” supporting up to 25 participants and the following features:

- <details>
    <summary>
      Configurable features: adapt the app to your specific use cases and roles.
      Configuration is handled through a <em>app-config.json</em> file that can be moved to the <em>VERA/config</em> folder. When calling the <em>generate-app-config.py</em> python script in the <em>VERA/Scripts</em> folder, the parameters specified in the <em>app-config.json</em> file will regenerate the <em>AppConfig.swift</em> file of the <em>VERAConfiguration</em> module.
    </summary>
    <img src="docs/assets/configFile.png" alt="Screenshot of a config.json">
</details>

- <details>
    <summary>Call participant list with audio on/off indicator.</summary>
    <img src="docs/assets/ParticipantList.png" alt="Screenshot of participant list">
  </details>
  
- ShareLink integration.

- Active speaker detection.

- Start, stop and download cloud-based session recording directly from the app.

- Apply real-time background effects to the local video stream, including background blur and background replacement.

- <details>
  <summary>Display live captions for enhanced accessibility.</summary>
    <img src="docs/assets/captions.png" alt="Screenshot of live captions feature">
  </details>

- <details>
  <summary>Send and receive emoji reactions during a video session.</summary>
    <img src="docs/assets/reactions.png" alt="Screenshot of reactions feature">
  </details>

- Layout manager with options to display active speaker, or all participants in a grid view.

- The dynamic display adjusts to show new joiners, hide video tiles to conserve bandwidth, and show the “next” participant when someone previously speaking leaves.

- CallKit: Helps iOS to coordinate the calling services with other apps.

- Screen sharing, enabling participants to broadcast their device screen into a Vonage video call using Apple's ReplayKit framework.

- In-call chat, allowing participants to exchange text messages during the video session.

- Settings controls, allowing participants to preconfigure publisher options in the waiting room and adjust video resolution, codec preferences, publisher settings, and call statistics during the meeting.

- Advanced noise suppression, helping reduce background noise from the local microphone during a call.

- Audio route selection, allowing users to switch the call audio output between available routes such as speaker, Bluetooth, or other system-supported devices.


## Platforms & Requirements

| Requirement | Version |
|---|---|
| iOS deployment target | 16.0+ |
| Xcode | 26 |
| Tuist | latest |
| SwiftLint | latest |
| SwiftFormat (swift-format) | latest |
| Git LFS | any |
| Java | 17 (Maestro E2E only) |

Core framework modules also target **macOS 14.6+** to enable fast unit-test runs without a simulator.

This app has been tested with **Vonage Video SDK 2.32** and **2.33**. Use the latest available SDK version where possible.

## Documentation

| Guide | Description |
|---|---|
| [Getting Started](docs/GETTING_STARTED.md) | Prerequisites, environment setup, and first run |
| [Architecture](docs/ARCHITECTURE.md) | Project architecture, module overview, Clean Architecture layers, DI, and key patterns |
| [Configuration](docs/CONFIGURATION.md) | Feature flags, theme tokens, signing, and SDK version |
| [Testing](docs/TESTING.md) | Unit, snapshot, and Maestro E2E tests |
| [Localization](docs/LOCALIZATION.md) | Adding languages and working with String Catalogs |
| [Code Style](docs/CODE_STYLE.md) | SwiftLint, swift-format, and style guidelines |
| [Contributing](docs/CONTRIBUTING.md) | How to open issues, submit PRs, and branching conventions |
| [Known Issues](docs/KNOWN_ISSUES.md) | Current known issues and workarounds |

## Contributing

Read [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) before opening a pull request. In short: open an issue first for anything beyond a minor bug fix, keep PRs small and focused, and ensure CI passes.

Please also read our [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Help

- Open an issue on this repository
- Tweet at us: [@VonageDev on Twitter](https://twitter.com/VonageDev)
- [Join the Vonage Developer Community Slack](https://developer.vonage.com/community/slack)
- Email support: [support@api.vonage.com](mailto:support@api.vonage.com)

## Further Reading

- Developer documentation: <https://developer.vonage.com>
