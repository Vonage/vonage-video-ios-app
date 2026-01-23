# Vonage Video API Reference App for iOS (Beta)

<img src="https://developer.nexmo.com/assets/images/Vonage_Nexmo.svg" height="48px" alt="Nexmo is now known as Vonage" />

## Welcome to Vonage

If you're new to Vonage, you can [sign up for a Vonage API account](https://dashboard.nexmo.com/sign-up?utm_source=DEV_REL&utm_medium=github&utm_campaign=vonage-video-ios-app) and get some free credit to get you started.

## What is it?

The Vonage Video API Reference App for iOS is an open-source video conferencing reference application for the [Vonage Video API](https://developer.vonage.com/en/video/client-sdks/web/overview) using the iOS SDK.

The Reference App demonstrates the best practices for integrating the [Vonage Video API](https://developer.vonage.com/en/video/client-sdks/web/overview) with your application for various use cases, from one-to-one and multi-participant video calling to CallKit integration and more.

## Cross-Platform Support

Looking to build on other platforms? The Vonage Video API Reference App is also available for:

- **Web (React)**: [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app)
- **Android**: [vonage-video-android-app](https://github.com/Vonage/vonage-video-android-app)

These reference apps share the same backend infrastructure and demonstrate consistent best practices across all platforms, making it easy to build unified video experiences for your users.

## Why use it?
The Vonage Video API Reference App for iOS provides developers an easy-to-setup way to get started with using our APIs with the iOS SDK.

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
      Configuration is handled through a <em>app-config.json</em> file that can be moved to the <em>VERA/config</em> folder. When calling to the <em>generate-app-config.py</em> python script in the <em>VERA/Scripts</em> folder, the parameters specified in the <em>app-config.json</em> file will regenerate the <em>AppConfig.swift</em> file of the <em>VERAConfiguration</em> module.
    </summary>
    <img src="docs/assets/configFile.png" alt="Screenshot of a config.json">
</details>

- <details>
    <summary>Call participant list with audio on/off indicator.</summary>
    <img src="docs/assets/ParticipantList.png" alt="Screenshot of participant list">
  </details>
  
- ShareLink integration.

- Active speaker detection.

- Layout manager with options to display active speaker, or all participants in a grid view.

- The dynamic display adjusts to show new joiners, hide video tiles to conserve bandwidth, and show the “next” participant when someone previously speaking leaves.

- CallKit: Helps iOS to coordinate the calling services with other apps.

## Project Architecture

This reference app requires the user to deploy a backend and then use the backend API URL as the base URL in the <em>DependencyContainer.swift</em> file of the VERAApp module. You can find backend code and deploying instructions in the [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app) repository.

The backend communicates with the Vonage video platform using the Vonage Server SDK and is responsible of generating the session IDs and tokens used to connect to the video rooms by the Vonage Client SDK.

## Module Overview

The Vonage iOS reference app is built with a modular architecture. The app is organized into the following frameworks:


- **VERAApp**: Main application target and composition root
- **VERACore**: UI and business logic of the main views
- **VERAChat**: Meeting room chat
- **VERAVonageChatPlugin**: Adapts the chat to the plugin interfaces
- **VERAVonageCallKitPlugin**: CallKit adapter plugin
- **VERADomain**: Shared domain models and entities
- **VERAConfiguration**: Holds the app configuration specification
- **VERACommonUI**: Shared UI components and resources
- **VERAVonage**: Vonage Video SDK integration

## Platforms supported

The current minimum deployment target for the reference app iOS 16+. Some of the mentioned modules are universal, which allows fast testing against macOS targets and platform reusability. For this last point it would be required to adapt the non universal modules to the desired platform.

## Requirements

- **Xcode 26**
- **Tuist**

## Running Locally

First follow the steps to create the Vonage account, application and backend set up and deployment at the [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app?tab=readme-ov-file#running-locally) URL.

Then you can specify the `DEVELOPMENT_TEAM`, `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the `regenerateSigningConfig.sh` script and execute it to generate the Signing.xcconfig file in the VERA/Config folder.

```
DEVELOPMENT_TEAM = YOUR_DEVELOPMENT_TEAM
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
```

For the `BASE_API_URL` modify the `EnvironmentConstants.swift` and the `VERA.entitlements` files. Or expose it as an environment variable and then execute `generateEnvironmentConstants.sh`.

```
export BASE_API_URL=https://api.example.com/
.VERA/Scripts/generateEnvironmentConstants.sh
```

Then install [Tuist](https://docs.tuist.dev/en/guides/quick-start/install-tuist), it's required for the project generation.

Once you have Tuist installed generate a new project by typing the following commands in the command line:

```bash
cd VERA
tuist generate
```

Tuist will generate and launch a new Xcode workspace based on the <em>Project.swift</em> definitions. Every module has one <em>Project.swift</em> file where all the targets, SPM dependencies and project details are declared using the Tuist DSL. This unlocks dynamic project generation based on configuration files, simplified merging conflict resolution and some other nice features.

Modify the base URL constant in the <em>DependencyContainer.swift</em> file in the <em>VERAApp</em> module.

Run the VERA app target in Xcode.

## Feature configuration

You can fork the repository and start modifying it for your needs. Or you also can modify the <em>app-config.json</em> file of the VERA/Config folder and then run the VERA/Scripts/generate-app-config.py python script. This will generate a Swift file with all the flags to customize the features of the app. 

Note that some of the features declared in the JSON file are not yet implemented.

Once the <em>app-config.json</em> is configured the <em>Tuist generate</em> command will read the json file and configure the project by only adding the required modules.

## Theme customization

You can customize the app colors by editing the <em>semantics.json</em> file light and dark color scheme values and then by executing the <em>generate-app-theme.py</em> Script in the VERA/Scripts folder. This will generate the xcasset resources with the specified RGB values in the <em>VERACommonUI</em> module.

## Testing

This project uses the <em>Swift Testing</em> framework for the unit, integration and snapshot tests. 

Tuist will generate the testing schemes for all the modules, then for testing you could execute the tests by running the <em>tuist test</em> command or by executing them with `⌘U` in the selected testing target in Xcode.

You can also edit the snapshot test images by recording new screenshots in the snapshot testing files.

## Code style

We use Swift Lint to format and fix the code linting. Check if the code follows the linting rules by running the <em>./Scripts/format.sh</em> or <em>./Scripts/format.sh --fix</em> for fixing the formatting in the command line.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Involved

If you wish to contribute to this project, read how in [Contributing](./docs/CONTRIBUTING.md).

## Known Issues

We track known issues in [Known Issues](./docs/KNOWN_ISSUES.md). Please refer to it for details.

## Report Issues

If you have any issues, feel free to open an issue or reach out to support via [support@api.vonage.com](support@api.vonage.com).

## Getting Help

We love to hear from you so if you have questions, comments or find a bug in the project, let us know! You can either:

* Open an issue on this repository
* Tweet at us! We're [@VonageDev on Twitter](https://twitter.com/VonageDev)
* Or [join the Vonage Developer Community Slack](https://developer.vonage.com/community/slack)

## Further Reading

* Check out the Developer Documentation at <https://developer.vonage.com>