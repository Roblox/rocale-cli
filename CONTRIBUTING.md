# Contributing to rocale-cli

Thank you for your interest in contributing to rocale-cli! This document covers how to get set up, make changes, and submit contributions.

## Getting Started

### Setup

1. Fork and clone the repository:
   ```sh
   git clone https://github.com/<your-username>/rocale-cli.git
   cd rocale-cli
   ```

2. Install toolchain dependencies:
   ```sh
   foreman install
   ```
   This installs Lute (Luau compiler), StyLua (formatter), and Rojo (build tool) at the pinned versions in `foreman.toml`.

3. Build:
   ```sh
   lute scripts/build
   ```
   The binary is output to `build/rocale-cli`.

## Development Workflow

### Building

```sh
lute scripts/build
```

### Running Tests

Tests run against a real Roblox place via Open Cloud APIs, so you'll need to set up a test environment:

1. [Create a new place](https://create.roblox.com/dashboard/creations) to use for testing.
2. Generate an [Open Cloud API Key](https://create.roblox.com/dashboard/credentials) with the following permissions for your place:
   - `universe-places:write`
   - `luau-execution-sessions:write`
3. Set the required environment variables:
   ```sh
   export TEST_UNIVERSE_ID=<your-universe-id>
   export TEST_PLACE_ID=<your-place-id>
   export ROBLOX_API_KEY=<your-api-key>
   ```
4. Run the tests:
   ```sh
   lute scripts/test
   ```

CI runs tests automatically on pull requests after a maintainer approves the change.

## Submitting Changes

1. Create a feature branch from `master`.
2. Make your changes.
3. Ensure the project builds and code is formatted with StyLua.
4. Open a pull request from your fork targeting the `master` branch.
5. Once a maintainer approves, CI will execute the test suite.

## Releases

Releases are handled by maintainers. To publish a new version:

1. [Draft a new release](https://github.com/Roblox/rocale-cli/releases/new) and create a new tag with the format `vx.x.x`.
2. CI automatically builds platform binaries (macOS, Linux, Windows) and attaches them to the release.
3. The release build bakes the version and commit hash into the binary via `lute scripts/build <version> $(git rev-parse HEAD)`.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
