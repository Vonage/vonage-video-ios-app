---
applyTo: "VERA/**/VERACommonUI/**/*,VERA/**/VERACore/**/*"
---

## UI rules

### Architecture
- Views use MVVM: `ObservableObject` ViewModels with `@Published` properties, always annotated with `@MainActor`.
- Two-tier structure: `*Screen` (coordinator — observes ViewModel, maps state to actions) wraps a `*View` (stateless presentation). Keep this separation when adding new screens.
- Navigation is decoupled via the `ActionHandler` typealias (`(Action) -> Void`) — views emit `Action` enum cases, never perform navigation directly.

### Factory / Wireframe pattern
- Each flow has a `*Factory` class (in a `Wireframe/` folder) that constructs the ViewModel and View together.
- Factories receive all dependencies through their initialiser from `DependencyContainer`. ViewModels never instantiate their own dependencies.
- Some factories return `(view, viewModel)` tuples so the caller can retain the ViewModel for external control.
- Mark factory `make()` methods `@MainActor`.

### Reusable components (VERACommonUI)
- Prefer existing shared components: `FilledButton`, `OutlinedButton`, `ControlButton`, `CircularControlButton`, `CardView`, `AvatarInitials`, `AvatarGroup`, `ToastView`, `DismissibleOverlayModifier`.
- New shared components go in `VERACommonUI/UI/`. Use `@ViewBuilder` generic containers (see `CardView<Content: View>` pattern).
- Create `ViewModifier` types for reusable visual behaviors (see `AdaptiveFontModifier`, `HorizontalFlipModifier`, `Pulsating`).

### Design tokens
- Reference semantic colors via `VERACommonUIAsset.SemanticColors.*` (e.g., `.primary`, `.error`, `.surface`, `.textSecondary`). These are generated from `Theme/semantics.json` — do not hardcode hex values.
- Use `.adaptiveFont(_:)` modifier with `TypographyStyle` cases (`.headline`, `.bodyBase`, `.caption`, etc.) for responsive typography. This modifier adapts to horizontal/vertical size class.
- Use `BorderRadius` enum (`.none`, `.extraSmall`, `.small`, `.medium`, `.large`, `.extraLarge`) via the `.cornerRadius(_:)` extension.

### Domain separation
- `UIParticipant` wraps the domain `Participant` with UI-only state (`isPinned`, `canBePinned`, `onTogglePin`). Never add UI concerns to domain `Participant`.
- State derivation (e.g., `MeetingRoomState`) uses `Publishers.CombineLatest` to merge domain streams with UI preferences. Keep domain publishers and UI-only state in separate Combine chains.
- Do not import `VERAVonage` or any SDK module from `VERACommonUI` or `VERACore`.

### Localization
- Use the `String.localized()` extension or `String(localized:)` for user-facing text.
- String catalogs (`.xcstrings`) are located in each module's `Resources/`. Supported languages: English (en), Spanish (es).
- For pluralization use `String.pluralizeIfNeeded(count:)`.

### Previews
- Provide `#Preview` blocks for new components. Use `PreviewData` helpers for mock data.
- Include dark mode previews with `.preferredColorScheme(.dark)` for components that use semantic colors.

### Platform considerations
- Guard iOS 26+ glass morphism effects behind `if #available` with opaque material fallbacks.
- `VERACommonUI` and `VERACore` target both iOS 16+ and macOS 14.6+ — avoid UIKit-only APIs.
