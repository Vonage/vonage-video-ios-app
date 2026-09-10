# Authentication

The Vonage Video iOS Reference App supports optional authentication via an external identity provider (IdP). The current implementation integrates [Okta](https://developer.okta.com/) using the [okta-mobile-swift](https://github.com/okta/okta-mobile-swift) SDK for browser-based OIDC sign-in.

Authentication is gated behind two separate compilation conditions and can be toggled on or off via `app-config.json` without affecting the rest of the codebase:

| Compilation condition | Controlled by | Purpose |
|---|---|---|
| `AUTHENTICATION_ENABLED` | `authSettings.allowAuthentication` | Enables the general authentication infrastructure (auth UI, token injection decorator) |
| `OKTA_ENABLED` | `"okta"` present in `authSettings.idProviders` | Compiles the `VERAOKTA` module and registers the Okta identity provider |

This separation allows the architecture to support multiple identity providers independently. A provider can be added to or removed from `idProviders` without affecting the auth infrastructure itself.

## Architecture Decisions

### Domain-level abstraction

Authentication concepts live in **VERADomain** — the innermost layer with no SDK imports:

| Type | Role |
|---|---|
| `AuthState` | Enum representing `.notAuthenticated` or `.authenticated(AuthenticatedUser)` |
| `AuthenticatedUser` | Value type holding name, email, and computed initials |
| `AuthStateDataSource` | Protocol publishing reactive `AuthState` changes via Combine |
| `IDProvider` | Value type representing an identity provider (id + display name) |

This means no module outside `VERAOKTA` needs to know about Okta — they only depend on domain protocols.

### VERAOKTA module

`VERAOKTA` is an optional feature module structured in the following layers:

```
VERAOKTA/
├── Domain/
│   ├── Repository/
│   │   └── OKTAAuthenticating.swift      # Protocol for sign-in/sign-out/token
│   └── Use cases/
│       └── OKTAUseCase.swift             # TokenProvider protocol
├── Data/
│   ├── OKTADataSource.swift              # OktaAuthManager (okta-mobile-swift wrapper)
│   └── OktaTokenProvider.swift           # Bridges @MainActor auth manager → Sendable token access
├── UI/
│   └── View/
│       └── SignInView.swift              # Generic IdP picker sheet
├── Wireframe/
│   └── OKTAFactory.swift                 # Composes the sign-in UI
├── Utils/
│   └── Bundle+VERAOKTA.swift
└── Resources/
    └── Localizable.xcstrings
```

### Token injection via decorator

Rather than scattering authentication headers throughout the networking layer, the app uses a **decorator pattern**:

```
URLSessionHTTPClient  →  TokenInjectingHTTPClient  →  Network
```

`TokenInjectingHTTPClient` wraps any `HTTPClient` and prepends an `Authorization: Bearer` header using the `TokenProvider` protocol. This keeps the base HTTP client unaware of authentication and makes the decorator trivial to test.

### Conditional compilation

Authentication uses two compilation conditions derived from `app-config.json`:

**`AUTHENTICATION_ENABLED`** — derived from `authSettings.allowAuthentication`:
- Gates the general authentication UI (toolbar button, sign-in sheet) in `VERAApp`.
- When disabled, the app compiles without any authentication infrastructure.

**`OKTA_ENABLED`** — derived from `"okta"` being present in `authSettings.idProviders`:
- Gates the `VERAOKTA` module as a dependency.
- When disabled, the Okta SDK is not pulled in and `OktaAuthManager` is not compiled.
- `DependencyContainer` and `AppHTTPClientProvider` use `#if OKTA_ENABLED` to conditionally wire Okta-specific types.

In practice, `OKTA_ENABLED` is nested inside `AUTHENTICATION_ENABLED` — disabling authentication removes all provider code, while disabling a specific provider only removes that provider's module.

> **Note:** Authentication is **disabled by default** in the committed `app-config.json`. This is intentional — the reference app showcases Vonage Video best practices, and authentication is something developers integrate separately for their own infrastructure. CI and local development environments enable the flag explicitly to test the Okta module.

### UI integration

Two shared UI components in `VERACommonUI` handle the authentication experience without importing `VERAOKTA`:

- **`NavBarAuthButton`** — A toolbar button that shows a person icon (not authenticated) or user initials (authenticated). It delegates sign-in/sign-out to closures provided by the composition root.
- **`NavBarAuthButtonViewModel`** — Observes `AuthStateDataSource` and publishes state to the button.

The sign-in flow itself is presented as a `.sheet` with `SignInView`, which receives a list of `IDProvider`s and a callback. This design allows adding more identity providers in the future without changing the UI.

## Okta Configuration

The Okta SDK reads its configuration from `Okta.plist` in the app's main bundle. This file contains OIDC client credentials and **must not be committed to the repository**. It is generated at build time from environment variables into `VERAApp/VERA/Resources/Okta.plist`.

### Plist structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>issuer_url</key>
    <string>https://your-org.okta.com</string>
    <key>client_id</key>
    <string>your_okta_client_id</string>
    <key>redirect_uri</key>
    <string>https://your-app.example.com/api/auth/callback/okta</string>
    <key>logout_redirect_uri</key>
    <string>https://your-app.example.com</string>
    <key>scope</key>
    <string>openid profile offline_access</string>
</dict>
</plist>
```

| Key | Description |
|---|---|
| `issuer_url` | Your Okta authorization server URL |
| `client_id` | The OIDC client ID registered in your Okta application |
| `redirect_uri` | The URI Okta redirects to after authentication |
| `logout_redirect_uri` | The URI Okta redirects to after sign-out |
| `scope` | OIDC scopes (default: `openid profile offline_access`) |

## Setup

### Local development

1. Copy the example file and fill in your values:

   ```bash
   cd VERA
   cp Scripts/setUpOkta.example.sh Scripts/setUpOkta.sh
   ```

2. Edit `Scripts/setUpOkta.sh` with your Okta application credentials:

   ```bash
   export OKTA_ISSUER_URL=https://your-org.okta.com
   export OKTA_CLIENT_ID=your_okta_client_id
   export OKTA_REDIRECT_URI=https://your-app.example.com/api/auth/callback/okta
   export OKTA_LOGOUT_REDIRECT_URI=https://your-app.example.com
   export OKTA_SCOPE="openid profile offline_access"
   ```

3. Run the setup script:

   ```bash
   ./Scripts/setUpOkta.sh
   ```

   This enables `authSettings.allowAuthentication` in `app-config.json` and generates `VERAApp/VERA/Resources/Okta.plist`.

> **Note:** `Scripts/setUpOkta.sh` and `Okta.plist` are both listed in `.gitignore` and will not be committed.

### CI (GitHub Actions)

In CI, the same script is invoked with GitHub Secrets:

```yaml
export OKTA_ISSUER_URL=${{ secrets.OKTA_ISSUER_URL }}
export OKTA_CLIENT_ID=${{ secrets.OKTA_CLIENT_ID }}
export OKTA_REDIRECT_URI=${{ secrets.OKTA_REDIRECT_URI }}
export OKTA_LOGOUT_REDIRECT_URI=${{ secrets.OKTA_LOGOUT_REDIRECT_URI }}
./Scripts/generateOktaConfig.sh
```

Add the following secrets to your GitHub repository settings:

| Secret | Value |
|---|---|
| `OKTA_ISSUER_URL` | Okta authorization server URL |
| `OKTA_CLIENT_ID` | OIDC client ID |
| `OKTA_REDIRECT_URI` | Post-login redirect URI |
| `OKTA_LOGOUT_REDIRECT_URI` | Post-logout redirect URI |

## Enabling / Disabling

Authentication is **disabled by default** in `VERA/Config/app-config.json`. Two settings control compilation:

```json
{
  "authSettings": {
    "allowAuthentication": true,
    "idProviders": ["okta"]
  }
}
```

| Key | Effect |
|---|---|
| `allowAuthentication` | `true` injects `AUTHENTICATION_ENABLED` — compiles the auth UI and token injection infrastructure |
| `idProviders` | Array of provider identifiers. Including `"okta"` injects `OKTA_ENABLED` and adds the `VERAOKTA` module as a dependency |

For local development, the `setUpOkta.sh` script handles both automatically (see [Setup](#setup)).

After changing the values, regenerate the app config and workspace:

```bash
cd VERA
python3 ./Scripts/generate-app-config.py
tuist generate
```

## Extending with Additional Providers

The architecture is designed to support multiple identity providers. To add a new one:

1. Create a new module (e.g., `VERAAuth0`) implementing `TokenProvider` and `AuthStateDataSource`.
2. Register the new `IDProvider` in `DependencyContainer`.
3. The existing `SignInView` will display it alongside Okta without any UI changes.
