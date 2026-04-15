---
applyTo: "**/*Tests.swift"
---

## Testing rules

### Framework
- Prefer **Swift Testing** for unit tests (`@Suite`, `@Test`, `#expect`, `#require`, `Issue.record()`). XCTest remains in use for UI tests and for memory leak tracking helpers (`trackForMemoryLeaks` via `XCTestCase` extension).
- Test types are `struct` with `@Suite("Description")`, not `class`.
- Mark tests that touch `@MainActor` ViewModels or `@Published` properties with `@MainActor`.

### Test structure
- Mirror the source code folder structure: `Landing page/Domain/Use cases/JoinRoomUseCaseTests.swift`.
- Name tests around behavior: `givenNoCategoriesThenProduceEmptyString()`, `createsAPublisherWithPassedUsername()`, or use `@Test("Should succeed with valid room name")`.
- For bug fixes, add a failing test first or clearly state why one is not feasible.

### System under test
- Use a `makeSUT()` factory function with defaulted mock parameters:
  ```swift
  private func makeSUT(
      userRepository: UserRepository = makeMockUserRepository(),
      publisherRepository: PublisherRepository = makePublisherRepositorySpy()
  ) -> JoinRoomUseCase { ... }
  ```
- This pattern ensures tests only specify the dependencies they care about.

### Mocks and spies
- **`Mock*`** — simple replacements with configurable return values (e.g., `MockHTTPClient` with `shouldThrowError`, `data`, `callCount`).
- **`*Spy`** — record interactions via an `actions: [ActionEnum]` array (e.g., `PublisherRepositorySpy` with `PublisherAction.get`, `.reset`, `.recreate`).
- Create mocks via `makeMock*()` factory functions (e.g., `makeMockUserRepository()`).
- Shared mocks live in `VERATestHelpers` (framework target inside `VERACore`). Module-specific test helpers go in `*AppTestHelpers` targets (e.g., `VERAChatAppTestHelpers`).

### Assertions
- Use `#expect(value == expected)` for equality checks.
- Use `#require(...)` as a guard that fails the test if the condition is not met.
- Use `Issue.record("message")` for custom failure messages in guard/switch fallthrough.
- Use `#expect(throws: ErrorType.self) { try await sut(...) }` for error assertions.
- Verify mock interactions: `#expect(repository.actions == [.save(user), .get])`.

### Async and Combine testing
- Test `@Published` properties by awaiting the `AsyncSequence`: `await sut.$state.values.first { $0 == .content }`.
- Test Combine publishers via `spy.subject.value = newValue` to inject state.
- Use the `delay()` helper from `VERATestHelpers/Helpers/Delay.swift` when you need a short async yield.

### Snapshot tests
- Use Point-Free's `SnapshotTesting` library via the `SnapshotTestHelper` in `VERACoreSnapshotTests/SnapshotTestHelpers.swift`.
- Helpers: `assertViewSnapshot(_:)` (size-that-fits), `assertViewSnapshot(_:width:height:)` (fixed size), `assertViewSnapshotsWithColorSchemes(_:)` (light + dark).
- Set `record: true` at the top of the file to record new baselines — never commit with `record: true`.
- Use `precision: 0.99` tolerance for device-specific snapshots.
- Snapshot images live in `__Snapshots__/` folders alongside the test files.
- Prefer focused unit tests over snapshot tests for logic — use snapshots only for visual regression of composed views.

### Coverage
- Cover disconnect, reconnect, and error paths when testing call-related code.
- Test both the enabled and disabled paths for feature-flagged behavior (e.g., `#if SETTINGS_ENABLED` null-object fallbacks).
